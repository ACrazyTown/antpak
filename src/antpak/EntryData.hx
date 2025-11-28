package antpak;

import haxe.io.Bytes;

typedef EntryData =
{
    data:Bytes,
    id:String,
    ?compression:CompressionMethod,
    ?encryption:EncryptionMethod
}

typedef ReadEntry = EntryData &
{
    fileLen:Int,
    filePos:Int
}

enum abstract CompressionMethod(Int) from Int to Int
{
    var ZIP = 1;

    inline public function supported():Bool
    {
        return switch (this) 
        {
            case ZIP: true;
            default: false;
        }
    }
}

enum abstract EncryptionMethod(Int) from Int to Int
{
    var AES = 1;

    inline public function supported():Bool
    {
        return #if crypto true #else false #end;
    }
}
