# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::RenderSystem do
  let(:renderer) { instance_double('Vanilla::Renderers::Renderer') }
  let(:grid) { instance_double('Vanilla::MapUtils::Grid') }
  let(:system) { described_class.new(renderer) }

  before do
    # Allow TileType validation to pass for test characters
    allow(Vanilla::Support::TileType).to receive(:valid?).and_return(true)
  end

  describe '#render' do
    it 'draws entities with position and render components' do
      # Setup test entities
      entity1 = Vanilla::Entities::Entity.new
      entity1.add_component(Vanilla::Components::PositionComponent.new(row: 1, column: 2))
      entity1.add_component(Vanilla::Components::RenderComponent.new(character: '@', layer: 1))

      entity2 = Vanilla::Entities::Entity.new
      entity2.add_component(Vanilla::Components::PositionComponent.new(row: 3, column: 4))
      entity2.add_component(Vanilla::Components::RenderComponent.new(character: 'M', layer: 0))

      entity3 = Vanilla::Entities::Entity.new # No render component
      entity3.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 6))

      # Expectations
      expect(renderer).to receive(:clear)
      expect(renderer).to receive(:draw_grid).with(grid)

      # Entity2 should be drawn first due to lower layer value
      expect(renderer).to receive(:draw_character).with(3, 4, 'M', nil).ordered
      expect(renderer).to receive(:draw_character).with(1, 2, '@', nil).ordered

      expect(renderer).to receive(:present)

      # Execute
      system.render([entity1, entity2, entity3], grid)
    end

    it 'skips entities without position or render components' do
      # Entity without position
      entity1 = Vanilla::Entities::Entity.new
      entity1.add_component(Vanilla::Components::RenderComponent.new(character: '@', layer: 1))

      # Entity without render
      entity2 = Vanilla::Entities::Entity.new
      entity2.add_component(Vanilla::Components::PositionComponent.new(row: 3, column: 4))

      # Complete entity
      entity3 = Vanilla::Entities::Entity.new
      entity3.add_component(Vanilla::Components::PositionComponent.new(row: 5, column: 6))
      entity3.add_component(Vanilla::Components::RenderComponent.new(character: '%', layer: 0)) # Stairs

      # Expectations
      expect(renderer).to receive(:clear)
      expect(renderer).to receive(:draw_grid).with(grid)

      # Only entity3 should be drawn
      expect(renderer).to receive(:draw_character).with(5, 6, '>', nil)

      expect(renderer).to receive(:present)

      # Execute
      system.render([entity1, entity2, entity3], grid)
    end

    it 'draws nothing with no drawable entities' do
      # Expectations
      expect(renderer).to receive(:clear)
      expect(renderer).to receive(:draw_grid).with(grid)
      expect(renderer).to receive(:present)

      # No draw_character calls expected

      # Execute
      system.render([], grid)
    end
  end
end
