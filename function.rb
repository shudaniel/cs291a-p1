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
    JSON.parse(json)
    return true
  rescue JSON::ParserError => e
    return false
end

def handleRootPath(body)
  if body["httpMethod"] != "GET"
    return {
      body: '',
      statusCode: 405
    }
  end


end

def handleTokenPath(body)
  if body["httpMethod"] != "POST"
    return {
      body: '',
      statusCode: 405
    }
  elsif body["headers"]["Content-Type"] != "application/json" 
    return {
      body: '',
      statusCode: 415
    }
  elsif not body or not valid_json?(body["body"])
    return {
      body: '',
      statusCode: 422
    }
  end
  token = JWT.encode body["body"], ENV['JWT_SECRET'], 'HS256'
  {
    body: {"token": token},
    statusCode: 201
  }

end

def response(body: nil, status: 200)
  if not body or (body["path"] != "/" and body["path"] != "/token") 
    {
      body: '',
      statusCode: 404
    }
  elsif body["path"] == "/"
    handleRootPath(body)
  else
    handleTokenPath(body)
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
