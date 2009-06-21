## Notification
## 
## Based on Fabien Penso's original Ruby on Rails source
## Updated by Anton Kiland (april 2009)
## 
## Requires json (sudo gem install json)
## Usage:
## notification = Notification.new(device_token)
## notification.alert = 'Hello World!'
## notification.badge = 10
## notification.sound = 'purr.caf'
## notification.send_notification
##
## If you want to send multiple notifications in the same session use:
## Notification.send_notifications([notification1, notification2, notification3])
##
## Protected under Apple iPhone Developer NDA
##

require 'rubygems'

require 'socket'
require 'openssl'
require 'json'

class Notification

  HOST = 'gateway.sandbox.push.apple.com'
  PATH = '/'
  PORT = 2195
  CERT = File.read(File.dirname(__FILE__) + '/twitch-certificate.pem') #if File.exists?('twitch-certificate.p12')
  PASSPHRASE = 'lucyandl0b0'
  USERAGENT = 'Ruby/Notification.rb'

  attr_accessor :sound, :badge, :alert, :app_data
  attr_reader :device_token

  def initialize (token)
    @device_token = token
  end

  def send_notification
    s, ssl = self.class.ssl_connection

    ssl.write(self.apn_message_for_sending)

    ssl.close
    s.close
  rescue SocketError => error
    raise "Error while sending notification: #{error}"
  end

  def self.send_notifications (notifications)
    s, ssl = self.class.ssl_connection

    notifications.each do |notification|
      ssl.write(notification.apn_message_for_sending)
    end

    ssl.close
    s.close
  rescue SocketError => error
    raise "Error while sending notifications: #{error}"
  end

  protected
  def self.ssl_connection
    ctx = OpenSSL::SSL::SSLContext.new
    ctx.key = OpenSSL::PKey::RSA.new(CERT, PASSPHRASE)
    ctx.cert = OpenSSL::X509::Certificate.new(CERT)

    s = TCPSocket.new(HOST, PORT)
    ssl = OpenSSL::SSL::SSLSocket.new(s, ctx)
    ssl.sync = true
    ssl.connect

    return s, ssl
  end

  protected
  def to_apple_json
    self.apple_array.to_json
  end

  protected 
  def apn_message_for_sending
    json = self.to_apple_json
    "\0\0 #{self.device_token_hex}\0#{json.length.chr}#{json}"
  end

  protected
  def device_token_hex
    [self.device_token.delete(' ')].pack('H*')
  end

  protected
  def apple_array
    result = {}
    result['aps'] = {}
    result['aps']['alert'] = alert if alert
    result['aps']['badge'] = badge if badge
    result['aps']['sound'] = sound if sound
    result.merge!(app_data) if app_data
    result
  end
end
