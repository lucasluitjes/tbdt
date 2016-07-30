class Node
  ATTRIBUTES = [:uri, :pulse_pubkeys, :message_queue, :public_key]

  attr_accessor *ATTRIBUTES

  def initialize opts={}
    opts.filter(ATTRIBUTES).each {|k,v| send(:"#{k}=",v) }

    @pulse_pubkeys, @message_queue = [], []
    @first_time = true
  end

  def register initial_key_pair
    retryable_post('http://' + uri + '/nodes', {
      uri: SELF_URI,
      pulse_key_pair: initial_key_pair,
      public_key: SELF_KEYPAIR.public_key.to_bytes.to_base64
    }.to_json)
  end

  def next_message_plaintext
    message_queue.empty? ? DUMMY_MESSAGE : message_queue.pop
  end

  def send_message message
    body = {
      source_uri: SELF_URI,
      message: message
    }.to_json
    Thread.new do 
      if @first_time || DELAY
        @first_time = false
# first time we send a node a message, we sleep a second beforehand 
# to ensure that the node is actually listening on its port
        sleep 1
      end
      retryable_post('http://' + uri + '/messages', body)
    end
  end

  def retryable_post *args
    tries ||= 0
    RestClient.post(*args)
  rescue Errno::ECONNREFUSED => e
    if tries < 3
      sleep (tries += 1) 
      retry
    end
  end
end
