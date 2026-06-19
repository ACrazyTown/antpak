package antpak.impl;

import haxe.io.Bytes;

class WriterV0 extends BaseWriter
{
    public function mutateEntryData() 
    {
        #if ANTPAK_VERBOSE_WRITER
        trace("-- Mutating files --");
        #end

        for (entry in _entries)
            entry.prepareData();
    }

    public function write():Bytes 
    {
         #if ANTPAK_VERBOSE_WRITER
        trace("-- Starting write --");
        #end

        _writeHeader();
        _writeTableOfContents();
        _writeContents();

        #if ANTPAK_VERBOSE_WRITER
        trace('-- Write complete (final size: ${Util.getBytesSize(_bytes.length)}) --');
        #end

        return _output.getBytes();
    }


    inline function _writeHeader():Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace('-- Writing header ($HEADER, v$VERSION) --');
        #end

        _output.writeString(Pak.HEADER);
        _output.writeByte(0); // version = 0
    }

    inline function _writeTableOfContents():Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace("-- Writing table of contents --");
        #end

        final headerLength = _output.length;

        _output.writeUInt16(_entries.length);

        // Get the length of everything, so we can properly calculate the position for packed files
        var tocLength:Int = 2;
        for (entry in _entries)
        {
            tocLength += 2; // path length
            tocLength += Bytes.ofString(entry.id).length; // path
            tocLength++; // i8 (compression)
            tocLength++; // i8 (encryption)
            tocLength += 4; // i32 (position)
            tocLength += 4; // i32 (length)
        }

        var dataLength = 0;
        for (entry in _entries)
        {
            #if ANTPAK_VERBOSE_WRITER
            trace('Writing entry (ID: ${entry.id}, compression: ${entry.compression},  encrypted: ${entry.encryptionKey != null})');
            #end

           _writeString(entry.id);

            _output.writeByte(entry.compression ?? 0);
            _output.writeByte(entry.encryptionKey == null ? 0 : 1);

            // position of the file
            final position = headerLength + tocLength + dataLength;
            _output.writeInt32(position);

            // length of the file
            _output.writeInt32(entry.data.length);

            dataLength += entry.data.length;
        }
    }

    inline function _writeContents():Void
    {
        #if ANTPAK_VERBOSE_WRITER
        trace('-- Writing contents --');
        #end

        for (entry in _entries)
        {
            #if ANTPAK_VERBOSE_WRITER
            trace('Writing bytes (ID: ${entry.id}, size: ${Util.getBytesSize(entry.data.length)}, total PAK size: ${Util.getBytesSize(_output.length + entry.data.length)})');
            #end

            _output.writeFullBytes(entry.data, 0, entry.data.length);
        }
    }

    /**
     * Helper that writes the length (in bytes) of the string,
     * and then the string into a `BytesOutput`
     * 
     * @param o The `BytesOutput` to write into
     * @param s The string to write
     */
    function _writeString(s:String):Void
    {
        var b = Bytes.ofString(s);
        _output.writeUInt16(b.length);
        _output.writeString(s);
    }
}