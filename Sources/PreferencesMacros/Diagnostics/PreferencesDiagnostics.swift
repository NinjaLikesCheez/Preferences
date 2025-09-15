import SwiftDiagnostics
import SwiftSyntax

enum PreferencesDiagnosticsMessage {
	case notAttachedToClassDeclaration
}

struct PreferencesDiagnostics {
	static func notAttachedToClassDeclaration(at decl: some DeclGroupSyntax) -> Diagnostic {
		Diagnostic(
			node: Syntax(decl.introducer),
			message: PreferencesDiagnosticsMessage.notAttachedToClassDeclaration,
			fixIt: FixIt(
				message: PreferenceFixItMessage.changeDeclarationToClass,
				changes: [
					FixIt.Change.replace(
						oldNode: Syntax(decl.introducer),
						newNode: Syntax(TokenSyntax(.keyword(.class), leadingTrivia: .newline, trailingTrivia: .space, presence: .present))
					)
				]
			)
		)
	}
}

extension PreferencesDiagnosticsMessage: DiagnosticMessage {
	var message: String {
		switch self {
		case .notAttachedToClassDeclaration:
			return "'Preferences' macro can only be applied to a class"
		}
	}

	var severity: DiagnosticSeverity {
		switch self {
		case .notAttachedToClassDeclaration:
			.error
		}
	}

	var diagnosticID: MessageID {
		MessageID(domain: "Preferences", id: "Preferences.\(self)")
	}
}
