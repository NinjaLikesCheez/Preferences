import SwiftDiagnostics
import SwiftSyntax

enum PreferenceFixItMessage {
	case changeDeclarationToClass
}

extension PreferenceFixItMessage: FixItMessage {
	var message: String {
		switch self {
		case .changeDeclarationToClass:
			return "Change declaration to a class"
		}
	}

	var fixItID: MessageID {
		MessageID(domain: "Preferences", id: "Preferences.FixIt.\(self)")
	}
}
