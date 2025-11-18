package antpak;

import haxe.zip.Uncompress;
import antpak.EntryData.ReadEntry;
import antpak.exceptions.InvalidFileException;
import haxe.io.Bytes;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;

using StringTools;

class Pak
{
    inline public static final HEADER:String = "ANTPAK";
    inline public static final VERSION:Int = 0;

    static var mounted:Array<Pak> = [];

    /**
     * Opens an `antpak` file from a specified file path and returns a new `Pak` instance.
     * 
     * If `stream` is true, only the basic info will be loaded upon creation.
     * Assets are loaded on demand and cached for later re-use.
     * 
     * If `stream` is false, the `Pak` will load immediately load all assets into memory.
     * It will call the `close()` method immediately after the constructor, 
     * as there is no need to keep an active file handle if everything is loaded into memory.
     * 
     * @param path The file path to the `Pak`.
     * @param stream Whether the `Pak` should be streamed or not.
     * @return Pak
     */
    public static function mount(path:String, stream:Bool):Pak
    {
        var p = new Pak(path, stream);
        mounted.push(p);
        return p;
    }

    /**
     * Closes a `Pak` instance and unloads all memory related to it.
     * 
     * @param pak The `Pak` to close.
     */
    public static function unmount(pak:Pak):Void
    {
        pak.close();
        pak.unload();
        mounted.remove(pak);
    }

    var _file:FileInput;
    var _version:Int = 0;
    var _stream:Bool;

    var _entries:Map<String, ReadEntry>;

    private function new(path:String, stream:Bool):Void 
    {
        _stream = stream;
        _entries = [];

        _file = File.read(path, stream);

        var readHeader = _file.readString(Bytes.ofString(HEADER).length);
        if (readHeader != HEADER)
        {
            throw new InvalidFileException(path);
        }

        _version = _file.readByte();

        // read table of contents
        var numEntries = _file.readUInt16();
        for (i in 0...numEntries)
        {
            var idLen = _file.readUInt16();
            var id = _file.readString(idLen);

            var compression = _file.readByte();
            var encryption = _file.readByte();

            var position = _file.readInt32();
            var length = _file.readInt32();

            var entry:ReadEntry =
            {
                id: id,
                encryption: encryption > 0 ? encryption : null,
                compression: compression > 0 ? compression : null,
                data: null,
                filePos: position,
                fileLen: length
            }

            // also load the files now if we're not streaming
            if (!stream)
                entry.data = _loadEntry(entry);

            _entries[id] = entry;
        }

        if (!stream)
            close();
    }

    /**
     * Returns an array of all asset IDs contained in this `Pak`.
     * 
     * @return An array of all asset IDs contained in this `Pak`.
     */
    public function list():Array<String>
    {
        var names:Array<String> = [];
        for (k in _entries.keys())
        {
            names.push(_entries[k].id);
        }
        return names;
    }

    /**
     * Closes the internal file handle.
     * 
     * Attempting to read a new asset from file will throw an exception, but already
     * loaded files are kept in-memory and can be read.
     * 
     * Use `Pak.unload()` to unload all memory associated with this `Pak` object.
     * 
     */
    public function close():Void
    {
        _file.close();
        _file = null;
    }

    /**
     * Unloads all memory associated with this `Pak` object.
     */
    public function unload():Void
    {
        _entries.clear();
        _entries = null;
    }

    /**
     * Checks whether the provided asset ID exists in this `Pak`.
     * @param path The asset ID.
     * @return `true` if the asset ID exists, `false` otherwise.
     */
    inline public function has(path:String):Bool
    {
        return _entries.exists(_normalizeAssetID(path));
    }

    /**
     * Checks whether the provided asset ID is loaded and cached.
     * This will always be `true` when streaming is not used.
     * 
     * @param path The asset ID.
     * @return `true` if the asset is loaded, `false` otherwise.
     */
    inline public function loaded(path:String):Bool
    {
        return _entries.get(_normalizeAssetID(path))?.data != null;
    }

    /**
     * Get (and if needed, load) the data for a specific asset.
     * 
     * If an asset is compressed or encrypted, it will be uncompressed/decrypted
     * when it is first loaded.
     * 
     * @param path The asset ID.
     * @return The asset data.
     */
    public function get(path:String):Bytes
    {
        if (!has(path))
            return null;

        var e = _entries.get(_normalizeAssetID(path));
        if (e?.data != null)
        {
            return e.data;
        }
        else if (_stream)
        {
            return _loadEntry(e);
        }

        return null;
    }

    function _loadEntry(e:ReadEntry):Bytes
    {
        var last = _file.tell();
        _file.seek(e.filePos, SeekBegin);
        var data = _file.read(e.fileLen);
        _file.seek(last, SeekBegin);

        if (e.encryption != null)
        {
            throw "TODO";
        }

        if (e.compression != null)
        {
            switch (e.compression)
            {
                case ZIP:
                    data = Uncompress.run(data);
            }
        }

        e.data = data;
        return e.data;
    }

    function _normalizeAssetID(id:String):String
    {
        if (id.startsWith("./"))
            return id.substring(2, id.length);

        return id;
    }
}
