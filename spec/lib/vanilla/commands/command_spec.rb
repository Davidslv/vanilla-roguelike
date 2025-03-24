require 'spec_helper'

RSpec.describe Vanilla::Commands::Command do
  describe '#execute' do
    it 'raises NotImplementedError' do
      command = described_class.new
      expect { command.execute }.to raise_error(NotImplementedError)
    end
  end
end
