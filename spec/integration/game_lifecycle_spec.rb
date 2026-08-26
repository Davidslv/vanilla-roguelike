# frozen_string_literal: true

require 'spec_helper'

# The path issue #141 actually broke: Vanilla.run's `ensure game.cleanup`,
# which every real session hits on exit and no spec exercised. HeadlessGame
# mirrors Game#setup_world and defines its own #cleanup, so Game#cleanup ran
# in production only.
RSpec.describe 'Game lifecycle', type: :integration do
  let(:seed) { 20_260_826 }

  # Constructing the real Game the way the system-roster spec does: keep the
  # EventManager off the filesystem and restore the SIGINT handler that
  # Game#initialize replaces.
  def with_real_game
    allow(Vanilla::Events::EventManager).to receive(:new).and_wrap_original do |original, *|
      original.call(store_config: { file: false })
    end
    previous_trap = Signal.trap('INT') {}
    game = Vanilla::Game.new(seed: seed)
    yield game
  ensure
    Signal.trap('INT', previous_trap) if previous_trap
    Vanilla::ServiceRegistry.unregister(:game)
    Vanilla::ServiceRegistry.unregister(:event_manager)
  end

  describe '#cleanup' do
    it 'completes the quit path without raising' do
      with_real_game do |game|
        expect { game.cleanup }.not_to raise_error
      end
    end

    it 'unregisters itself from the ServiceRegistry' do
      with_real_game do |game|
        game.cleanup

        expect(Vanilla::ServiceRegistry.get(:game)).to be_nil
      end
    end
  end
end
