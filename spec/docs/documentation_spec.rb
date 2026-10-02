# frozen_string_literal: true

require 'spec_helper'
require 'yaml'

# Keeps the docs from drifting away from the code. Each check here caught a
# real drift when it was written: dead links to files that had moved, a system
# order missing five systems, and a Ruby version in the README that disagreed
# with .ruby-version.
RSpec.describe 'Repository documentation' do # rubocop:disable RSpec/DescribeClass -- tests files, not a class
  root = File.expand_path('../..', __dir__)

  doc_files = Dir.glob(
    ['*.md', 'llms.txt', 'docs/**/*.md', '.github/**/*.md', 'spec/**/*.md', 'lib/**/*.md'],
    base: root
  ).sort

  # GitHub's heading anchor: lowercase, drop punctuation, spaces to hyphens.
  def self.anchors_in(path)
    File.read(path).scan(/^#+\s+(.+)$/).map do |(heading)|
      heading.strip.downcase.gsub(/[^\p{Word}\- ]/, '').tr(' ', '-')
    end
  end

  def self.relative_links_in(path)
    text = File.read(path).gsub(/```.*?```/m, '').gsub(/`[^`\n]*`/, '')
    text.scan(/\[[^\]]*\]\(([^)\s]+)\)/).flatten.reject { |link| link.match?(/\A(https?:|mailto:)/) }
  end

  describe 'relative links' do
    doc_files.each do |doc|
      it "resolve in #{doc}" do
        doc_path = File.join(root, doc)
        broken = self.class.relative_links_in(doc_path).reject do |link|
          target, anchor = link.split('#', 2)
          target_path = target.empty? ? doc_path : File.expand_path(target, File.dirname(doc_path))
          next false unless File.exist?(target_path)
          next true if anchor.nil? || File.directory?(target_path) || !target_path.end_with?('.md')

          self.class.anchors_in(target_path).include?(anchor)
        end

        expect(broken).to be_empty, "Broken links in #{doc}: #{broken.join(', ')}"
      end
    end
  end

  describe 'system order tables' do
    let(:registered) do
      allow(Vanilla::Events::EventManager).to receive(:new).and_wrap_original do |original, *|
        original.call(store_config: { file: false })
      end
      previous_trap = Signal.trap('INT') {} # Game#initialize replaces the handler
      begin
        Vanilla::Game.new(seed: 1).world.systems.map do |system, priority|
          [system.class.name.split('::').last, priority.to_s]
        end
      ensure
        Signal.trap('INT', previous_trap)
        Vanilla::ServiceRegistry.unregister(:game)
        Vanilla::ServiceRegistry.unregister(:event_manager)
      end
    end

    # Rows of a Markdown table whose first column is a priority number and
    # whose next column names a system, e.g. "| 2.5 | FOVSystem | ... |".
    def documented_order(path)
      File.read(path).scan(/^\|\s*([\d.]+)\s*\|\s*(\w+System)\s*\|/).map { |priority, name| [name, priority] }
    end

    %w[AGENTS.md docs/architecture.md].each do |doc|
      it "matches Game#setup_world in #{doc}" do
        expect(documented_order(File.join(root, doc))).to eq(registered)
      end
    end
  end

  describe 'Ruby version' do
    let(:pinned_minor) { File.read(File.join(root, '.ruby-version')).strip[/\A\d+\.\d+/] }

    it 'is the version CI tests on' do
      workflow = YAML.load_file(File.join(root, '.github/workflows/test.yml'))
      ci_rubies = workflow.dig('jobs', 'test', 'strategy', 'matrix', 'ruby')

      expect(ci_rubies).to include(pinned_minor)
    end

    it 'is not hard-coded in the docs' do
      stale = doc_files.select do |doc|
        File.read(File.join(root, doc)).match?(/Ruby \(?(version|v)?\s*\d+\.\d+\.\d+/i)
      end

      expect(stale).to be_empty, "Point at .ruby-version instead of a fixed version: #{stale.join(', ')}"
    end
  end
end
