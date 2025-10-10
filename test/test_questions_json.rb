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

    def test_strips_question_numbers_while_preserving_math
      docx_path = File.join(__dir__, "fixtures", "files", "Phy-3ques.docx")
      
      # Extract questions as JSON
      json_output = Docx::Questions.extract_questions_json(docx_path)
      questions = JSON.parse(json_output)
      
      # Verify question numbers are stripped
      questions.each do |question|
        # Questions should not start with digits followed by a period
        refute_match(/^\d+\./, question["text"], "Question should not start with number")
      end
      
      # Verify content is still intact - should start with meaningful text
      assert questions[0]["text"].start_with?("The velocity"), "First question should start with 'The velocity'"
      assert questions[1]["text"].start_with?("The charge"), "Second question should start with 'The charge'"
      assert questions[2]["text"].start_with?("Assertion"), "Third question should start with 'Assertion'"
      
      # Verify mathematical symbols are still preserved
      math_questions = questions.select { |q| q["text"].include?("<math>") }
      assert_equal 2, math_questions.length, "Should preserve mathematical symbols in 2 questions"
    end

    def test_structured_question_parsing_with_mathematical_symbols
      docx_path = File.join(__dir__, "fixtures", "files", "Phy-3ques.docx")
      
      # Extract questions as array (structured format)
      questions = Docx::Questions.extract_questions(docx_path)
      
      # Test first question structure
      q1 = questions[0]
      assert_kind_of Hash, q1
      assert q1.key?(:qstem), "Should have qstem"
      assert q1.key?(:options), "Should have options"
      assert q1.key?(:anskey), "Should have anskey"  
      assert q1.key?(:hint), "Should have hint"
      assert q1.key?(:text), "Should have original text for compatibility"
      
      # Test qstem contains mathematical symbols
      assert q1[:qstem].include?("<math>"), "Question stem should contain mathematical symbols"
      assert q1[:qstem].include?("<msub>"), "Question stem should contain subscripts"
      
      # Test options parsing
      assert_kind_of Array, q1[:options]
      assert_equal 4, q1[:options].length, "Should have 4 options"
      
      # Test options contain mathematical symbols (including block math)
      math_options = q1[:options].select { |opt| opt[:text].include?("math>") }
      assert_equal 4, math_options.length, "All options should contain mathematical symbols"
      
      # Test answer key
      assert_equal "c", q1[:anskey], "Answer key should be 'c'"
      
      # Test hint contains mathematical symbols
      assert q1[:hint].include?("<math>"), "Hint should contain mathematical symbols"
    end

    def test_structured_parsing_preserves_superscripts
      docx_path = File.join(__dir__, "fixtures", "files", "Phy-3ques.docx")
      
      # Extract questions
      questions = Docx::Questions.extract_questions(docx_path)
      
      # Test second question has superscripts in options
      q2 = questions[1]
      superscript_options = q2[:options].select { |opt| opt[:text].include?("<msup>") }
      assert_equal 4, superscript_options.length, "All options should contain superscripts"
      
      # Verify specific superscript content
      assert q2[:options][0][:text].include?("<mn>27</mn>"), "First option should contain exponent 27"
      
      # Test hint has superscripts and complex mathematical expressions
      assert q2[:hint].include?("<msup>"), "Hint should contain superscripts"
      assert q2[:hint].include?("<mfrac>"), "Hint should contain fractions"
    end
  end
end
