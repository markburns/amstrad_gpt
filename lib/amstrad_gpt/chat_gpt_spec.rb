# frozen_string_literal: true

require_relative "./chat_gpt"

RSpec.describe AmstradGpt::ChatGpt do
  let(:api_key) { "test_api_key" }
  let(:subject) { described_class.new(api_key:, prompt:) }
  let(:prompt) { "some prompt" }

  describe "#initialize" do
    it "assigns an API key" do
      expect(subject.instance_variable_get(:@api_key)).to eq(api_key)
    end
  end

  describe "#send_message" do
    let(:content) { "Hello, AI!" }
    let(:response_double) do
      instance_double("Faraday::Response", body: '{"choices":[{"message":{"content":"Hello, human!"}}]}')
    end

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(response_double)
      allow(subject).to receive(:parse_response).with(response_double.body).and_call_original
    end

    it "sends a message and receives a response" do
      expect(subject.send_message(content)).to eq("Hello, human!")
    end

    it "appends user message and response message to messages list" do
      expect { subject.send_message(content) }.to change { subject.send(:messages).size }.by(2)
      messages = subject.send :messages
      expect(messages[-2][:role]).to eq "user"
      expect(messages[-1][:role]).to eq "assistant"
    end
  end

  describe "#messages" do
    it "initially has no messages" do
      expect(subject.send(:messages)).to be_empty
    end
  end

  describe "#connection" do
    it "creates a Faraday connection" do
      expect(subject.send(:connection)).to be_a(Faraday::Connection)
    end

    it "sets up the connection with correct headers" do
      connection = subject.send(:connection)
      expect(connection.headers["Authorization"]).to include(api_key)
    end
  end

  describe "#parse_response" do
    let(:response_body) { '{"choices":[{"message":{"content":"Test response"}}]}' }

    it "parses the response body to get the content of the message" do
      expect(subject.send(:parse_response, response_body)).to eq("Test response")
    end
  end
end
