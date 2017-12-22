require 'base64'

module RbNaCl
  class PrivateKey
    def to_base64
      to_bytes.to_base64
    end

    def self.from_base64(str)
      if str.is_a?(PrivateKey)
        str
      else
        new(str.from_base64.force_encoding('BINARY'))
      end
    end
  end

  class PublicKey
    def to_base64
      to_bytes.to_base64
    end

    def self.from_base64(str)
      if str.is_a?(PublicKey)
        str
      else
        new(str.from_base64.force_encoding('BINARY'))
      end
    end
  end
end

class Hash
  def filter(white_list)
    select { |k, _v| white_list.map(&:to_sym).include?(k.to_sym) }
  end
end

class String
  def to_base64
    Base64.encode64(self)
  end

  def from_base64
    Base64.decode64(self)
  end
end
