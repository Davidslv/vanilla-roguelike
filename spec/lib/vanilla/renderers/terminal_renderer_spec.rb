# frozen_string_literal: true

require 'spec_helper'

# Covers the HUD lines above the maze. These were only checked by eye before,
# through a manual script (scripts/test_display.rb, now removed).
RSpec.describe Vanilla::Renderers::TerminalRenderer do
  subject(:renderer) { described_class.new }

  let(:grid) { Vanilla::MapUtils::Grid.new(2, 3) }

  def hud_lines
    output = capture_stdout { renderer.draw_grid(grid, 'BinaryTree') }
    output.lines.first(3).map(&:chomp)
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  describe '#draw_grid' do
    it 'shows the seed in the header' do
      renderer.set_game_info(seed: 12_345, difficulty: 1)

      expect(hud_lines[0]).to eq('Vanilla Roguelike | Seed: 12345')
    end

    it 'shows grid size and algorithm' do
      expect(hud_lines[1]).to eq('Rows: 2 | Columns: 3 | Algorithm: BinaryTree')
    end

    it 'shows full health and level' do
      renderer.set_game_info(seed: 12_345, difficulty: 1)
      renderer.set_player_health(current: 100, max: 100)

      expect(hud_lines[2]).to eq('HP: 100/100 (100%) | Level: 1')
    end

    it 'shows health after damage as a rounded percentage' do
      renderer.set_game_info(seed: 12_345, difficulty: 2)
      renderer.set_player_health(current: 75, max: 100)

      expect(hud_lines[2]).to eq('HP: 75/100 (75%) | Level: 2')
    end

    it 'shows the hunger status after the level when the player is hungry' do
      renderer.set_game_info(seed: 1, difficulty: 3)
      renderer.set_player_health(current: 80, max: 100)
      renderer.set_player_hunger(status: :hungry)

      expect(hud_lines[2]).to eq('HP: 80/100 (80%) | Level: 3 | Hungry')
    end

    it 'shows no hunger status when the player is fed' do
      renderer.set_game_info(seed: 1, difficulty: 3)
      renderer.set_player_health(current: 80, max: 100)
      renderer.set_player_hunger(status: :ok)

      expect(hud_lines[2]).to eq('HP: 80/100 (80%) | Level: 3')
    end

    it 'omits the seed and player line before game info is set' do
      expect(hud_lines[0]).to eq('Vanilla Roguelike')
      expect(hud_lines[2]).to eq('')
    end
  end
end
