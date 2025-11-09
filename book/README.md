# Building the Book PDF for Amazon KDP

This directory contains the source markdown files for "Building Your Own Roguelike: A Practical Guide". To convert these files to a PDF suitable for Amazon KDP publishing, follow these steps:

## Prerequisites

1. **Node.js and npm** - For rendering Mermaid diagrams
   ```bash
   # Check if installed
   node --version
   npm --version
   ```

2. **mermaid-cli** - For rendering Mermaid diagrams to images
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   # Or install locally: npm install
   ```

3. **Pandoc** - For converting Markdown to PDF
   ```bash
   # macOS
   brew install pandoc

   # Linux
   sudo apt-get install pandoc
   ```

4. **LaTeX** - Required by Pandoc for PDF generation
   ```bash
   # macOS (BasicTeX is smaller, faster to install)
   brew install --cask basictex

   # Or full MacTeX (larger but more complete)
   brew install --cask mactex

   # After installing BasicTeX, you may need to add to PATH:
   # export PATH="/Library/TeX/texbin:$PATH"
   ```

## Building the PDF

Run the build script:

```bash
ruby scripts/build_pdf.rb
```

The script will:
1. Check all dependencies are installed
2. Render all Mermaid diagrams to PNG images
3. Combine all markdown chapters in order
4. Convert to PDF with KDP-appropriate settings

The output will be in `book_output/Building_Your_Own_Roguelike.pdf`

## PDF Settings for Amazon KDP

The generated PDF uses these settings:
- **Page size**: 6" x 9" (trade paperback)
- **Margins**: 0.5" on all sides (KDP minimum)
- **Font size**: 11pt
- **Line spacing**: 1.2
- **Table of contents**: Automatically generated
- **Section numbering**: Enabled

## Amazon KDP Requirements

Before uploading to KDP, ensure:
- ✅ PDF is 6" x 9" or another supported size
- ✅ Margins are at least 0.5" on all sides
- ✅ All diagrams are visible and readable
- ✅ Page numbers are present (if desired)
- ✅ No blank pages at the end
- ✅ Text is readable and properly formatted

## Troubleshooting

### Diagrams not rendering
- Ensure `mmdc` is in your PATH: `which mmdc`
- Check that Node.js is installed: `node --version`
- Try rendering a diagram manually: `mmdc -i test.mmd -o test.png`

### PDF generation fails
- Verify LaTeX is installed: `which pdflatex` or `which xelatex`
- Check Pandoc version: `pandoc --version`
- Try generating a simple PDF: `echo "# Test" | pandoc -o test.pdf`

### Image paths not working
- The script should handle this automatically
- If issues persist, check that diagrams are in `book_output/diagrams/`

## Customization

To customize the PDF settings, edit `scripts/build_pdf.rb` and modify the `convert_to_pdf` method. Common changes:
- Page size (other KDP sizes: 5" x 8", 7" x 10", etc.)
- Font size and family
- Margins
- Line spacing
- Color scheme

## Output Structure

```
book_output/
├── diagrams/           # Rendered Mermaid diagrams (PNG)
├── combined.md         # Combined markdown (for debugging)
└── Building_Your_Own_Roguelike.pdf  # Final PDF
```


