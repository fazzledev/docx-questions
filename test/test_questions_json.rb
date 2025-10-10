# frozen_string_literal: true

require "test_helper"

module Docx
  class TestQuestionsJson < Minitest::Test
    def test_extracts_questions_as_json_string
      docx_path = File.join(__dir__, "fixtures", "files", "p6.docx") 

      # Extract questions as JSON string
      json_output = Docx::Questions.extract_questions_json(docx_path)

      # Verify it's valid JSON
      questions = JSON.parse(json_output)

      # Should be an array
      assert_kind_of Array, questions

      # Should have at least one question
      assert questions.length > 0

      # Each question should have the expected structure
      questions.each do |question|
        assert question.key?("text")
        assert_kind_of String, question["text"]
      end
    end

    def test_json_preserves_mathematical_content  
      docx_path = File.join(__dir__, "fixtures", "files", "p6.docx")
      
      # Extract questions as JSON
      json_output = Docx::Questions.extract_questions_json(docx_path)
      questions = JSON.parse(json_output)
      
      # Find question with mathematical symbols
      math_question = questions.find { |q| q["text"].include?("<math>") }
      refute_nil math_question, "Should find question with mathematical symbols"
      
      # Verify MathML content is preserved
      assert math_question["text"].include?("<msub>"), "Should preserve subscripts in MathML"
      assert math_question["text"].include?("<mi>v</mi>"), "Should preserve mathematical variables"
      assert math_question["text"].include?("<mn>0</mn>"), "Should preserve mathematical numbers"
    end

    def test_extract_questions_returns_array
      docx_path = File.join(__dir__, "fixtures", "files", "p6.docx")
      
      # Extract questions as array
      questions = Docx::Questions.extract_questions(docx_path)
      
      # Should be an array
      assert_kind_of Array, questions
      
      # Should have at least one question
      assert questions.length > 0
      
      # Each question should be a hash with symbol keys
      questions.each do |question|
        assert_kind_of Hash, question
        assert question.key?(:text)
      end
    end

    def test_extract_multiple_questions_with_mathematical_symbols
      docx_path = File.join(__dir__, "fixtures", "files", "Phy-3ques.docx")
      
      # Extract questions as JSON
      json_output = Docx::Questions.extract_questions_json(docx_path)
      questions = JSON.parse(json_output)
      
      # Should have exactly 3 questions
      assert_equal 3, questions.length
      
      # Find questions with different types of mathematical symbols
      subscript_question = questions.find { |q| q["text"].include?("<msub>") }
      superscript_question = questions.find { |q| q["text"].include?("<msup>") }
      
      refute_nil subscript_question, "Should find question with subscripts"
      refute_nil superscript_question, "Should find question with superscripts"
      
      # Verify specific mathematical content
      assert subscript_question["text"].include?("<mi>v</mi>"), "Should preserve variables in subscripts"
      assert superscript_question["text"].include?("<mn>10</mn>"), "Should preserve numbers in superscripts"
    end
  end
end
