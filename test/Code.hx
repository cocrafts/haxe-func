package;

class Main {
	public static var globalCounter:Int = 0;

	public static function main() {
		var counter = 0;
		var isBooleanSupported = true;
		var localAddr = "EQArzP5prfRJtDM5WrMNWyr9yUTAi0c9o6PfR4hkWy9UQXHx";
		var added = add(counter, globalCounter);
		counter++;

		Jetton.init();
	}

	public static function add(a:Int, b:Int) {
		return a + b;
	}
}

function main() {}
