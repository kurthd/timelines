# OpenSSL provides both symmetric and public key encryption  
require 'openssl'  
require 'base64'

class TwitterUser < ActiveRecord::Base
  # Configure public and private keys for encrypting provided credentials.
  @@encryption_public_key = File.join(RAILS_ROOT, 'config', 'public.pem')
  @@encryption_private_key = File.join(RAILS_ROOT, 'config', 'private.pem')

  attr_accessor :password
  attr_protected :encrypted_password, :encrypted_key, :encrypted_iv

  before_save :encrypt_sensitive

  def to_s
    self.username
  end

  def decrypt_sensitive(password)
    puts "Calling decrypt_sensitive."
    if self.encrypted_password
      private_key =
        OpenSSL::PKey::RSA.new(File.read(@@encryption_private_key), password)
      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')

      cipher.decrypt
      cipher.key = private_key.private_decrypt(decode64(self.encrypted_key))
      cipher.iv = private_key.private_decrypt(decode64(self.encrypted_iv))

      decrypted_data = cipher.update(decode64(self.encrypted_password))
      decrypted_data << cipher.final
    else
      ''
    end
  end

  def clear_sensitive
    self.encrypted_password = self.encrypted_key = self.encrypted_iv = nil
  end

  private

  def encrypt_sensitive
    puts "Calling encrypt_sensitive"
    if !self.password.blank?
      public_key = OpenSSL::PKey::RSA.new(File.read(@@encryption_public_key))
      cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
      cipher.encrypt
      cipher.key = random_key = cipher.random_key
      cipher.iv = random_iv = cipher.random_iv

      self.encrypted_password = cipher.update(self.password)
      self.encrypted_password << encode64(cipher.final)

      self.encrypted_key = encode64(public_key.public_encrypt(random_key))
      self.encrypted_iv = encode64(public_key.public_encrypt(random_iv))

      puts "encrypted data: #{self.encrypted_password}"
      puts "encrypted key: #{self.encrypted_key}"
      puts "encrypted iv: #{self.encrypted_iv}"
    end
  end
end
