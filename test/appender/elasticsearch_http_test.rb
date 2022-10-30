require_relative "../test_helper"

# Unit Test for SemanticLogger::Appender::Elasticsearch
module Appender
  class ElasticsearchHttpTest < Minitest::Test
    response_mock = Struct.new(:code, :body)

    describe SemanticLogger::Appender::ElasticsearchHttp do
      let(:appender) do
        Net::HTTP.stub_any_instance(:start, true) do
          SemanticLogger::Appender::ElasticsearchHttp.new(url: "http://localhost:9200")
        end
      end
      let(:amessage) { "AppenderElasticsearchTest log message" }

      it "logs to daily indexes" do
        index = nil
        appender.stub(:post, ->(_json, ind) { index = ind }) do
          appender.info amessage
        end
        assert_equal "/semantic_logger-#{Time.now.strftime('%Y.%m.%d')}/log", index
      end

      SemanticLogger::LEVELS.each do |level|
        it "send #{level}" do
          request = nil
          appender.http.stub(:request, ->(r) { request = r; response_mock.new("200", "ok") }) do
            appender.send(level, amessage)
          end
          message = JSON.parse(request.body)
          assert_equal amessage, message["message"]
          assert_equal level.to_s, message["level"]
          refute message["exception"]
        end

        it "sends #{level} exceptions" do
          exc     = nil
          begin
            Uh oh
          rescue Exception => e
            exc = e
          end
          request = nil
          appender.http.stub(:request, ->(r) { request = r; response_mock.new("200", "ok") }) do
            appender.send(level, "Reading File", exc)
          end
          hash = JSON.parse(request.body)
          assert_equal "Reading File", hash["message"], hash
          assert exception = hash["exception"]
          assert_equal "NameError", exception["name"]
          assert_match "undefined local variable or method", exception["message"]
          assert_equal level.to_s, hash["level"]
          assert exception["stack_trace"].first.include?(__FILE__), exception
        end

        it "sends #{level} custom attributes" do
          request = nil
          appender.http.stub(:request, ->(r) { request = r; response_mock.new("200", "ok") }) do
            appender.send(level, amessage, key1: 1, key2: "a")
          end
          message = JSON.parse(request.body)
          assert_equal amessage, message["message"]
          assert_equal level.to_s, message["level"]
          refute message["stack_trace"]
          assert payload = message["payload"], message
          assert_equal 1, payload["key1"], message
          assert_equal "a", payload["key2"], message
        end
      end
    end
  end
end
