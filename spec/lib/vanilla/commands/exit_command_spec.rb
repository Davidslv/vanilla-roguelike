require 'spec_helper'

RSpec.describe Vanilla::Commands::ExitCommand do
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:info)
  end

  describe '#execute' do
    it 'logs a message and calls exit' do
      command = described_class.new

      expect(logger).to receive(:info).with('Player exiting game')
      expect(command).to receive(:exit)

      command.execute
    end
  end
end
