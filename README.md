# haxe-func

Func (TON) target for Haxe that make developing Smart Contract on TON easier with the power of Haxe. Made with [Reflaxe](https://github.com/SomeRanDev/reflaxe) which is used to build [Reflaxe.CPP](https://github.com/SomeRanDev/reflaxe.CPP), GC-free `C++` target for Haxe.

Primary goal of this project: re-use static typing and powerful, yet friendly syntax Haxe offer for Smart Contract development in TON.
This also cover Javascript/Typescript SDK generation, Unit Testing for the Smart Contract.

## At a Glance (pesudo for now):
```haxe
import std.lib.Func;

@:asm(0x123123)
typedef TransferMsg = {
    var to:Address; 
    var text:String;
}

class MyContract extends Contract {
    public function init():Void {}
    public function receive(msg: TransferMsg):Void {
        var params: SendParameters = {
            to: msg.to,
            value: 0,
            mode: SendRemainingValue,
            body: msg.text.asComment(),
        };
        send(params);
    }
}
```

## Installation:

This project is currently in development, but once posted on haxelib, this is now the installation process should work:
| #   | What to do                                           | What to write                            |
| --- | ---------------------------------------------------- | ---------------------------------------- |
| 1   | Install via haxelib.                                 | <pre>haxelib install haxe-func</pre>   |
| 2   | Add the lib to your `.hxml` file or compile command. | <pre lang="hxml">-lib haxe-func</pre>  |
| 3   | Set the output folder for the compiled FunC.          | <pre lang="hxml">-D func-output=out</pre> |

## Nightly Installation:
```sh
haxelib git haxe-func https://github.com/cocrafts/haxe-func
```

Here's a simple `.hxml` template to get you started!

```hxml
-cp src
-main Main

-lib haxe-func
-D func-output=out
```
