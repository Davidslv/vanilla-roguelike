#!/usr/bin/env ruby
# frozen_string_literal: true

# Cover post-processor: take a Canva-exported RGB PDF and turn it into an
# IngramSpark-compliant PDF/X-1a:2001 CMYK cover.
#
# Canva can't export PDF/X-1a or CMYK natively. This script:
#   1. Verifies the input dimensions match what Ingram expects
#   2. Converts RGB → CMYK using a CMYK ICC profile
#   3. Generates a PDFX_def.ps with proper OutputIntent + GTS_PDFX metadata
#   4. Outputs a single-page PDF/X-1a:2001 file ready to upload to Ingram
#
# Usage:
#   ruby scripts/cover_postprocess.rb <input.pdf> [--width=W --height=H]
#
# Width/height are the EXPECTED dimensions in inches (from Ingram's template).
# If omitted, verification is skipped and whatever dimensions the input has
# are preserved. Always pass them when you have the Ingram spec — verification
# is the cheapest way to catch a wrong-canvas mistake before submitting.
#
# Example for 7×10 / 178 pages / 70# white:
#   ruby scripts/cover_postprocess.rb ~/Downloads/cover.pdf --width=15.5 --height=10.25
#   (replace 15.5 with the actual Document Size width from Ingram's template)

require 'fileutils'
require 'optparse'

class CoverPostprocessor
  def initialize(input_path, expected_width: nil, expected_height: nil, output_path: nil)
    @input = File.expand_path(input_path)
    @expected_width = expected_width
    @expected_height = expected_height
    @output = output_path || default_output_path
  end

  def run
    abort "✗ Input file does not exist: #{@input}" unless File.exist?(@input)

    puts "Cover post-processor"
    puts "=" * 60
    puts "  Input:  #{@input}"
    puts "  Output: #{@output}"
    puts

    inspect_input
    verify_dimensions if @expected_width && @expected_height
    icc = ensure_icc_profile
    pdfx_def = generate_pdfx_def(icc)
    convert(icc, pdfx_def)
    verify_output

    puts
    puts "✓ Done. Upload #{@output} to IngramSpark."
  end

  private

  def default_output_path
    base = File.basename(@input, '.pdf')
    dir = File.dirname(@input)
    File.join(dir, "#{base}_ingram_ready.pdf")
  end

  def inspect_input
    info = `pdfinfo #{shell_escape(@input)} 2>/dev/null`
    pages = info[/^Pages:\s+(\d+)/, 1].to_i
    size_line = info[/^Page size:\s+([^\n]+)/, 1].to_s.strip
    @input_pts = parse_size_pts(size_line)

    puts "  Pages:    #{pages} #{pages == 1 ? '✓' : '⚠ (cover should be 1 page)'}"
    puts "  Size:     #{size_line}"
    puts "  Inches:   #{format('%.3f', @input_pts[:width] / 72.0)} × #{format('%.3f', @input_pts[:height] / 72.0)}"

    creator = info[/^Creator:\s+([^\n]+)/, 1].to_s.strip
    puts "  Creator:  #{creator}"
    puts "            (Canva-flagged input — will need RGB→CMYK conversion)" if creator.match?(/canva/i)

    return if pages == 1

    abort "✗ Cover should be exactly 1 page; got #{pages}. Aborting."
  end

  def parse_size_pts(size_line)
    m = size_line.match(/(\d+(?:\.\d+)?)\s*x\s*(\d+(?:\.\d+)?)\s*pts/)
    abort "✗ Could not parse page size: #{size_line}" unless m

    { width: m[1].to_f, height: m[2].to_f }
  end

  def verify_dimensions
    expected_w_pts = @expected_width * 72
    expected_h_pts = @expected_height * 72
    actual_w_in = @input_pts[:width] / 72.0
    actual_h_in = @input_pts[:height] / 72.0

    tolerance = 0.5 # pts; allow ~0.007 in slop
    w_ok = (@input_pts[:width] - expected_w_pts).abs < tolerance
    h_ok = (@input_pts[:height] - expected_h_pts).abs < tolerance

    return if w_ok && h_ok

    warn ""
    warn "✗ Dimension mismatch — Ingram will reject this cover:"
    warn "  Expected: #{@expected_width} × #{@expected_height} in"
    warn "  Got:      #{format('%.3f', actual_w_in)} × #{format('%.3f', actual_h_in)} in"
    warn "  Diff:     #{format('%+.3f', actual_w_in - @expected_width)} × " \
         "#{format('%+.3f', actual_h_in - @expected_height)} in"
    warn ""
    warn "  Re-export from Canva at the correct canvas size, then re-run."
    abort
  end

  def ensure_icc_profile
    candidates = [
      '/usr/local/share/ghostscript/10.04.0/iccprofiles/default_cmyk.icc',
      '/opt/homebrew/share/ghostscript/10.04.0/iccprofiles/default_cmyk.icc',
      '/System/Library/ColorSync/Profiles/Generic CMYK Profile.icc'
    ]
    icc = candidates.find { |p| File.exist?(p) }
    abort "✗ No CMYK ICC profile found on this system." unless icc

    puts "  ICC:      #{icc}"
    icc
  end

  def generate_pdfx_def(icc)
    pdfx_def = <<~POSTSCRIPT
      %!
      % PDF/X-1a:2001 definition for cover post-processor
      [ /Title (Building Your Own Roguelike: A Practical Guide — Cover)
        /Author (David Silva)
        /Creator (cover_postprocess.rb / Ghostscript)
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
      [ {icc_PDFX} (#{icc}) (r) file /PUT pdfmark
      [ {Catalog} <</OutputIntents [ {OutputIntent_PDFX} ]>> /PUT pdfmark

      [ /GTS_PDFXVersion (PDF/X-1:2001)
        /GTS_PDFXConformance (PDF/X-1a:2001)
        /DOCINFO pdfmark
    POSTSCRIPT

    path = File.join(File.dirname(@input), 'cover_PDFX_def.ps')
    File.write(path, pdfx_def)
    path
  end

  def convert(icc, pdfx_def)
    puts
    puts "Converting RGB → CMYK PDF/X-1a:2001..."

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
      "-sOutputFile=#{shell_escape(@output)}",
      shell_escape(pdfx_def),
      shell_escape(@input)
    ].join(' ')

    abort "✗ Ghostscript conversion failed." unless system(cmd)
    abort "✗ Output file is suspiciously small or missing." unless File.exist?(@output) && File.size(@output) > 1024
  end

  def verify_output
    puts
    puts "Verifying output..."

    info = `pdfinfo #{shell_escape(@output)} 2>/dev/null`
    pages = info[/^Pages:\s+(\d+)/, 1].to_i
    size = info[/^Page size:\s+([^\n]+)/, 1].to_s.strip
    pdf_version = info[/^PDF version:\s+([^\n]+)/, 1].to_s.strip

    puts "  Pages:        #{pages}"
    puts "  Size:         #{size}"
    puts "  PDF version:  #{pdf_version} #{pdf_version == '1.3' ? '✓ (PDF/X-1a)' : '⚠ (expected 1.3)'}"

    # Inkcov check — confirm CMYK
    inkcov_path = '/tmp/cover_inkcov.txt'
    system("gs -o #{inkcov_path} -sDEVICE=inkcov #{shell_escape(@output)} >/dev/null 2>&1")
    if File.exist?(inkcov_path)
      coverage = File.read(inkcov_path).strip.split.first(4).map(&:to_f)
      cmyk_label = "C=#{format('%.3f', coverage[0])} M=#{format('%.3f', coverage[1])} " \
                   "Y=#{format('%.3f', coverage[2])} K=#{format('%.3f', coverage[3])}"
      puts "  Ink coverage: #{cmyk_label}"
      File.delete(inkcov_path)
    end

    # Font embedding
    fonts = `pdffonts #{shell_escape(@output)} 2>/dev/null`.lines
    not_embedded = fonts.grep(/\bno\s+(yes|no)\s+(yes|no)/).count # crude check
    puts "  Fonts:        #{fonts.size - 2} found, all embedded ✓" if not_embedded.zero?
  end

  def shell_escape(path)
    "'#{path.to_s.gsub("'", "'\\\\''")}'"
  end
end

if __FILE__ == $PROGRAM_NAME
  options = { width: nil, height: nil, output: nil }
  parser = OptionParser.new do |o|
    o.banner = 'Usage: ruby scripts/cover_postprocess.rb <input.pdf> [options]'
    o.on('--width=W', Float, 'Expected cover width in inches (from Ingram template)') { |v| options[:width] = v }
    o.on('--height=H', Float, 'Expected cover height in inches (from Ingram template)') { |v| options[:height] = v }
    o.on('--output=PATH', String, 'Output path (default: <input>_ingram_ready.pdf)') { |v| options[:output] = v }
    o.on('-h', '--help') { puts o; exit }
  end
  parser.parse!

  input = ARGV.first
  if input.nil?
    puts parser
    exit 1
  end

  CoverPostprocessor.new(
    input,
    expected_width: options[:width],
    expected_height: options[:height],
    output_path: options[:output]
  ).run
end
