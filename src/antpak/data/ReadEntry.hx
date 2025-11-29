package antpak.data;

import haxe.zip.Uncompress;
import haxe.io.Bytes;

class ReadEntry extends Entry
{
    public var position(default, null):Int;

    public var length(default, null):Int;

    public function new(id:String, compression:CompressionMethod, encKey:String, position:Int, length:Int)
    {
        super(id, compression, encKey);
        this.position = position;
        this.length = length;
    }

    override function prepareData(?data:Bytes):Void
    {
        var processed:Bytes = data ?? this.data;

        if (encryptionKey != null)
        {
            // todo decrypt
        }

        if (compression != null)
        {
            switch (compression)
            {
                case ZIP: processed = Uncompress.run(processed);
                default:
            }
        }

        this.data = processed;
    }
}
