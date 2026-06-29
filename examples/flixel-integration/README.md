# Integrating antpak with HaxeFlixel projects 
<sup>(also applicable to Lime/OpenFL... to an extent)<sup>

This project is provided as an example, which you should expect to have to modify according to your use case. The steps in the source files are documented, which should hopefully make this process a bit easier to understand.

The example project generates a single PAK file from the `assets/` directory in the folder above.

> [!NOTE]
> Due to current limitations, PAKs do not have an associated asset type. For example, if you try to query a list of assets with the `MUSIC` type, you will instead get a list of all assets in the PAK. You can work around this by filtering based on the file extension.

First things first, make sure you've installed the `antpak` library: `haxelib git antpak https://github.com/ACrazyTown/antpak`.

## Generating the PAKs
### If you're using Project.xml:
Copy over [`project.hxp`](project.hxp) to the root of your project, next to Project.xml.
The [HXP format](https://lime.openfl.org/docs/project-files/hxp-format/) is essentially the same thing as Project.xml but written using Haxe. It is prioritized above XML and therefore will run before it. We use this to our advantage to run a script that generates the PAK file(s) and tells Lime to copy them over to the export directory, before running the Project.xml.

> [!IMPORTANT]
> In your Project.xml, **make sure** to get rid of any `<assets />` tags that reference the same assets as the PAK, otherwise you're going to have **both** the PAK and the copied (or embedded) files in your game.

### If you're using Project.hxp:
Like above, you'll reference the included [`project.hxp`](project.hxp) file here. Though you can't copy it in its entirety, you'll need to copy over certain bits.

Next to the class declaration, you **must** include the following metadata like so: 
```haxe
@:compiler("-lib")
@:compiler("antpak")
class Project extends HXProject {...}
```
This tells HXP to include `antpak` when running the script, which makes it possible for us to call the required methods needed to generate PAKs.

Copy over the `createAssetsPak()` method from the example hxp file. You should call it sometime before processing assets. 

> [!IMPORTANT]
> Like with Project.xml based projects, **make sure** to get rid of any code that references the same assets as the PAK, otherwise you're going to have **both** the PAK and the copied (or embedded) files in your game

## Actually using them

<sup>This is the part that's HaxeFlixel only, for now... sorry!</sup>

Make sure you've included the `antpak` library into your project!
- `<haxelib name="antpak" />` if you're using Project.xml
- `haxelibs.push(new Haxelib("antpak"))` if you're using Project.hxp

In your project's source code, before any calls to `FlxG.assets` are made, call
```haxe
antpak.integration.FlxPakAssets.init();
```

`FlxPakAssets` hijacks the `FlxG.assets` method with its own custom methods, which first check if the wanted asset is available in any of the mounted PAKs, before falling back to the original methods. 

> [!NOTE]
> If you're using any other libraries (or hijacking `FlxG.assets` yourself), you should make sure to init `FlxPakAssets` last, after that.

Finally, mount your PAKs via `antpak.Pak.mount(path);` and you're good to go!
