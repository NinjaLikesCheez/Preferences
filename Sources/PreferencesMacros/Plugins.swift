import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PreferencesPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		PreferencesMacro.self,
		StorageMacro.self,
	]
}

enum MacroNames: String {
	case preferences = "Preferences"
	case stored = "Stored"
}
