require 'spec_helper'

RSpec.describe Vanilla::Systems::RenderSystemFactory do
  describe '.create' do
    it 'creates a RenderSystem with a TerminalRenderer' do
      # Mock the TerminalRenderer to avoid actual terminal operations
      terminal_renderer = instance_double('Vanilla::Renderers::TerminalRenderer')
      allow(Vanilla::Renderers::TerminalRenderer).to receive(:new).and_return(terminal_renderer)

      render_system = described_class.create

      expect(render_system).to be_a(Vanilla::Systems::RenderSystem)
      expect(render_system.instance_variable_get(:@renderer)).to eq(terminal_renderer)
    end

    it 'returns a valid RenderSystem instance' do
      # This test allows the real TerminalRenderer to be created
      # but doesn't test its actual rendering methods
      render_system = described_class.create

      expect(render_system).to be_a(Vanilla::Systems::RenderSystem)
      expect(render_system.instance_variable_get(:@renderer)).to be_a(Vanilla::Renderers::TerminalRenderer)
    end
  end
end
