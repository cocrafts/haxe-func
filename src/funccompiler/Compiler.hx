package funccompiler;

import reflaxe.compiler.EverythingIsExprSanitizer;
#if (macro || func_runtime)
import StringTools;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.display.Display.MetadataTarget;
import reflaxe.DirectToStringCompiler;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;
import reflaxe.data.EnumOptionData;
import reflaxe.helpers.Context;
import funccompiler.subcompilers.TypeCompiler;

using reflaxe.helpers.ArrayHelper;
using reflaxe.helpers.BaseTypeHelper;
using reflaxe.helpers.ClassFieldHelper;
using reflaxe.helpers.ModuleTypeHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.NullableMetaAccessHelper;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.OperatorHelper;
using reflaxe.helpers.StringBufHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;

class Compiler extends DirectToStringCompiler {
	var TComp:TypeCompiler;
	var selfStack:Array<{selfName:String, publicOnly:Bool}> = [];

	public function new() {
		super();
		TComp = new TypeCompiler(this);
	}

	public function compileClassImpl(classType:ClassType, varFields:Array<ClassVarData>, funcFields:Array<ClassFuncData>,):Null<String> {
		final variables = [];
		final globalVariables = [];
		final globalVariableInits = [];
		final functions = [];
		final filePath = '${classType.name}.func';
		final isTopLevel = StringTools.endsWith(classType.name, "_Fields_");
		final isHaxeClass = classType.pack[0] == "haxe";
		final isMainClass = classType.name == "Main";

		if (!isTopLevel && !isHaxeClass) {
			var metaList = classType.meta.get();
			for (meta in metaList) {
				if (meta.name == ":customMeta") {
					trace(":customMeta found");
				}
			}

			for (item in varFields) {
				final varDeclaration = new StringBuf();
				final field = item.field;
				final varName:String = field.meta.extractStringFromFirstMeta(':nativeName') ?? compileVarName(field.name, null, field);
				final fieldExpr = field.expr();

				if (item.isStatic) {
					varDeclaration.add('global ');
				}

				final compiledType = TComp.compileType(field.type, field.pos);
				if (compiledType != null) {
					varDeclaration.add('${compiledType.trustMe()}');
				}

				varDeclaration.add(' ${varName};');
				if (fieldExpr != null) {
					globalVariableInits.push({
						name: varName,
						value: compileClassVarExpr(fieldExpr),
					});
				}

				(item.isStatic ? globalVariables : variables).push(varDeclaration.toString());
			}

			for (item in funcFields) {
				final field = item.field;
				final tfunc = item.tfunc;
				final isMainFunc = field.name == "main";
				final isConstructor = field.name == "new";
				final funcDeclaration = new StringBuf();
				final returnType = TComp.compileType(item.ret, field.pos);
				final args = tfunc?.args ?? [];

				if (isMainClass && isMainFunc && returnType != "()") {
					Context.error("main must return void ()", field.pos);
				}

				if (returnType != null) {
					funcDeclaration.add('${returnType} ');
				}

				funcDeclaration.add('${field.name}(');
				funcDeclaration.add(args.map(a -> compileFunctionArgument(a, field.pos)).join(", "));
				funcDeclaration.add(") {\n");

				if (isMainFunc && globalVariableInits.length > 0) {
					final initFragment = new StringBuf();
					for (init in globalVariableInits) {
						initFragment.add('${init.name} = ${init.value};\n');
					}

					funcDeclaration.add(initFragment.toString().tab());
					funcDeclaration.add("\n");
				}

				if (item.expr != null) {
					funcDeclaration.add(compileClassFuncExpr(item.expr).tab());
				}

				funcDeclaration.add("\n}\n");
				functions.push(funcDeclaration);
			}

			final funcCode = {
				var result = new StringBuf();

				if (globalVariables.length > 0) {
					result.add('${globalVariables.join("\n")}\n\n');
				}

				if (variables.length > 0) {
					result.add('${variables.join("\n")}\n\n');
				}

				if (functions.length > 0) {
					result.add('${functions.join("\n\n")}\n\n');
				}

				'${StringTools.trim(result.toString())}\n\n';
			}

			setExtraFile(filePath, funcCode);
		}

		return null;
	}

	public function compileEnumImpl(enumType:EnumType, constructs:Array<EnumOptionData>):Null<String> {
		var result = 'enum ${enumType.name} {\n';
		for (construct in enumType.constructs) {
			result += '  ${construct.name},\n';
		}

		result += '}';
		return result;
	}

	public function compileExpressionImpl(expr:TypedExpr, topLevel:Bool):Null<String> {
		var result = new StringBuf();

		switch (expr.expr) {
			case TConst(constant):
				result.add(constantToFunC(constant));
			case TLocal(v):
				result.add(compileVarName(v.name, expr));
			case TIdent(i):
				result.add(compileVarName(i, expr));
			case TArray(e1, e2):
				result.addMulti(compileExpressionOrError(e1), "[", compileExpressionOrError(e2), "]");
			case TBinop(op, e1, e2):
				result.add(binopToFunC(op, e1, e2));
			case TField(e, fa):
				result.add(fieldAccessToFunC(e, fa));
			case TTypeExpr(m):
				result.add(TComp.compileType(TypeHelper.fromModuleType(m), expr.pos) ?? "()");
			case TParenthesis(e):
				{
					final compiledExpr = compileExpressionOrError(e);
					final expr = if (!EverythingIsExprSanitizer.isBlocklikeExpr(e)) {
						'(${compiledExpr})';
					} else {
						compiledExpr;
					}
					result.add(expr);
				}
			case TObjectDecl(fields):
				trace('TObjectDecl not supported yet: ${fields}');
			case TArrayDecl(el):
				{
					result.add("[");
					result.add(el.map(e -> compileExpression(e).join(", ")));
					result.add("]");
				}
			case TCall(e, el):
				result.add(callToFunC(e, el, expr));
			case TNew(classTypeRef, _, el):
				trace('TNew not supported yet: ${classTypeRef}, ${el}');
			case TUnop(op, isPostFix, e):
				result.add(unopToFunC(op, e, isPostFix));
			case TFunction(tfunc):
				trace('TFunction not supported yet: ${tfunc}');
			case TVar(tvar, maybeExpr):
				{
					final e = compileExpressionOrError(maybeExpr);
					final compiledType = TComp.compileType(tvar.t, expr.pos);
					result.add('${compiledType} ');
					result.add(compileVarName(tvar.name, expr));
					result.add(' = ${e};');
				}
			case TBlock(el):
				trace('TBlock ${el}');
			case TFor(tvar, iterExpr, blockExpr):
				trace('TFor ${tvar}, ${iterExpr}, ${blockExpr}');
			case TIf(econd, ifExpr, elseExpr):
				trace('TIf ${econd}, ${ifExpr}, ${elseExpr}');
			case TWhile(econd, blockExpr, normalWhile):
				trace('TWhile ${econd}, ${blockExpr}, ${normalWhile}');
			case TSwitch(e, cases, edef):
				trace('TSwitch ${e}, ${cases}, ${edef}');
			case TTry(e, catches):
				trace('TTry ${e}, ${catches}');
			case TReturn(maybeExpr):
				{
					result.add("return");
					if (maybeExpr != null) {
						result.add(' ${compileExpression(maybeExpr)}');
					}
				}
			case TBreak:
				result.add("break");
			case TContinue:
				result.add("continue");
			case TThrow(expr):
				trace('TThrow not supported yet: ${expr}');
			case TCast(expr, maybeModuleType):
				trace('TCast ${expr}, ${maybeModuleType}');
			case TMeta(_, expr):
				trace('TMeta not supported yet: ${expr}');
			case TEnumParameter(expr, enumField, index):
				trace('TEnumParameter not supported yet: ${expr}, ${enumField}, ${index}');
			case TEnumIndex(expr):
				trace('TEnumIndex not supported yet: ${expr}');
		}

		return result.toString();
	}

	function compileFunctionArgument(arg:{v:TVar, value:Null<TypedExpr>}, pos:Position) {
		final result = new StringBuf();
		final type = TComp.compileType(arg.v.t, pos);

		result.add('${type} ');
		result.add(compileVarName(arg.v.name));
		return result.toString();
	}

	function callToFunC(calledExpr:TypedExpr, args:Array<TypedExpr>, originalExpr:TypedExpr):StringBuf {
		var result = new StringBuf();
		result.add(compileExpression(calledExpr));
		result.add("(");
		result.add(args.map(e -> compileExpressionOrError(e)).join(", "));
		result.add(")");

		return result;
	}

	function fieldAccessToFunC(e:TypedExpr, fa:FieldAccess):String {
		final nameMeta:NameAndMeta = switch (fa) {
			case FInstance(_, _, classFieldRef): classFieldRef.get();
			case FStatic(_, classFieldRef): classFieldRef.get();
			case FAnon(classFieldRef): classFieldRef.get();
			case FClosure(_, classFieldRef): classFieldRef.get();
			case FEnum(_, enumField): enumField;
			case FDynamic(s): {name: s, meta: null};
		}

		return compileVarName(nameMeta.getNameOrNativeName());
	}

	function binopToFunC(op:Binop, e1:TypedExpr, e2:TypedExpr):String {
		var leftExpr = compileExpression(e1);
		var rightExpr = compileExpression(e2);
		final operatorStr = OperatorHelper.binopToString(op);

		return '${leftExpr} ${operatorStr} ${rightExpr};';
	}

	function unopToFunC(op:Unop, e:TypedExpr, isPostfix:Bool):String {
		final compiledExpr = compileExpressionOrError(e);

		switch (op) {
			case OpIncrement:
				return '${compiledExpr} += 1;';
			case OpDecrement:
				return '${compiledExpr} -= 1;';
			case _:
		}

		final operatorStr = OperatorHelper.unopToString(op);
		return isPostfix ? (compiledExpr + operatorStr) : (operatorStr + compiledExpr);
	}

	function constantToFunC(constant:TConstant):String {
		switch (constant) {
			case TInt(i):
				return Std.string(i);
			case TFloat(f):
				return Std.string(f);
			case TString(s):
				return '"${s}"';
			case TBool(b):
				return b ? "-1" : "0";
			case _:
				return "";
		}
	}
}
#end
