package antpak;

import haxe.io.Bytes;
import haxe.ds.ReadOnlyArray;

@:access(antpak.Pak)
class PakFileSystem
{
    public static var mounted(get, null):ReadOnlyArray<Pak> = [];

    inline static function get_mounted():ReadOnlyArray<Pak>
        return cast _mounted;

    // static var _mountedMap:Map<String, Pak>;
    static var _mounted:Array<Pak> = [];

    public static function mount(path:String, stream:Bool):Pak
    {
        // var pak = _mountedMap.get(path);

        var p = new Pak(path, stream);
        _mounted.push(p);
        return p;
    }

    public static function unmount(pak:Pak):Void
    {
        pak.close();
        pak.unload();
        _mounted.remove(pak);
    }

    public static function list():Array<String>
    {
        var list:Array<String> = [];
        
        for (pak in _mounted)
            list = list.concat(pak.list());

        return list;
    }

    public static function has(path:String):Bool
    {
        for (pak in _mounted)
        {
            if (pak.has(path))
                return true;
        }

        return false;
    }

    public static function loaded(path:String):Bool
    {
        for (pak in _mounted)
        {
            if (pak.has(path))
                return pak.loaded(path);
        }

        return false;
    }

    public static function get(path:String):Bytes
    {
        for (pak in _mounted)
        {
            var data = pak.get(path);
            if (data != null)
                return data;
        }

        return null;
    }

    public static function remove(path:String):Void
    {
        for (pak in _mounted)
            pak.remove(path);
    }
}