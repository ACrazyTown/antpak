package antpak;

import antpak.impl.BaseWriter;
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
    public function write(?version:Int):Bytes
    {
        var bytes:Bytes = null;
        version ??= Pak.VERSION;

        if (_entries.length > 0)
        {
            var writer:BaseWriter = switch (version)
            {
                case 0: new antpak.impl.WriterV0(_entries);
                default: throw 'Incompatible antpak version ($version)';
            }

            writer.mutateEntryData();
            bytes = writer.write();

            _entries.resize(0);
        }

        return bytes;
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
