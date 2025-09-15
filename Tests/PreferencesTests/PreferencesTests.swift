import MacroTesting
import PreferencesMacros
//import SwiftSyntax
//import SwiftSyntaxBuilder
//import SwiftSyntaxMacros
//import SwiftSyntaxMacrosTestSupport
import Testing

@Suite(.macros(["Preferences": PreferencesMacro.self], record: .missing))
final class PreferencesTests {
	@Test func shouldFailOnNonClassDeclaration() async throws {
		assertMacro {
			"""
			@Preferences
			struct Prefs {}
			"""
		} diagnostics: {
			"""
			@Preferences
			struct Prefs {}
			┬─────
			╰─ 🛑 'Preferences' macro can only be applied to a class
			   ✏️ Change declaration to a class
			"""
		} fixes: {
			"""
			@Preferences
			class Prefs {}
			"""
		} expansion: {
			"""
			class Prefs {}

			extension Prefs: Observation.Observable {
			}
			"""
		}
	}
}
