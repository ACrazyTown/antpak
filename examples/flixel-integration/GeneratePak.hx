package;

import antpak.Writer;
import sys.io.File;

// Used to build our assets into a PAK and move it to the game export folder.
class GeneratePak
{
    static function main():Void
    {
        var writer:Writer = new Writer();
        writer.addAssetsRecursively("../assets/", null, ZIP);
        final bytes = writer.write();

        // TODO: unhardcode path
        File.saveBytes("export/hl/bin/assets.pak", bytes);
    }
}
