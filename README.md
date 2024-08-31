# Haxe-Func

Haxe-Func is a toolset designed to simplify the development of smart contracts on the TON network by leveraging the power and flexibility of Haxe. Built using [Reflaxe](https://github.com/SomeRanDev/reflaxe), which is utilized to create [Reflaxe.CPP](https://github.com/SomeRanDev/reflaxe.CPP)—a GC-free C++ target for Haxe—Haxe-Func aims to provide a comprehensive and efficient development environment for TON smart contracts.

## Key Features

- **Haxe Integration:** Harnesses Haxe's static typing and intuitive syntax to produce clean, maintainable, and reliable smart contract code.
- **Cross-Platform SDK Generation:** Generates SDKs for JavaScript and TypeScript to seamlessly integrate smart contracts with front-end applications.
- **Unit Testing:** Provides robust unit testing support to ensure high code quality and early detection of issues.

## Project Goals

The primary goal of Haxe-Func is to enable developers to write smart contracts for the TON network using Haxe's powerful and user-friendly language features. This includes:

- **Enhanced Development Experience:** Leverage Haxe’s static typing and advanced macro system to streamline the development of smart contracts.
- **Comprehensive Tooling:** Offer full support for unit testing and SDK generation to integrate smart contracts into various applications.
- **Documentation and Support:** Provide extensive documentation and tooling to facilitate a smooth development process.

## At a Glance (WIP):
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

### Current working state ([test/Code.hx](./test/Code.hx)):
```haxe
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
```
Produce following FunC (clone this repo and run `haxelib run reflaxe test`):
```func
global slice name = "hello";

() main() {
    int counter = 0;
    int isBoolSupported = -1;
    slice localAddr = "EQArzP5prfRJtDM5WrMNWyr9yUTAi0c9o6PfR4hkWy9UQXHx";

    greet(localAddr);
    greet(name);
}


() greet(slice name) {
    ;;this is raw func code
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

## Roadmap

- **Initial Release:** Establish the basic functionality for generating smart contracts and integrating with the TON network.
- **Future Enhancements:** Expand features, improve documentation, and enhance IDE support based on community feedback.

## References

- [Haxe-Func Repository](https://github.com/cocrafts/haxe-func)
- [Reflaxe](https://github.com/SomeRanDev/reflaxe)
- [Reflaxe.CPP](https://github.com/SomeRanDev/reflaxe.CPP)

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
