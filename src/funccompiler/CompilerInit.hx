package funccompiler;

#if (macro || func_runtime)
import reflaxe.ReflectCompiler;

class CompilerInit {
	public static function Start() {
		#if !eval
		Sys.println("CompilerInit.Start can only be called from a macro context.");
		return;
		#end

		#if (haxe_ver < "4.3.0")
		Sys.println("Reflaxe/Func requires Haxe version 4.3.0 or greater.");
		return;
		#end

		ReflectCompiler.AddCompiler(new Compiler(), {
			fileOutputExtension: ".func",
			outputDirDefineName: "func-output",
			fileOutputType: FilePerClass,
			reservedVarNames: reservedNames(),
			targetCodeInjectionName: "__func__",
			smartDCE: true,
			trackUsedTypes: true
		});
	}

	static function reservedNames() {
		return [];
	}
}
#end
