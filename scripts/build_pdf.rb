#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tempfile'

# Script to convert markdown book files to PDF with rendered Mermaid diagrams
# For Amazon KDP publishing
# Uses SVG format for diagrams (vector-based, print-quality)

class BookPDFBuilder
  BOOK_DIR = File.join(__dir__, '..', 'book')
  OUTPUT_DIR = File.join(__dir__, '..', 'book_output')
  DIAGRAMS_DIR = File.join(OUTPUT_DIR, 'diagrams')
  COMBINED_MD = File.join(OUTPUT_DIR, 'combined.md')
  FINAL_PDF = File.join(OUTPUT_DIR, 'Building_Your_Own_Roguelike.pdf')

  # Chapter files in order
  CHAPTERS = [
    # '00-table-of-contents.md',
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
    @diagram_counter = 0
    @diagram_map = {}
  end

  def build
    puts "Building PDF for Amazon KDP..."
    puts "=" * 60

    check_dependencies
    setup_directories
    render_diagrams
    combine_markdown
    convert_to_pdf

    puts "\n" + "=" * 60
    puts "✓ PDF generated successfully!"
    puts "  Location: #{FINAL_PDF}"
    puts "\nNext steps for Amazon KDP:"
    puts "  1. Review the PDF for formatting"
    puts "  2. Ensure all diagrams are visible"
    puts "  3. Check page margins (0.5\" minimum)"
    puts "  4. Verify page size (6\" x 9\" trade paperback)"
  end

  private

  def check_dependencies
    puts "\n[1/5] Checking dependencies..."

    # Check for mmdc (mermaid-cli)
    unless system('which mmdc > /dev/null 2>&1')
      puts "✗ mermaid-cli not found. Installing..."
      puts "  Run: npm install -g @mermaid-js/mermaid-cli"
      puts "  Or: npm install (if package.json exists)"
      exit 1
    end
    puts "  ✓ mermaid-cli found"

    # Check for pandoc
    unless system('which pandoc > /dev/null 2>&1')
      puts "✗ pandoc not found. Please install:"
      puts "  macOS: brew install pandoc"
      puts "  Linux: sudo apt-get install pandoc"
      puts "  Or visit: https://pandoc.org/installing.html"
      exit 1
    end
    puts "  ✓ pandoc found"

    # Check for rsvg-convert (needed for SVG in PDFs)
    # If not available, we'll use PNG instead
    @use_svg = system('which rsvg-convert > /dev/null 2>&1')
    if @use_svg
      puts "  ✓ rsvg-convert found (will use SVG for diagrams)"
    else
      puts "  ⚠ rsvg-convert not found (will use PNG for diagrams)"
      puts "     For SVG support, install: brew install librsvg"
    end

    # Check for LaTeX (needed for PDF generation)
    unless system('which pdflatex > /dev/null 2>&1') || system('which xelatex > /dev/null 2>&1')
      puts "⚠ LaTeX not found. PDF generation may fail."
      puts "\n  Installation options (choose one):"
      puts "  1. MacTeX (full, recommended): brew install --cask mactex"
      puts "  2. MacTeX-no-gui (full, no GUI apps): brew install --cask mactex-no-gui"
      puts "  3. BasicTeX (minimal): Download from https://www.tug.org/mactex/morepackages.html"
      puts "  4. TinyTeX (lightweight):"
      puts "     - Install R: brew install r"
      puts "     - Then: Rscript -e \"install.packages('tinytex'); tinytex::install_tinytex()\""
      puts "\n  After installation, you may need to add to PATH:"
      puts "     export PATH=\"/usr/local/texlive/2024/bin/universal-darwin:\$PATH\""
      puts "     (Adjust year as needed)"
    else
      puts "  ✓ LaTeX found"
    end
  end

  def setup_directories
    puts "\n[2/5] Setting up directories..."
    FileUtils.mkdir_p(OUTPUT_DIR)
    FileUtils.mkdir_p(DIAGRAMS_DIR)
    puts "  ✓ Directories created"
  end

  def render_diagrams
    puts "\n[3/5] Rendering Mermaid diagrams..."

    CHAPTERS.each do |chapter_file|
      chapter_path = File.join(BOOK_DIR, chapter_file)
      next unless File.exist?(chapter_path)

      content = File.read(chapter_path)
      updated_content = content.gsub(/```mermaid\n(.*?)```/m) do |match|
        diagram_code = Regexp.last_match(1)
        render_single_diagram(diagram_code, chapter_file)
      end

      # Write updated content to temp file for later use
      temp_file = File.join(OUTPUT_DIR, "#{chapter_file}.processed")
      File.write(temp_file, updated_content)
    end

    puts "  ✓ Rendered #{@diagram_counter} diagrams"
  end

  def render_single_diagram(diagram_code, source_file)
    @diagram_counter += 1
    diagram_id = "diagram_#{@diagram_counter}"

    # Use PNG if rsvg-convert is not available (Pandoc can't handle SVG without it)
    # PNG at high resolution (1200x800) is still good for print
    extension = @use_svg ? 'svg' : 'png'
    output_file = File.join(DIAGRAMS_DIR, "#{diagram_id}.#{extension}")

    # Create temporary mermaid file
    temp_mmd = Tempfile.new(['diagram', '.mmd'])
    temp_mmd.write(diagram_code)
    temp_mmd.close

    # Render with mermaid-cli
    # For PNG: high resolution (1200x800) for print quality
    # For SVG: vector format for best print quality (requires rsvg-convert)
    cmd = "mmdc -i #{temp_mmd.path} -o #{output_file} -w 1200 -H 800 -b transparent"
    success = system(cmd)

    unless success
      puts "  ⚠ Warning: Failed to render diagram #{diagram_id}"
      return "![Diagram rendering failed](#{diagram_id})"
    end

    temp_mmd.unlink

    # Return markdown image reference with relative path
    # This will be converted to proper relative path in combine_markdown
    "![Mermaid Diagram](#{output_file})"
  end

  def combine_markdown
    puts "\n[4/5] Combining markdown files..."

    combined = String.new
    combined << "# Building Your Own Roguelike: A Practical Guide\n\n"
    # combined << "*Generated for Amazon KDP*\n\n"
    combined << "---\n\n"

    CHAPTERS.each do |chapter_file|
      processed_file = File.join(OUTPUT_DIR, "#{chapter_file}.processed")
      if File.exist?(processed_file)
        content = File.read(processed_file)
        # Convert image paths to relative paths from OUTPUT_DIR
        content = content.gsub(/!\[([^\]]*)\]\(([^)]+)\)/) do |match|
          alt_text = Regexp.last_match(1)
          img_path = Regexp.last_match(2)
          # If it's an absolute path to a diagram, make it relative
          if img_path.include?('diagrams/') && File.exist?(img_path)
            relative_path = File.join('diagrams', File.basename(img_path))
            "![#{alt_text}](#{relative_path})"
          elsif File.exist?(img_path)
            # Absolute path exists, use it
            match
          else
            match
          end
        end
        combined << content
        combined << "\n\n---\n\n"
      else
        # Fallback to original if processed doesn't exist
        original_file = File.join(BOOK_DIR, chapter_file)
        if File.exist?(original_file)
          combined << File.read(original_file)
          combined << "\n\n---\n\n"
        end
      end
    end

    File.write(COMBINED_MD, combined)
    puts "  ✓ Combined #{CHAPTERS.size} chapters"
  end

  def convert_to_pdf
    puts "\n[5/5] Converting to PDF..."

    # Change to OUTPUT_DIR so relative image paths work
    Dir.chdir(OUTPUT_DIR) do
      # Pandoc command with KDP-appropriate settings
      # 6" x 9" trade paperback size
      # 0.5" margins on all sides
      # For bleed support (if needed), uncomment and adjust:
      # --variable=geometry:paperwidth=6.25in (adds 0.125" bleed per side)
      # --variable=geometry:paperheight=9.25in
      # --variable=geometry:includehead=true
      # --variable=geometry:includefoot=true
      # Build command array for better handling
      cmd_parts = [
        'pandoc',
        'combined.md',
        '-o', File.basename(FINAL_PDF),
        '--pdf-engine=xelatex', # Better Unicode support
        '--variable=geometry:margin=0.5in',
        '--variable=geometry:paperwidth=6in',
        '--variable=geometry:paperheight=9in',
        '--variable=fontsize:11pt',
        '--variable=linestretch:1.2',
        '--variable=colorlinks:true',
        '--variable=linkcolor:blue',
        '--toc', # Table of contents
        '--toc-depth=2',
        '--number-sections',
        '--syntax-highlighting=tango' # Updated from deprecated --highlight-style
      ]

      # For xelatex, font embedding is automatic, but we can ensure it
      # Note: xelatex embeds fonts by default, so this is mainly for explicit control
      cmd_parts << '--pdf-engine-opt=-interaction=nonstopmode'

      cmd = cmd_parts.join(' ')
      success = system(cmd)

      unless success
        puts "  ⚠ PDF conversion with xelatex failed. Trying with pdflatex..."
        # Fallback to pdflatex
        cmd_parts = cmd_parts.map do |part|
          case part
          when '--pdf-engine=xelatex'
            '--pdf-engine=pdflatex'
          when '--pdf-engine-opt=-interaction=nonstopmode'
            '--pdf-engine-opt=-interaction=nonstopmode'
          else
            part
          end
        end
        cmd = cmd_parts.join(' ')
        success = system(cmd)
      end

      unless success
        puts "  ✗ PDF conversion failed. Please check:"
        puts "     - LaTeX is installed (try: brew install --cask basictex)"
        puts "     - All diagrams were rendered"
        puts "     - Combined markdown file is valid"
        puts "     - Run: pandoc --version to verify pandoc works"
        exit 1
      end

      # PDF is already in the correct location (we're in OUTPUT_DIR)
      # No need to move it
    end

    puts "  ✓ PDF generated"

    # Note: Some diagrams may be too large for the page (LaTeX warnings)
    # This is normal and LaTeX will adjust them automatically
    if File.exist?(FINAL_PDF)
      file_size = File.size(FINAL_PDF) / 1024.0 / 1024.0
      puts "  ✓ PDF size: #{file_size.round(2)} MB"
    end
  end
end

# Run the builder
if __FILE__ == $PROGRAM_NAME
  builder = BookPDFBuilder.new
  builder.build
end

