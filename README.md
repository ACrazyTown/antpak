# antpak

An `antpak` is a custom implementation of a PAK file archive format. This library adds support for reading and writing `antpak` files in Haxe. See the [specification](SPEC.md).

**NOTE:** This library currently only supports [`Sys` targets](https://haxe.org/manual/std-sys.html).

Also wait it's still a work in progress so you probably shouldn't use it, also wait I made it cause I was bored so no guarantees I'll keep working on it heehee !

## Integration with other libraries
### HaxeFlixel
Integration with HaxeFlixel is really simple. After creating your `FlxGame`, call `FlxPakAssets.init()` somewhere. After that, mount your PAKs and use HaxeFlixel as usual. 

> [!WARNING]
> `FlxPakAssets` hooks into the dynamic functions provided by `FlxG.assets`. If your or another library's code also tries to hook into these functions, issues may occur.

The asset system first checks if the wanted asset is available in the PAK, and then queries Flixel's default asset system if it isn't.

> [!WARNING]
> Due to how PAKs work, it is not possible to query an asset based on its asset type. When requesting an asset, it will attempt to convert itself into the requested type. Ensure you are requesting the right file and type to avoid any unforeseen consequences.

## TODO
- [ ] Polish up API
- [ ] Implement missing features
- [x] Add example
- [ ] More robust excludes (wildcard support, etc.)
- [ ] Lime/OpenFL/Flixel integration?
    - [x] Flixel 