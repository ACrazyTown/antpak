package antpak.exceptions;

import haxe.Exception;

class NoCryptoException extends Exception
{
    public function new(id:String)
    {
        super('Encryption requested for file ($id) but the crypto is not included. Please install and include the crypto library to use encryption functionality.');
    }
}