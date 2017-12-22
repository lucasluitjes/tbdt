require 'sinatra'
require 'json'

Lock = Mutex.new
Nodes = []

post '/nodes' do
  body = JSON.parse(request.body.read)

  Lock.synchronize do
    result = Nodes.to_json
    Nodes << body
    result
  end
end
