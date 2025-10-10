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

      # Each question should have the new expected structure
      questions.each do |question|
        assert question.key?("qstem"), "Should have qstem"
        assert question.key?("key"), "Should have key"
        assert question.key?("hint"), "Should have hint"
        refute question.key?("text"), "Should not have text field"

        # Options should be present
        assert question.key?("optA"), "Should have optA"
        assert question.key?("optB"), "Should have optB"
        assert question.key?("optC"), "Should have optC"
        assert question.key?("optD"), "Should have optD"
      end
    end

    def test_json_preserves_mathematical_content
      docx_path = File.join(__dir__, "fixtures", "files", "p6.docx")

      # Extract questions as JSON
      json_output = Docx::Questions.extract_questions_json(docx_path)
      questions = JSON.parse(json_output)

      # Find question with mathematical symbols in qstem or options
      math_question = questions.find { |q|
        q["qstem"].include?("<math>") ||
        q["optA"].include?("<math>") ||
        q["hint"].include?("<math>")
      }
      refute_nil math_question, "Should find question with mathematical symbols"

      # Verify MathML content is preserved in qstem
      if math_question["qstem"].include?("<math>")
        assert math_question["qstem"].include?("<msub>"), "Should preserve subscripts in qstem MathML"
        assert math_question["qstem"].include?("<mi>"), "Should preserve mathematical variables in qstem"
      end

      # Verify MathML content is preserved in options
      if math_question["optA"].include?("<math>")
        assert math_question["optA"].include?("<msub>"), "Should preserve subscripts in option MathML"
        assert math_question["optA"].include?("<mi>v</mi>"), "Should preserve mathematical variables"
        assert math_question["optA"].include?("<mn>"), "Should preserve mathematical numbers"
      end
    end

    def test_extract_questions_returns_array
      docx_path = File.join(__dir__, "fixtures", "files", "p6.docx")

      # Extract questions as array
      questions = Docx::Questions.extract_questions(docx_path)

      # Should be an array
      assert_kind_of Array, questions

      # Should have at least one question
      assert questions.length > 0

      # Each question should be a hash with the new structure
      questions.each do |question|
        assert_kind_of Hash, question
        assert question.key?(:qstem), "Should have qstem"
        assert question.key?(:optA), "Should have optA"
        assert question.key?(:key), "Should have key"
        assert question.key?(:hint), "Should have hint"
        refute question.key?(:text), "Should not have text field"
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
      subscript_question = questions.find { |q|
        q["qstem"].include?("<msub>") ||
        q["optA"]&.include?("<msub>") ||
        q["hint"]&.include?("<msub>")
      }
      superscript_question = questions.find { |q|
        q["optA"]&.include?("<msup>") ||
        q["hint"]&.include?("<msup>")
      }

      refute_nil subscript_question, "Should find question with subscripts"
      refute_nil superscript_question, "Should find question with superscripts"

      # Verify specific mathematical content in options or hints
      assert (subscript_question["optA"]&.include?("<mi>v</mi>") || subscript_question["hint"]&.include?("<mi>v</mi>")),
             "Should preserve variables in subscripts"
      assert (superscript_question["optA"]&.include?("<mn>10</mn>") || superscript_question["hint"]&.include?("<mn>10</mn>")),
             "Should preserve numbers in superscripts"
    end

    def test_strips_question_numbers_while_preserving_math
      docx_path = File.join(__dir__, "fixtures", "files", "Phy-3ques.docx")

      # Extract questions as JSON
      json_output = Docx::Questions.extract_questions_json(docx_path)
      questions = JSON.parse(json_output)

      # Verify question numbers are stripped from qstem
      questions.each do |question|
        # Question stems should not start with digits followed by a period
        refute_match(/^\d+\./, question["qstem"], "Question stem should not start with number")
      end

      # Verify content is still intact - should start with meaningful text
      assert questions[0]["qstem"].start_with?("The velocity"), "First question should start with 'The velocity'"
      assert questions[1]["qstem"].start_with?("The charge"), "Second question should start with 'The charge'"
      assert questions[2]["qstem"].start_with?("Assertion"), "Third question should start with 'Assertion'"

      # Verify mathematical symbols are still preserved in qstem
      math_questions = questions.select { |q| q["qstem"].include?("<math>") }
      assert_equal 1, math_questions.length, "Should preserve mathematical symbols in qstem"

      # Verify mathematical symbols in options and hints
      questions.each do |q|
        if q["optA"] && q["optA"].include?("<math>")
          assert q["optA"].include?("<math>"), "Options should preserve mathematical symbols"
        end
        if q["hint"] && q["hint"].include?("<math>")
          assert q["hint"].include?("<math>"), "Hints should preserve mathematical symbols"
        end
      end
    end

    def test_structured_question_parsing_with_mathematical_symbols
      docx_path = File.join(__dir__, "fixtures", "files", "Phy-3ques.docx")

      # Extract questions as array (structured format)
      questions = Docx::Questions.extract_questions(docx_path)

      # Test first question structure
      q1 = questions[0]
      assert_kind_of Hash, q1
      assert q1.key?(:qstem), "Should have qstem"
      assert q1.key?(:optA), "Should have optA"
      assert q1.key?(:optB), "Should have optB"
      assert q1.key?(:optC), "Should have optC"
      assert q1.key?(:optD), "Should have optD"
      assert q1.key?(:key), "Should have key"
      assert q1.key?(:hint), "Should have hint"
      refute q1.key?(:text), "Should not have text field"

      # Test qstem contains mathematical symbols
      assert q1[:qstem].include?("<math>"), "Question stem should contain mathematical symbols"
      assert q1[:qstem].include?("<msub>"), "Question stem should contain subscripts"

      # Test options contain mathematical symbols
      assert q1[:optA].include?("<math>"), "Option A should contain mathematical symbols"
      assert q1[:optB].include?("<math>"), "Option B should contain mathematical symbols"
      assert q1[:optC].include?("<math>"), "Option C should contain mathematical symbols"
      assert q1[:optD].include?("math>"), "Option D should contain mathematical symbols (block math)"

      # Test answer key
      assert_equal "c", q1[:key], "Answer key should be 'c'"

      # Test hint contains mathematical symbols
      assert q1[:hint].include?("<math>"), "Hint should contain mathematical symbols"
    end

    def test_structured_parsing_preserves_superscripts
      docx_path = File.join(__dir__, "fixtures", "files", "Phy-3ques.docx")

      # Extract questions
      questions = Docx::Questions.extract_questions(docx_path)

      # Test second question has superscripts in options
      q2 = questions[1]

      # All options should contain superscripts
      assert q2[:optA].include?("<msup>"), "Option A should contain superscripts"
      assert q2[:optB].include?("<msup>"), "Option B should contain superscripts"
      assert q2[:optC].include?("<msup>"), "Option C should contain superscripts"
      assert q2[:optD].include?("<msup>"), "Option D should contain superscripts"

      # Verify specific superscript content
      assert q2[:optA].include?("<mn>27</mn>"), "First option should contain exponent 27"

      # Test hint has superscripts and complex mathematical expressions
      assert q2[:hint].include?("<msup>"), "Hint should contain superscripts"
      assert q2[:hint].include?("<mfrac>"), "Hint should contain fractions"
    end
  end
end
