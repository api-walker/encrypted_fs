# EncryptedFs

This filesystem was created to learn about FUSE.
It encrypts the data of the mountpoint on the fly and saves it to the destination directory.

## Installation
Clone it and build with:

    $ gem build encrypted_fs.gemspec

## Usage

    $ encrypted_fs /mountpoint /mirror_directory  [password]

Note: If no password is entered, then you will be prompted to enter one.

## Security
- All encryption is done in RAM, so sensitive data will never be written to the disk without being encrypted (if enabled).

## Performance
- Original speed: 37 MB/s
- Speed with full encryption mode: 14 MB/s

## Bugs
- Large files can slow your system.

## Contributing
1. Fork it ( https://github.com/api-walker/encrypted_fs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
