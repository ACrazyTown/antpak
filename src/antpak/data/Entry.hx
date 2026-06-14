package antpak.data;

import haxe.io.Bytes;

abstract class Entry
{
    public var id(default, null):String;

    public var data(default, null):Bytes;

    public var compression(default, null):Null<CompressionMethod>;

    public var encryptionKey(default, null):Null<String>;

    public function new(id:String, compression:CompressionMethod, encKey:String):Void
    {
        this.id = id;
        this.compression = compression;
        this.encryptionKey = encKey;
    }

    public abstract function prepareData(?data:Bytes):Void;
}
