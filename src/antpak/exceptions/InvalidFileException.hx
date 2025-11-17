package antpak.exceptions;

import haxe.Exception;

class InvalidFileException extends Exception
{
    public function new(path:String)
    {
        super('File ($path) is not a valid PAK or is corrupted.');
    }
}