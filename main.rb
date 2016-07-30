require 'restclient'
require 'sinatra'
require 'json'
require 'rbnacl/libsodium'
require 'rbnacl'

include RbNaCl

require_relative 'lib/extensions'
require_relative 'lib/node'
require_relative 'lib/message'
require_relative 'lib/key_pair'
require_relative 'lib/directory'
require_relative 'lib/controller'

MESSAGE_LENGTH = 256
DUMMY_MESSAGE = ' ' * MESSAGE_LENGTH
DIRECTORY_SERVER_URI = "http://localhost:8070"
SELF_URI = "#{settings.bind}:#{settings.port}"
SELF_KEYPAIR = KeyPair.generate

# slows everything down, makes log output more readable
DELAY = false

# when testing, one node should die after some time to verify that the entire network stops
DIE_EVENTUALLY = settings.port == 8081 ? true: false

Controller.instance = Controller.new(environment: :testing)

$die = 0

set :show_exceptions, false

post '/nodes' do
  body = JSON.parse(request.body.read)

  node = Node.new(
    uri: body['uri'], 
    public_key: PublicKey.new(body['public_key'].from_base64)
  )

  pulse_key_pair = KeyPair.new(
    id: body['pulse_key_pair']["id"],
    public_key: body['pulse_key_pair']["public_key"]
  )

  Controller.instance.add_node(node, pulse_key_pair)
  200
end

post '/messages' do
  if DIE_EVENTUALLY && ($die += 1) > 100
    # quickndirty way to kill one instance and get proof that the network
    # goes down subsequently
    500
  else
    body = JSON.parse(request.body.read)
    node = Controller.instance.nodes.find {|n|n.uri == body['source_uri']}
    message = Message.from_json(body['message'])
    Controller.instance.process_message(node, message)
    200
  end
end

get '/inbox' do
    Controller.instance.decrypted_messages.to_json
end

post '/outbox' do
  body = JSON.parse(request.body.read)
  body.each do |message|
  Controller.instance.next_message_for_node(
    message['destination_uri'],
    message['content']
  )
      
  end
  200
end

