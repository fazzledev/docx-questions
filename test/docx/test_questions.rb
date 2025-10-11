# frozen_string_literal: true

require "test_helper"

module Docx
  class TestQuestions < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Docx::Questions::VERSION
    end

    def test_extracts_json_from_docx_file
      docx_path = File.join(__dir__, "..", "fixtures", "files", "p6.docx")
      expected_json_path = File.join(__dir__, "..", "fixtures", "files", "p6.json")

      # Read expected JSON content
      expected_json = File.read(expected_json_path).strip

      # Extract JSON from DOCX file
      extracted_json = Docx::Questions.extract_json(docx_path)
      
      # Assert that the extracted JSON matches the expected JSON
      assert_equal expected_json, extracted_json.strip
    end

    def test_extracts_multiple_questions_json_from_docx_file
      docx_path = File.join(__dir__, "..", "fixtures", "files", "Phy-3ques.docx")
      expected_json_path = File.join(__dir__, "..", "fixtures", "files", "Phy-3ques.json")

      # Read expected JSON content
      expected_json = File.read(expected_json_path).strip

      # Extract JSON from DOCX file
      extracted_json = Docx::Questions.extract_json(docx_path)
      
      # Assert that the extracted JSON matches the expected JSON
      assert_equal expected_json, extracted_json.strip
    end
  end
end
