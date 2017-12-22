class KeyPair
  ATTRIBUTES = %i[id private_key public_key].freeze

  attr_accessor(*ATTRIBUTES)

  def initialize(opts = {})
    opts.filter(ATTRIBUTES).each { |k, v| send(:"#{k}=", v) }

    self.private_key = PrivateKey.from_base64(private_key) if private_key
    self.public_key = PublicKey.from_base64(public_key) if public_key
  end

  def self.generate
    rbnacl = PrivateKey.generate
    new(
      id: RbNaCl::Random.random_bytes(SecretBox.key_bytes).to_base64,
      private_key: rbnacl,
      public_key: rbnacl.public_key
    )
  end

  def to_json(*_opts)
    {
      id: id,
      private_key: private_key && private_key.to_base64,
      public_key: public_key && public_key.to_base64
    }.to_json
  end

  def public_key_only
    KeyPair.new(id: id, public_key: public_key)
  end
end
