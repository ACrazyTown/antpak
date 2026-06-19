package antpak.impl;

import sys.io.FileInput;
import haxe.io.Bytes;
import antpak.data.ReadEntry;

interface IReader
{
    public function readEntries(stream:Bool):Map<String, ReadEntry>;
    public function loadEntryData(entry:ReadEntry):Bytes;
}

abstract class BaseReader
{
    var _file:FileInput;

    public function new(file:FileInput)
    {
        _file = file;
    }

    abstract public function readEntries(stream:Bool):Map<String, ReadEntry>;
    abstract public function loadEntryData(entry:ReadEntry):Bytes;
}