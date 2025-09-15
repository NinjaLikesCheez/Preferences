@attached(member, names: named(_$observationRegistrar), named(_defaults), named(access), named(withMutation))
@attached(extension, conformances: Observable, names: named(_$observationRegistrar), named(_defaults), named(access), named(withMutation))
public macro Preferences(named name: String? = nil) = #externalMacro(module: "PreferencesMacros", type: "PreferencesMacro")
