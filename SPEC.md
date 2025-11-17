# antpak Specification (v0)
## Structure

### Header

The header is pretty simple, and holds just 2 values:

```
header    String   (6 bytes)
version   UInt8    (1 byte)
```

where:

- `header` is always a 6 byte string reading `ANTPAK`.  If this is not the case, the file should be treated as invalid/corrupted and an exception should be thrown.
- `version` is the version of the format. This is used internally to allow for backwards compatibility.

### Table of Contents

The table of contents stores pretty much all of the information for a file, except for its data. This was done so that files can be stored at seperate positions to allow for file streaming.

At the start of the table is a single value that holds the number of entries in the table:

```
numEntries   UInt16   (2 bytes)
```

Each entry in the table of contents consists of the following structure:
```
idLength      UInt16   (2 bytes)
id            String   (size is determined by idLength)
compression   UInt8    (1 byte)
encryption    UInt8    (1 byte)
position      Int32    (4 bytes)
length        Int32    (4 bytes)
``` 

where:
- `idLength` is the length of the `id` string.
- `id` is the "path" or "key" to the file, used to access it.
- `compression` is a number that corresponds to the used compression method. Set to `0` to disable compression on this file. See supported compression methods at the bottom of the document.
- `encryption` is a number that corresponds to the used encryption method. Set to `0` to disable encryption on this file. See supported encryption methods at the bottom of the document.

If both `encryption` and `compression` are set, the file will first be compressed, then encrypted.

You should stop reading the file here, and use the provided positions and lengths from the table to seek and read each file's contents.

### Contents

```
data   Bytes   (size is read in the table of contents)
```

There is actually not much here, it is just the bytes of each file stored one after another. Use the positions and lengths from the table of contents to seek and read each file's contents.

## Supported compression methods
- `1` - ZIP compression, `haxe.zip.Compress` will be used.

## Supported encryption methods
**NOTE:** ALL encryption methods require the inclusion of the Haxe [crypto](https://lib.haxe.org/p/crypto/) library. If a file is encrypted and the library is not present, an exception will be thrown.

- `1` - AES encryption.
