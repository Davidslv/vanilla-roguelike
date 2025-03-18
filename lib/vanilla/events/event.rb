require 'json'
require 'time'

module Vanilla
  module Events
    # Base class for all events in the system
    class Event
      attr_reader :timestamp, :source, :type, :data

      # Initialize a new event
      # @param type [String] The event type identifier
      # @param source [Object] The source/originator of the event
      # @param data [Hash] Additional event data
      def initialize(type, source = nil, data = {})
        @type = type
        @source = source
        @data = data
        @timestamp = Time.now
      end

      # String representation of the event
      # @return [String] Human-readable event description
      def to_s
        "[#{@timestamp}] #{@type}: #{@data.inspect}"
      end

      # Convert the event to a JSON-serializable hash
      # @return [Hash] The event data as a serializable hash
      def to_h
        {
          type: @type,
          timestamp: @timestamp.iso8601,
          source: @source.to_s,
          data: @data
        }
      end

      # Serialize the event to JSON
      # @return [String] JSON string representation of the event
      def to_json(*_args)
        to_h.to_json
      end

      # Create an event from a JSON string
      # @param json [String] JSON string representation of an event
      # @return [Event] A new Event instance
      def self.from_json(json)
        data = JSON.parse(json, symbolize_names: true)

        # Create new event with parsed data
        event = new(
          data[:type],
          data[:source],
          data[:data] || {}
        )

        # Set timestamp manually to preserve original time
        event.instance_variable_set(:@timestamp, Time.iso8601(data[:timestamp]))

        event
      end
    end
  end
end