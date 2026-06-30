# frozen_string_literal: true

require 'webrick'
require 'json'
require_relative 'web_game'
require_relative 'web_renderer'

module Vanilla
  module Web
    # A tiny, dependency-free (Ruby stdlib WEBrick) game server.
    #
    # Architecture: server-authoritative. ALL game logic stays in Ruby; the
    # browser is a thin client that POSTs a keypress and draws the frame it
    # gets back. We chose plain HTTP (POST-a-key / GET-a-frame) over WebSockets
    # because the game is strictly turn-based — one keypress produces exactly
    # one frame — so a request/response cycle is a perfect, robust fit and adds
    # zero native dependencies.
    #
    # Endpoints:
    #   GET  /            -> index.html (the client)
    #   GET  /state       -> current frame JSON (also used to (re)start a game)
    #   POST /input       -> { "key": "l" } : steps the game, returns new frame
    #   POST /new         -> { "seed": 123, "difficulty": 1 } : fresh game
    class Server
      WEB_DIR = File.expand_path(__dir__)

      def initialize(port: 4567, host: '127.0.0.1')
        @port = port
        @host = host
        @mutex = Mutex.new
        new_game
      end

      def start
        server = WEBrick::HTTPServer.new(
          BindAddress: @host,
          Port: @port,
          Logger: WEBrick::Log.new(File::NULL),
          AccessLog: []
        )

        server.mount_proc('/') { |req, res| route(req, res) }

        trap('INT')  { server.shutdown }
        trap('TERM') { server.shutdown }

        warn "Vanilla Roguelike (web) listening on http://#{@host}:#{@port}"
        warn "Seed: #{@game.seed}  Difficulty: #{@game.difficulty}"
        server.start
      end

      private

      def new_game(seed: nil, difficulty: 1)
        @game = WebGame.new(seed: seed, difficulty: difficulty).start
        @renderer = WebRenderer.new(@game.world, seed: @game.seed, difficulty: @game.difficulty)
      end

      def route(req, res)
        case [req.request_method, req.path]
        when ['GET', '/']       then serve_file(res, 'index.html', 'text/html')
        when ['GET', '/state']  then json(res, frame)
        when ['POST', '/input'] then handle_input(req, res)
        when ['POST', '/new']   then handle_new(req, res)
        else
          res.status = 404
          res.body = 'Not found'
        end
      rescue StandardError => e
        res.status = 500
        res['Content-Type'] = 'application/json'
        res.body = JSON.generate(error: e.message, backtrace: e.backtrace&.first(5))
      end

      def handle_input(req, res)
        body = parse_body(req)
        key = body['key'].to_s
        @mutex.synchronize { @game.handle_key(key) unless key.empty? }
        json(res, frame)
      end

      def handle_new(req, res)
        body = parse_body(req)
        seed = body['seed']
        seed = seed.to_i if seed.is_a?(String) && !seed.empty?
        difficulty = (body['difficulty'] || 1).to_i
        @mutex.synchronize { new_game(seed: seed, difficulty: difficulty) }
        json(res, frame)
      end

      def frame
        @mutex.synchronize { @renderer.frame.merge(turn: @game.turn, quit: @game.quit?) }
      end

      def parse_body(req)
        return {} if req.body.nil? || req.body.empty?

        JSON.parse(req.body)
      rescue JSON::ParserError
        {}
      end

      def json(res, hash)
        res['Content-Type'] = 'application/json'
        res['Cache-Control'] = 'no-store'
        res.body = JSON.generate(hash)
      end

      def serve_file(res, name, content_type)
        path = File.join(WEB_DIR, name)
        res['Content-Type'] = content_type
        res.body = File.read(path)
      end
    end
  end
end
