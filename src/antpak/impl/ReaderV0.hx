package antpak.impl;

import haxe.io.Bytes;
import haxe.ds.StringMap;
import antpak.data.ReadEntry;
import sys.io.FileInput;

class ReaderV0 extends BaseReader
{
    public function readEntries(stream:Bool):Map<String, ReadEntry>
    {
        var entries:Map<String, ReadEntry> = [];

         // read table of contents
        var numEntries = _file.readUInt16();
        for (i in 0...numEntries)
        {
            var idLen = _file.readUInt16();
            var id = _file.readString(idLen);

            var compression = _file.readByte();
            var encryption = _file.readByte();

            var position = _file.readInt32();
            var length = _file.readInt32();

            var entry = new ReadEntry(id, compression, null, position, length);

            // also load the files now if we're not streaming
            if (!stream)
                loadEntryData(entry);

            entries.set(id, entry);
        }

        return entries;
    }

    public function loadEntryData(entry:ReadEntry):Bytes
    {
        var last = _file.tell();
        _file.seek(entry.position, SeekBegin);
        var data = _file.read(entry.length);
        _file.seek(last, SeekBegin);

        entry.prepareData(data);

        return entry.data;
    }
}