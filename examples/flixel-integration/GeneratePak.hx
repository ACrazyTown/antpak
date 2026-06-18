package;

import antpak.Writer;
import sys.io.File;

// Used to build our assets into a PAK and move it to the game export folder.
class GeneratePak
{
    static function main():Void
    {
        var writer:Writer = new Writer();
        writer.addDirectoryRecursive("../assets/", null, ZIP);
        final bytes = writer.write();

        // Write our PAK to a temporary paks/ folder in the root,
        // from where it will be later copied to the export directory
        File.saveBytes("./paks/assets.pak", bytes);
    }
}
