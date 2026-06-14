# antpak

An `antpak` is a custom implementation of a PAK file archive format. This library adds support for reading and writing `antpak` files in Haxe. See the [specification](SPEC.md).

**NOTE:** This library currently only supports [`Sys` targets](https://haxe.org/manual/std-sys.html).

Also wait it's still a work in progress so you probably shouldn't use it, also wait I made it cause I was bored so no guarantees I'll keep working on it heehee !

## Integration with other libraries
### HaxeFlixel
Integration with HaxeFlixel is really simple. After creating your `FlxGame`, call `FlxPakAssets.init()` somewhere. After that, mount your PAKs and use HaxeFlixel as usual. 

For convenience you'd ideally want a way to automatically build the pak with the game. This can be accomplished using the `<postbuild>` tag in Project.xml and an additional Haxe script. See the [Flixel example](/examples/flixel-integration) for specifics, or follow these general steps:
1. Install the library via `haxelib git antpak https://github.com/ACrazyTown/antpak`
2. Copy over [`GeneratePak`](/examples/flixel-integration/GeneratePak.hx) and [`gen.hxml`](/examples/flixel-integration/gen.hxml) to your top folder. You will have to adjust some of the parameters in the script according to your project.
3. Add `<postbuild cmd="haxe gen.hxml"></postbuild>` somewhere in your Project.xml.
4. In your game code, add `FlxPakAssets.init()` somewhere before the `FlxGame` is created. You should also make sure it is called before any attempts to fetch assets, otherwise you won't be able to fetch assets from PAKs.
5. Mount your PAK using `Pak.mount(path);`
6. Profit

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
