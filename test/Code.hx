package;

enum TestEnum {
	One;
	Two;
	Three;
}

typedef MyStruct = {
	var name:String;
}

@:customMeta
class Main {
	public static var name:String = "hello";

	public static function main() {
		var counter = 0;
		var isBoolSupported = true;
		var localAddr = "EQArzP5prfRJtDM5WrMNWyr9yUTAi0c9o6PfR4hkWy9UQXHx";

		greet(localAddr);
		greet(name);
	}

	public static function greet(name:String) {
		untyped __func__(";;this is raw func code");
	}
}

function main() {}
