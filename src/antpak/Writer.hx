package antpak;

import haxe.io.Path;
import sys.FileSystem;
import antpak.EntryData.EncryptionMethod;
import antpak.EntryData.CompressionMethod;
import haxe.zip.Compress;
import antpak.exceptions.FileTooLargeException;
import antpak.exceptions.NoCryptoException;
import haxe.Utf8;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.BytesOutput;
import sys.io.File;

using StringTools;

class Writer
{
    final HEADER:String = "ANTPAK";
    final VERSION:Int = 0;

    var _entries:Array<EntryData>;

    public function new() 
    {
        _entries = [];
    }

    /**
     * Adds a `Bytes` asset to the PAK.
     * 
     * @param id A unique id ("path") to the asset.
     * @param bytes The asset data
     * @param compression The compression method for this asset.
     * @param encryption The encryption method for this asset.
     */
    public function add(id:String, bytes:Bytes, ?compression:CompressionMethod, ?encryption:EncryptionMethod):Void
    {
        _entries.push({
            id: _normalizeAssetID(id),
            data: bytes,
            compression: compression,
            encryption: encryption
        });
    }

    /**
     * Adds an asset to the PAK from a file path.
     * 
     * @param path The path to the asset.
     * @param compression The compression method for this asset.
     * @param encryption The encryption method for this asset.
     */
    public function addAsset(path:String, ?compression:CompressionMethod, ?encryption:EncryptionMethod):Void
    {
        var bytes = File.getBytes(path);
        _entries.push({
            id: _normalizeAssetID(path),
            data: bytes,
            compression: compression,
            encryption: encryption
        });
    }

    /**
     * Recursively adds all of the assets in a directory (including subdirectories) to the PAK.
     * 
     * @param path The path of the directory the assets will be added from.
     * @param exclude A list of excluded directories and file paths.
     * @param compression The compression method applied for all added assets.
     * @param encryption The encryption method applied for all added assets.
     */
    public function addAssetsRecursively(path:String, ?exclude:Array<String>, ?compression:CompressionMethod, ?encryption:EncryptionMethod):Void
    {
        if (FileSystem.isDirectory(path))
        {
            var assets = _readDirectoryRecursively(path, exclude);
            for (assetPath in assets)
            {
                addAsset(assetPath, compression, encryption);
            }
        }
    }

    /**
     * Writes all stored data into a Bytes instance and resets this `Writer` instance.
     * 
     * If no entries have been added, the result will be `null`.
     * 
     * @return Bytes representation of the PAK.
     */
    public function write():Bytes
    {
        var bytes:Bytes = null;

        if (_entries.length > 0)
        {
            _mutateFiles();

            var _bytes = new BytesOutput();

            _writeHeader(_bytes);
            _writeTableOfContents(_bytes);
            _writeContents(_bytes);

            bytes = _bytes.getBytes();

            _entries.resize(0);
        }

        return bytes;
    }

    inline function _mutateFiles():Void
    {
        for (entry in _entries)
        {
            // first encrypt
            if (entry.encryption != null)
            {
                #if !crypto
                throw new NoCryptoException(entry.id);
                #end

                throw "TODO";
            }

            // then compress
            if (entry.compression != null)
            {
                switch (entry.compression)
                {
                    case ZIP:
                        entry.data = Compress.run(entry.data, 6);
                }
            }
        }
    }

    inline function _writeHeader(o:BytesOutput):Void
    {
        o.writeString(HEADER);
        o.writeByte(VERSION);
    }

    inline function _writeTableOfContents(o:BytesOutput):Void
    {
        final headerLength = o.length;

        o.writeUInt16(_entries.length);

        // Get the length of everything, so we can properly calculate the position for packed files
        var tocLength:Int = 2;
        for (entry in _entries)
        {
            tocLength += 2; // path length
            tocLength += Bytes.ofString(entry.id).length; // path
            tocLength++; // i8 (compression)
            tocLength++; // i8 (encryption)
            tocLength += 4; // i32 (position)
            tocLength += 4; // i32 (length)
        }

        var dataLength = 0;
        for (entry in _entries)
        {
            _writeString(o, entry.id);

            o.writeByte(entry.compression ?? 0);
            o.writeByte(entry.encryption ?? 0);

            // position of the file
            final position = headerLength + tocLength + dataLength;
            o.writeInt32(position);

            // length of the file
            o.writeInt32(entry.data.length);

            dataLength += entry.data.length;
        }
    }

    inline function _writeContents(o:BytesOutput):Void
    {
        for (entry in _entries)
        {
            // final p = _entryPositions[entry.id];
            o.writeFullBytes(entry.data, 0, entry.data.length);
        }
    }

    /**
     * Helper that writes the length (in bytes) of the string,
     * and then the string into a `BytesOutput`
     * 
     * @param o The `BytesOutput` to write into
     * @param s The string to write
     */
    function _writeString(o:BytesOutput, s:String):Void
    {
        var b = Bytes.ofString(s);
        o.writeUInt16(b.length);
        o.writeString(s);
    }

    // TODO: wait im kinda dum lol need to clean this up
    function _readDirectoryRecursively(startPath:String, exclude:Array<String>):Array<String>
    {
        var paths:Array<String> = [];

        startPath = Path.addTrailingSlash(startPath);

        var read = FileSystem.readDirectory(startPath);
        for (path in read)
        {
            path = startPath + path;
            if (FileSystem.isDirectory(path))
                path = Path.addTrailingSlash(path);

            if (exclude?.contains(path))
                continue;

            if (!FileSystem.isDirectory(path))
                paths.push(path);
            else
            {
                paths = paths.concat(_readDirectoryRecursively(path, exclude));
            }
        }

        return paths;
    }

    function _normalizeAssetID(id:String):String
    {
        if (id.startsWith("./"))
            return id.substring(2, id.length);

        return id;
    }
}
