import Preferences

@Preferences
class Preferences {
	var setting: String = "Hello, World!"
	init() {}
}

var preferences = Preferences()
preferences.setting = "Hello, World! 2"
print(preferences.setting)
