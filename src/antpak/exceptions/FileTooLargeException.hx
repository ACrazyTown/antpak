package antpak.exceptions;

import haxe.Exception;

class FileTooLargeException extends Exception
{
    public function new()
    {
        super('The resulting PAK file will be larger than ~2.14GB which will make it unreadable by Haxe. Please split your assets into multiple different PAKs.');
    }
}