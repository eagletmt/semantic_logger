require_relative "../test_helper"

# Unit Test for SemanticLogger::Appender::Splunk
module Appender
  class SplunkTest < Minitest::Test
    class Mock
      attr_accessor :message, :event

      def submit(message, event)
        self.message = message
        self.event   = event
      end
    end

    describe SemanticLogger::Appender::Splunk do
      let(:appender) do
        mock = Module.new do
          def self.indexes
            {"main" => "main"}
          end
        end
        ::Splunk.stub(:connect, mock) do
          SemanticLogger::Appender::Splunk.new
        end
      end
      let(:amessage) { "AppenderSplunkTest log message" }

      SemanticLogger::LEVELS.each do |level|
        it "send #{level}" do
          mock = Mock.new
          appender.stub(:service_index, mock) do
            appender.send(level, amessage)
          end
          assert_equal amessage, mock.message
          assert_equal level, mock.event[:event][:level]
          refute mock.event[:event][:exception]
        end

        it "sends #{level} exceptions" do
          exc = nil
          begin
            Uh oh
          rescue Exception => e
            exc = e
          end

          mock = Mock.new
          appender.stub(:service_index, mock) do
            appender.send(level, amessage, exc)
          end
          assert_equal amessage, mock.message

          assert exception = mock.event[:event][:exception]
          assert "NameError", exception[:name]
          assert "undefined local variable or method", exception[:message]
          assert_equal level, mock.event[:event][:level]
          assert exception[:stack_trace].first.include?(__FILE__), exception
        end

        it "sends #{level} custom attributes" do
          mock = Mock.new
          appender.stub(:service_index, mock) do
            appender.send(level, amessage, key1: 1, key2: "a")
          end
          assert_equal amessage, mock.message

          assert event = mock.event[:event], mock.event.ai
          assert_equal level, event[:level]
          refute event[:stack_trace]
          assert payload = event[:payload]
          assert_equal(1, payload[:key1], payload)
          assert_equal("a", payload[:key2], payload)
        end
      end

      it "does not send :trace notifications to Splunk when set to :error" do
        mock = Mock.new
        appender.level = :error
        appender.stub(:service_index, mock) do
          appender.trace("AppenderSplunkTest trace message")
        end
        assert_nil mock.event
        assert_nil mock.message
      end
    end
  end
end
