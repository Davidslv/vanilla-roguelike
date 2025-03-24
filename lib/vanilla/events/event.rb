# frozen_string_literal: true

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
          data: safe_serialize(@data)
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

      private

      # Safely serialize data by handling non-serializable objects
      # @param value [Object] The value to serialize
      # @return [Object] A serializable version of the value
      def safe_serialize(value)
        case value
        when Hash
          value.each_with_object({}) do |(k, v), h|
            h[k] = safe_serialize(v)
          end
        when Array
          value.map { |v| safe_serialize(v) }
        when Numeric, String, true, false, nil
          value
        else
          # For complex objects, convert to string representation
          value.to_s
        end
      rescue
        # If any error occurs during serialization, return a safe fallback
        "#<#{value.class} - non-serializable>"
      end
    end
  end
end
