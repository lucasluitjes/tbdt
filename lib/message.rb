class Message
  ATTRIBUTES = %i[ciphertext plaintext key_ids current_key_pair next_public_key].freeze

  attr_accessor(*ATTRIBUTES)

  def initialize(opts = {})
    opts.filter(ATTRIBUTES).each { |k, v| send(:"#{k}=", v) }

    encrypt!(*opts[:encrypt]) if opts[:encrypt]
  end

  def encrypt!(public_keys, sender_key)
    ensure_message_length!
    @key_ids = public_keys.map(&:id)

    self.ciphertext = plaintext
    public_keys.each do |public_key|
      box = SimpleBox.from_keypair(
        public_key.public_key,
        sender_key.private_key
      )
      self.ciphertext = box.encrypt(ciphertext)
    end
  end

  def ensure_message_length!
    self.plaintext = plaintext[0, MESSAGE_LENGTH].ljust(MESSAGE_LENGTH, ' ')
  end

  def decrypt!(keys, sender_key)
    self.plaintext = ciphertext
    key_ids.reverse.each do |key_id|
      box = SimpleBox.from_keypair(
        sender_key,
        keys[key_id].private_key
      )
      self.plaintext = box.decrypt(plaintext)
    end
  end

  def to_json(*opts)
    {
      ciphertext: ciphertext.to_base64,
      key_ids: key_ids,
      current_key_pair: current_key_pair,
      next_public_key: next_public_key
    }.to_json(opts)
  end

  def dummy?
    plaintext == DUMMY_MESSAGE
  end

  def decryptable?(key_pairs)
    !key_ids.map { |n| key_pairs[n] }.include?(nil)
  end

  def self.from_json(json)
    msg = Message.new(json.filter(%i[ciphertext plaintext key_ids]))

    msg.ciphertext = msg.ciphertext.from_base64.force_encoding('BINARY')
    msg.current_key_pair = KeyPair.new(json['current_key_pair'])
    msg.next_public_key = KeyPair.new(json['next_public_key'])

    msg
  end
end
