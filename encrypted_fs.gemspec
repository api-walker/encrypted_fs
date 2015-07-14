# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'encrypted_fs/version'

Gem::Specification.new do |spec|
  spec.name          = "encrypted_fs"
  spec.version       = EncryptedFs::VERSION
  spec.authors       = ['Elias Fröhner']
  spec.email         = ['froehner@comcard.de']

  spec.summary       = %q{Encrypted filesystem.}
  spec.description   = %q{Encrypted filesystem with AES.}
  spec.homepage      = 'https://github.com/api-walker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.executables      = ['encrypted_fs']

  spec.add_dependency "base32", "~> 0.3"
  spec.add_dependency "rfuse", "~> 1.1"
  spec.add_dependency "rfusefs", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
