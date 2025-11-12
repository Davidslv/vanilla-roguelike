# frozen_string_literal: true

require_relative "component"

module Vanilla
  module Components
    # Component that enables developer mode features
    # Primarily used to toggle Field of View system for debugging
    class DevModeComponent < Component
      attr_accessor :fov_disabled, :show_all_entities

      def initialize(fov_disabled: false)
        super()
        @fov_disabled = fov_disabled
        @show_all_entities = fov_disabled
      end

      def type
        :dev_mode
      end

      # Toggle FOV system on/off
      def toggle_fov
        @fov_disabled = !@fov_disabled
        @show_all_entities = @fov_disabled
      end

      def to_hash
        {
          fov_disabled: @fov_disabled,
          show_all_entities: @show_all_entities
        }
      end

      def self.from_hash(hash)
        new(fov_disabled: hash[:fov_disabled])
      end
    end
  end
end
