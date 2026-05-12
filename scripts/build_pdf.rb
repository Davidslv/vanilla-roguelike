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
  FINAL_PDF_COLOR = File.join(OUTPUT_DIR, 'Building_Your_Own_Roguelike_2E.pdf')
  FINAL_PDF_BW = File.join(OUTPUT_DIR, 'Building_Your_Own_Roguelike_2E_BW.pdf')

  ISBN_PAPERBACK = '978-1-0666494-1-9'
  EDITION_LABEL = 'Second Edition'
  EDITION_YEAR = 2026
  FIRST_EDITION_DATE = 'November 2025'

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
    '22-journey.md',
    '23-about-the-author.md'
  ].freeze

  def initialize(bw: false, strict: false)
    @diagram_counter = 0
    @diagram_map = {}
    @bw = bw
    @strict = strict
  end

  def final_pdf
    @bw ? FINAL_PDF_BW : FINAL_PDF_COLOR
  end

  def build
    mode = @bw ? "B&W" : "Colour"
    puts "Building #{mode} PDF for Amazon KDP..."
    puts "=" * 60

    check_dependencies
    setup_directories
    render_diagrams
    combine_markdown
    convert_to_pdf

    puts "\n" + "=" * 60
    puts "✓ #{mode} PDF generated successfully!"
    puts "  Location: #{final_pdf}"
    puts "\nNext steps for IngramSpark / KDP (Second Edition, 7\" x 10\"):"
    puts "  1. Review the PDF for formatting"
    puts "  2. Ensure all diagrams are visible"
    puts "  3. Verify page size (7\" x 10\" trade paperback)"
    puts "  4. Note the final page count and use it to compute Ingram cover spine width"
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
        # Extract caption from context (heading or paragraph before diagram)
        caption = extract_caption(content, match)
        render_single_diagram(diagram_code, chapter_file, caption)
      end

      # Write updated content to temp file for later use
      temp_file = File.join(OUTPUT_DIR, "#{chapter_file}.processed")
      File.write(temp_file, updated_content)
    end

    puts "  ✓ Rendered #{@diagram_counter} diagrams"
  end

  def extract_caption(content, diagram_match)
    # Find the position of the diagram in the content
    diagram_pos = content.index(diagram_match)
    return "Diagram" if diagram_pos.nil?

    # Look backwards for the most recent heading or paragraph
    before_diagram = content[0...diagram_pos]

    # Find the LAST heading before the diagram (most recent)
    # Escape # to avoid string interpolation in regex
    headings = before_diagram.scan(/(?:^|\n)(\#{1,6})\s+(.+?)(?:\n|$)/m)
    if headings.any?
      heading_text = headings.last[1].strip
      # Clean up markdown formatting
      heading_text = heading_text.gsub(/\*\*([^*]+)\*\*/, '\1') # Remove bold
      heading_text = heading_text.gsub(/\*([^*]+)\*/, '\1') # Remove italic
      heading_text = heading_text.gsub(/\[([^\]]+)\]\([^)]+\)/, '\1') # Remove links
      return heading_text unless heading_text.empty?
    end

    # Fallback: look for paragraph text before diagram
    paragraphs = before_diagram.split(/\n\n+/)
    if paragraphs.length > 0
      last_para = paragraphs[-1].strip
      # Remove markdown formatting and take first sentence
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

    # Use PNG if rsvg-convert is not available (Pandoc can't handle SVG without it)
    # PNG at high resolution (1200x800) is still good for print
    extension = 'png'# @use_svg ? 'svg' : 'png'
    # Separate output paths so colour and B&W builds don't overwrite each other
    mode_dir = @bw ? 'bw' : 'color'
    FileUtils.mkdir_p(File.join(DIAGRAMS_DIR, mode_dir))
    output_file = File.join(DIAGRAMS_DIR, mode_dir, "#{diagram_id}.#{extension}")

    # For B&W: strip colour styles and use neutral theme
    if @bw
      diagram_code = diagram_code.gsub(/^.*style\s+\S+\s+fill:.*$/, '')
      diagram_code = diagram_code.gsub(/^.*classDef\s+\S+\s+fill:.*$/, '')
      diagram_code = diagram_code.gsub(/:::\S+/, '')
    end

    # Create temporary mermaid file
    temp_mmd = Tempfile.new(['diagram', '.mmd'])
    temp_mmd.write(diagram_code)
    temp_mmd.close

    # Render with mermaid-cli
    theme_flag = @bw ? "-t neutral" : ""
    cmd = "mmdc -i #{temp_mmd.path} -o #{output_file} -w 1500 -H 1000 -s 2 -b transparent #{theme_flag}"
    success = system(cmd)

    unless success
      puts "  ⚠ Warning: Failed to render diagram #{diagram_id}"
      return "![Diagram rendering failed](#{diagram_id})"
    end

    temp_mmd.unlink

    # Return markdown image reference with caption
    # Add LaTeX float placement [H] to force image to appear "here" (not floating)
    # This prevents images from appearing in the middle of text
    "![#{caption}](#{output_file}){width=95%}"
  end

  def combine_markdown
    puts "\n[4/5] Combining markdown files..."

    combined = String.new
    # Title page + copyright page are emitted by frontmatter.tex via
    # pandoc's --include-before-body, which puts them ahead of the TOC.

    CHAPTERS.each do |chapter_file|
      processed_file = File.join(OUTPUT_DIR, "#{chapter_file}.processed")
      if File.exist?(processed_file)
        content = File.read(processed_file)
        # Strip redundant "Chapter N: " prefix from the file's H1 so book-class
        # numbering ("Chapter 22.") doesn't collide with the source heading
        # ("Chapter 22: Title") and produce "Chapter 22. Chapter 22: Title".
        content = content.sub(/\A(#\s+)Chapter\s+\d+:\s*/, '\1')
        # Insert a blank line before any bullet/numbered list item that
        # immediately follows a non-list, non-blank line. Without this,
        # pandoc treats "**Heading:**\n- item" as a single paragraph and
        # the list flattens into prose with literal " - " separators.
        content = ensure_blank_line_before_lists(content)
        # Convert image paths to relative paths from OUTPUT_DIR
        # Also add LaTeX float placement to prevent images from floating into text
        content = content.gsub(/!\[([^\]]*)\]\(([^)]+)\)(?:\{([^}]*)\})?/) do |match|
          alt_text = Regexp.last_match(1)
          img_path = Regexp.last_match(2)
          existing_attrs = Regexp.last_match(3)

          # If it's an absolute path to a diagram, make it relative
          if img_path.include?('diagrams/') && File.exist?(img_path)
            mode_dir = @bw ? 'bw' : 'color'
            relative_path = File.join('diagrams', mode_dir, File.basename(img_path))
            # Add LaTeX placement to force image here (not floating)
            # Use width attribute and FloatBarrier to prevent floating
            attrs = existing_attrs ? "#{existing_attrs}" : "width=100%"
            # Add FloatBarrier before image to prevent it from floating into previous text
            "\\FloatBarrier\n\n![#{alt_text}](#{relative_path}){#{attrs}}\n\n"
          elsif File.exist?(img_path)
            # Absolute path exists, use it
            match
          else
            match
          end
        end
        combined << content
        combined << "\n\n\\newpage\n\n" # Page break between chapters
      else
        # Fallback to original if processed doesn't exist
        original_file = File.join(BOOK_DIR, chapter_file)
        if File.exist?(original_file)
          combined << File.read(original_file)
          combined << "\n\n\\newpage\n\n" # Page break between chapters
        end
      end
    end

    File.write(COMBINED_MD, combined)
    puts "  ✓ Combined #{CHAPTERS.size} chapters"

    guard_against_placeholders(combined)
  end

  # Insert blank line before list items that follow a non-blank, non-list line.
  # Skips content inside fenced code blocks so we don't reflow code.
  def ensure_blank_line_before_lists(content)
    out = []
    in_code = false
    prev_line = ''
    list_re = /\A\s{0,3}([-*+]|\d+\.)\s+\S/

    content.each_line do |line|
      if line.start_with?('```')
        in_code = !in_code
        out << line
        prev_line = line
        next
      end

      if !in_code &&
         line.match?(list_re) &&
         prev_line.strip.length.positive? &&
         !prev_line.match?(list_re) &&
         !prev_line.start_with?('#')
        out << "\n"
      end

      out << line
      prev_line = line
    end
    out.join
  end

  # Warn (and in --strict mode, abort) if the manuscript still contains
  # "[FILL IN: ..." or "## TODO" markers. Prevents the book from accidentally
  # shipping with scaffold prose visible to readers.
  def guard_against_placeholders(combined)
    placeholders = []
    combined.each_line.with_index(1) do |line, lineno|
      if line.include?('[FILL IN:') || line.match?(/^\s*##?\s+TODO\b/i)
        placeholders << "  line #{lineno}: #{line.strip[0, 100]}"
      end
    end

    return if placeholders.empty?

    warn ""
    warn "  ⚠ Manuscript still contains #{placeholders.size} placeholder(s):"
    warn placeholders.first(5).join("\n")
    warn "  ...and #{placeholders.size - 5} more" if placeholders.size > 5

    return unless @strict

    warn ""
    warn "✗ Build aborted (--strict): resolve placeholders before submitting to print."
    exit 1
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
      # Create LaTeX header to control image placement and code wrapping
      # Use placeins package for \FloatBarrier and floatrow for better control
      latex_header = <<~LATEX
        % Font configuration (XeLaTeX supports system fonts)
        \\usepackage{fontspec}
        % Body font: Helvetica. The macOS system Helvetica's ligature tables
        % intermittently drop the i in fi/ffi (producing "Diﬀculty"/"Deﬁne").
        % Disable common ligatures (fi/fl/ffi/ffl) so f and i render as
        % separate glyphs and the bug never triggers.
        \\setmainfont{Helvetica}[Ligatures=NoCommon]
        \\setsansfont{Helvetica}[Ligatures=NoCommon]
        \\setmonofont{Menlo}

        % Map common Unicode glyphs that Helvetica lacks (or renders as tofu)
        % to their math-mode equivalents, which always have a fallback font.
        \\usepackage{newunicodechar}
        \\newunicodechar{→}{\\ensuremath{\\rightarrow}}
        \\newunicodechar{←}{\\ensuremath{\\leftarrow}}
        \\newunicodechar{↑}{\\ensuremath{\\uparrow}}
        \\newunicodechar{↓}{\\ensuremath{\\downarrow}}
        \\newunicodechar{⇒}{\\ensuremath{\\Rightarrow}}
        \\newunicodechar{⇐}{\\ensuremath{\\Leftarrow}}
        \\newunicodechar{≤}{\\ensuremath{\\leq}}
        \\newunicodechar{≥}{\\ensuremath{\\geq}}
        \\newunicodechar{≠}{\\ensuremath{\\neq}}

        \\usepackage{placeins}
        \\usepackage{float}
        \\floatplacement{figure}{H}
        \\usepackage{graphicx}

        % Typography polish — discourage widows/orphans and prevent section
        % headings from being hyphenated mid-word (e.g. "Player De-tection").
        \\widowpenalty=10000
        \\clubpenalty=10000
        \\usepackage{titlesec}
        \\titleformat*{\\section}{\\Large\\bfseries\\raggedright}
        \\titleformat*{\\subsection}{\\large\\bfseries\\raggedright}
        \\titleformat*{\\subsubsection}{\\normalsize\\bfseries\\raggedright}
        % Table configuration - tabularx + longtable + booktabs handles wrapping
        % naturally without redefining the float environment.
        \\usepackage{tabularx}
        \\usepackage{longtable}
        \\usepackage{booktabs}
        \\usepackage{etoolbox}
        \\setlength{\\tabcolsep}{4pt}
        \\renewcommand{\\arraystretch}{1.2}
        \\renewcommand{\\tabularxcolumn}[1]{m{#1}}
        % Tables in 6-column technical comparison form get squished at 7" trim.
        % Use footnotesize inside any longtable/tabular so column content fits.
        \\AtBeginEnvironment{longtable}{\\footnotesize}
        \\AtBeginEnvironment{tabular}{\\footnotesize}
        \\AtBeginEnvironment{tabularx}{\\footnotesize}
        % Code wrapping and formatting
        \\usepackage{listings}
        \\usepackage[dvipsnames]{xcolor}  % dvipsnames gives access to NavyBlue, etc.
        \\usepackage{fancyvrb}
        \\usepackage{upquote}
        % Configure code blocks to wrap and fit page width
        \\lstset{
          breaklines=true,
          breakatwhitespace=true,
          postbreak=\\mbox{\\textcolor{red}{$\\hookrightarrow$}\\space},
          basicstyle=\\ttfamily\\footnotesize,
          columns=fullflexible,
          keepspaces=true,
          frame=single,
          framesep=3pt,
          framerule=0.5pt,
          rulecolor=\\color{gray!40},
          backgroundcolor=\\color{white},
          xleftmargin=5pt,
          xrightmargin=5pt,
          aboveskip=10pt,
          belowskip=10pt,
          linewidth=\\textwidth,
          breakindent=0pt
        }
        % Configure Verbatim (used by Pandoc for code blocks)
        % Use smaller font and frame, but rely on listings for wrapping
        \\fvset{
          fontsize=\\footnotesize,
          frame=single,
          framesep=3pt,
          framerule=0.5pt,
          rulecolor=\\color{gray!40}
        }
        % Create a custom verbatim environment that wraps
        \\usepackage{etoolbox}
        \\makeatletter
        % Patch verbatim to use smaller font and respect margins better
        \\apptocmd{\\@verbatim}{%
          \\footnotesize%
          \\setlength{\\leftskip}{\\@totalleftmargin}%
          \\setlength{\\rightskip}{0pt}%
        }{}{}
        \\makeatother
        % Use tcolorbox for better code block wrapping (if available)
        % Otherwise, configure verbatim to use smaller font and respect margins
        \\makeatletter
        \\renewcommand{\\verbatim@font}{\\ttfamily\\footnotesize}
        % Make verbatim respect page margins
        \\def\\@verbatim{%
          \\trivlist
          \\item\\relax
          \\if@minipage\\else
            \\vskip\\parskip
          \\fi
          \\leftskip\\@totalleftmargin\\rightskip\\z@skip
          \\parindent\\z@\\parfillskip\\@flushglue\\parskip\\z@
          \\@tempswafalse
          \\def\\par{%
            \\if@tempswa
              \\leavevmode\\null\\@@par\\penalty\\interlinepenalty
            \\else
              \\@tempswatrue
              \\ifhmode\\@@par\\penalty\\interlinepenalty\\fi
            \\fi
          }%
          \\obeylines\\verbatim@font\\@noligs
          \\let\\do\\@makeother\\dospecials
          \\everypar\\expandafter{\\the\\everypar\\unpenalty}%
        }
        \\makeatother
        % Use listings package for code blocks that need wrapping
        % Pandoc will use this for code blocks
        \\lstdefinestyle{codeblock}{
          breaklines=true,
          breakatwhitespace=false,
          breakindent=0pt,
          postbreak=\\raisebox{0ex}[0ex][0ex]{\\ensuremath{\\hookrightarrow\\space}},
          basicstyle=\\ttfamily\\footnotesize,
          columns=fullflexible,
          keepspaces=true,
          frame=single,
          framesep=3pt,
          framerule=0.5pt,
          backgroundcolor=\\color{white}
        }
      LATEX

      # Write header to temp file
      header_file = File.join(OUTPUT_DIR, 'latex_header.tex')
      File.write(header_file, latex_header)

      # YAML metadata for keywords / non-title-page data only.
      # We deliberately do NOT set `title:` here, because that would trigger
      # pandoc's auto-\maketitle and we want full control via frontmatter.tex.
      # PDF /Title and /Author metadata is set by PDFX_def.ps in the gs step.
      metadata_yaml = <<~YAML
        ---
        keywords: [roguelike, ruby, game development, ECS, procedural generation]
        ---
      YAML
      File.write(File.join(OUTPUT_DIR, 'book_metadata.yaml'), metadata_yaml)

      # Frontmatter LaTeX — title page + copyright page, included via
      # --include-before-body so they appear before the auto-generated TOC.
      frontmatter_tex = <<~TEX
        \\begin{titlepage}
        \\thispagestyle{empty}
        \\begin{center}
        \\vspace*{2in}

        {\\Huge\\bfseries Building Your Own Roguelike}\\\\[0.5em]
        {\\LARGE A Practical Guide}\\\\[2em]
        {\\Large #{EDITION_LABEL}}\\\\[6em]
        {\\Large David Silva}

        \\vspace*{\\fill}
        \\end{center}
        \\end{titlepage}

        \\thispagestyle{empty}
        \\vspace*{\\fill}

        \\noindent Building Your Own Roguelike: A Practical Guide\\\\
        #{EDITION_LABEL}

        \\bigskip
        \\noindent Copyright \\textcopyright{} #{EDITION_YEAR} David Silva. All rights reserved.

        \\bigskip
        \\noindent No part of this book may be reproduced or transmitted in any form or by any means, electronic or mechanical, including photocopying, recording, or by any information storage and retrieval system, without permission in writing from the author.

        \\bigskip
        \\noindent ISBN: #{ISBN_PAPERBACK} (paperback)

        \\noindent First Edition: #{FIRST_EDITION_DATE}\\\\
        #{EDITION_LABEL}: #{EDITION_YEAR}

        \\vspace*{2cm}
        \\newpage
      TEX
      File.write(File.join(OUTPUT_DIR, 'frontmatter.tex'), frontmatter_tex)

      # Build command array for better handling
      cmd_parts = [
        'pandoc',
        'combined.md',
        '-o', File.basename(final_pdf),
        '--pdf-engine=xelatex', # Better Unicode support
        '--include-in-header', header_file,
        '--include-before-body', 'frontmatter.tex',
        # 7" x 10" trade paperback, Second Edition
        # Asymmetric margins (inner gutter wider for perfect-bound spine)
        '--variable=documentclass:book',
        '--variable=classoption:twoside,openany',
        '--variable=geometry:paperwidth=7in',
        '--variable=geometry:paperheight=10in',
        '--variable=geometry:inner=0.875in',
        '--variable=geometry:outer=0.625in',
        '--variable=geometry:top=0.75in',
        '--variable=geometry:bottom=0.75in',
        '--variable=fontsize:11pt',
        '--variable=linestretch:1.2',
        '--variable=colorlinks:true',
        # Hyperlinks: black for B&W (avoids colour-page surcharges), and a
        # desaturated near-black for the colour print edition (bright blue
        # links scream "self-published PDF" on physical paper).
        "--variable=linkcolor:#{@bw ? 'black' : 'NavyBlue'}",
        "--variable=urlcolor:#{@bw ? 'black' : 'NavyBlue'}",
        "--variable=toccolor:black",
        # PDF metadata via YAML file (avoids shell-quoting issues with colons in title)
        '--metadata-file=book_metadata.yaml',
        # Treat # as \chapter (book class), not \section
        '--top-level-division=chapter',
        '--toc', # Table of contents
        '--toc-depth=2',
        '--number-sections',
        '--syntax-highlighting=tango', # New flag (--highlight-style is deprecated)
        '--wrap=preserve' # Preserve line breaks but allow wrapping
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

    # IngramSpark and most trade printers require even page counts.
    # Append a blank trailing page if the count is odd.
    ensure_even_page_count

    # B&W books need DeviceGray (K-only) so KDP/Ingram don't bill colour-page
    # surcharges. Colour books get full PDF/X-1a:2001 CMYK.
    if @bw
      convert_to_grayscale
    else
      convert_to_pdfx
    end

    if File.exist?(final_pdf)
      file_size = File.size(final_pdf) / 1024.0 / 1024.0
      puts "  ✓ PDF size: #{file_size.round(2)} MB"
    end
  end

  # Locate a CMYK ICC profile to use as the PDF/X-1a OutputIntent.
  # Falls back through the most-common system locations.
  def cmyk_icc_profile
    candidates = [
      '/usr/local/share/ghostscript/10.04.0/iccprofiles/default_cmyk.icc',
      '/opt/homebrew/share/ghostscript/10.04.0/iccprofiles/default_cmyk.icc',
      '/System/Library/ColorSync/Profiles/Generic CMYK Profile.icc'
    ]
    candidates.find { |path| File.exist?(path) }
  end

  # Generate a PDFX_def.ps that declares the metadata Ghostscript needs to
  # emit valid PDF/X-1a:2001. Returns the path to the generated file.
  def generate_pdfx_def(icc_profile_path)
    pdfx_def = <<~POSTSCRIPT
      %!
      % PDF/X-1a:2001 definition file generated by build_pdf.rb
      % Required metadata + OutputIntent for IngramSpark / trade print compliance.

      [ /Title (Building Your Own Roguelike: A Practical Guide)
        /Author (David Silva)
        /Subject (#{EDITION_LABEL})
        /Creator (build_pdf.rb / pandoc / xelatex / Ghostscript)
        /DOCINFO pdfmark

      [ /_objdef {OutputIntent_PDFX} /type /dict /OBJ pdfmark
      [ {OutputIntent_PDFX}
        <<
          /Type /OutputIntent
          /S /GTS_PDFX
          /OutputCondition (Commercial Offset Print, Coated Stock)
          /OutputConditionIdentifier (CGATS TR 001)
          /RegistryName (http://www.color.org)
          /Info (U.S. Web Coated SWOP-equivalent)
          /DestOutputProfile {icc_PDFX}
        >> /PUT pdfmark

      [ /_objdef {icc_PDFX} /type /stream /OBJ pdfmark
      [ {icc_PDFX} <</N 4>> /PUT pdfmark
      [ {icc_PDFX} (#{icc_profile_path}) (r) file /PUT pdfmark
      [ {Catalog} <</OutputIntents [ {OutputIntent_PDFX} ]>> /PUT pdfmark

      [ /GTS_PDFXVersion (PDF/X-1:2001)
        /GTS_PDFXConformance (PDF/X-1a:2001)
        /DOCINFO pdfmark
    POSTSCRIPT

    path = File.join(OUTPUT_DIR, 'PDFX_def.ps')
    File.write(path, pdfx_def)
    path
  end

  def convert_to_pdfx
    puts "\n[6/6] Converting to PDF/X-1a:2001 (CMYK)..."

    icc = cmyk_icc_profile
    if icc.nil?
      warn "  ⚠ No CMYK ICC profile found; falling back to plain CMYK conversion"
      return convert_to_cmyk_only
    end
    puts "  Using ICC profile: #{icc}"

    pdfx_def = generate_pdfx_def(icc)
    rgb_pdf = final_pdf.sub('.pdf', '_rgb.pdf')
    FileUtils.mv(final_pdf, rgb_pdf)

    cmd = [
      'gs',
      '-dPDFX',
      '-dBATCH',
      '-dNOPAUSE',
      '-dNOOUTERSAVE',
      '-dCompatibilityLevel=1.3',
      '-dPDFSETTINGS=/prepress',
      '-sColorConversionStrategy=CMYK',
      '-dProcessColorModel=/DeviceCMYK',
      '-dRenderIntent=3',
      "-sOutputICCProfile=#{shell_escape(icc)}",
      '-dAutoFilterColorImages=false',
      '-dColorImageFilter=/FlateEncode',
      '-dDownsampleColorImages=true',
      '-dColorImageResolution=300',
      '-dAutoFilterGrayImages=false',
      '-dGrayImageFilter=/FlateEncode',
      '-dDownsampleGrayImages=true',
      '-dGrayImageResolution=300',
      '-sDEVICE=pdfwrite',
      "-sOutputFile=#{shell_escape(final_pdf)}",
      shell_escape(pdfx_def),
      shell_escape(rgb_pdf)
    ].join(' ')

    success = system(cmd)

    if success && File.exist?(final_pdf) && File.size(final_pdf) > 1024
      FileUtils.rm(rgb_pdf)
      puts "  ✓ Converted to PDF/X-1a:2001 (CMYK)"
    else
      warn "  ⚠ PDF/X-1a conversion failed; falling back to plain CMYK"
      FileUtils.mv(rgb_pdf, final_pdf) if File.exist?(rgb_pdf)
      convert_to_cmyk_only
    end
  end

  # Plain-CMYK fallback (no PDF/X metadata, but still printable).
  def convert_to_cmyk_only
    rgb_pdf = final_pdf.sub('.pdf', '_rgb.pdf')
    FileUtils.mv(final_pdf, rgb_pdf) unless File.exist?(rgb_pdf)

    cmd = [
      'gs',
      '-dBATCH',
      '-dNOPAUSE',
      '-dNOOUTERSAVE',
      '-dCompatibilityLevel=1.4',
      '-dPDFSETTINGS=/prepress',
      '-sColorConversionStrategy=CMYK',
      '-dProcessColorModel=/DeviceCMYK',
      '-dAutoFilterColorImages=false',
      '-dColorImageFilter=/FlateEncode',
      '-dDownsampleColorImages=true',
      '-dColorImageResolution=300',
      '-dAutoFilterGrayImages=false',
      '-dGrayImageFilter=/FlateEncode',
      '-dDownsampleGrayImages=true',
      '-dGrayImageResolution=300',
      '-sDEVICE=pdfwrite',
      "-sOutputFile=#{shell_escape(final_pdf)}",
      shell_escape(rgb_pdf)
    ].join(' ')

    success = system(cmd)

    if success && File.exist?(final_pdf) && File.size(final_pdf) > 1024
      FileUtils.rm(rgb_pdf) if File.exist?(rgb_pdf)
      puts "  ✓ Converted to CMYK (no PDF/X metadata)"
    else
      warn "  ✗ CMYK conversion failed; keeping RGB version (NOT print-ready)"
      FileUtils.mv(rgb_pdf, final_pdf) if File.exist?(rgb_pdf)
    end
  end

  # Convert to true grayscale (K-only) for B&W print. KDP and IngramSpark
  # bill any C/M/Y ink as colour pages, so neutral-themed RGB diagrams or
  # rich-black text would silently inflate per-copy print cost.
  def convert_to_grayscale
    puts "\n[6/6] Converting to grayscale (DeviceGray, K-only)..."

    rgb_pdf = final_pdf.sub('.pdf', '_rgb.pdf')
    FileUtils.mv(final_pdf, rgb_pdf)

    cmd = [
      'gs',
      '-dBATCH',
      '-dNOPAUSE',
      '-dNOOUTERSAVE',
      '-dCompatibilityLevel=1.4',
      '-dPDFSETTINGS=/prepress',
      '-sColorConversionStrategy=Gray',
      '-dProcessColorModel=/DeviceGray',
      '-dOverrideICC=true',
      '-dAutoFilterGrayImages=false',
      '-dGrayImageFilter=/FlateEncode',
      '-dDownsampleGrayImages=true',
      '-dGrayImageResolution=300',
      '-dAutoFilterMonoImages=false',
      '-dMonoImageFilter=/CCITTFaxEncode',
      '-sDEVICE=pdfwrite',
      "-sOutputFile=#{shell_escape(final_pdf)}",
      shell_escape(rgb_pdf)
    ].join(' ')

    success = system(cmd)

    if success && File.exist?(final_pdf) && File.size(final_pdf) > 1024
      FileUtils.rm(rgb_pdf) if File.exist?(rgb_pdf)
      puts "  ✓ Converted to grayscale (DeviceGray, K-only)"
    else
      warn "  ✗ Grayscale conversion failed; keeping previous version"
      FileUtils.mv(rgb_pdf, final_pdf) if File.exist?(rgb_pdf)
    end
  end

  # IngramSpark requires even page counts. If the generated PDF is odd, append
  # a single blank page at the same trim size (7×10 = 504×720 pts).
  def ensure_even_page_count
    count = pdf_page_count(final_pdf)
    return if count.zero?

    if count.even?
      puts "  ✓ Page count #{count} is already even"
      return
    end

    puts "\n[5b/6] Appending blank page (#{count} → #{count + 1}) for printer even-count requirement..."

    blank_pdf = File.join(OUTPUT_DIR, 'blank_page.pdf')
    # Use PostScript directly to set the page size in points and emit a blank
    # page. This is more reliable than -g (which interacts with default DPI).
    blank_cmd = [
      'gs', '-sDEVICE=pdfwrite', '-dBATCH', '-dNOPAUSE',
      "-sOutputFile=#{shell_escape(blank_pdf)}",
      '-c', '"<< /PageSize [504 720] >> setpagedevice showpage"'
    ].join(' ')

    unless system(blank_cmd) && File.exist?(blank_pdf)
      warn "  ⚠ Could not generate blank page; final count remains #{count} (ODD)"
      return
    end

    merged = final_pdf.sub('.pdf', '_with_blank.pdf')
    merge_cmd = [
      'gs', '-sDEVICE=pdfwrite', '-dBATCH', '-dNOPAUSE',
      "-sOutputFile=#{shell_escape(merged)}",
      shell_escape(final_pdf), shell_escape(blank_pdf)
    ].join(' ')

    if system(merge_cmd) && File.exist?(merged) && File.size(merged) > 1024
      FileUtils.mv(merged, final_pdf)
      FileUtils.rm(blank_pdf, force: true)
      new_count = pdf_page_count(final_pdf)
      puts "  ✓ Final page count: #{new_count}"
    else
      warn "  ⚠ Blank-page merge failed; final count remains #{count} (ODD)"
      FileUtils.rm(blank_pdf, force: true)
    end
  end

  def pdf_page_count(path)
    return 0 unless File.exist?(path)
    line = `pdfinfo #{shell_escape(path)} 2>/dev/null | grep '^Pages:'`
    line.split.last.to_i
  end

  def shell_escape(path)
    "'#{path.gsub("'", "'\\\\''")}'"
  end
end

# Run the builder
# Usage: ruby scripts/build_pdf.rb         (colour)
#        ruby scripts/build_pdf.rb --bw    (black & white)
if __FILE__ == $PROGRAM_NAME
  bw = ARGV.include?('--bw')
  strict = ARGV.include?('--strict')
  builder = BookPDFBuilder.new(bw: bw, strict: strict)
  builder.build
end

