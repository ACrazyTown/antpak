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
}

enum abstract EncryptionMethod(Int) from Int to Int
{
    var AES = 1;
}