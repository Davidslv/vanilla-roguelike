require 'spec_helper'

RSpec.describe Vanilla::Characters::Shared::Movement do
  # Test class that includes the module
  class TestCharacter
    include Vanilla::Characters::Shared::Movement

    attr_accessor :row, :column, :found_stairs

    def initialize(row: 5, column: 10)
      @row = row
      @column = column
      @found_stairs = false
    end

    def can_move?(direction)
      true
    end

    def stairs?(direction)
      false
    end
  end

  let(:character) { TestCharacter.new }
  let(:logger) { instance_double('Vanilla::Logger') }

  before do
    allow(Vanilla::Logger).to receive(:instance).and_return(logger)
    allow(logger).to receive(:warn)
  end

  describe '#move' do
    it 'logs deprecation warning' do
      expect(logger).to receive(:warn).with(/DEPRECATED: TestCharacter#move is deprecated/)

      character.move(:left)
    end
  end

  describe '#move_left' do
    it 'logs deprecation warning' do
      expect(logger).to receive(:warn).with(/DEPRECATED: TestCharacter#move_left is deprecated/)

      character.move_left
    end

    it 'still performs the movement' do
      allow(logger).to receive(:warn)

      expect {
        character.move_left
      }.to change(character, :column).by(-1)
    end
  end

  describe '#move_right' do
    it 'logs deprecation warning' do
      expect(logger).to receive(:warn).with(/DEPRECATED: TestCharacter#move_right is deprecated/)

      character.move_right
    end

    it 'still performs the movement' do
      allow(logger).to receive(:warn)

      expect {
        character.move_right
      }.to change(character, :column).by(1)
    end
  end

  describe '#move_up' do
    it 'logs deprecation warning' do
      expect(logger).to receive(:warn).with(/DEPRECATED: TestCharacter#move_up is deprecated/)

      character.move_up
    end

    it 'still performs the movement' do
      allow(logger).to receive(:warn)

      expect {
        character.move_up
      }.to change(character, :row).by(-1)
    end
  end

  describe '#move_down' do
    it 'logs deprecation warning' do
      expect(logger).to receive(:warn).with(/DEPRECATED: TestCharacter#move_down is deprecated/)

      character.move_down
    end

    it 'still performs the movement' do
      allow(logger).to receive(:warn)

      expect {
        character.move_down
      }.to change(character, :row).by(1)
    end
  end
end