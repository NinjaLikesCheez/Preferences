import MacroTesting
import PreferencesMacros
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
			class Prefs {

			    internal let _$observationRegistrar = Observation.ObservationRegistrar()

			    private var _defaults: UserDefaults = UserDefaults.standard
			}

			extension Prefs: Observation.Observable {
				internal nonisolated func access<Member>(keyPath: KeyPath<Prefs, Member>) {
					_$observationRegistrar.access(self, keyPath: keyPath)
				}

				internal nonisolated func withMutation<Member, T>(
					keyPath: KeyPath<Prefs, Member>,
					_ mutation: () throws -> T
				) rethrows -> T {
					try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
				}
			}
			"""
		}
	}

	@Test func addsDefaultStorageWhenNoneIsSpecified() async throws {
		// YES IT'S WILD THAT THIS RANDOM WHITESPACE IS ADDED IDK HOW TO FIX IT???
		assertMacro {
			"""
			@Preferences
			class Prefs {
				@Stored(in: .memory)
				var test = ""
				
				var password: String
			}
			"""
		} expansion: {
			"""
			class Prefs {
				@Stored(in: .memory)
				var test = ""
				@Stored
				
				var password: String

				internal let _$observationRegistrar = Observation.ObservationRegistrar()

				private var _defaults: UserDefaults = UserDefaults.standard
			}

			extension Prefs: Observation.Observable {
				internal nonisolated func access<Member>(keyPath: KeyPath<Prefs, Member>) {
					_$observationRegistrar.access(self, keyPath: keyPath)
				}

				internal nonisolated func withMutation<Member, T>(
					keyPath: KeyPath<Prefs, Member>,
					_ mutation: () throws -> T
				) rethrows -> T {
					try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
				}
			}
			"""
		}
	}

	@Test func suiteNameIsAddedWhenSpecified() async throws {
		assertMacro {
			"""
			@Preferences(named: "my-suite")
			class Prefs {
			
			}
			"""
		} expansion: {
			"""
			class Prefs {

			    internal let _$observationRegistrar = Observation.ObservationRegistrar()

			    private var _defaults: UserDefaults = UserDefaults(suiteName: "my-suite")

			}

			extension Prefs: Observation.Observable {
				internal nonisolated func access<Member>(keyPath: KeyPath<Prefs, Member>) {
					_$observationRegistrar.access(self, keyPath: keyPath)
				}

				internal nonisolated func withMutation<Member, T>(
					keyPath: KeyPath<Prefs, Member>,
					_ mutation: () throws -> T
				) rethrows -> T {
					try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
				}
			}
			"""
		}
	}
}
