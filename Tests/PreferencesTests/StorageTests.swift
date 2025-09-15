//
//  StorageTests.swift
//  Preferences
//
//  Created by ninji on 17/09/2025.
//

import MacroTesting
import PreferencesMacros
import Testing

@Suite(.macros(["Stored": StorageMacro.self], record: .missing))
final class StorageTests {
	@Test func mustHaveInitializer() async throws {
		assertMacro {
			"""
			@Stored
			var foo: String
			"""
		} diagnostics: {
			"""
			@Stored
			var foo: String
			    ┬──────────
			    ╰─ 🛑 'Stored' properties must have an initial value
			       ✏️ Add initializer to provide a default value
			"""
		} fixes: {
			"""
			@Stored
			var foo: String = <#initializer#>
			"""
		} 
	}

	@Test func storedCannotBeAttachedToLet() async throws {
		assertMacro {
			"""
			@Stored
			let foo = "Hi"
			"""
		} diagnostics: {
			"""
			@Stored
			let foo = "Hi"
			┬──
			╰─ 🛑 'Stored' declarations must be mutable
			   ✏️ Make declaration mutable
			"""
		} fixes: {
			"""
			 @Stored var foo = "Hi" 
			"""
		} 
	}

	@Test func storageCannotBeAttachedToAccessorBlock() async throws {
		assertMacro {
			"""
			@Stored
			var foo: String { "Hello" }
			"""
		} diagnostics: {
			"""
			@Stored
			├─ 🛑 'Stored' properties can not have an accessor block (get/set)
			│  ✏️ Remove accessor block
			╰─ 🛑 'Stored' properties can not have an accessor block (get/set)
			   ✏️ Remove accessor block
			var foo: String { "Hello" }
			"""
		} fixes: {
			"""
			@Stored
			var foo: String  = <#initializer#>
			"""
		}
	}

	@Test func storageHasUnderlyingStorage() async throws {
		assertMacro {
			"""
			class Foo {
				@Stored(in: .memory)
				var foo: String = ""
			}
			"""
		} expansion: {
			#"""
			class Foo {
				var foo: String {
					get {
						access(keyPath: \.foo)
						return _foo
					}
					set {
						withMutation(keyPath: \.foo) {
							_foo = newValue
						}
					}
				}

				var _foo: String = ""
			}
			"""#
		}
	}
}
