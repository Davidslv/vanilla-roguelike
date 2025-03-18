module Vanilla
  module Systems
    class RenderSystemFactory
      def self.create
        renderer = Vanilla::Renderers::TerminalRenderer.new
        RenderSystem.new(renderer)
      end
    end
  end
end