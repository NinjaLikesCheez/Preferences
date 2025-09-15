// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
	name: "Preferences",
	platforms: [.iOS(.v18), .tvOS(.v18), .watchOS(.v11), .macCatalyst(.v18), .visionOS(.v2), .macOS(.v15)],
	products: [
		// Products define the executables and libraries a package produces, making them visible to other packages.
		.library(
			name: "Preferences",
			targets: ["Preferences"]
		),
		.executable(
			name: "PreferencesClient",
			targets: ["PreferencesClient"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.1"),
		.package(url: "https://github.com/pointfreeco/swift-macro-testing", from: "0.6.3"),
	],
	targets: [
		// Targets are the basic building blocks of a package, defining a module or a test suite.
		// Targets can depend on other targets in this package and products from dependencies.
		// Macro implementation that performs the source transformation of a macro.
		.macro(
			name: "PreferencesMacros",
			dependencies: [
				.product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
				.product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
			]
		),

		// Library that exposes a macro as part of its API, which is used in client programs.
		.target(name: "Preferences", dependencies: ["PreferencesMacros"]),

		// A client of the library, which is able to use the macro in its own code.
		.executableTarget(name: "PreferencesClient", dependencies: ["Preferences"]),

		// A test target used to develop the macro implementation.
		.testTarget(
			name: "PreferencesTests",
			dependencies: [
				"PreferencesMacros",
				.product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
				.product(name: "MacroTesting", package: "swift-macro-testing"),
			]
		),
	]
)
