# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Messages::DeathMessage do
  describe '.for' do
    it 'names the killer for a combat death' do
      expect(described_class.for(cause: :combat, killer_name: 'Troll')).to eq(['death.player_dies', { enemy: 'Troll' }])
    end

    it 'says "enemy" when a combat death has no killer name' do
      expect(described_class.for(cause: :combat, killer_name: nil)).to eq(['death.player_dies', { enemy: 'enemy' }])
    end

    it 'uses the starvation message' do
      expect(described_class.for(cause: :starvation)).to eq(['death.starvation', {}])
    end

    it 'falls back to the generic message' do
      expect(described_class.for(cause: :mystery)).to eq(['death.generic_death', {}])
    end
  end
end
