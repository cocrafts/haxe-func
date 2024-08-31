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
	public static var globalCounter = 20;
	public static var another = "string-based-value";

	public static function main() {
		var counter = 0;
		var isBoolSupported = true;
		var localAddr = "EQArzP5prfRJtDM5WrMNWyr9yUTAi0c9o6PfR4hkWy9UQXHx";

		greet(localAddr);
		greet("hello");
	}

	public static function greet(name:String) {
		untyped __func__(";;this is raw func code");
	}

	public static function increase(a:Int, b:Int) {
		return a + b;
	}
}

function main() {}
