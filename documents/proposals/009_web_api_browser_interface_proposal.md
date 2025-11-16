# Proposal 009: Web API Layer and Browser Interface

## Overview

Enable web browser gameplay while keeping all game logic in Ruby on the server. This proposal outlines adding a web API layer with WebSocket support to make Vanilla Roguelike playable in any web browser, eliminating the need for terminal setup while preserving the existing Ruby ECS architecture.

**Architecture Approach**: Server-side game state with WebSocket for real-time updates (thin client)

**Target Audience**: Web users wanting to play without Ruby/terminal setup, potential for wider audience reach

## Current State

### Existing Architecture

Vanilla currently uses a **terminal-based architecture** with the following characteristics:

1. **Turn-Based Game Loop**: Blocking input (`wait_for_input`) that pauses until player presses a key
2. **ECS Architecture**: World coordinator managing entities, components, and systems
3. **Terminal Renderer**: ASCII output directly to stdout via `TerminalRenderer`
4. **Single-Player**: One game instance per terminal session

**Key Files:**
- `lib/vanilla/game.rb` - Game loop and initialization
- `lib/vanilla/world.rb` - ECS coordinator
- `lib/vanilla/systems/input_system.rb` - Blocking keyboard input
- `lib/vanilla/keyboard_handler.rb` - Terminal input handling
- `lib/vanilla/renderers/terminal_renderer.rb` - ASCII terminal output
- `lib/vanilla/systems/render_system.rb` - Rendering pipeline

### Current Game Loop

```ruby
def game_loop
  until @world.quit?
    @world.update(nil)  # Update all systems
    @turn += 1
    render
  end
end

# InputSystem blocks on keyboard input
def update(_unused)
  key = @world.display.keyboard_handler.wait_for_input # BLOCKS HERE
  @input_handler.handle_input(key)
end
```

The game loop is **synchronous and blocking** - it waits for player input before continuing.

### Rendering Pipeline

```ruby
def update(_delta_time)
  @renderer.clear           # Clear terminal
  update_renderer_info      # Get player health, difficulty, etc.
  render_grid               # Draw grid with entities
  render_messages           # Draw message log
  @renderer.present         # Output to terminal
end
```

All rendering happens to stdout - there's no concept of state serialization.

## Proposed Architecture

### Architecture Overview

```
┌─────────────────────────────────────────┐
│         Browser Client                  │
│  ┌────────────┐      ┌───────────────┐  │
│  │   Canvas   │      │  Input Handler│  │
│  │  Renderer  │      └───────┬───────┘  │
│  └─────▲──────┘              │          │
│        │                     │          │
│  ┌─────┴─────────────────────▼───────┐  │
│  │      WebSocket Client              │  │
│  └─────────────────┬──────────────────┘  │
└────────────────────┼─────────────────────┘
                     │ WebSocket Protocol
                     │ (JSON messages)
┌────────────────────▼─────────────────────┐
│         Ruby Server (Puma)               │
│  ┌──────────────────────────────────┐    │
│  │   Sinatra Web Framework          │    │
│  └──────────────┬───────────────────┘    │
│                 │                        │
│  ┌──────────────▼───────────────────┐    │
│  │   WebSocket Handler              │    │
│  │   (Faye-WebSocket)               │    │
│  └──────────────┬───────────────────┘    │
│                 │                        │
│  ┌──────────────▼───────────────────┐    │
│  │   Session Manager                │    │
│  │   sessionId => GameAdapter       │    │
│  └──────────────┬───────────────────┘    │
│                 │                        │
│  ┌──────────────▼───────────────────┐    │
│  │   GameAdapter (per session)      │    │
│  │   • Input Queue                  │    │
│  │   • Game Instance                │    │
│  │   • State Callbacks              │    │
│  └──────────────┬───────────────────┘    │
│                 │                        │
│  ┌──────────────▼───────────────────┐    │
│  │   Game Instance (ECS)            │    │
│  │   ┌─────────┐  ┌──────────┐     │    │
│  │   │  World  │  │ Systems  │     │    │
│  │   └─────────┘  └──────────┘     │    │
│  └──────────────────────────────────┘    │
└──────────────────────────────────────────┘
```

### Server Components

#### 1. Sinatra Web Application
- Serves static HTML/JS/CSS files
- Provides REST endpoints for game management
- Handles WebSocket upgrade requests
- **File**: `lib/vanilla/web/server.rb`

#### 2. WebSocket Handler
- Manages WebSocket connections
- Routes messages to appropriate game sessions
- Sends state updates to clients
- **File**: `lib/vanilla/web/websocket_handler.rb`

#### 3. Session Manager
- Maintains map of session ID → GameAdapter
- Creates new game sessions
- Cleans up abandoned sessions (timeout)
- Thread-safe concurrent access
- **File**: `lib/vanilla/web/session_manager.rb`

#### 4. Game Adapter
- Bridges blocking game loop with async WebSocket
- Maintains input queue for player actions
- Runs game in separate thread
- Captures state updates and sends via callbacks
- **File**: `lib/vanilla/web/game_adapter.rb`

#### 5. State Serializer
- Converts game state to JSON
- Serializes grid, entities, player stats, messages
- Handles visibility/FOV information
- Optimizes payload size
- **File**: `lib/vanilla/web/state_serializer.rb`

#### 6. Web Renderer
- Implements `Renderer` interface
- Instead of drawing to terminal, builds JSON state
- Used by GameAdapter to capture renderable state
- **File**: `lib/vanilla/renderers/web_renderer.rb`

### Client Components

#### 1. HTML5 Game Client
- Single-page application
- Establishes WebSocket connection
- Handles keyboard input
- Renders game state
- **File**: `public/index.html`

#### 2. WebSocket Client
- Connects to server WebSocket endpoint
- Sends input events
- Receives state updates
- Handles reconnection
- **File**: `public/js/websocket-client.js`

#### 3. Renderer
- Canvas or DOM-based rendering
- ASCII character display (flexible for future tile graphics)
- Color support for entities
- Message log display
- **File**: `public/js/renderer.js`

#### 4. Input Handler
- Captures keyboard events
- Maps keys to game commands
- Sends to server via WebSocket
- **File**: `public/js/input-handler.js`

#### 5. Game Controller
- Main client-side orchestrator
- Coordinates WebSocket, renderer, input
- **File**: `public/js/game.js`

## Technical Design

### WebSocket Protocol

The protocol uses JSON messages for bidirectional communication.

#### Client → Server Messages

**Input Message:**
```json
{
  "type": "input",
  "key": "h",
  "timestamp": 1234567890
}
```

**Quit Message:**
```json
{
  "type": "quit"
}
```

#### Server → Client Messages

**Connection Established:**
```json
{
  "type": "connected",
  "sessionId": "abc123-def456-ghi789",
  "message": "Connected to Vanilla Roguelike"
}
```

**State Update:**
```json
{
  "type": "state_update",
  "data": {
    "grid": {
      "rows": 20,
      "cols": 40,
      "cells": [
        {"row": 0, "col": 0, "type": "wall", "visible": false, "explored": false},
        {"row": 0, "col": 1, "type": "floor", "visible": true, "explored": true}
      ]
    },
    "entities": [
      {
        "id": 1,
        "char": "@",
        "row": 5,
        "col": 5,
        "color": "yellow",
        "name": "Player"
      },
      {
        "id": 2,
        "char": "g",
        "row": 8,
        "col": 10,
        "color": "green",
        "name": "Goblin"
      }
    ],
    "player": {
      "health": {
        "current": 80,
        "max": 100
      },
      "position": {
        "row": 5,
        "col": 5
      }
    },
    "messages": [
      "You hit the goblin for 5 damage!",
      "The goblin misses you."
    ],
    "gameInfo": {
      "seed": 12345,
      "difficulty": 1,
      "turn": 42,
      "algorithm": "RecursiveBacktracker"
    },
    "visibility": {
      "fovActive": true,
      "devMode": false
    }
  }
}
```

**Error Message:**
```json
{
  "type": "error",
  "message": "Invalid input",
  "code": "INVALID_INPUT"
}
```

**Game Over:**
```json
{
  "type": "game_over",
  "reason": "death",
  "stats": {
    "turns": 152,
    "kills": 5,
    "level": 3
  }
}
```

### API Endpoints

#### `GET /`
Serves the main game client HTML page.

**Response**: HTML document with game UI

#### `GET /ws`
WebSocket upgrade endpoint for game connection.

**Protocol**: WebSocket
**Returns**: WebSocket connection with bidirectional JSON messages

#### `POST /api/games`
Create a new game session (optional - can also create on WebSocket connect).

**Request Body:**
```json
{
  "difficulty": 1,
  "seed": 12345
}
```

**Response:**
```json
{
  "sessionId": "abc123-def456",
  "wsUrl": "ws://localhost:4567/ws?session=abc123-def456"
}
```

#### `DELETE /api/games/:id`
End a game session and clean up resources.

**Response:**
```json
{
  "message": "Session ended"
}
```

#### `GET /api/games/:id/state` (Debug Only)
Get current game state as JSON (for debugging).

**Response**: Same as state_update WebSocket message

## Implementation Details

### 1. Game Adapter Pattern

The `GameAdapter` is the key component that bridges the blocking game loop with async WebSocket communication.

**Responsibilities:**
- Run game loop in separate thread
- Provide input queue for WebSocket to push keys
- Capture state updates after each turn
- Notify WebSocket handler via callbacks

**Implementation Sketch:**

```ruby
module Vanilla
  module Web
    class GameAdapter
      attr_reader :session_id, :game

      def initialize(session_id, options = {})
        @session_id = session_id
        @options = options
        @input_queue = Queue.new
        @state_callbacks = []
        @running = false
        @thread = nil
        @logger = Vanilla::Logger.instance
      end

      # Start game in background thread
      def start
        @running = true
        @thread = Thread.new do
          begin
            @game = Vanilla::Game.new(@options.merge(web_mode: true, input_queue: @input_queue))
            @game.start_with_state_callback do |state|
              notify_state_change(state)
            end
          rescue => e
            @logger.error("[GameAdapter] Error in game thread: #{e.message}")
            @running = false
          end
        end
      end

      # Queue input from WebSocket
      def queue_input(key)
        @input_queue << key if @running
      end

      # Register callback for state updates
      def on_state_change(&block)
        @state_callbacks << block
      end

      # Stop game thread
      def stop
        @running = false
        @input_queue << 'q' # Send quit signal
        @thread&.join(2) # Wait up to 2 seconds
        @thread&.kill if @thread&.alive? # Force kill if needed
      end

      # Check if game is still running
      def alive?
        @running && @thread&.alive?
      end

      private

      def notify_state_change(state)
        @state_callbacks.each do |callback|
          callback.call(state)
        rescue => e
          @logger.error("[GameAdapter] Error in state callback: #{e.message}")
        end
      end
    end
  end
end
```

### 2. Modified Input System

The `InputSystem` needs to support both blocking terminal input (current) and non-blocking queue input (web mode).

**Changes to `lib/vanilla/systems/input_system.rb`:**

```ruby
class InputSystem < System
  def initialize(world, input_queue: nil)
    super(world)
    @logger = Vanilla::Logger.instance
    @input_handler = InputHandler.new(world)
    @quit = false
    @input_queue = input_queue # Queue for web mode
  end

  def update(_unused)
    key = if @input_queue
            # Web mode: non-blocking queue read with timeout
            begin
              @input_queue.pop(true) # Non-blocking pop
            rescue ThreadError
              return # No input available, continue to next frame
            end
          else
            # Terminal mode: blocking input
            @world.display.keyboard_handler.wait_for_input
          end

    # Process key...
    @input_handler.handle_input(key)
  end
end
```

### 3. Modified Game Class

The `Game` class needs to support:
- Web mode initialization
- State callbacks after each turn
- Input queue injection

**Changes to `lib/vanilla/game.rb`:**

```ruby
class Game
  def initialize(options = {})
    # Existing initialization...
    @web_mode = options[:web_mode] || false
    @input_queue = options[:input_queue]
    @state_callback = nil

    setup_world
  end

  def start_with_state_callback(&block)
    @state_callback = block
    start
  end

  private

  def setup_world
    # Existing setup...

    # Pass input_queue to InputSystem
    @world.add_system(
      Vanilla::Systems::InputSystem.new(@world, input_queue: @input_queue),
      1
    )

    # Use WebRenderer in web mode
    if @web_mode
      @world.add_system(
        Vanilla::Systems::RenderSystem.new(
          @world,
          @difficulty,
          @seed,
          renderer: Vanilla::Renderers::WebRenderer.new
        ),
        10
      )
    end
  end

  def game_loop
    # After each render, send state via callback if in web mode
    until @world.quit?
      @world.update(nil)
      @turn += 1
      render

      if @web_mode && @state_callback
        state = capture_current_state
        @state_callback.call(state)
      end
    end
  end

  def capture_current_state
    # Get rendered state from WebRenderer
    render_system = @world.systems.find { |s, _| s.is_a?(Vanilla::Systems::RenderSystem) }[0]
    render_system.get_last_state
  end
end
```

### 4. Web Renderer

Creates JSON state instead of terminal output.

```ruby
module Vanilla
  module Renderers
    class WebRenderer < Renderer
      attr_reader :last_state

      def initialize
        @last_state = {}
        @logger = Vanilla::Logger.instance
      end

      def clear
        @last_state = {}
      end

      def draw_grid(grid, algorithm, visibility: nil, dev_mode: nil)
        @last_state[:grid] = serialize_grid(grid, visibility, dev_mode)
        @last_state[:entities] = serialize_entities(grid)
        @last_state[:visibility] = {
          fov_active: visibility && !(dev_mode&.fov_disabled),
          dev_mode: dev_mode&.fov_disabled || false
        }
      end

      def set_game_info(seed:, difficulty:)
        @last_state[:game_info] ||= {}
        @last_state[:game_info][:seed] = seed
        @last_state[:game_info][:difficulty] = difficulty
      end

      def set_player_health(current:, max:)
        @last_state[:player] ||= {}
        @last_state[:player][:health] = { current: current, max: max }
      end

      def present
        # Nothing to do - state is captured in @last_state
      end

      def get_last_state
        @last_state
      end

      private

      def serialize_grid(grid, visibility, dev_mode)
        # Serialize only visible/explored cells to reduce payload
        fov_active = visibility && !(dev_mode&.fov_disabled)

        cells = []
        grid.rows.times do |row|
          grid.columns.times do |col|
            cell = grid[row, col]

            visible = !fov_active || visibility&.tile_visible?(row, col)
            explored = !fov_active || visibility&.tile_explored?(row, col)

            # Only send visible or explored cells
            if visible || explored
              cells << {
                row: row,
                col: col,
                type: cell_type(cell),
                visible: visible,
                explored: explored
              }
            end
          end
        end

        {
          rows: grid.rows,
          cols: grid.columns,
          cells: cells
        }
      end

      def serialize_entities(grid)
        entities = []
        # Extract entities from grid
        # This will be expanded based on actual entity structure
        entities
      end

      def cell_type(cell)
        if cell.north || cell.south || cell.east || cell.west
          'floor'
        else
          'wall'
        end
      end
    end
  end
end
```

### 5. State Serializer

Utility for serializing complete game state to JSON.

```ruby
module Vanilla
  module Web
    class StateSerializer
      def self.serialize(world, renderer_state)
        {
          grid: renderer_state[:grid],
          entities: serialize_entities(world),
          player: serialize_player(world),
          messages: serialize_messages(world),
          game_info: renderer_state[:game_info],
          visibility: renderer_state[:visibility]
        }
      end

      def self.serialize_entities(world)
        world.query_entities([:position, :render]).map do |entity|
          pos = entity.get_component(:position)
          render = entity.get_component(:render)

          {
            id: entity.id,
            char: render.character,
            row: pos.row,
            col: pos.col,
            color: render.color.to_s,
            name: entity.name
          }
        end
      end

      def self.serialize_player(world)
        player = world.find_entity_by_tag(:player)
        return {} unless player

        pos = player.get_component(:position)
        health = player.get_component(:health)

        {
          position: { row: pos.row, col: pos.col },
          health: {
            current: health.current_health,
            max: health.max_health
          }
        }
      end

      def self.serialize_messages(world)
        message_system = Vanilla::ServiceRegistry.get(:message_system)
        message_system&.recent_messages || []
      end
    end
  end
end
```

### 6. Session Manager

Manages multiple concurrent game sessions.

```ruby
module Vanilla
  module Web
    class SessionManager
      def initialize
        @sessions = {}
        @mutex = Mutex.new
        @logger = Vanilla::Logger.instance
        start_cleanup_thread
      end

      def create_session(options = {})
        session_id = SecureRandom.uuid

        @mutex.synchronize do
          adapter = GameAdapter.new(session_id, options)
          @sessions[session_id] = {
            adapter: adapter,
            created_at: Time.now,
            last_activity: Time.now
          }
          adapter.start
          @logger.info("[SessionManager] Created session: #{session_id}")
          session_id
        end
      end

      def get_session(session_id)
        @mutex.synchronize do
          session = @sessions[session_id]
          session[:last_activity] = Time.now if session
          session&.[](:adapter)
        end
      end

      def remove_session(session_id)
        @mutex.synchronize do
          session = @sessions.delete(session_id)
          session[:adapter]&.stop if session
          @logger.info("[SessionManager] Removed session: #{session_id}")
        end
      end

      def active_session_count
        @mutex.synchronize { @sessions.size }
      end

      private

      def start_cleanup_thread
        Thread.new do
          loop do
            sleep(60) # Check every minute
            cleanup_stale_sessions
          end
        end
      end

      def cleanup_stale_sessions
        @mutex.synchronize do
          stale_sessions = @sessions.select do |_id, session|
            # Remove if inactive for 30 minutes or dead
            Time.now - session[:last_activity] > 1800 || !session[:adapter].alive?
          end

          stale_sessions.each do |session_id, _|
            @logger.info("[SessionManager] Cleaning up stale session: #{session_id}")
            remove_session(session_id)
          end
        end
      end
    end
  end
end
```

### 7. WebSocket Handler

Manages WebSocket connections and routes messages.

```ruby
require 'faye/websocket'

module Vanilla
  module Web
    class WebSocketHandler
      def initialize(session_manager)
        @session_manager = session_manager
        @logger = Vanilla::Logger.instance
      end

      def handle_connection(env)
        return unless Faye::WebSocket.websocket?(env)

        ws = Faye::WebSocket.new(env)
        session_id = nil

        ws.on :open do |event|
          # Create new game session
          session_id = @session_manager.create_session
          adapter = @session_manager.get_session(session_id)

          # Send connected message
          ws.send({
            type: 'connected',
            sessionId: session_id,
            message: 'Connected to Vanilla Roguelike'
          }.to_json)

          # Register state update callback
          adapter.on_state_change do |state|
            ws.send({
              type: 'state_update',
              data: state
            }.to_json)
          end

          @logger.info("[WebSocket] Client connected: #{session_id}")
        end

        ws.on :message do |event|
          handle_message(session_id, event.data, ws)
        end

        ws.on :close do |event|
          @session_manager.remove_session(session_id) if session_id
          @logger.info("[WebSocket] Client disconnected: #{session_id}")
        end

        ws.rack_response
      end

      private

      def handle_message(session_id, data, ws)
        message = JSON.parse(data)
        adapter = @session_manager.get_session(session_id)

        unless adapter
          ws.send({ type: 'error', message: 'Invalid session' }.to_json)
          return
        end

        case message['type']
        when 'input'
          adapter.queue_input(message['key'])
        when 'quit'
          adapter.queue_input('q')
          @session_manager.remove_session(session_id)
        else
          @logger.warn("[WebSocket] Unknown message type: #{message['type']}")
        end
      rescue JSON::ParserError => e
        @logger.error("[WebSocket] JSON parse error: #{e.message}")
        ws.send({ type: 'error', message: 'Invalid JSON' }.to_json)
      end
    end
  end
end
```

### 8. Sinatra Web Server

Main web application server.

```ruby
require 'sinatra/base'
require 'json'

module Vanilla
  module Web
    class Server < Sinatra::Base
      configure do
        set :public_folder, File.expand_path('../../../public', __dir__)
        set :bind, '0.0.0.0'
        set :port, 4567
        set :server, 'puma'
      end

      def initialize(app = nil)
        super(app)
        @session_manager = SessionManager.new
        @ws_handler = WebSocketHandler.new(@session_manager)
      end

      # Serve main game client
      get '/' do
        send_file File.join(settings.public_folder, 'index.html')
      end

      # WebSocket endpoint
      get '/ws' do
        @ws_handler.handle_connection(request.env)
      end

      # REST API endpoints
      post '/api/games' do
        content_type :json

        data = JSON.parse(request.body.read)
        session_id = @session_manager.create_session(data.transform_keys(&:to_sym))

        {
          sessionId: session_id,
          wsUrl: "ws://#{request.host}:#{request.port}/ws"
        }.to_json
      end

      delete '/api/games/:id' do
        content_type :json
        @session_manager.remove_session(params[:id])
        { message: 'Session ended' }.to_json
      end

      get '/api/games/:id/state' do
        content_type :json

        adapter = @session_manager.get_session(params[:id])
        if adapter && adapter.game
          state = capture_game_state(adapter.game)
          state.to_json
        else
          status 404
          { error: 'Session not found' }.to_json
        end
      end

      # Health check
      get '/health' do
        content_type :json
        {
          status: 'ok',
          active_sessions: @session_manager.active_session_count
        }.to_json
      end

      private

      def capture_game_state(game)
        # Capture current game state for debugging
        {}
      end
    end
  end
end
```

## Dependencies

### Gemfile Additions

```ruby
# Web server and framework
gem 'sinatra', '~> 3.0'
gem 'puma', '~> 6.0'

# WebSocket support
gem 'faye-websocket', '~> 0.11'

# Fast JSON serialization
gem 'oj', '~> 3.16'

# Async operations (if needed)
gem 'async', '~> 2.0'
```

## Client Implementation

### HTML Structure

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Vanilla Roguelike</title>
  <link rel="stylesheet" href="/css/style.css">
</head>
<body>
  <div id="game-container">
    <div id="game-header">
      <h1>Vanilla Roguelike</h1>
      <div id="game-info"></div>
    </div>

    <div id="game-stats">
      <div id="player-health"></div>
      <div id="player-level"></div>
    </div>

    <canvas id="game-canvas" width="800" height="600"></canvas>

    <div id="message-log"></div>

    <div id="connection-status">Connecting...</div>
  </div>

  <script src="/js/renderer.js"></script>
  <script src="/js/input-handler.js"></script>
  <script src="/js/websocket-client.js"></script>
  <script src="/js/game.js"></script>
</body>
</html>
```

### JavaScript Client Structure

**game.js** - Main orchestrator:
```javascript
class VanillaGame {
  constructor() {
    this.ws = new WebSocketClient();
    this.renderer = new GameRenderer('game-canvas');
    this.input = new InputHandler();

    this.init();
  }

  init() {
    // Connect WebSocket
    this.ws.connect();

    // Handle state updates
    this.ws.on('state_update', (data) => {
      this.renderer.render(data);
      this.updateUI(data);
    });

    // Handle input
    this.input.on('keypress', (key) => {
      this.ws.sendInput(key);
    });

    // Handle connection status
    this.ws.on('connected', (data) => {
      this.showStatus('Connected!');
    });

    this.ws.on('disconnected', () => {
      this.showStatus('Disconnected');
    });
  }

  updateUI(state) {
    // Update health, level, messages
    document.getElementById('player-health').textContent =
      `HP: ${state.player.health.current}/${state.player.health.max}`;
    document.getElementById('player-level').textContent =
      `Level: ${state.gameInfo.difficulty}`;

    // Update message log
    const log = document.getElementById('message-log');
    log.innerHTML = state.messages.map(m => `<div>${m}</div>`).join('');
  }

  showStatus(message) {
    document.getElementById('connection-status').textContent = message;
  }
}

// Start game when page loads
window.addEventListener('DOMContentLoaded', () => {
  new VanillaGame();
});
```

**websocket-client.js** - WebSocket communication:
```javascript
class WebSocketClient {
  constructor() {
    this.ws = null;
    this.callbacks = {};
    this.sessionId = null;
  }

  connect() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const url = `${protocol}//${window.location.host}/ws`;

    this.ws = new WebSocket(url);

    this.ws.onopen = () => {
      console.log('WebSocket connected');
    };

    this.ws.onmessage = (event) => {
      const message = JSON.parse(event.data);
      this.handleMessage(message);
    };

    this.ws.onclose = () => {
      console.log('WebSocket disconnected');
      this.emit('disconnected');
    };

    this.ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  }

  handleMessage(message) {
    switch (message.type) {
      case 'connected':
        this.sessionId = message.sessionId;
        this.emit('connected', message);
        break;
      case 'state_update':
        this.emit('state_update', message.data);
        break;
      case 'error':
        console.error('Server error:', message.message);
        break;
      case 'game_over':
        this.emit('game_over', message);
        break;
    }
  }

  sendInput(key) {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify({
        type: 'input',
        key: key,
        timestamp: Date.now()
      }));
    }
  }

  on(event, callback) {
    if (!this.callbacks[event]) {
      this.callbacks[event] = [];
    }
    this.callbacks[event].push(callback);
  }

  emit(event, data) {
    if (this.callbacks[event]) {
      this.callbacks[event].forEach(cb => cb(data));
    }
  }
}
```

**renderer.js** - Canvas rendering:
```javascript
class GameRenderer {
  constructor(canvasId) {
    this.canvas = document.getElementById(canvasId);
    this.ctx = this.canvas.getContext('2d');
    this.cellSize = 20;
    this.colors = {
      wall: '#666',
      floor: '#222',
      unexplored: '#000',
      explored_dim: '#333',
      yellow: '#FFD700',
      green: '#00FF00',
      red: '#FF0000',
      white: '#FFFFFF'
    };
  }

  render(state) {
    this.clear();
    this.renderGrid(state.grid, state.visibility);
    this.renderEntities(state.entities, state.visibility);
  }

  clear() {
    this.ctx.fillStyle = '#000';
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
  }

  renderGrid(grid, visibility) {
    grid.cells.forEach(cell => {
      const x = cell.col * this.cellSize;
      const y = cell.row * this.cellSize;

      if (cell.visible) {
        // Fully visible
        this.ctx.fillStyle = this.colors[cell.type];
      } else if (cell.explored) {
        // Explored but not visible (dimmed)
        this.ctx.fillStyle = this.colors.explored_dim;
      } else {
        // Unexplored
        return;
      }

      this.ctx.fillRect(x, y, this.cellSize, this.cellSize);
    });
  }

  renderEntities(entities, visibility) {
    // Only render entities in visible cells
    entities.forEach(entity => {
      // Check if entity position is visible
      const x = entity.col * this.cellSize;
      const y = entity.row * this.cellSize;

      this.ctx.fillStyle = this.colors[entity.color] || this.colors.white;
      this.ctx.font = `${this.cellSize}px monospace`;
      this.ctx.fillText(entity.char, x, y + this.cellSize);
    });
  }
}
```

**input-handler.js** - Keyboard input:
```javascript
class InputHandler {
  constructor() {
    this.callbacks = {};
    this.keyMap = {
      'h': 'h',
      'j': 'j',
      'k': 'k',
      'l': 'l',
      'ArrowLeft': 'h',
      'ArrowDown': 'j',
      'ArrowUp': 'k',
      'ArrowRight': 'l',
      'q': 'q',
      'i': 'i',
      'm': 'm'
    };

    this.init();
  }

  init() {
    document.addEventListener('keydown', (e) => {
      const key = this.keyMap[e.key];
      if (key) {
        e.preventDefault();
        this.emit('keypress', key);
      }
    });
  }

  on(event, callback) {
    if (!this.callbacks[event]) {
      this.callbacks[event] = [];
    }
    this.callbacks[event].push(callback);
  }

  emit(event, data) {
    if (this.callbacks[event]) {
      this.callbacks[event].forEach(cb => cb(data));
    }
  }
}
```

## Testing Strategy

### Unit Tests

1. **State Serializer Tests**
   ```ruby
   describe Vanilla::Web::StateSerializer do
     it 'serializes game state to JSON'
     it 'includes grid, entities, player, messages'
     it 'handles visibility/FOV correctly'
     it 'optimizes payload size'
   end
   ```

2. **Session Manager Tests**
   ```ruby
   describe Vanilla::Web::SessionManager do
     it 'creates new sessions with unique IDs'
     it 'retrieves existing sessions'
     it 'removes sessions on request'
     it 'cleans up stale sessions'
     it 'handles concurrent access safely'
   end
   ```

3. **Game Adapter Tests**
   ```ruby
   describe Vanilla::Web::GameAdapter do
     it 'starts game in background thread'
     it 'queues input from WebSocket'
     it 'notifies callbacks on state change'
     it 'stops cleanly on shutdown'
   end
   ```

### Integration Tests

1. **WebSocket Communication**
   ```ruby
   describe 'WebSocket Game Session' do
     it 'establishes WebSocket connection'
     it 'creates game session on connect'
     it 'sends state updates after input'
     it 'cleans up session on disconnect'
   end
   ```

2. **Full Game Flow**
   ```ruby
   describe 'Complete Game Flow' do
     it 'connects client to server'
     it 'receives initial game state'
     it 'sends movement command'
     it 'receives updated game state'
     it 'handles game over'
   end
   ```

### End-to-End Tests

Using Selenium or Puppeteer:
- Load game in browser
- Verify WebSocket connection
- Send keyboard input
- Verify game state updates
- Test multiple concurrent sessions

## Implementation Phases

### Phase 1: Core Infrastructure (3-5 days)

**Tasks:**
- [ ] Add web framework dependencies to Gemfile
- [ ] Create basic Sinatra application structure
- [ ] Implement WebSocket endpoint with Faye
- [ ] Create SessionManager with thread safety
- [ ] Basic StateSerializer implementation

**Deliverables:**
- Working web server
- WebSocket connection established
- Basic session management

### Phase 2: Game Adapter (3-4 days)

**Tasks:**
- [ ] Create GameAdapter class
- [ ] Modify InputSystem to support input queue
- [ ] Add web mode to Game class
- [ ] Implement state callbacks
- [ ] Create WebRenderer for JSON output

**Deliverables:**
- Game runs in background thread
- Input queue working
- State updates captured

### Phase 3: Client Implementation (4-6 days)

**Tasks:**
- [ ] Create HTML game client structure
- [ ] Implement WebSocket client JavaScript
- [ ] Build Canvas-based renderer
- [ ] Create input handler
- [ ] Style game UI with CSS

**Deliverables:**
- Functional web client
- Game playable in browser
- Keyboard input working

### Phase 4: Integration & Testing (3-4 days)

**Tasks:**
- [ ] Write unit tests for all components
- [ ] Integration tests for WebSocket flow
- [ ] Test concurrent sessions
- [ ] Performance testing and optimization
- [ ] Memory leak detection and fixes

**Deliverables:**
- Comprehensive test suite
- Performance benchmarks
- Bug fixes

### Phase 5: Polish & Deployment (2-3 days)

**Tasks:**
- [ ] Error handling and reconnection logic
- [ ] Session timeout configuration
- [ ] Deployment documentation
- [ ] Production configuration (environment variables)
- [ ] Docker container (optional)

**Deliverables:**
- Production-ready code
- Deployment guide
- Configuration documentation

**Total Estimated Time: 15-22 days**

## Benefits

### For Players

✅ **No Terminal Setup Required**: Play directly in browser without installing Ruby or dependencies

✅ **Cross-Platform**: Works on any device with a modern web browser (desktop, mobile, tablet)

✅ **Shareable**: Can send link to friends to play

✅ **Lower Barrier to Entry**: More accessible to casual players unfamiliar with terminals

✅ **Game Persistence**: Foundation for save/load functionality

### For Development

✅ **No Code Rewrite**: All game logic remains in Ruby - zero porting effort

✅ **Server Authority**: Server-side state prevents cheating and ensures consistency

✅ **Single Source of Truth**: Game state managed entirely on server

✅ **Easy Spectator Mode**: Foundation for watching other players

✅ **Multiplayer Ready**: Architecture supports future multiplayer features

✅ **Analytics**: Can track player behavior, popular strategies, common death causes

## Challenges & Risks

### Technical Challenges

⚠️ **Memory Usage**: Each game session requires full Game instance (ECS, World, all Systems)
- **Mitigation**: Session timeouts, maximum concurrent session limit, memory monitoring

⚠️ **WebSocket Connection Management**: Handling disconnects, reconnects, network issues
- **Mitigation**: Heartbeat mechanism, automatic reconnection, connection status UI

⚠️ **State Serialization Overhead**: Converting Ruby objects to JSON every turn
- **Mitigation**: Optimize serialization, only send changed data (delta updates), use fast JSON library (oj)

⚠️ **Network Latency**: Turn-based game tolerates latency better than real-time, but still noticeable
- **Mitigation**: Optimize payload size, compression, client-side prediction (optimistic UI updates)

⚠️ **Concurrent Game Instances**: Thread safety, shared resources
- **Mitigation**: Thread-safe SessionManager, each game isolated in own thread

### Operational Challenges

⚠️ **Server Hosting**: Need VPS or cloud hosting with sufficient RAM
- **Mitigation**: Start with modest server, scale as needed, implement session limits

⚠️ **Session Cleanup**: Abandoned sessions waste memory
- **Mitigation**: Automatic timeout (30 min inactivity), health check endpoint, monitoring

⚠️ **Debugging Web Sessions**: Harder to debug than terminal
- **Mitigation**: Comprehensive logging, debug API endpoint for state inspection, error reporting

⚠️ **Security**: Rate limiting, DoS prevention, input validation
- **Mitigation**: Rate limit connections, validate all input server-side, use established frameworks

## Alternatives Considered

### Option A: REST API Only (No WebSocket)

**Approach**: HTTP polling for state updates

**Pros**:
- Simpler implementation
- Stateless server design
- Standard HTTP caching

**Cons**:
- Higher latency (polling delay)
- More bandwidth (repeated full state)
- Worse user experience

**Verdict**: ❌ Not recommended - WebSocket provides much better experience for turn-based game

### Option B: Complete JavaScript Rewrite

**Approach**: Port all Ruby code to JavaScript, run entirely client-side

**Pros**:
- No server required
- Works offline
- Zero latency
- Easier hosting (static files)

**Cons**:
- Massive rewrite effort (weeks/months)
- Two codebases to maintain
- Features diverge over time
- Cheating possible (client-side code)

**Verdict**: ❌ Not recommended - Against project goal of keeping Ruby implementation

### Option C: Hybrid (Some Logic Client-Side)

**Approach**: Move some systems (rendering, pathfinding) to client

**Pros**:
- Reduced server load
- Faster client responsiveness
- Better for some types of features

**Cons**:
- Logic duplication
- Synchronization complexity
- Still requires JavaScript port of some code

**Verdict**: ❌ Not recommended for v1 - Can consider for optimizations later

## Future Enhancements

Once the basic web version is working, these features become possible:

### 1. Game Persistence
- Save game state to database (Redis, PostgreSQL)
- Resume game from any device
- Save multiple game slots

### 2. Replay System
- Record all turns and player actions
- Watch previous games
- Share replays with others
- Learn from good players

### 3. Spectator Mode
- Watch live games in progress
- Multiple spectators per game
- Spectator chat

### 4. Leaderboards
- Track high scores
- Compare with friends
- Global rankings
- Weekly challenges

### 5. Multiplayer
- Cooperative mode (2 players, same dungeon)
- Competitive mode (race to stairs)
- Asynchronous turns
- Shared dungeon exploration

### 6. Mobile Optimization
- Touch controls (swipe to move)
- Responsive design
- Progressive Web App (install to home screen)
- Mobile-friendly UI

### 7. Tile Graphics
- Replace ASCII with sprite-based graphics
- Multiple tilesets
- Animations
- Particle effects

### 8. Social Features
- Friend list
- Challenge friends
- Share achievements
- Tournament mode

## Security Considerations

### Input Validation
- Validate all keyboard input on server
- Reject invalid commands
- Rate limit input frequency

### Authentication (Future)
- Optional user accounts
- OAuth integration
- Guest mode (current default)

### Rate Limiting
- Limit WebSocket connections per IP
- Throttle message frequency
- Prevent DoS attacks

### Data Validation
- Validate all JSON messages
- Reject malformed data
- Log suspicious activity

## Performance Considerations

### Server-Side Optimization

**Memory Management:**
- Session timeout: 30 minutes inactivity
- Maximum concurrent sessions: 100 (configurable)
- Memory monitoring and alerting

**CPU Usage:**
- Each game runs in separate thread
- Thread pool limits
- Monitor CPU per session

**Serialization:**
- Use fast JSON library (oj gem)
- Only serialize visible data
- Compress WebSocket messages (gzip)

### Client-Side Optimization

**Rendering:**
- Canvas rendering for performance
- Only redraw changed cells (dirty rectangles)
- RequestAnimationFrame for smooth rendering

**Network:**
- Minimize payload size
- Delta updates (only send changes)
- Client-side prediction for responsiveness

### Benchmarks

Target performance metrics:
- Serialization: < 10ms per turn
- WebSocket send: < 5ms
- Total turn latency: < 50ms
- Memory per session: < 50MB
- Concurrent sessions: 100+

## Deployment Guide

### Development Setup

```bash
# Install dependencies
bundle install

# Run web server
ruby bin/web_server.rb

# Access game
open http://localhost:4567
```

### Production Deployment

**Requirements:**
- Ruby 3.4.1+
- Linux VPS (2GB RAM minimum)
- Nginx (reverse proxy)
- SSL certificate (Let's Encrypt)

**Configuration:**

```yaml
# config/production.yml
server:
  host: 0.0.0.0
  port: 4567
  threads: 5

session:
  max_concurrent: 100
  timeout_minutes: 30

logging:
  level: info
  file: /var/log/vanilla/web.log
```

**Nginx Config:**

```nginx
upstream vanilla_backend {
  server 127.0.0.1:4567;
}

server {
  listen 80;
  server_name vanilla.example.com;
  return 301 https://$server_name$request_uri;
}

server {
  listen 443 ssl http2;
  server_name vanilla.example.com;

  ssl_certificate /etc/letsencrypt/live/vanilla.example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/vanilla.example.com/privkey.pem;

  location / {
    proxy_pass http://vanilla_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

**Systemd Service:**

```ini
[Unit]
Description=Vanilla Roguelike Web Server
After=network.target

[Service]
Type=simple
User=vanilla
WorkingDirectory=/opt/vanilla
ExecStart=/usr/local/bin/ruby bin/web_server.rb
Restart=always
Environment="RACK_ENV=production"

[Install]
WantedBy=multi-user.target
```

## Monitoring

### Health Checks

```ruby
# GET /health
{
  "status": "ok",
  "active_sessions": 42,
  "uptime": 86400,
  "memory_mb": 1024
}
```

### Metrics to Track

- Active sessions count
- Average session duration
- Memory usage per session
- WebSocket connection errors
- Turn processing time
- Serialization time

### Logging

Log important events:
- Session creation/destruction
- WebSocket connections/disconnections
- Errors and exceptions
- Performance metrics

## Recommendation

### ✅ **RECOMMENDED for Implementation**

**Rationale:**

1. **Leverages Existing Architecture**: No rewrite needed - all Ruby code reused
2. **Server-Side Security**: Game state controlled by server, prevents cheating
3. **Good User Experience**: WebSocket provides responsive real-time feel
4. **Low Barrier to Entry**: Browser-based play opens game to wider audience
5. **Foundation for Growth**: Enables persistence, spectator mode, multiplayer
6. **Manageable Complexity**: Clear architecture with well-defined components
7. **Proven Technology**: Sinatra + WebSocket is battle-tested stack

**Key Success Factors:**

1. Proper session management with timeout cleanup
2. Efficient state serialization (< 10ms per turn)
3. Smooth adaptation of blocking game loop to async
4. Responsive client rendering with Canvas
5. Robust error handling and reconnection logic
6. Comprehensive testing at all levels

**Risks**: Manageable with proposed mitigations

**Timeline**: 15-22 days for full implementation

**Conclusion**: This proposal provides a clear path to web-based gameplay while preserving the existing Ruby implementation and creating a foundation for future enhancements.

## References

- [Faye WebSocket Ruby](https://github.com/faye/faye-websocket-ruby) - WebSocket server implementation
- [Sinatra Documentation](https://sinatrarb.com/) - Lightweight Ruby web framework
- [WebSocket Protocol RFC 6455](https://tools.ietf.org/html/rfc6455) - WebSocket standard
- [Canvas API (MDN)](https://developer.mozilla.org/en-US/docs/Web/API/Canvas_API) - HTML5 Canvas rendering
- [Puma Web Server](https://puma.io/) - Ruby application server
- [OJ Gem](https://github.com/ohler55/oj) - Fast JSON serialization

## Next Steps

1. **Review & Discuss**: Present proposal to team/stakeholders for feedback
2. **Prototype**: Build minimal proof of concept (WebSocket + basic state update)
3. **Validate Approach**: Test with simple game session in browser (2-3 days)
4. **Decision Point**: Proceed with full implementation or iterate on design
5. **Phase 1**: Begin core infrastructure implementation

## Appendix: Code Examples

### Example: Complete Game Session Flow

```
1. Client loads http://localhost:4567
2. Browser connects to ws://localhost:4567/ws
3. Server creates new session (UUID: abc-123)
4. Server starts GameAdapter in background thread
5. GameAdapter initializes Game with input queue
6. Game generates initial maze
7. Server sends initial state to client via WebSocket
8. Client renders game state on Canvas
9. Player presses 'h' key
10. Client sends {"type":"input","key":"h"} via WebSocket
11. Server queues 'h' in GameAdapter input queue
12. Game loop reads from queue, processes movement
13. Game state updates (player moves left)
14. WebRenderer captures new state as JSON
15. GameAdapter calls state callback
16. Server sends state update via WebSocket
17. Client receives update, re-renders Canvas
18. Loop continues from step 9...
```

This flow demonstrates the complete cycle from user input to rendered output, showing how all components interact.

