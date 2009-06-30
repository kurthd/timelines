# OpenSSL provides both symmetric and public key encryption  
require 'openssl'  
require 'base64'

class TwitterUser < ActiveRecord::Base
  # Configure public and private keys for encrypting provided credentials.
  @@encryption_public_key = File.join(RAILS_ROOT, 'config', 'public.pem')
  @@encryption_private_key = File.join(RAILS_ROOT, 'config', 'private.pem')

  attr_accessor :key, :secret
  attr_protected :encrypted_key, :encrypted_secret
  attr_protected :key_encrypted_key, :key_encrypted_iv
  attr_protected :secret_encrypted_key, :secret_encrypted_iv


  before_save :encrypt_sensitive

  def to_s
    self.username
  end

  def decrypt_sensitive(password)
    if self.encrypted_key && self.encrypted_secret
      self.key = self.decrypt_key(password)
      self.secret = self.decrypt_secret(password)
    else
      self.key = ''
      self.secret = ''
    end
  end

  def decrypt_key(password)
    private_key =
      OpenSSL::PKey::RSA.new(File.read(@@encryption_private_key), password)
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')

    cipher.decrypt
    cipher.key =
      private_key.private_decrypt(Base64.decode64(self.key_encrypted_key))
    cipher.iv =
      private_key.private_decrypt(Base64.decode64(self.key_encrypted_iv))

    decrypted_key = cipher.update(Base64.decode64(self.encrypted_key))
    decrypted_key << cipher.final
  end

  def decrypt_secret(password)
    private_key =
      OpenSSL::PKey::RSA.new(File.read(@@encryption_private_key), password)
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')

    cipher.decrypt
    cipher.key =
      private_key.private_decrypt(Base64.decode64(self.secret_encrypted_key))
    cipher.iv =
      private_key.private_decrypt(Base64.decode64(self.secret_encrypted_iv))

    decrypted_secret = cipher.update(Base64.decode64(self.encrypted_secret))
    decrypted_secret << cipher.final
  end

  def clear_sensitive
    self.encrypted_key = self.encrypted_secret = nil
    self.key_encrypted_key = self.key_encrypted_iv = nil
    self.secret_encrypted_key = self.secret_encrypted_iv = nil
  end

  def encrypt_sensitive
    if !self.key.blank? && !self.secret.blank?
      self.encrypt_key
      self.encrypt_secret
    end
  end

  def encrypt_key
    public_key = OpenSSL::PKey::RSA.new(File.read(@@encryption_public_key))
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    cipher.encrypt
    cipher.key = random_key = cipher.random_key
    cipher.iv = random_iv = cipher.random_iv

    self.encrypted_key = cipher.update(self.key)
    self.encrypted_key << Base64.encode64(cipher.final)

    self.key_encrypted_key =
      Base64.encode64(public_key.public_encrypt(random_key))
    self.key_encrypted_iv =
      Base64.encode64(public_key.public_encrypt(random_iv))
  end

  def encrypt_secret
    public_key = OpenSSL::PKey::RSA.new(File.read(@@encryption_public_key))
    cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
    cipher.encrypt
    cipher.key = random_key = cipher.random_key
    cipher.iv = random_iv = cipher.random_iv

    self.encrypted_secret = cipher.update(self.secret)
    self.encrypted_secret << Base64.encode64(cipher.final)

    self.secret_encrypted_key =
      Base64.encode64(public_key.public_encrypt(random_key))
    self.secret_encrypted_iv =
      Base64.encode64(public_key.public_encrypt(random_iv))
  end
end
