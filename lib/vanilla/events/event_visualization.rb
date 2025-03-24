# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'time'
require_relative 'storage/event_store'
require_relative 'storage/file_event_store'

module Vanilla
  module Events
    # A utility class for visualizing event logs
    class EventVisualization
      def initialize(event_store)
        @event_store = event_store
      end

      # Generates HTML timeline visualization for a session
      # @param session_id [String] the session ID to visualize
      # @param output_file [String] the HTML file path to write
      # @return [String] the path to the generated HTML file
      def generate_timeline(session_id = nil, output_file = nil)
        session_id ||= latest_session_id
        output_file ||= "event_timeline_#{session_id}.html"

        events = @event_store.load_session(session_id)
        return nil if events.empty?

        html = generate_html(events, session_id)

        FileUtils.mkdir_p('event_visualizations')
        output_path = File.join('event_visualizations', output_file)
        File.write(output_path, html)

        output_path
      end

      # Find the most recent session ID
      # @return [String] the latest session ID
      def latest_session_id
        Dir.glob(File.join(@event_store.storage_path, '*.jsonl'))
           .map { |f| File.basename(f, '.jsonl').gsub(/^events_/, '') }
           .sort
           .last
      end

      private

      # Generate HTML visualization
      # @param events [Array<Event>] the events to visualize
      # @param session_id [String] the session ID
      # @return [String] HTML content
      def generate_html(events, session_id)
        return "<html><body><h1>No events found</h1></body></html>" if events.empty?

        # Group events by type
        event_types = events.map(&:type).uniq.sort
        events_by_type = {}
        event_types.each do |type|
          events_by_type[type] = events.select { |e| e.type == type }
        end

        # Find time boundaries
        start_time = events.first.timestamp
        end_time = events.last.timestamp
        duration = end_time - start_time

        # Generate the HTML
        html = <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Event Timeline - #{session_id}</title>
            <style>
              body { font-family: Arial, sans-serif; margin: 20px; }
              h1 { color: #333; }
              .timeline { position: relative; margin: 20px 0; border-left: 2px solid #ccc; padding-left: 20px; }
              .event-group { margin-bottom: 30px; }
              .event-type { font-weight: bold; margin-bottom: 10px; }
              .event { position: relative; margin-bottom: 5px; cursor: pointer; }
              .event-marker {
                position: absolute;
                width: 10px;
                height: 10px;
                border-radius: 50%;
                background-color: #3498db;
                left: -25px;
                top: 5px;
              }
              .event-time { color: #666; font-size: 0.8em; margin-right: 10px; display: inline-block; width: 80px; }
              .event-details { display: none; padding: 10px; background-color: #f5f5f5; margin: 5px 0; border-radius: 4px; }
              .event.active .event-details { display: block; }
              .event.active .event-marker { background-color: #e74c3c; }
              .timestamp { color: #666; font-size: 0.8em; }
              .filter-controls { margin-bottom: 20px; }
              .event-count { font-size: 0.8em; color: #666; margin-left: 10px; }
              .timeline-header { display: flex; justify-content: space-between; align-items: center; }
              .position-marker {
                position: absolute;
                left: calc(var(--position-percent) * 100%);
                width: 2px;
                height: 100%;
                background-color: rgba(255, 0, 0, 0.5);
                z-index: 1;
              }
            </style>
          </head>
          <body>
            <h1>Event Timeline - #{session_id}</h1>
            <div class="timestamp">
              Start: #{start_time.strftime('%Y-%m-%d %H:%M:%S.%L')}<br>
              End: #{end_time.strftime('%Y-%m-%d %H:%M:%S.%L')}<br>
              Duration: #{duration.round(2)} seconds
            </div>

            <div class="filter-controls">
              <input type="text" id="search" placeholder="Filter events..." style="width: 250px; padding: 5px;">
              <button id="expandAll">Expand All</button>
              <button id="collapseAll">Collapse All</button>
              <div style="margin-top: 10px;">
                <label>Show event types:</label>
                <div id="eventTypeFilters">
                  <!-- Event type checkboxes will be inserted here -->
                </div>
              </div>
            </div>

            <div class="timeline">
              <!-- Timeline content will be inserted here -->
            </div>

            <script>
              // Event data
              const events = #{events.map { |e| {
                id: e.id,
                type: e.type,
                source: e.source.to_s,
                timestamp: e.timestamp,
                time_offset: (e.timestamp - start_time).round(3),
                position_percent: duration > 0 ? (e.timestamp - start_time) / duration : 0,
                data: e.data || {}
              }
}.to_json};

              const eventTypes = #{event_types.to_json};
              const duration = #{duration};

              // Setup event type filters
              const filtersContainer = document.getElementById('eventTypeFilters');
              eventTypes.forEach(type => {
                const count = events.filter(e => e.type === type).length;
                const div = document.createElement('div');
                div.innerHTML = `
                  <label>
                    <input type="checkbox" class="event-type-filter" data-type="${type}" checked>
                    ${type} <span class="event-count">(${count})</span>
                  </label>
                `;
                filtersContainer.appendChild(div);
              });

              // Render timeline
              function renderTimeline() {
                const timeline = document.querySelector('.timeline');
                timeline.innerHTML = '';

                // Add position marker
                const marker = document.createElement('div');
                marker.className = 'position-marker';
                marker.style.setProperty('--position-percent', 0);
                timeline.appendChild(marker);

                // Group events by type and render
                const visibleTypes = Array.from(
                  document.querySelectorAll('.event-type-filter:checked')
                ).map(cb => cb.dataset.type);

                const searchTerm = document.getElementById('search').value.toLowerCase();

                eventTypes.forEach(type => {
                  if (!visibleTypes.includes(type)) return;

                  const typeEvents = events.filter(e => e.type === type && (
                    searchTerm === '' ||
                    type.toLowerCase().includes(searchTerm) ||
                    JSON.stringify(e.data).toLowerCase().includes(searchTerm)
                  ));

                  if (typeEvents.length === 0) return;

                  const eventGroup = document.createElement('div');
                  eventGroup.className = 'event-group';

                  const eventTypeHeader = document.createElement('div');
                  eventTypeHeader.className = 'event-type';
                  eventTypeHeader.innerHTML = `${type} <span class="event-count">(${typeEvents.length})</span>`;
                  eventGroup.appendChild(eventTypeHeader);

                  typeEvents.forEach(event => {
                    const eventEl = document.createElement('div');
                    eventEl.className = 'event';
                    eventEl.dataset.id = event.id;
                    eventEl.dataset.position = event.position_percent;

                    const marker = document.createElement('div');
                    marker.className = 'event-marker';
                    marker.style.left = `calc(-25px + ${event.position_percent * 100}% * 0.8)`;
                    eventEl.appendChild(marker);

                    const eventContent = document.createElement('div');
                    eventContent.innerHTML = `
                      <span class="event-time">+${event.time_offset}s</span>
                      <span>${event.source}</span>
                    `;
                    eventEl.appendChild(eventContent);

                    const eventDetails = document.createElement('div');
                    eventDetails.className = 'event-details';
                    eventDetails.innerHTML = `
                      <div><strong>ID:</strong> ${event.id}</div>
                      <div><strong>Type:</strong> ${event.type}</div>
                      <div><strong>Source:</strong> ${event.source}</div>
                      <div><strong>Timestamp:</strong> ${event.timestamp}</div>
                      <div><strong>Data:</strong> <pre>${JSON.stringify(event.data, null, 2)}</pre></div>
                    `;
                    eventEl.appendChild(eventDetails);

                    eventEl.addEventListener('click', () => {
                      eventEl.classList.toggle('active');
                      marker.style.setProperty('--position-percent', event.position_percent);
                    });

                    eventEl.addEventListener('mouseenter', () => {
                      marker.style.setProperty('--position-percent', event.position_percent);
                    });

                    eventGroup.appendChild(eventEl);
                  });

                  timeline.appendChild(eventGroup);
                });
              }

              // Event listeners for filters
              document.querySelectorAll('.event-type-filter').forEach(checkbox => {
                checkbox.addEventListener('change', renderTimeline);
              });

              document.getElementById('search').addEventListener('input', renderTimeline);

              document.getElementById('expandAll').addEventListener('click', () => {
                document.querySelectorAll('.event').forEach(el => {
                  el.classList.add('active');
                });
              });

              document.getElementById('collapseAll').addEventListener('click', () => {
                document.querySelectorAll('.event').forEach(el => {
                  el.classList.remove('active');
                });
              });

              // Initial render
              renderTimeline();
            </script>
          </body>
          </html>
        HTML

        html
      end
    end
  end
end
