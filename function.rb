# frozen_string_literal: true

require 'json'
require 'jwt'
require 'pp'

def main(event:, context:)
  # You shouldn't need to use context, but its fields are explained here:
  # https://docs.aws.amazon.com/lambda/latest/dg/ruby-context.html
  
  response(body: event, status: 200)
end

def valid_json?(json)
  begin
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
  end
end

def handleRootPath(body)
  if body["httpMethod"] != "GET"
    return {
      body: '',
      statusCode: 405
    }
  end
  regex = /^Bearer \S+$/
  headers_cpy = body["headers"].transform_keys(&:downcase)
  if not headers_cpy["authorization"] or not headers_cpy["authorization"].match(regex)
    return {
      body: '',
      statusCode: 403
    }
  end

  begin
    token = body["headers"]["Authorization"].split(' ')[1]
    decoded_token = JWT.decode token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }
  
    {
      body: decoded_token[0]["data"],
      statusCode: 200
    }
  rescue JWT::ExpiredSignature, JWT::ImmatureSignature => e
    return {
        body: '',
        statusCode: 401
      }
  
  rescue JWT::VerificationError, JWT::DecodeError => e
    return {
      body: '',
      statusCode: 403
    }
  end


end

def handleTokenPath(body)
  
  if body["httpMethod"] != "POST"
    return {
      body: '',
      statusCode: 405
    }
  end
  
  headers_cpy = body["headers"].transform_keys(&:downcase)
  puts headers_cpy
  if not headers_cpy or headers_cpy["content-type"] != "application/json" 
    return {
      body: '',
      statusCode: 415
    }
  end

  if not body or not body["body"] or not valid_json?(body["body"])
    return {
      body: '',
      statusCode: 422
    }
  end

  puts "PAYLOAD"
  puts body["body"]
  
  payload = {
    data: body["body"],
    exp: Time.now.to_i + 5,
    nbf: Time.now.to_i + 2
  }

  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'

  return {
    body: {"token": token},
    statusCode: 201
  }

end

def response(body: nil, status: 200)
  if not body or (body["path"] != "/" and body["path"] != "/token") 
    return {
      body: '',
      statusCode: 404
    }
  elsif body["path"] == "/"
    return handleRootPath(body)
  else
    
    return handleTokenPath(body)
    # {
    #   body: body ? body.to_json + "\n" : '',
    #   statusCode: status
    # }
  end
end

if $PROGRAM_NAME == __FILE__
  # If you run this file directly via `ruby function.rb` the following code
  # will execute. You can use the code below to help you test your functions
  # without needing to deploy first.
  ENV['JWT_SECRET'] = 'NOTASECRET'

  # Call /token
  PP.pp main(context: {}, event: {
               'body' => '{"name": "bboe"}',
               'headers' => { 'Content-Type' => 'application/json' },
               'httpMethod' => 'POST',
               'path' => '/token'
             })

  # Generate a token
  payload = {
    data: { user_id: 128 },
    exp: Time.now.to_i + 1,
    nbf: Time.now.to_i
  }
  token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
  # Call /
  PP.pp main(context: {}, event: {
               'headers' => { 'Authorization' => "Bearer #{token}",
                              'Content-Type' => 'application/json' },
               'httpMethod' => 'GET',
               'path' => '/'
             })
end
