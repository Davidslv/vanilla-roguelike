#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

# Script to combine markdown book files and convert to Google Docs format (.docx)
# Google Docs can import .docx files directly

class GoogleDocsCombiner
  BOOK_DIR = File.join(__dir__, '..', 'book')
  OUTPUT_DIR = File.join(__dir__, '..', 'book_output')
  COMBINED_MD = File.join(OUTPUT_DIR, 'combined_for_google_docs.md')
  FINAL_DOCX = File.join(OUTPUT_DIR, 'Building_Your_Own_Roguelike.docx')

  # Chapter files in order (excluding table of contents as it's included in the combined file)
  CHAPTERS = [
    '01-what-is-a-roguelike.md',
    '02-development-mindset.md',
    '03-first-prototype.md',
    '04-grids-and-cells.md',
    '05-maze-algorithms-beginning.md',
    '06-algorithm-diversity.md',
    '07-beyond-mazes.md',
    '08-architecture-problem.md',
    '09-intro-ecs.md',
    '10-ecs-entities-components.md',
    '11-ecs-systems.md',
    '12-world-coordinator.md',
    '13-input-movement.md',
    '14-collision-interaction.md',
    '15-combat-system.md',
    '16-items-inventory.md',
    '17-ai-monsters.md',
    '18-event-driven.md',
    '19-testing.md',
    '20-performance.md',
    '21-extending.md',
    '22-journey.md'
  ].freeze

  def initialize
    @errors = []
  end

  def build
    puts "Combining book chapters for Google Docs..."
    puts "=" * 60

    setup_directories
    combine_markdown
    convert_to_docx

    puts "\n" + "=" * 60
    if File.exist?(FINAL_DOCX)
      puts "✓ Document generated successfully!"
      puts "  Location: #{FINAL_DOCX}"
      puts "\nNext steps:"
      puts "  1. Open Google Docs (docs.google.com)"
      puts "  2. Click 'File' > 'Open' > 'Upload'"
      puts "  3. Select: #{FINAL_DOCX}"
      puts "  4. Google Docs will convert and import the document"
    else
      puts "⚠ Could not generate .docx file"
      puts "  Combined markdown file available at: #{COMBINED_MD}"
      puts "  You can import this directly to Google Docs:"
      puts "  1. Open Google Docs"
      puts "  2. Click 'File' > 'Open' > 'Upload'"
      puts "  3. Select: #{COMBINED_MD}"
      puts "  4. Google Docs will convert markdown to a document"
    end

    if @errors.any?
      puts "\n⚠ Warnings:"
      @errors.each { |error| puts "  - #{error}" }
    end
  end

  private

  def setup_directories
    FileUtils.mkdir_p(OUTPUT_DIR)
  end

  def combine_markdown
    puts "\n[1/2] Combining markdown files..."

    combined = String.new
    combined << "# Building Your Own Roguelike: A Practical Guide\n\n"
    combined << "*A Practical Guide to Building Roguelike Games from Scratch*\n\n"
    combined << "---\n\n"

    # Add table of contents
    toc_file = File.join(BOOK_DIR, '00-table-of-contents.md')
    if File.exist?(toc_file)
      toc_content = File.read(toc_file)
      # Remove the title since we already have one
      toc_content = toc_content.gsub(/^#.*\n/, '')
      combined << toc_content
      combined << "\n\n---\n\n"
    end

    # Add all chapters
    CHAPTERS.each_with_index do |chapter_file, index|
      chapter_path = File.join(BOOK_DIR, chapter_file)

      if File.exist?(chapter_path)
        content = File.read(chapter_path)

        # Add page break before each chapter (except the first)
        combined << "\n\n---\n\n" if index > 0

        combined << content
        combined << "\n\n"

        puts "  ✓ Added #{chapter_file}"
      else
        error_msg = "Chapter file not found: #{chapter_file}"
        @errors << error_msg
        puts "  ✗ #{error_msg}"
      end
    end

    File.write(COMBINED_MD, combined)
    puts "  ✓ Combined #{CHAPTERS.size} chapters"
    puts "  ✓ Combined markdown saved to: #{COMBINED_MD}"
  end

  def convert_to_docx
    puts "\n[2/2] Converting to .docx format..."

    # Check if pandoc is available
    unless system('which pandoc > /dev/null 2>&1')
      puts "  ⚠ pandoc not found. Skipping .docx conversion."
      puts "  ℹ You can still import the markdown file (#{COMBINED_MD}) directly to Google Docs"
      return
    end

    # Change to OUTPUT_DIR so relative paths work
    Dir.chdir(OUTPUT_DIR) do
      cmd = [
        'pandoc',
        'combined_for_google_docs.md',
        '-o', File.basename(FINAL_DOCX),
        '--from=markdown',
        '--to=docx'
      ].join(' ')

      success = system(cmd)

      if success
        puts "  ✓ Converted to .docx successfully"
      else
        error_msg = "pandoc conversion failed"
        @errors << error_msg
        puts "  ✗ #{error_msg}"
        puts "  ℹ You can still import the markdown file directly to Google Docs"
      end
    end
  end
end

# Run the script
if __FILE__ == $PROGRAM_NAME
  combiner = GoogleDocsCombiner.new
  combiner.build
end

