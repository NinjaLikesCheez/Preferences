import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct PreferencesPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		PreferencesMacro.self
	]
}
