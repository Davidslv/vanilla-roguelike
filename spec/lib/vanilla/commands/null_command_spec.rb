# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Vanilla::Commands::NullCommand do
  describe '#execute' do
    it 'returns true and does nothing' do
      command = described_class.new
      expect(command.execute).to be true
    end
  end
end
