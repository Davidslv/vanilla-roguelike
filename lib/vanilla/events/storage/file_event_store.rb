# frozen_string_literal: true

require 'fileutils'
require 'json'
require_relative '../../logger'

module Vanilla
  module Events
    module Storage
      # Implementation of event storage using files on disk
      # Events are stored in JSONL (JSON Lines) format, one event per line
      class FileEventStore < EventStore
        attr_reader :current_session, :storage_path

        # Initialize a new file-based event store
        # @param directory [String] The directory to store event files in
        # @param session_id [String, nil] Optional session ID, defaults to timestamp
        def initialize(directory = "event_logs", session_id = nil)
          @logger = Vanilla::Logger.instance
          @directory = directory
          @storage_path = directory

          FileUtils.mkdir_p(@directory) unless Dir.exist?(@directory)
          @current_session = session_id || Time.now.strftime("%Y%m%d_%H%M%S")
          @current_file = nil
        end

        # Store an event to disk
        # @param event [Vanilla::Events::Event] The event to store
        # @return [void]
        def store(event)
          ensure_file_open

          # Write event as JSON line
          @current_file.puts(event.to_json)
          @current_file.flush # Ensure data is written immediately
        end

        # Query for events based on options
        # This implementation loads the session and filters in memory
        # For more advanced querying needs, consider using a database
        # @param options [Hash] Query options
        # @return [Array<Vanilla::Events::Event>] Matching events
        def query(options = {})
          session_id = options[:session_id] || @current_session
          events = load_session(session_id)

          # Filter by type
          if options[:type]
            events = events.select { |e| e.type == options[:type] }
          end

          # Filter by time range
          if options[:start_time] && options[:end_time]
            events = events.select do |e|
              e.timestamp >= options[:start_time] && e.timestamp <= options[:end_time]
            end
          end

          # Limit results
          if options[:limit]
            events = events.last(options[:limit])
          end

          events
        end

        # Load all events from a session
        # @param session_id [String, nil] Session ID to load, or current session if nil
        # @return [Array<Vanilla::Events::Event>] Events from the session
        def load_session(session_id = nil)
          session_id ||= @current_session
          events = []

          # First try without the events_ prefix (for backward compatibility)
          filename = File.join(@directory, "#{session_id}.jsonl")

          # If not found, try with the events_ prefix
          unless File.exist?(filename)
            filename = File.join(@directory, "events_#{session_id}.jsonl")
          end

          return [] unless File.exist?(filename)

          File.open(filename, "r") do |file|
            file.each_line do |line|
              next if line.strip.empty?

              events << Event.from_json(line)
            end
          end

          events
        end

        # List available sessions
        # @return [Array<String>] List of session IDs
        def list_sessions
          Dir.glob(File.join(@directory, "events_*.jsonl")).map do |file|
            File.basename(file).gsub(/^events_/, "").gsub(/\.jsonl$/, "")
          end
        end

        # Close the file handle
        # @return [void]
        def close
          @current_file&.close
          @current_file = nil
        end

        private

        # Ensure the file is open for writing
        # @return [void]
        def ensure_file_open
          return if @current_file && !@current_file.closed?

          filename = File.join(@directory, "events_#{@current_session}.jsonl")
          @current_file = File.open(filename, "a")
        end
      end
    end
  end
end
