# frozen_string_literal: true

module Vanilla
  # Hunger rules (#161, docs/proposals/004_hunger_system_proposal.md).
  #
  # NutritionComponent only stores how much food is left. The rules live here,
  # so HungerSystem and the HUD read the same thresholds. Values are scaled to
  # measured play: a direct player needs about 13 turns per level.
  module Hunger
    START_FOOD = 150   # about 11 levels for a direct player
    MAX_FOOD = 200     # eating cannot store more than this
    HUNGRY_AT = 50     # about 4 levels of warning
    WEAK_AT = 20       # about 1.5 levels left
    STARVE_DAMAGE = 2  # HP per turn at 0 food: from 100 HP, about 4 levels
    APPLE_FOOD = 60    # about 4.5 levels

    LABELS = { hungry: 'Hungry', weak: 'Weak', starving: 'Starving' }.freeze

    module_function

    # @param food_left [Integer]
    # @return [Symbol] :ok, :hungry, :weak or :starving
    def status(food_left)
      return :starving if food_left <= 0
      return :weak if food_left <= WEAK_AT
      return :hungry if food_left <= HUNGRY_AT

      :ok
    end

    # @return [String, nil] HUD text for a status; nil when fed
    def label(status)
      LABELS[status]
    end
  end
end
