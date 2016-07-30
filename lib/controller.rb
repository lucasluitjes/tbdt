class Controller
  attr_reader :nodes

  class << self
    attr_accessor :instance
  end

  def initialize opts
    @inbox, @encrypted_messages, @decrypted_messages = [], [], []
    @key_pairs = { SELF_KEYPAIR.id => SELF_KEYPAIR }

    @nodes = Directory.register_and_get_nodes

    @current_key_pair = KeyPair.generate

# in test context we spin up two nodes simultaneously, sleep to be sure they exist when they register with eachother
    sleep 1 if opts[:environment] == :testing && !@nodes.empty?

    @nodes.each {|n| n.register(@current_key_pair) }
  end

  def send_pulse
    return unless ready_for_pulse?

    new_key_pair = KeyPair.generate
    @key_pairs[new_key_pair.id] = new_key_pair

    public_keys = @nodes.map(&:pulse_pubkeys).map(&:shift)
    public_keys << new_key_pair

    send_messages new_key_pair, public_keys
    @current_key_pair = new_key_pair
  end

  def send_messages new_key_pair, public_keys
    @nodes.each do |node|
      message = Message.new(
        plaintext: node.next_message_plaintext,
        current_key_pair: @current_key_pair,
        next_public_key: new_key_pair.public_key_only,
        encrypt: [public_keys, SELF_KEYPAIR]
      )

      node.send_message(message) 
    end
  end

  def ready_for_pulse?
    !@nodes.empty? && !@nodes.map {|n| n.pulse_pubkeys.empty?}.include?(true)
  end

  def add_node node, key_pair
    node.pulse_pubkeys << key_pair
    @key_pairs[key_pair.id] = key_pair
    @nodes << node

    send_pulse
  end

  def process_message node, message
    @key_pairs[message.current_key_pair.id] = message.current_key_pair

    node.pulse_pubkeys << message.next_public_key 
    @encrypted_messages << { node: node, message: message }

    decrypt_messages!
    send_pulse
  end

  def decrypt_messages!
    @encrypted_messages.delete_if do |encrypted_message|
      message, node = encrypted_message[:message], encrypted_message[:node]

      if message.decryptable?(@key_pairs) 
        message.decrypt!(@key_pairs, node.public_key)
        inbox_entry = { sender: node.uri, content: message.plaintext.strip }
        @decrypted_messages << inbox_entry unless message.is_dummy?
      end
    end
  end

  def decrypted_messages
    result = @decrypted_messages
    @decrypted_messages = []
    result
  end

  def next_message_for_node node_uri, message_content
    @nodes.find { |n| n.uri == node_uri }.message_queue << message_content
  end
end
