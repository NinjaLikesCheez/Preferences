import SwiftDiagnostics
import SwiftSyntax

enum StorageFixItMessage {
	case declarationHasAccessorBlock
	case requiresInitializer
	case notMutable
}

extension StorageFixItMessage: FixItMessage {
	var message: String {
		switch self {
		case .declarationHasAccessorBlock:
			"Remove accessor block"
		case .requiresInitializer:
			"Add initializer to provide a default value"
		case .notMutable:
			"Make declaration mutable"
		}
	}

	var fixItID: MessageID {
		MessageID(domain: "Storage", id: "Storage.FixIt.\(self)")
	}
}
