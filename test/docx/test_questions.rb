# frozen_string_literal: true

require "test_helper"

module Docx
  class TestQuestions < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::Docx::Questions::VERSION
    end

    def test_extracts_text_from_docx_file
      docx_path = File.join(__dir__, "..", "fixtures", "files", "p6.docx")
      expected_text_path = File.join(__dir__, "..", "fixtures", "files", "p6.txt")

      # Read expected text content
      expected_text = File.read(expected_text_path).strip

      # Extract text from DOCX file
      extracted_text = Docx::Questions.extract_text(docx_path)

      # Assert that the extracted text matches the expected text
      assert_equal expected_text, extracted_text.strip
    end

    def test_extracts_multiple_questions_from_docx_file
      docx_path = File.join(__dir__, "..", "fixtures", "files", "Phy-3ques.docx")
      expected_text_path = File.join(__dir__, "..", "fixtures", "files", "Phy-3ques.txt")

      # Read expected text content
      expected_text = File.read(expected_text_path).strip

      # Extract text from DOCX file
      extracted_text = Docx::Questions.extract_text(docx_path)

      # Assert that the extracted text matches the expected text
      assert_equal expected_text, extracted_text.strip
    end
  end
end
