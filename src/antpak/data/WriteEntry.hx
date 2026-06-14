package antpak.data;

#if crypto
import haxe.crypto.Aes;
#end
import antpak.Util;
import antpak.exceptions.NoCryptoException;
import haxe.zip.Compress;
import haxe.io.Bytes;

@:structInit
class WriteEntry extends Entry
{
    public function new(id:String, data:Bytes, compression:CompressionMethod, encKey:String)
    {
        super(id, compression, encKey);
        this.data = data;
    }

    public function prepareData(?data:Bytes):Void 
    {
        var processed:Bytes = data ?? this.data;

        #if ANTPAK_VERBOSE_WRITER
        var oldSize:Int = processed.length;
        #end

        if (compression != null)
        {
            if (compression.supported())
            {
                switch (compression)
                {
                    case ZIP: processed = Compress.run(processed, 6);
                    default:
                }

                #if ANTPAK_VERBOSE_WRITER
                var oldSizeString:String = Util.getBytesSize(oldSize);
                var newSizeString:String = Util.getBytesSize(processed.length);

                var diff:Float = Util.roundToTwoDecimals(((processed.length - oldSize) / oldSize) * 100);
                trace('Compressed bytes (ID: ${id}, method: ${compression}, size: $oldSizeString -> $newSizeString ($diff%))');
                #end
            }
            else
                throw "TODO";
        }

        if (encryptionKey != null)
        {
            #if crypto
            // var aes = new Aes();
            #else
            throw new NoCryptoException(id);
            #end
        }

        this.data = processed;
    }
}
