import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public enum IndentType {
	case tabs
	case spaces(Int)
}

// TODO: consider using https://github.com/stackotter/swift-macro-toolkit
public struct PreferencesMacro: MemberMacro {
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		guard let classDeclaration = declaration as? ClassDeclSyntax else {
			context.diagnose(
				PreferencesDiagnostics.notAttachedToClassDeclaration(at: declaration)
			)

			return []
		}

		return []
	}
}

extension PreferencesMacro: MemberAttributeMacro {
	public static func expansion(
		of node: AttributeSyntax,
		attachedTo _: some DeclGroupSyntax,
		providingAttributesFor member: some DeclSyntaxProtocol,
		in _: some MacroExpansionContext
	) throws -> [SwiftSyntax.AttributeSyntax] {
		return []
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
		let observableProtocol: DeclSyntax = "extension \(type.trimmed): Observation.Observable {}"

		guard let extensionDecl = observableProtocol.as(ExtensionDeclSyntax.self) else { return [] }

		return [extensionDecl]
	}
}
