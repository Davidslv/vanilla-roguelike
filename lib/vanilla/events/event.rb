require 'json'
require 'time'
require 'securerandom'

module Vanilla
  module Events
    # Base class for all events in the system
    class Event
      attr_reader :id, :timestamp, :source, :type, :data

      # Initialize a new event
      # @param type [String] The event type identifier
      # @param source [Object] The source/originator of the event
      # @param data [Hash] Additional event data
      # @param id [String, nil] Optional event ID, generated if not provided
      # @param timestamp [Time, nil] Optional timestamp, current time if not provided
      def initialize(type, source = nil, data = {}, id = nil, timestamp = nil)
        @id = id || SecureRandom.uuid
        @type = type
        @source = source
        @data = data
        @timestamp = timestamp.is_a?(String) ? Time.parse(timestamp) : (timestamp || Time.now.utc)
      end

      # String representation of the event
      # @return [String] Human-readable event string
      def to_s
        "[#{@timestamp}] #{@type}: #{@data.inspect}"
      end

      # Hash representation of the event
      # @return [Hash] Event data as a hash
      def to_h
        {
          id: @id,
          type: @type,
          source: @source.to_s,
          timestamp: @timestamp.iso8601(3),
          data: @data
        }
      end

      # JSON representation of the event
      # @return [String] Event data as a JSON string
      def to_json(*_args)
        to_h.to_json
      end

      # Create an event from its JSON representation
      # @param json [String] JSON representation of an event
      # @return [Event] Reconstructed event
      def self.from_json(json)
        data = JSON.parse(json, symbolize_names: true)

        new(
          data[:type],
          data[:source],
          data[:data] || {},
          data[:id],
          data[:timestamp]
        )
      end
    end
  end
end