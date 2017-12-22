require 'pp'
require 'service_manager'
require 'restclient'

def post_json(url, obj)
  RestClient.post url, obj.to_json, content_type: :json, accept: :json
end

puts "\n\n\n"

# start the directory server and nodes
ServiceManager.start

# wait for server and nodes to be up
sleep 2

# send a message from localhost:8081 to localhost:8082
post_json('http://localhost:8081/outbox', [{
            destination_uri: 'localhost:8082',
            content: 'hello world!'
          }])

sleep 7

# check if localhost:8082 received the message
response = JSON.parse(RestClient.get('http://localhost:8082/inbox').body)

expected_response = [{
  'sender' => 'localhost:8081',
  'content' => 'hello world!'
}]

if expected_response == response
  puts "\n\nSuccess\n\n\n"
else
  puts "\n\nFailure:"
  pp response
  puts "\n\n"
end
