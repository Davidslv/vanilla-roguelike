#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'tempfile'
require 'pathname'

# Script to combine markdown book files and convert to Google Docs format (.docx)
# Google Docs can import .docx files directly
# Renders Mermaid diagrams to PNG images

class GoogleDocsCombiner
  BOOK_DIR = File.join(__dir__, '..', 'book')
  OUTPUT_DIR = File.join(__dir__, '..', 'book_output')
  DIAGRAMS_DIR = File.join(OUTPUT_DIR, 'diagrams')
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
    @diagram_counter = 0
    @has_mermaid = false
  end

  def build
    puts "Combining book chapters for Google Docs..."
    puts "=" * 60

    check_dependencies
    setup_directories
    render_diagrams
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

  def check_dependencies
    puts "\n[0/4] Checking dependencies..."

    # Check for mmdc (mermaid-cli)
    if system('which mmdc > /dev/null 2>&1')
      puts "  ✓ mermaid-cli found"
      @has_mermaid = true
    else
      puts "  ⚠ mermaid-cli not found"
      puts "     Mermaid diagrams will remain as code blocks"
      puts "     To render diagrams, install: npm install -g @mermaid-js/mermaid-cli"
      @has_mermaid = false
    end

    # Check for pandoc
    unless system('which pandoc > /dev/null 2>&1')
      puts "  ⚠ pandoc not found"
      puts "     Will create markdown file only"
      puts "     To convert to .docx, install: brew install pandoc"
    else
      puts "  ✓ pandoc found"
    end
  end

  def setup_directories
    FileUtils.mkdir_p(OUTPUT_DIR)
    FileUtils.mkdir_p(DIAGRAMS_DIR)
  end

  def render_diagrams
    return unless @has_mermaid

    puts "\n[1/4] Rendering Mermaid diagrams..."

    CHAPTERS.each do |chapter_file|
      chapter_path = File.join(BOOK_DIR, chapter_file)
      next unless File.exist?(chapter_path)

      content = File.read(chapter_path)
      next unless content.include?('```mermaid')

      updated_content = content.gsub(/```mermaid\n(.*?)```/m) do |match|
        diagram_code = Regexp.last_match(1)
        caption = extract_caption(content, match)
        render_single_diagram(diagram_code, chapter_file, caption)
      end

      # Write processed content to temp file
      temp_file = File.join(OUTPUT_DIR, "#{chapter_file}.processed")
      File.write(temp_file, updated_content)
    end

    puts "  ✓ Rendered #{@diagram_counter} diagrams"
  end

  def extract_caption(content, diagram_match)
    diagram_pos = content.index(diagram_match)
    return "Diagram" if diagram_pos.nil?

    before_diagram = content[0...diagram_pos]
    headings = before_diagram.scan(/(?:^|\n)(\#{1,6})\s+(.+?)(?:\n|$)/m)
    if headings.any?
      heading_text = headings.last[1].strip
      heading_text = heading_text.gsub(/\*\*([^*]+)\*\*/, '\1')
      heading_text = heading_text.gsub(/\*([^*]+)\*/, '\1')
      heading_text = heading_text.gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
      return heading_text unless heading_text.empty?
    end

    paragraphs = before_diagram.split(/\n\n+/)
    if paragraphs.length > 0
      last_para = paragraphs[-1].strip
      last_para = last_para.gsub(/[#*\[\]()]/, '').strip
      if last_para.length > 0 && last_para.length < 100
        return last_para.split(/[.!?]/).first || "Diagram"
      end
    end

    "Diagram"
  end

  def render_single_diagram(diagram_code, source_file, caption = "Diagram")
    @diagram_counter += 1
    diagram_id = "diagram_#{@diagram_counter}"
    output_file = File.join(DIAGRAMS_DIR, "#{diagram_id}.png")

    # Create temporary mermaid file
    temp_mmd = Tempfile.new(['diagram', '.mmd'])
    temp_mmd.write(diagram_code)
    temp_mmd.close

    # Render with mermaid-cli (PNG format for Google Docs compatibility)
    cmd = "mmdc -i #{temp_mmd.path} -o #{output_file} -w 1200 -H 800 -b transparent"
    success = system(cmd)

    unless success
      puts "  ⚠ Warning: Failed to render diagram #{diagram_id}"
      return "![Diagram rendering failed](#{diagram_id})"
    end

    temp_mmd.unlink

    # Return markdown image reference with relative path
    relative_path = File.join('diagrams', "#{diagram_id}.png")
    "![#{caption}](#{relative_path})"
  end

  def combine_markdown
    puts "\n[#{@has_mermaid ? '2' : '1'}/#{@has_mermaid ? '4' : '2'}] Combining markdown files..."

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
      # Check for processed version first (with rendered diagrams)
      processed_file = File.join(OUTPUT_DIR, "#{chapter_file}.processed")
      chapter_path = if File.exist?(processed_file)
                       processed_file
                     else
                       File.join(BOOK_DIR, chapter_file)
                     end

      if File.exist?(chapter_path)
        content = File.read(chapter_path)

        # Convert image paths to relative paths from OUTPUT_DIR
        content = content.gsub(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
          alt_text = Regexp.last_match(1)
          img_path = Regexp.last_match(2)

          # If it's an absolute path to a diagram, make it relative
          if img_path.include?('diagrams/') && File.exist?(img_path)
            relative_path = File.join('diagrams', File.basename(img_path))
            "![#{alt_text}](#{relative_path})"
          elsif img_path.start_with?('/') && File.exist?(img_path)
            # Absolute path exists, make relative to OUTPUT_DIR
            relative_path = Pathname.new(img_path).relative_path_from(Pathname.new(OUTPUT_DIR)).to_s
            "![#{alt_text}](#{relative_path})"
          else
            match
          end
        end

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
    step_num = @has_mermaid ? 3 : 2
    total_steps = @has_mermaid ? 4 : 2
    puts "\n[#{step_num}/#{total_steps}] Converting to .docx format..."

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
        '--to=docx',
        '--standalone'
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

