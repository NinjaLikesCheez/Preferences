import SwiftDiagnostics
import SwiftSyntax
import MacroToolkit

enum StorageDiagnosticsMessage {
	case declarationHasAccessorBlock
	case notAttachedToAVariableDeclaration
	case notMutable
	case requiresInitializer
}

struct StorageDiagnostics {
	static func requiresInitializer(at variable: VariableDeclSyntax) -> Diagnostic {
		var binding = variable.bindings.first!

		var initializer = InitializerClauseSyntax(
			equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
			value: ExprSyntax("<#initializer#>")
		)

		binding.initializer = initializer

		var newNode = variable
		newNode.bindings = [binding]

		return Diagnostic(
			node: variable.bindings.first!,
			message: StorageDiagnosticsMessage.requiresInitializer,
			fixIt: FixIt(
				message: StorageFixItMessage.requiresInitializer,
				changes: [
					FixIt.Change.replace(
						oldNode: Syntax(variable),
						newNode: Syntax(newNode)
					)
				]
			)
		)
	}

	static func notMutable(at variable: VariableDeclSyntax) -> Diagnostic {
		Diagnostic(
			node: Syntax(variable.bindingSpecifier),
			message: StorageDiagnosticsMessage.notMutable,
			fixIts: [
				FixIt(
					message: StorageFixItMessage.notMutable,
					changes: [
						FixIt.Change.replace(
							oldNode: Syntax(variable),
							newNode: Syntax(
								VariableDeclSyntax(
									leadingTrivia: .space,
									attributes: variable.attributes,
									modifiers: variable.modifiers,
									bindingSpecifier: TokenSyntax(
										.keyword(.var),
										leadingTrivia: .space,
										trailingTrivia: .space,
										presence: .present
									),
									bindings: variable.bindings,
									trailingTrivia: .space
								)
							)
						)
					]
				)
			]
		)
	}

	static func notAttachedToAVariableDeclaration(at declaration: some DeclSyntaxProtocol) -> Diagnostic {
		return Diagnostic(
			node: Syntax(declaration),
			message: StorageDiagnosticsMessage.notAttachedToAVariableDeclaration,
		)
	}

	static func declarationHasAccessorBlock(at variable: VariableDeclSyntax) -> Diagnostic {
//			// Create an initializer with a placeholder for the value
//		var binding = variable.bindings.first!
//
//		var initializer = InitializerClauseSyntax(
//			equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
//			value: ExprSyntax("<#initializer#>")

		// TODO: Move all these node mutations into the *FixIts as functions
		var newNode = variable

		var initializer = InitializerClauseSyntax(
			equal: .equalToken(leadingTrivia: .space, trailingTrivia: .space),
			value: ExprSyntax("<#initializer#>")
		)

		var firstBinding = newNode.bindings.first!
		firstBinding.accessorBlock = nil
		firstBinding.initializer = initializer

		let newBindings = [firstBinding] + PatternBindingListSyntax(variable.bindings.dropFirst())
		newNode.bindings = newBindings

		return Diagnostic(
			node: Syntax(variable),
			message: StorageDiagnosticsMessage.declarationHasAccessorBlock,
			fixIt: FixIt(
				message: StorageFixItMessage.declarationHasAccessorBlock,
				changes: [
					FixIt.Change.replace(
						oldNode: Syntax(variable.bindings),
						newNode: Syntax(newBindings)
					)
				]
			)
		)
	}
}

extension StorageDiagnosticsMessage: DiagnosticMessage {
	var message: String {
		switch self {
		case .declarationHasAccessorBlock:
			return "'Stored' properties can not have an accessor block (get/set)"
		case .notMutable:
			return "'Stored' declarations must be mutable"
		case .requiresInitializer:
			return "'Stored' properties must have an initial value"
		case .notAttachedToAVariableDeclaration:
			return "'Stored' must be attached to a property"
		}
	}

	var severity: DiagnosticSeverity {
		switch self {
		case .notMutable, .declarationHasAccessorBlock, .requiresInitializer, .notAttachedToAVariableDeclaration:
			.error
		}
	}

	var diagnosticID: MessageID {
		MessageID(domain: "Storage", id: "Storage.\(self)")
	}
}
