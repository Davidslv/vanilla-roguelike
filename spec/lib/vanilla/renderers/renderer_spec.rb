require 'spec_helper'

RSpec.describe Vanilla::Renderers::Renderer do
  let(:renderer) { described_class.new }

  describe 'abstract methods' do
    it 'raises NotImplementedError for #clear' do
      expect { renderer.clear }.to raise_error(NotImplementedError, "Renderers must implement #clear")
    end

    it 'raises NotImplementedError for #draw_grid' do
      grid = double('grid')
      expect { renderer.draw_grid(grid) }.to raise_error(NotImplementedError, "Renderers must implement #draw_grid")
    end

    it 'raises NotImplementedError for #draw_character' do
      expect { renderer.draw_character(0, 0, '@') }.to raise_error(NotImplementedError, "Renderers must implement #draw_character")
    end

    it 'raises NotImplementedError for #present' do
      expect { renderer.present }.to raise_error(NotImplementedError, "Renderers must implement #present")
    end
  end
end
