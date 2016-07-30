require 'sinatra'
require 'json'

$lock = Mutex.new
$nodes = []

post '/nodes' do
  body = JSON.parse(request.body.read)

  $lock.synchronize do
    result = $nodes.to_json
    $nodes << body
    result
  end
end
