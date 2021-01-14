require 'json'
require 'jwt'
require 'pp'

payload = {
    data: {},
    exp: Time.now.to_i + 5,
    nbf: Time.now.to_i
}

secret = 'password'
puts "SECFET", secret
token = JWT.encode payload, secret, 'HS256'
puts "TOKEN", token
decoded = JWT.decode( token, secret, true, algorithm: 'HS256' )
puts "DECODED",  decoded
