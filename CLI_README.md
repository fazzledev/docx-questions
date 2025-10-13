# Extract Questions CLI

A command-line interface for extracting questions from DOCX files and converting them to structured JSON format in zip files.

## Usage

```bash
./bin/extract_questions [options] <docx_file>
```

## Options

- `-o, --output FILE` - Specify output zip file path (default: same name as input file). If a directory is specified, uses the same filename as input. Automatically creates directories if they don't exist.
- `-d, --debug` - Enable debug mode for troubleshooting
- `-h, --help` - Show help message
- `-v, --version` - Show version information

## Examples

### Basic usage
```bash
./bin/extract_questions "document.docx"
# Creates document.zip in current directory
```

### Specify output file
```bash
./bin/extract_questions "document.docx" -o "output.zip"
# Creates output.zip in current directory
```

### Enable debug mode
```bash
./bin/extract_questions "document.docx" -d
# Shows debug information during extraction
```

### Extract to specific directory
```bash
./bin/extract_questions "document.docx" -o "tmp/"
# Creates document.zip in tmp directory (uses same filename as input)
```

### Extract to specific file with custom path
```bash
./bin/extract_questions "document.docx" -o "tmp/extracted_questions.zip"
# Creates extracted_questions.zip in tmp directory
```

### Extract to nested directory (auto-creates directories)
```bash
./bin/extract_questions "document.docx" -o "output/questions/chapter1/"
# Creates output/questions/chapter1/document.zip (auto-creates directories)
```

## Output Format

The CLI generates a zip file containing:
- One folder per question (`question_1/`, `question_2/`, etc.)
- Each folder contains a `question.json` file with:
  - `number`: Question number
  - `text`: Question text (with MathML for equations)
  - `options`: Multiple choice options (a, b, c, d)
  - `key`: Correct answer
  - `hint`: Detailed solution/explanation
- `images/` subfolder in question folders that contain images (if any)

## Features

- Extracts questions from DOCX files
- Converts mathematical equations to MathML format
- Extracts and preserves images
- Handles complex question formats
- Provides detailed extraction summary
- Debug mode for troubleshooting
- Error handling with helpful messages
