package antpak;

import antpak.Util;
import antpak.data.WriteEntry;
import haxe.io.Path;
import sys.FileSystem;
import antpak.data.CompressionMethod;
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

    var _entries:Array<WriteEntry>;

    public function new() 
    {
        _entries = [];
    }

    /**
     * Adds a `Bytes` asset to the PAK.
     * 
     * If an asset ID starts with the directory up prefix (`../`) the prefix
     * will be removed and the first directory will be treated as a subdirectory of the root.
     * 
     * @param id A unique id ("path") to the asset.
     * @param bytes The asset data
     * @param compression The compression method for this asset.
     * @param encryption The encryption method for this asset.
     */
    public function addBytes(id:String, bytes:Bytes, compression:CompressionMethod = NONE, ?encryptionKey:String):Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace('Registered asset from bytes (ID: $id)');
        #end

        _entries.push({
            id: _normalizeAssetID(id),
            data: bytes,
            compression: compression,
            encKey: encryptionKey
        });
    }

    /**
     * Adds an asset to the PAK from a file path.
     * 
     * If an asset ID starts with the directory up prefix (`../`) the prefix
     * will be removed and the first directory will be treated as a subdirectory of the root.
     * 
     * @param path The path to the asset.
     * @param compression The compression method for this asset.
     * @param encryption The encryption method for this asset.
     */
    public function addFile(path:String, compression:CompressionMethod = NONE, ?encryptionKey:String):Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace('Registered asset from path (path: $path)');
        #end

        var bytes = File.getBytes(path);
        _entries.push({
            id: _normalizeAssetID(path),
            data: bytes,
            compression: compression,
            encKey: encryptionKey
        });
    }

    /**
     * Recursively adds all of the assets in a directory (including subdirectories) to the PAK.
     * 
     * If an asset ID starts with the directory up prefix (`../`) the prefix
     * will be removed and the first directory will be treated as a subdirectory of the root.
     * 
     * @param path The path of the directory the assets will be added from.
     * @param exclude A list of assets/directories to exclude.
     * @param compression The compression method applied for all added assets.
     * @param encryption The encryption method applied for all added assets.
     */
    public function addDirectoryRecursive(path:String, ?exclude:Array<String>, compression:CompressionMethod = NONE, ?encryptionKey:String):Void
    {
        if (FileSystem.isDirectory(path))
        {
            #if ANTPAK_VERBOSE_WRITER
            trace('Registering assets from directory (path: $path)');
            #end

            function filtered(path:String, exclude:Array<String>):Bool 
            {
                for (e in exclude)
                {
                    e = e.replace("/", "\\/"); // don't interpet / as a regex pattern
                    e = e.replace(".", "\\."); // don't interpet . as a regex pattern
                    e = e.replace("*", ".*");  // .* is regex for however many characters

                    // trace(path, "^" + e + "$");
                    var r = new EReg("^" + e + "$", "i");
                    if (r.match(path))
                        return true;
                }

                return false;
            }

            var assets = _readDirectoryRecursively(path);
            for (assetPath in assets)
            {
                if (exclude != null && filtered(assetPath, exclude))
                {
                    #if ANTPAK_VERBOSE_WRITER
                    trace('Excluding asset (path: $assetPath)');
                    #end
                    continue;
                }

                addFile(assetPath, compression, encryptionKey);
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
            #if ANTPAK_VERBOSE_WRITER
            trace("-- Starting write --");
            #end

            _mutateFiles();

            var _bytes = new BytesOutput();

            _writeHeader(_bytes);
            _writeTableOfContents(_bytes);
            _writeContents(_bytes);

            #if ANTPAK_VERBOSE_WRITER
            trace('-- Write complete (final size: ${Util.getBytesSize(_bytes.length)}) --');
            #end

            bytes = _bytes.getBytes();

            _entries.resize(0);
        }

        return bytes;
    }

    inline function _mutateFiles():Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace("-- Mutating files --");
        #end

        for (entry in _entries)
        {
            entry.prepareData();
        }
    }

    inline function _writeHeader(o:BytesOutput):Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace('-- Writing header ($HEADER, v$VERSION) --');
        #end

        o.writeString(HEADER);
        o.writeByte(VERSION);
    }

    inline function _writeTableOfContents(o:BytesOutput):Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace("-- Writing table of contents --");
        #end

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
            #if ANTPAK_VERBOSE_WRITER
            trace('Writing entry (ID: ${entry.id}, compression: ${entry.compression},  encrypted: ${entry.encryptionKey != null})');
            #end

            _writeString(o, entry.id);

            o.writeByte(entry.compression ?? 0);
            o.writeByte(entry.encryptionKey == null ? 0 : 1);

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
        #if ANTPAK_VERBOSE_WRITER
        trace('-- Writing contents --');
        #end

        for (entry in _entries)
        {
            #if ANTPAK_VERBOSE_WRITER
            trace('Writing bytes (ID: ${entry.id}, size: ${Util.getBytesSize(entry.data.length)}, total PAK size: ${Util.getBytesSize(o.length + entry.data.length)})');
            #end

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
    function _readDirectoryRecursively(startPath:String):Array<String>
    {
        var paths:Array<String> = [];

        startPath = Path.addTrailingSlash(startPath);

        var read = FileSystem.readDirectory(startPath);
        for (path in read)
        {
            path = startPath + path;
            if (FileSystem.isDirectory(path))
                path = Path.addTrailingSlash(path);

            if (!FileSystem.isDirectory(path))
                paths.push(path);
            else
            {
                paths = paths.concat(_readDirectoryRecursively(path));
            }
        }

        return paths;
    }

    function _normalizeAssetID(id:String):String
    {
        id = Path.normalize(id);

        while (id.startsWith("../"))
            id = id.substring(3, id.length);

        return id;
    }
}
