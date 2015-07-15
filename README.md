# EncryptedFs (FUSE)

It is implemented in ruby with rfusefs and its encryption is based on AES-256 CBC-mode.
Data of the mountpoint is encrypted on the fly and saved to the destination directory.

## Installation
Clone it and build with:

    $ cd [your-folder]
    $ git clone https://github.com/api-walker/encrypted_fs.git
    $ gem build encrypted_fs.gemspec
    $ gem install encrypted_fs-0.1.0.gem

## Usage
Destination directory must be empty at first time!
    
    $ encrypted_fs /mountpoint /mirror_directory  [password]
    
## Options
### Encryption
- None
- Content only
- Filename + content

### Erasing
- None
- Overwrite n-times

## Security
- All encryption is done in RAM, so sensitive data will never be written to the disk without being encrypted (if enabled).

## Performance 

### Setup
- multiple files with varying size
- Encryption: Filename + content

### Results
- Original speed:   37 MB/s
- EncryptedFs:      14 MB/s

## Bugs
- Large files can slow your system.

## Contributing
1. Fork it ( https://github.com/api-walker/encrypted_fs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
