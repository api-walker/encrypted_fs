require 'openssl'
require 'digest'

# AES-256 cryptographic helper class
# based on https://gist.github.com/RiANOl/1077760

class CryptoHelper
  def initialize(key)
    @key = key
    @iv = key.reverse
  end

  def aes256_cbc_encrypt(data)
    if data.size != 0
      key = Digest::SHA512.digest(@key) if (@key.kind_of?(String) && 32 != @key.bytesize)
      iv = Digest::SHA512.digest(Digest::MD5.digest(@iv)) if (@iv.kind_of?(String) && 16 != @iv.bytesize)
      aes = OpenSSL::Cipher.new('AES-256-CBC')
      aes.encrypt
      aes.key = key
      aes.iv = iv
      aes.update(data) + aes.final
    else
      return ""
    end
  end

  def aes256_cbc_decrypt(data)
    if data.size != 0
      key = Digest::SHA512.digest(@key) if (@key.kind_of?(String) && 32 != @key.bytesize)
      iv = Digest::SHA512.digest(Digest::MD5.digest(@iv)) if (@iv.kind_of?(String) && 16 != @iv.bytesize)
      aes = OpenSSL::Cipher.new('AES-256-CBC')
      aes.decrypt
      aes.key = key
      aes.iv = iv
      aes.update(data) + aes.final
    else
      return ""
    end
  end
end