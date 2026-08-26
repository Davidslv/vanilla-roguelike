# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/headless_game'

# Guards the seam that let issue #141 through: HeadlessGame swaps terminal-bound
# collaborators for hand-rolled stand-ins. A plain class is not a verifying
# double, so a stand-in can quietly implement methods the real class lacks --
# and every integration spec then exercises an interface production does not
# have.
#
# A stand-in may legitimately add affordances a spec drives it with (queueing a
# key, inspecting what was consumed). Those must be declared in :harness_only,
# which is the point: adding one is a deliberate line in this file, while
# drifting ahead of production fails the build.
HARNESS_SUBSTITUTIONS = [
  {
    stand_in: HeadlessGame::ScriptedKeyboard,
    real: Vanilla::KeyboardHandler,
    harness_only: [:push] # scripts the key queue; production reads the terminal
  }
].freeze

RSpec.describe 'Harness fidelity', type: :integration do
  HARNESS_SUBSTITUTIONS.each do |pair|
    stand_in = pair[:stand_in]
    real = pair[:real]

    it "#{real} implements every production method #{stand_in} stands in for" do
      claimed = stand_in.public_instance_methods(false) - pair[:harness_only]
      missing = claimed - real.public_instance_methods(false)

      expect(missing).to be_empty,
                         "#{stand_in} answers #{missing.inspect}, but #{real} does not. " \
                         'Specs are exercising an interface production lacks; either implement ' \
                         "it on #{real} or declare it in :harness_only."
    end

    it "#{stand_in} declares no unused harness_only methods" do
      stale = pair[:harness_only] - stand_in.public_instance_methods(false)

      expect(stale).to be_empty, "#{stale.inspect} no longer exist on #{stand_in}"
    end
  end
end
