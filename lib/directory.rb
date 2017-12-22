class Directory
  def self.register_and_get_nodes
    resp = RestClient.post(DIRECTORY_SERVER_URI + '/nodes', {
      uri: SELF_URI,
      public_key: SELF_KEYPAIR.public_key.to_bytes.to_base64
    }.to_json)

    JSON.parse(resp.body).map do |node|
      Node.new(
        uri: node['uri'],
        public_key: PublicKey.new(node['public_key'].from_base64)
      )
    end
  end
end
