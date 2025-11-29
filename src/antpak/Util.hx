package antpak;

class Util
{
    public static function getBytesSize(bytes:Int):String
    {
        var units:Array<String> = ["b", "kb", "mb", "gb"];
        var unitIndex:Int = 0;

        var size:Float = bytes;

        while (size > 1024) 
        {
            size /= 1024;
            unitIndex++;
        }

        size = roundToTwoDecimals(size);
        return '$size${units[unitIndex]}';
    }

    public static function roundToTwoDecimals(n:Float):Float
        return Math.fround(n * 100) / 100;
}
