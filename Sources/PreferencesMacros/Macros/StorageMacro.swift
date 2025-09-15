// MIT License
//
// Copyright (c) 2024 Fatbobman(东坡肘子)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import MacroToolkit

public struct StorageMacro: AccessorMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingAccessorsOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AccessorDeclSyntax] {
		print("Running StorageMacro accessor macro")
		guard
			let variable = Variable(declaration)
		else {
			context.diagnose(StorageDiagnostics.notAttachedToAVariableDeclaration(at: declaration))
			return []
		}

		guard
			let patternBinding = variable.bindings.first,
			let identifier = patternBinding._syntax.pattern.as(IdentifierPatternSyntax.self),
			// TODO: This line isn't working... why?
			// variable._syntax.bindingSpecifier == .keyword(.var)
			variable._syntax.bindingSpecifier.text == "var"
		else {
			context.diagnose(StorageDiagnostics.notMutable(at: variable._syntax))
			return []
		}

		guard variable.isStoredProperty else {
			context.diagnose(StorageDiagnostics.declarationHasAccessorBlock(at: variable._syntax))
			return []
		}

		guard patternBinding._syntax.initializer != nil else {
			context.diagnose(StorageDiagnostics.requiresInitializer(at: variable._syntax))
			return []
		}

		let arguments = InitializerArguments(from: node)
		let key = arguments.key ?? identifier.identifier.text

		var accessors = [AccessorDeclSyntax]()

		switch arguments.storage {
		case .memory:
			accessors.append(memoryStorageGetter(for: identifier))
			accessors.append(memoryStorageSetter(for: identifier))
		case .keychain:
			accessors.append(keychainStorageGetter())
			accessors.append(keychainStorageSetter())
		case .defaults:
			accessors.append(defaultsStorageGetter(key, for: identifier))
			accessors.append(defaultsStorageSetter(key, for: identifier))
		}

		return accessors
	}

	private static func memoryStorageGetter(for identifier: IdentifierPatternSyntax) -> AccessorDeclSyntax {
		"""
		get {
			access(keyPath: \\.\(identifier))
			return _\(identifier) 
		}
		"""
	}

	private static func memoryStorageSetter(for identifier: IdentifierPatternSyntax) -> AccessorDeclSyntax {
		"""
		set {
			withMutation(keyPath: \\.\(identifier)) {
				_\(raw:identifier) = newValue
			}
		}
		"""
	}

	private static func keychainStorageGetter() -> AccessorDeclSyntax {
		"""
		"""
	}

	private static func keychainStorageSetter() -> AccessorDeclSyntax {
		"""
		"""
	}

	private static func defaultsStorageGetter(_ key: String, for identifier: IdentifierPatternSyntax) -> AccessorDeclSyntax {
		"""
		get {
			access(keyPath: \\.\(identifier)) 
			return _defaults.value(forKey: key) ?? _\(identifier)
		}
		"""
	}

		private static func defaultsStorageSetter(_ key: String, for identifier: IdentifierPatternSyntax) -> AccessorDeclSyntax {
		"""
		set {
			withMutation(keyPath: \\.\(identifier)) {
				_defaults.setValue(newValue, forKey: key)
			} 
		}
		"""
	}

	struct InitializerArguments {
		let key: String?
		let storage: Storage

		init(from node: AttributeSyntax) {
			let attribute = MacroAttribute(node)

			key = attribute.argument(labeled: "key")?.asStringLiteral?.value

			if
				let expr = attribute.argument(labeled: "in")?._syntax,
				let memberAccess = MemberAccessExprSyntax(expr)
			{
				storage = Storage(rawValue: memberAccess.declName.baseName.text) ?? .keychain
			} else {
				storage = .keychain
			}
		}
	}
}


extension StorageMacro: PeerMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingPeersOf declaration: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext,
	) throws -> [DeclSyntax] {
		print("Running StorageMacro peer macro")
		guard
			let variable = Variable(declaration)
		else {
			context.diagnose(StorageDiagnostics.notAttachedToAVariableDeclaration(at: declaration))
			return []
		}

		guard variable.isStoredProperty else {
			context.diagnose(StorageDiagnostics.declarationHasAccessorBlock(at: variable._syntax))
			return []
		}

		let bindings = variable
			.bindings
			.map(\._syntax)
			.compactMap { node in
				guard let identifier = node.pattern.as(IdentifierPatternSyntax.self) else { return node }

				return PatternBindingSyntax(
					leadingTrivia: node.leadingTrivia,
					pattern: IdentifierPatternSyntax(
						leadingTrivia: identifier.leadingTrivia,
						identifier: TokenSyntax(
							.identifier("_" + identifier.identifier.text),
							leadingTrivia: identifier.identifier.leadingTrivia,
							trailingTrivia: identifier.identifier.trailingTrivia,
							presence: identifier.identifier.presence
						),
						trailingTrivia: identifier.trailingTrivia
					),
					typeAnnotation: node.typeAnnotation,
					initializer: node.initializer,
					accessorBlock: node.accessorBlock,
					trailingComma: node.trailingComma,
					trailingTrivia: node.trailingTrivia
				)
			}

		let storage = VariableDeclSyntax(
			leadingTrivia: variable._syntax.leadingTrivia,
			attributes: [], // This is to stop recursive expansion - but we should probably filter out just 'Stored'
			modifiers: variable._syntax.modifiers,
			bindingSpecifier: TokenSyntax(
				variable._syntax.bindingSpecifier.tokenKind,
				leadingTrivia: .space,
				trailingTrivia: .space,
				presence: .present
			),
			bindings: PatternBindingListSyntax(bindings),
			trailingTrivia: variable._syntax.trailingTrivia
		)

		return [storage].map { DeclSyntax($0) }
	} 
}

extension StorageMacro {
	enum Storage: String {
		case memory
		case keychain
		case defaults
	}
}
