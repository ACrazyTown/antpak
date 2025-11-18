package antpak.integration;

#if (!flixel || flixel < version("5.9.0"))
#error "FlxPakAssets requires HaxeFlixel 5.9.0+"
#else
import flixel.FlxG;
import flixel.system.FlxAssets;
import flixel.FlxBasic;
import flixel.system.frontEnds.AssetFrontEnd;
import openfl.display.BitmapData;
import lime.media.AudioBuffer;
import openfl.media.Sound;
import lime.text.Font;
import haxe.io.Bytes;
import lime.app.Future;

@:access(antpak.Pak)
class FlxPakAssets
{
    static var _getAssetUnsafe:(id:String, type:FlxAssetType, useCache:Bool)->Any = null;
    static var _loadAsset:(id:String, type:FlxAssetType, useCache:Bool)->Future<Any> = null;
    static var _exists:(id:String, ?type:FlxAssetType)->Bool = null;
    static var _isLocal:(id:String, ?type:FlxAssetType, useCache:Bool)->Bool = null;
    static var _list:(?type:FlxAssetType)->Array<String> = null;

    public static function init():Void
    {
        // save flixel's methods
        _getAssetUnsafe = FlxG.assets.getAssetUnsafe;
        _loadAsset = FlxG.assets.loadAsset;
        _exists = FlxG.assets.exists;
        _isLocal = FlxG.assets.isLocal;
        _list = FlxG.assets.list;

        // hook in ours
        FlxG.assets.getAssetUnsafe = getAssetUnsafe;
        FlxG.assets.loadAsset = loadAsset;
        FlxG.assets.exists = exists;
        FlxG.assets.isLocal = isLocal;
        FlxG.assets.list = list;
    }

    static function getAssetUnsafe(id:String, type:FlxAssetType, useCache:Bool = true):Any
    {
        for (pak in Pak.mounted)
        {
            if (pak.has(id))
            {
                var data = pak.get(id);

                // try to return the proper asset depending
                // on what type the user wants
                return switch (type)
                {
                    case TEXT: data.toString();
                    case BINARY: data;
                    case FONT: Font.fromBytes(data);
                    case SOUND: Sound.fromAudioBuffer(AudioBuffer.fromBytes(data));
                    case IMAGE: BitmapData.fromBytes(data);
                }
            }
        }

        return _getAssetUnsafe(id, type, useCache);
    }

    static function loadAsset(id:String, type:FlxAssetType, useCache:Bool = true):Future<Any>
    {
        // TODO: don't iterate twice (here and in getAssetUnsafe)
        for (pak in Pak.mounted)
        {
            if (pak.has(id))
            {
                return Future.withValue(getAssetUnsafe(id, type, useCache));
            }
        }

        return _loadAsset(id, type, useCache);
    }

    // does not respect asset type (yet?)
    static function exists(id:String, ?type:FlxAssetType):Bool 
    {
        for (pak in Pak.mounted)
        {
            if (pak.has(id))
                return true;
        }

        return _exists(id, type);
    }

    // does not respect asset type (yet?)
    static function isLocal(id:String, ?type:FlxAssetType, useCache:Bool = true):Bool
    {
       for (pak in Pak.mounted)
        {
            if (pak.has(id))
                return true; // always local (synchronous)
        }

        return _isLocal(id, type, useCache);
    }

    // does not respect asset type (yet?)
    static function list(?type:FlxAssetType):Array<String>
    {
        var list:Array<String> = [];

        for (pak in Pak.mounted)
        {
            list = list.concat(pak.list());
        }

        list = list.concat(_list(type));

        return list;
    }
}
#end
