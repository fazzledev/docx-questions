# frozen_string_literal: true

require "test_helper"
require "pathname"

module Docx
  class TestQuestions < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Docx::Questions::VERSION
    end

    def test_extracts_json_from_docx_file
      docx_path = File.join(__dir__, "..", "fixtures", "files", "p6.docx")
      expected_fixture_dir = File.join(__dir__, "..", "fixtures", "files", "p6")

      # Extract zip from DOCX file
      extracted_zip = Docx::Questions.extract_json(docx_path)
      
      # Compare extracted zip contents with expected fixture folders
      compare_zip_with_fixture_folders(extracted_zip, expected_fixture_dir)
    end

    def test_extracts_multiple_questions_json_from_docx_file
      docx_path = File.join(__dir__, "..", "fixtures", "files", "Phy-3ques.docx")
      expected_fixture_dir = File.join(__dir__, "..", "fixtures", "files", "Phy-3ques")

      # Extract zip from DOCX file
      extracted_zip = Docx::Questions.extract_json(docx_path)
      
      # Compare extracted zip contents with expected fixture folders
      compare_zip_with_fixture_folders(extracted_zip, expected_fixture_dir)
    end

    private

    def compare_zip_with_fixture_folders(zip_content, fixture_dir)
      require 'zip'
      require 'tempfile'
      
      # Write zip to temp file
      temp_zip = Tempfile.new(['test', '.zip'])
      temp_zip.write(zip_content)
      temp_zip.close
      
      # Extract zip contents
      extracted_contents = {}
      Zip::File.open(temp_zip.path) do |zip_file|
        zip_file.each do |entry|
          next if entry.directory?
          content = entry.get_input_stream.read
          extracted_contents[entry.name] = content
        end
      end
      
      # Compare with fixture folders (JSON files)
      Dir.glob(File.join(fixture_dir, "**", "*.json")).each do |fixture_file|
        relative_path = Pathname.new(fixture_file).relative_path_from(Pathname.new(fixture_dir)).to_s
        expected_content = File.read(fixture_file)
        
        assert extracted_contents.key?(relative_path), "Missing file in zip: #{relative_path}"
        
        # Normalize content for comparison (handle encoding differences)
        expected_normalized = expected_content.strip
        actual_normalized = extracted_contents[relative_path].force_encoding('UTF-8').strip
        
        assert_equal expected_normalized, actual_normalized, "Content mismatch for #{relative_path}"
      end
      
      # Compare image files if they exist
      Dir.glob(File.join(fixture_dir, "**", "images", "*")).each do |fixture_file|
        next if File.directory?(fixture_file)
        relative_path = Pathname.new(fixture_file).relative_path_from(Pathname.new(fixture_dir)).to_s
        expected_content = File.read(fixture_file, mode: 'rb')
        
        assert extracted_contents.key?(relative_path), "Missing image file in zip: #{relative_path}"
        
        # Compare binary content for images
        assert_equal expected_content, extracted_contents[relative_path], "Image content mismatch for #{relative_path}"
      end
      
      # Ensure no extra files in zip
      extracted_contents.each do |zip_path, _|
        fixture_file = File.join(fixture_dir, zip_path)
        assert File.exist?(fixture_file), "Extra file in zip: #{zip_path}"
      end
      
      temp_zip.unlink
    end
  end
end
