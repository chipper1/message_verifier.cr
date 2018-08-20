require "../spec_helper"

describe MessageVerifier::Verifier do
  describe "#valid_message?" do
    it "is false with a blank message" do
      MessageVerifier::Verifier.new("a").valid_message?("").should eq(false)
    end

    it "is false with a message with invalid encoding" do
      MessageVerifier::Verifier.new("a").valid_message?(String.new(Bytes[255, 0])).should eq(false)
    end

    it "is false when there isn't data" do
      MessageVerifier::Verifier.new("a").valid_message?("--blah").should eq(false)
    end

    it "is false when there isn't a digest" do
      MessageVerifier::Verifier.new("a").valid_message?("blah--").should eq(false)
    end

    it "is false with the digest doesn't match the generated digest" do
      MessageVerifier::Verifier.new("a").valid_message?("blah--zba").should eq(false)
    end

    it "is true with the digest matches the generated digest" do
      secret = "supersecret123456"
      data = Base64.strict_encode("superdupersecret")

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      MessageVerifier::Verifier.new(secret).valid_message?("#{data}--#{digest}").should eq(true)
    end
  end

  describe "#verified" do
    it "requires a valid message" do
      MessageVerifier::Verifier.new("a").verified("").should be_nil
    end

    it "returns nil string decodeds with invalid encoding" do
      secret = "supersecret123456"
      data = "superdupersecret"

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      MessageVerifier::Verifier.new(secret).verified("#{data}--#{digest}").should be_nil
    end

    it "returns nil when improperly encoded string" do
      secret = "supersecret123456"
      data = %({ "_rails": { "message": "Qm9vbQ==", "exp": null, "pur": "login" } })

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      MessageVerifier::Verifier.new(secret).verified("#{data}--#{digest}").should be_nil
    end

    it "returns nil when the purpose doesn't match" do
      secret = "supersecret123456"
      data = Base64.strict_encode(%({ "_rails": { "message": "Qm9vbQ==", "exp": null, "pur": "login" } }))

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      MessageVerifier::Verifier.new(secret).verified("#{data}--#{digest}", "other").should be_nil
    end

    it "returns message when the purpose matches" do
      secret = "supersecret123456"
      data = Base64.strict_encode(%({ "_rails": { "message": "Qm9vbQ==", "exp": null, "pur": "login" } }))

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      MessageVerifier::Verifier.new(secret).verified("#{data}--#{digest}", "login").should eq("Boom")
    end

    it "returns encoded message" do
      secret = "supersecret123456"
      data = Base64.strict_encode("superdupersecret")

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      MessageVerifier::Verifier.new(secret).verified("#{data}--#{digest}").should eq("superdupersecret")
    end
  end

  describe "#verify" do
    it "decodes the message" do
      secret = "supersecret123456"
      data = Base64.strict_encode("superdupersecret")

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      MessageVerifier::Verifier.new(secret).verify("#{data}--#{digest}").should eq("superdupersecret")
    end

    it "raises an error with an invalid message" do
      expect_raises(MessageVerifier::InvalidSignature) do
        MessageVerifier::Verifier.new("a").verify("")
      end
    end

    it "returns nil when improperly encoded message" do
      secret = "supersecret123456"
      data = "superdupersecret"

      digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

      expect_raises(MessageVerifier::InvalidSignature) do
        MessageVerifier::Verifier.new(secret).verify("#{data}--#{digest}")
      end
    end

    describe "#generate" do
      it "wraps the message" do
        secret = "supersecret123456"
        data = Base64.strict_encode(%({"_rails":{"message":"Qm9vbQ==","exp":null,"pur":"login"}}))

        digest = OpenSSL::HMAC.hexdigest(:sha1, secret, data)

        MessageVerifier::Verifier.new(secret).generate("Boom", purpose: "login").should eq("#{data}--#{digest}")
      end
    end
  end
end