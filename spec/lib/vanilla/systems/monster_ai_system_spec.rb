# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::MonsterAISystem do
  let(:world) { instance_double('Vanilla::World') }
  let(:system) { described_class.new(world) }
  let(:movement_system) { instance_double('Vanilla::Systems::MovementSystem') }

  # A straight 1x5 corridor with every cell linked to its eastern neighbour:
  # (0,0)-(0,1)-(0,2)-(0,3)-(0,4)
  let(:grid) do
    Vanilla::MapUtils::Grid.new(1, 5).tap do |g|
      (0..3).each { |col| g[0, col].link(cell: g[0, col + 1], bidirectional: true) }
    end
  end

  # Player sits at the east end of the corridor.
  let(:player) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_tag(:player)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 0, column: 4))
      e.add_component(Vanilla::Components::FactionComponent.new(faction_id: Vanilla::Factions::HERO, hostile_to: [Vanilla::Factions::MONSTER]))
    end
  end

  # Each context overrides these to position the monster and shape what it sees.
  let(:monster_column) { 0 }
  let(:monster_hostile) { true }
  let(:monster_sees) { [[0, 4]] } # tiles currently visible to the monster
  let(:monster) do
    Vanilla::Entities::Entity.new.tap do |e|
      e.add_tag(:monster)
      e.add_component(Vanilla::Components::PositionComponent.new(row: 0, column: monster_column))
      e.add_component(Vanilla::Components::MovementComponent.new(active: true))
      hostile_to = monster_hostile ? [Vanilla::Factions::HERO] : []
      e.add_component(Vanilla::Components::FactionComponent.new(faction_id: Vanilla::Factions::MONSTER, hostile_to: hostile_to))
      visibility = Vanilla::Components::VisibilityComponent.new(vision_radius: 5)
      monster_sees.each { |(row, col)| visibility.add_visible_tile(row, col) }
      e.add_component(visibility)
    end
  end

  let(:player_present) { true }

  before do
    allow(world).to receive(:find_entity_by_tag).with(:player).and_return(player_present ? player : nil)
    allow(world).to receive_messages(grid: grid, query_entities: [monster], systems: [[movement_system, 2]])
    allow(movement_system).to receive(:is_a?).with(Vanilla::Systems::MovementSystem).and_return(true)
    allow(movement_system).to receive(:move)
  end

  describe '#update' do
    context 'when a hostile player is visible' do
      it 'steps one cell toward the player' do
        system.update(nil)
        # From (0,0) the only lower-distance neighbour is (0,1), which lies east.
        expect(movement_system).to have_received(:move).with(monster, :east)
      end
    end

    context 'when the monster is adjacent to the player' do
      let(:monster_column) { 3 }

      it 'steps onto the player\'s cell (which triggers the combat collision)' do
        system.update(nil)
        expect(movement_system).to have_received(:move).with(monster, :east)
      end
    end

    context 'when the monster cannot see the player' do
      let(:monster_sees) { [] }

      it 'does not move' do
        system.update(nil)
        expect(movement_system).not_to have_received(:move)
      end
    end

    context 'when the target is not hostile to the monster' do
      let(:monster_hostile) { false }

      it 'does not move' do
        system.update(nil)
        expect(movement_system).not_to have_received(:move)
      end
    end

    context 'when there is no player' do
      let(:player_present) { false }

      it 'does nothing' do
        system.update(nil)
        expect(movement_system).not_to have_received(:move)
      end
    end
  end
end
