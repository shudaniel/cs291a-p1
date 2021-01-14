require 'json'
require 'jwt'
require 'pp'

payload = {
    data: {},
    exp: Time.now.to_i + 5,
    nbf: Time.now.to_i + 2
}

token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
puts "TOKEN", token
decoded = JWT.decode token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }
puts decoded