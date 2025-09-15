@attached(member)
@attached(extension, conformances: Observable)
@attached(memberAttribute)
public macro Preferences() = #externalMacro(module: "PreferencesMacros", type: "PreferencesMacro")
