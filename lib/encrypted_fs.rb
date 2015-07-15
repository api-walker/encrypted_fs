#!/usr/bin/env ruby
require 'fusefs'
require 'fileutils'
require 'base32'
require 'find'

# own libraries
require 'bytes'
require 'crypto_helper'

include FuseFS

class EncryptedFS < FuseFS::FuseDir
  attr_reader :stats

  # debug modes
  DEBUG_MODE_NONE = 0
  DEBUG_MODE_BASIC = 1
  DEBUG_MODE_EXTENDED = 2

  # encryption levels
  ENCRYPT_MODE_NONE = 0
  ENCRYPT_MODE_CONTENT = 1
  ENCRYPT_MODE_ALL = 2

  # delete modes
  DELETE_MODE_NORMAL = 0
  DELETE_MODE_SECURE = 1 # can slow delete operations

  # setup
  DEBUG_STATE = DEBUG_MODE_EXTENDED
  ENCRYPT_STATE = ENCRYPT_MODE_ALL
  DELETE_STATE = DELETE_MODE_SECURE

  def initialize(mirror_dir, mountpoint, password, stats = nil)
    # SETUP
    # debug?
    @debug_mode = DEBUG_STATE

    # use encryption?
    @encrypt_mode = ENCRYPT_STATE

    # use extended delete? => not supported by GUI explorers => they move file to .Trash
    @delete_mode = DELETE_STATE
    @delete_rounds = 3 # overwrite file 3 times

    @mirror_dir = mirror_dir
    @mountpoint = mountpoint

    @stats = stats || StatsHelper.new()

    @crypto_helper = CryptoHelper.new(password)

    puts ""
    debug_log("Info: Building stats...") if @debug_mode != DEBUG_MODE_NONE

    # disable I/O messages while indexing
    @debug_mode = DEBUG_MODE_NONE

    if Dir[@mirror_dir].entries.empty?
      @stats.adjust(0, 1)
    else
      filesize = 0
      nodes = -1 #own mirror dir
      Find.find(@mirror_dir) do|f|
        f = f.sub @mirror_dir, ''
        filesize += size(f)
        nodes += 1
      end
      @stats.adjust(filesize, nodes)
      
      @debug_mode = DEBUG_STATE
      debug_log("Info: Found #{nodes.entries}") if @debug_mode != DEBUG_MODE_NONE
      debug_log("Info: Size of decrypted volume is #{filesize.bytes}") if @debug_mode != DEBUG_MODE_NONE
    end
  end

  def directory?(path)
    File.directory?(virtual_to_real_path(path))
  end

  def file?(path)
    File.file?(virtual_to_real_path(path))
  end

  #List directory contents
  def contents(path)
    nodes = Dir.entries(File.join(virtual_to_real_path(path))) - %w{. ..}

    if @encrypt_mode == ENCRYPT_MODE_ALL
      nodes.each_with_index do |entry, idx|
        filename = File.basename(entry)
        begin
          nodes[idx] = @crypto_helper.aes256_cbc_decrypt(Base32.decode(filename))
        rescue OpenSSL::Cipher::CipherError
          die()
        end
      end
    end

    nodes.sort
  end

  def read_file(path)
    debug_log("Reading: #{path}") if @debug_mode == DEBUG_MODE_EXTENDED

    result = ''
    if File.exists?(virtual_to_real_path(path)) and file?(path)
      if @encrypt_mode == ENCRYPT_MODE_NONE
        result = File.read(virtual_to_real_path(path))
      else
        begin
          result = @crypto_helper.aes256_cbc_decrypt(File.read(virtual_to_real_path(path)))
        rescue OpenSSL::Cipher::CipherError
          die()
        end
      end
    end
    result
  end

  def size(path)
    size = 0

    if @encrypt_mode == ENCRYPT_MODE_NONE
      size = File.size(virtual_to_real_path(path)) if file?(path)
      size ||= 0
    else
      size = read_file(path).size
    end

    size
  end

  def times(path)
    fs = File::Stat.new(virtual_to_real_path(path))
    [fs.atime, fs.mtime, fs.ctime]
  end

  #can_write only applies to files... see can_mkdir for directories...
  def can_write?(path)
    mount_user?
  end

  def write_to(path, contents)
    debug_log("Writing: #{path}") if @debug_mode == DEBUG_MODE_EXTENDED

    if File.exists?(virtual_to_real_path(path))
      @stats.adjust(contents.size - size(path), 0)
    else
      @stats.adjust(contents.size, 1)
    end
    if contents.size != 0 &&  @encrypt_mode != ENCRYPT_MODE_NONE
      File.write(virtual_to_real_path(path), @crypto_helper.aes256_cbc_encrypt(contents))
    else
      File.write(virtual_to_real_path(path), contents)
    end
  end

  # Delete a file
  def can_delete?(path)
    mount_user?
  end

  def delete(path)
    @stats.adjust(size(virtual_to_real_path(path)), -1)
    if @delete_mode == DELETE_MODE_NORMAL
      debug_log("Deleting: #{path}") if @debug_mode == DEBUG_MODE_EXTENDED

      File.delete(virtual_to_real_path(path))
    else
      debug_log("Secure deleting: #{path}") if @debug_mode == DEBUG_MODE_EXTENDED

      secure_delete(path)
    end
  end

  #mkdir - does not make intermediate dirs!
  def can_mkdir?(path)
    mount_user?
  end

  def mkdir(path)
    debug_log("Creating: #{path}") if @debug_mode == DEBUG_MODE_EXTENDED

    Dir.mkdir(virtual_to_real_path(path))
  end

  # Delete an existing directory make sure it is not empty
  def can_rmdir?(path)
    mount_user? && Dir.exists?(virtual_to_real_path(path))
  end

  def rmdir(path)
    debug_log("Deleting: #{path}") if @debug_mode == DEBUG_MODE_EXTENDED

    Dir.rmdir(virtual_to_real_path(path))
    @stats.adjust(0, -1)
  end

  def rename(from_path, to_path)
    debug_log("Renaming: #{from_path} to #{to_path}") if @debug_mode == DEBUG_MODE_EXTENDED

    File.rename(virtual_to_real_path(from_path), virtual_to_real_path(to_path))
  end

  # path is ignored? - recursively calculate for all subdirs - but cache and then rely on fuse to keep count
  def statistics(path)
    @stats.to_statistics
  end

  private
  # is the accessing user the same as the user that mounted our FS?, used for
  # all write activity
  def mount_user?
    Process.uid == FuseFS.reader_uid
  end

  def secure_delete(path)
    file_location = virtual_to_real_path(path)

    size = File.size(file_location) if file?(path)
    size ||= 0

    if size > 0
      random_generator = Random.new(Time.now.to_i)
      (0...@delete_rounds).each do |i|
        File.write(file_location, random_generator.bytes(size))
      end
    end

    File.delete(file_location)
  end

  def virtual_to_real_path(path)
    if @encrypt_mode == ENCRYPT_MODE_ALL
      path.split("/").each do |splitted|
        path = path.sub splitted, Base32.encode(@crypto_helper.aes256_cbc_encrypt(splitted))
      end
    end
    File.join(@mirror_dir, path)
  end

  def debug_log(message)
    puts "#{Time.now.strftime('%H:%M')} #{message}"
  end

  def die()
    puts 'Error: Wrong password or encryption level?'
    FuseFS.exit
  end
end
