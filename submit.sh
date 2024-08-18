rm -rf _Build
haxelib run reflaxe build
zip -r haxe-func.zip _Build -x "*/\.*"
haxelib submit haxe-func.zip
