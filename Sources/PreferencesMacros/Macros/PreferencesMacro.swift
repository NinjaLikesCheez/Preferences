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

public struct PreferencesMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// Ensure we're attaching to a class (we use Observable, it has to be attached to a class)
		guard let classDeclaration = declaration as? ClassDeclSyntax else {
			context.diagnose(PreferencesDiagnostics.notAttachedToClassDeclaration(at: declaration))
			return []
		}

		// Find all the properties that should be stored
		let storedProperties = classDeclaration
			.memberBlock
			.members
			.compactMap { Variable($0.decl) }
			.compactMap { variable -> Variable? in
				// Check that the variable is not marked with the '@Stored(in: .memory)' macro
				if let storedAttribute = variable.attribute(named: MacroNames.stored.rawValue) {
					guard
						let argumentValue = storedAttribute.asMacroAttribute?.argument(labeled: "in"),
						let memberAccessExpression = argumentValue._syntax.as(MemberAccessExprSyntax.self),
						memberAccessExpression.declName.baseName.text != "memory"
					else { return nil }
				}

				return variable.isStoredProperty ? variable : nil
			}

			// TODO: Add stored to all of the stored properties

		/* Build out the observation mechanisms */
		let registrarSyntax: DeclSyntax =
		"""
		internal let _$observationRegistrar = Observation.ObservationRegistrar()
		"""

		let initializer = InitializerArguments(from: node)
		let userDefaultStoreSyntax: DeclSyntax = if let name = initializer.name {
			"""
			private var _defaults: UserDefaults = UserDefaults(suiteName: "\(raw: name)")
			"""
		} else {
			"""
			private var _defaults: UserDefaults = UserDefaults.standard
			"""
		}

		return [
			registrarSyntax,
			userDefaultStoreSyntax
		]
	}

	struct InitializerArguments {
		let name: String?

		init(from node: AttributeSyntax) {
			let attribute = MacroAttribute(node)

			name = attribute.argument(labeled: "named")?.asStringLiteral?.value
		}
	}
}

extension PreferencesMacro: MemberAttributeMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo declaration: some DeclGroupSyntax,
		providingAttributesFor member: some DeclSyntaxProtocol,
		in context: some MacroExpansionContext
	) throws -> [AttributeSyntax] {
		// Add a 'default' storage for any member that doesn't have one already
		guard
			let variable = Variable(member),
			variable.isStoredProperty,
			variable.attribute(named: MacroNames.stored.rawValue) == nil
		else {
			return []
		}

		return [AttributeSyntax(stringLiteral: "@\(MacroNames.stored.rawValue)")]
	}
}

extension PreferencesMacro: ExtensionMacro {
	public static func expansion(
		of _: AttributeSyntax,
		attachedTo _: some DeclGroupSyntax,
		providingExtensionsOf type: some TypeSyntaxProtocol,
		conformingTo _: [TypeSyntax],
		in _: some MacroExpansionContext
	) throws -> [ExtensionDeclSyntax] {
		// TODO: error report
		guard
			let type = Type(type),
			let identifier = type.asSimpleType?.name
		else { return []}


		let observableProtocol: DeclSyntax =
		"""
		extension \(raw: identifier): Observation.Observable {
			internal nonisolated func access<Member>(keyPath: KeyPath<\(raw: identifier), Member>) {
				_$observationRegistrar.access(self, keyPath: keyPath)
			}
			
			internal nonisolated func withMutation<Member, T>(
				keyPath: KeyPath<\(raw: identifier), Member>, 
				_ mutation: () throws -> T
			) rethrows -> T {
				try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
			}
		}
		"""

		guard let extensionDecl = observableProtocol.as(ExtensionDeclSyntax.self) else { return [] }

		return [extensionDecl]
	}
}
