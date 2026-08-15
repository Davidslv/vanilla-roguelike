# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Systems::MonsterSystem do
  let(:world) { instance_double(Vanilla::World, subscribe: nil) }
  let(:player) { Vanilla::EntityFactory.create_player(0, 0) }
  let(:system) { described_class.new(world, player: player) }

  # These draws must come from the global srand-pinned RNG (the determinism
  # tripwire spec relies on it), so the examples pin the seed and restore it.
  around do |example|
    previous = srand(20_260_815)
    example.run
    srand(previous)
  end

  describe '#select_weighted_monster_type' do
    let(:types) { { 'goblin' => 0.4, 'orc' => 0.3, 'troll' => 0.2, 'ogre' => 0.1 } }

    # Guards the roll spanning the whole weighted table. Kernel#rand truncates
    # a Float max to an Integer (rand(1.0) is always 0), so a naive port of
    # Random#rand(total) silently collapses every spawn to the first type.
    it 'draws every type from the weighted table over many rolls' do
      drawn = Array.new(300) { system.send(:select_weighted_monster_type, types) }.uniq

      expect(drawn).to match_array(types.keys)
    end
  end

  describe '#determine_monster_count' do
    it 'stays within the level bounds' do
      counts = Array.new(50) { system.send(:determine_monster_count, 2) }.uniq.sort

      expect(counts).to all(be_between(2, 4))
      expect(counts.size).to be > 1
    end
  end
end
