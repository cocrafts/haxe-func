package funccompiler.subcompilers;

import funccompiler.Compiler;
import reflaxe.helpers.Context;

using reflaxe.helpers.ArrayHelper;
using reflaxe.helpers.BaseTypeHelper;
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.TypeHelper;

import haxe.macro.Expr;
import haxe.macro.Type;

@:access(funccompiler.Compiler)
class TypeCompiler {
	var main:Compiler;

	public function new(main:Compiler) {
		this.main = main;
	}

	public function compileClassName(classType:ClassType):String {
		return if (classType.name == "String") {
			"slice";
		} else {
			classType.getNameOrNativeName();
		}
	}

	public function compileModuleType(m:ModuleType):String {
		return switch (m) {
			case TClassDecl(classRef):
				{
					compileClassName(classRef.get());
				}
			case TEnumDecl(enumRef):
				{
					final e = enumRef.get();
					if (e.isReflaxeExtern()) {
						e.pack.joinAppend(".") + e.getNameOrNativeName();
					} else {
						"Dictionary";
					}
				}
			case _: m.getNameOrNative();
		}
	}

	public function compileType(t:Type, errorPos:Position):Null<String> {
		switch (t) {
			case TAbstract(absRef, params):
				final abs = absRef.get();
				final primitiveResult = if (params.length == 0) {
					switch (abs.name) {
						case "Void": "()";
						case "Int": "int";
						case "Bool": "int";
						case "String": "slice";
						case "Float": Context.error("FunC does not allow Float type, consider use Int instead!", errorPos);
						case _: null;
					}
				} else {
					null;
				}

				if (primitiveResult != null) {
					return primitiveResult;
				}
			case TDynamic(_):
				return null;
			case TAnonymous(_):
				return null;
			case TFun(_, _):
				return null;
			case TInst(clsRef, _):
				return compileModuleType(TClassDecl(clsRef));
			case TEnum(enmRef, _):
				return compileModuleType(TEnumDecl(enmRef));
			case TType(defRef, _):
				return compileType(defRef.get().type, errorPos);
			case TMono(typeRef):
				{
					final t = typeRef.get();
					return if (t != null) compileType(t, errorPos); else null; // It's okay to return `null` here.
				}
			case _:
		}

		return Context.error('Cannot convert this type to FunC at the moment ${Std.string(t)}', errorPos);
	}
}
