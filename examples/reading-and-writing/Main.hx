import sys.FileSystem;
import antpak.Pak;
import sys.io.File;
import antpak.Writer;
import haxe.crypto.Sha1;

class Main
{
    static function main() 
    {
        // create a new Writer, this is what we use to create the PAK file.
        var writer:Writer = new Writer();

        // We'll add one asset from bytes.
        writer.add("./assets/dog.png", File.getBytes("./assets/dog.png"));

        // We'll add another using a file path and compress it using the ZIP compression method
        writer.addAsset("./assets/3d-dog.png", ZIP);

        // We have some more assets left in our assets folder. but so we don't have to add them one by one,
        // we'll use a function to add them recursively. (And we'll also ZIP compression on them too!)
        // The second argument is an excludes array, which lets us add paths to files and directories
        // we DON'T want to include in our PAK.
        writer.addAssetsRecursively("./assets/more", ["*/.DS_Store", "./assets/more/even-more/catland/", "./assets/more/even-more/cat.txt"], ZIP);
    
        // Now that we've added everything we've wanted, we'll use the `write()` method to give us the bytes
        // of the PAK file, and we'll write it to disk.
        var output = writer.write();
        File.saveBytes("./assets.pak", output);

        // Let's load it back up and verify our assets are the same as we left them.
        // Instead of using Haxe's File api, we'll use the Pak class.
        // We'll also set the `stream` argument to true, to have assets loaded on demand instead of immediately.
        var pak = Pak.mount("./assets.pak", true);

        // Make sure the files we've excluded are not here.
        // Despite the fact that above we've added our file paths with the "./" prefix, we can also access them without it.
        if (pak.has("assets/more/even-more/cat.txt") ||
            pak.has("./assets/more/even-more/catland/cat3.txt"))
        {
            throw "Cats!? NOOOOO!!!";
        }

        // Ignore this, it's used to get a properly spaced out print later
        var largestId:String = "";
        for (id in pak.getAllAssetIDs())
        {
            if (id.length > largestId.length)
                largestId = id;
        }

        // Since this is pure Haxe, we can't display any of the images or play the sounds.
        // We'll have to settle for comparing the file hashes to see if the files are the same.
        for (id in pak.getAllAssetIDs())
        {
            // Get their data,
            var packedData = pak.get(id);
            var rawData = File.getBytes('./$id');

            // get the hashes,
            var packedHash = Sha1.make(packedData).toHex();
            var rawHash = Sha1.make(rawData).toHex();

            // and compare them.
            var p = 'Comparing ($id)';
            for (i in 0...(largestId.length - id.length))
                p += " ";
            p += '  |  $packedHash vs $rawHash';
            Sys.println(p);

            // Throw if they're not the same.
            if (packedHash != rawHash)
            {
                throw "Hashes don't match! This is a bug, please report it!";
            }
        }

        // If we've reached this point, that means our PAK has passed the test!
        Sys.println("All good!");

        // We're done with the PAK, so let's close and unload it.
        Pak.unmount(pak);
    }
}
