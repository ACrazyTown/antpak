package antpak.data;

enum abstract CompressionMethod(Int) from Int to Int
{
    var NONE = 0;
    var ZIP = 1;

    inline public function supported():Bool
    {
        return switch (this) 
        {
            case NONE, ZIP: true;
            default: false;
        }
    }
}
