//
//  Storage.swift
//  Preferences
//
//  Created by ninji on 17/09/2025.
//

public enum Storage {
	case defaults
	case keychain
	case memory
}

@attached(peer, names: prefixed(`_`))
@attached(accessor)
public macro Stored(_ key: String? = nil, in storage: Storage = .memory) = #externalMacro(module: "PreferencesMacros", type: "StorageMacro")
