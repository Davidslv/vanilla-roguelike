# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vanilla::Hunger do
  describe '.status' do
    {
      200 => :ok, 51 => :ok,
      50 => :hungry, 21 => :hungry,
      20 => :weak, 1 => :weak,
      0 => :starving
    }.each do |food_left, status|
      it "is #{status} at #{food_left} food" do
        expect(described_class.status(food_left)).to eq(status)
      end
    end
  end

  describe '.label' do
    it 'has no HUD label when the player is fed' do
      expect(described_class.label(:ok)).to be_nil
    end

    it 'names every other status' do
      expect([:hungry, :weak, :starving].map { |s| described_class.label(s) }).to eq(%w[Hungry Weak Starving])
    end
  end
end
