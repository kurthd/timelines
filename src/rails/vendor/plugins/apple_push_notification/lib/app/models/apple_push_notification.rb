# 
# Fabien Penso <fabien.penso@conovae.com>
# April 6th, 2009.
# 

require 'socket'
require 'openssl'

class ApplePushNotification < ActiveRecord::Base

	HOST = "gateway.sandbox.push.apple.com"
	PATH = '/'
	PORT = 2195
	CERT = File.read("config/apple_push_notification.pem") if File.exists?("config/apple_push_notification.pem")
	PASSPHRASE = "foobar"
	CACERT = File.expand_path(File.dirname(__FILE__) + "certs/ca.gateway.sandbox.push.apple.com.crt")
	USERAGENT = 'Mozilla/5.0 (apple_push_notification Ruby on Rails 0.1)'

	attr_accessor :paylod, :sound, :badge, :alert, :appdata
	attr_accessible :device_token

	validates_uniqueness_of :device_token

	def send_notification

		ctx = OpenSSL::SSL::SSLContext.new
		ctx.key = OpenSSL::PKey::RSA.new(CERT, PASSPHRASE)
		ctx.cert = OpenSSL::X509::Certificate.new(CERT)

		s = TCPSocket.new(HOST, PORT)
		ssl = OpenSSL::SSL::SSLSocket.new(s, ctx)
		ssl.sync = true
		ssl.connect

		ssl.write(self.apn_message_for_sending)

		ssl.close
		s.close

	rescue SocketError => error
		raise "Error while sending notifications: #{error}"
	end

	def self.send_notifications(notifications)
		ctx = OpenSSL::SSL::SSLContext.new
		ctx.key = OpenSSL::PKey::RSA.new(CERT, PASSPHRASE)
		ctx.cert = OpenSSL::X509::Certificate.new(CERT)

		s = TCPSocket.new(HOST, PORT)
		ssl = OpenSSL::SSL::SSLSocket.new(s, ctx)
		ssl.sync = true
		ssl.connect

		for notif in notifications do
			ssl.write(notif.apn_message_for_sending)
		end

		ssl.close
		s.close
	rescue SocketError => error
		raise "Error while sending notifications: #{error}"
	end

	protected

	def to_apple_json
		logger.debug "Sending #{self.apple_array.to_json}"
		self.apple_array.to_json
	end

	def apn_message_for_sending
		json = self.to_apple_json
		"\0\0 #{self.device_token_hexa}\0#{json.length.chr}#{json}"
	end

	def device_token_hexa
		[self.device_token.delete(' ')].pack('H*')
	end

	def apple_array
		result = {}
		result['aps'] = {}
		result['aps']['alert'] = alert if alert
		result['aps']['badge'] = badge if badge
		result['aps']['sound'] = sound if sound and sound.is_a? String
		result['aps']['sound'] = "1.aiff" if sound and sound.is_a?(TrueClass)
		result.merge appdata if appdata

		result
	end
end
