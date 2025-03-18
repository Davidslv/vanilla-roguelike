require 'spec_helper'

RSpec.describe Vanilla::Entities::Stairs do
  let(:row) { 7 }
  let(:column) { 12 }
  let(:stairs) { described_class.new(row: row, column: column) }

  describe '#initialize' do
    it 'is an entity' do
      expect(stairs).to be_a(Vanilla::Components::Entity)
    end

    it 'adds a position component with the correct coordinates' do
      expect(stairs).to have_component(:position)

      position = stairs.get_component(:position)
      expect(position.row).to eq(row)
      expect(position.column).to eq(column)
    end

    it 'adds a render component with the stairs character' do
      expect(stairs).to have_component(:render)

      render_component = stairs.get_component(:render)
      expect(render_component.character).to eq(Vanilla::Support::TileType::STAIRS)
    end

    it 'sets the render component to the appropriate layer' do
      render_component = stairs.get_component(:render)
      expect(render_component.layer).to eq(2) # Layer 2 as specified in the class
    end
  end

  describe 'component delegation' do
    it 'delegates position methods' do
      expect(stairs.coordinates).to eq([row, column])

      stairs.move_to(8, 15)
      expect(stairs.row).to eq(8)
      expect(stairs.column).to eq(15)
    end

    it 'delegates rendering methods' do
      expect(stairs.tile).to eq(Vanilla::Support::TileType::STAIRS)
    end
  end
end