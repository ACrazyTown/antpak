package antpak.impl;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import antpak.data.WriteEntry;

abstract class BaseWriter
{
    var _entries:Array<WriteEntry>;
    var _output:BytesOutput;

    public function new(entries:Array<WriteEntry>)
    {
        _entries = entries;
        _output = new BytesOutput();
    }

    public abstract function mutateEntryData():Void;
    public abstract function write():Bytes;
}