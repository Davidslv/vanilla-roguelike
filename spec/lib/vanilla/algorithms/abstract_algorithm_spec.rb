# frozen_string_literal: true

require 'spec_helper'
require 'vanilla/algorithms/abstract_algorithm'

RSpec.describe Vanilla::Algorithms::AbstractAlgorithm do
  describe '.demodulize' do
    it 'returns the class name without module namespace' do
      # AbstractAlgorithm is in the Vanilla::Algorithms namespace
      expect(described_class.demodulize).to eq('AbstractAlgorithm')
    end
  end
end
