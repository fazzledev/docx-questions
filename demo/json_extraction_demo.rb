#!/usr/bin/env ruby#!/usr/bin/env ruby

# frozen_string_literal: true# frozen_string_literal: true



# Demo script for JSON question extraction# Demo script for JSON question extraction

require_relative '../lib/docx/questions'require_relative '../lib/docx/questions'



puts "📄 DOCX Questions JSON Extraction Demo"puts "📄 DOCX Questions JSON Extraction Demo"

puts "=" * 40puts "=" * 40



# Test with the sample DOCX file# Test with the sample DOCX file

docx_path = File.join(__dir__, '..', 'test', 'fixtures', 'files', 'p6.docx')docx_path = File.join(__dir__, '..', 'test', 'fixtures', 'files', 'p6.docx')



if File.exist?(docx_path)if File.exist?(docx_path)

  puts "\n🔍 Extracting questions from: #{File.basename(docx_path)}"  puts "\n🔍 Extracting questions from: #{File.basename(docx_path)}"



  # Extract as Ruby objects for inspection  # Extract as Ruby objects for inspection

  questions = Docx::Questions.extract_questions(docx_path)  questions = Docx::Questions.extract_questions(docx_path)



  puts "\n📊 Extraction Results:"  puts "\n📊 Extraction Results:"

  puts "  Total questions found: #{questions.length}"  puts "  Total questions found: #{questions.length}"



  questions.each_with_index do |question, index|  questions.each_with_index do |question, index|

    puts "\n📝 Question #{index + 1}:"    puts "\n📝 Question #{index + 1}:"

    puts "  Text preview: #{question[:text][0..100]}#{'...' if question[:text].length > 100}"    puts "  Text preview: #{question[:text][0..100]}#{'...' if question[:text].length > 100}"

    puts "  Full length: #{question[:text].length} characters"    puts "  Full length: #{question[:text].length} characters"

    puts "  Contains images: #{question[:text].include?('<img>')}"    puts "  Contains images: #{question[:text].include?('<img>')}"

    puts "  Contains MathML: #{question[:text].include?('<math>')}"    puts "  Contains MathML: #{question[:text].include?('<math>')}"

  end  end



  # Extract as JSON string  # Extract as JSON string

  puts "\n🔧 JSON Output Sample:"  puts "\n🔧 JSON Output Sample:"

  json_output = Docx::Questions.extract_questions_json(docx_path)  json_output = Docx::Questions.extract_questions_json(docx_path)

  parsed_json = JSON.parse(json_output)  parsed_json = JSON.parse(json_output)



  # Show first question in pretty JSON format  # Show first question in pretty JSON format

  if parsed_json.length > 0  if parsed_json.length > 0

    puts JSON.pretty_generate(parsed_json.first)    puts JSON.pretty_generate(parsed_json.first)

  end  end



  # Test with multiple questions file  # Test with multiple questions file

  multi_docx_path = File.join(__dir__, '..', 'test', 'fixtures', 'files', 'Phy-3ques.docx')  multi_docx_path = File.join(__dir__, '..', 'test', 'fixtures', 'files', 'Phy-3ques.docx')

  if File.exist?(multi_docx_path)  if File.exist?(multi_docx_path)

    puts "\n\n🔬 Testing Multiple Questions File: #{File.basename(multi_docx_path)}"    puts "\n\n🔬 Testing Multiple Questions File: #{File.basename(multi_docx_path)}"

    multi_questions = Docx::Questions.extract_questions(multi_docx_path)    multi_questions = Docx::Questions.extract_questions(multi_docx_path)

    puts "  Questions found: #{multi_questions.length}"    puts "  Questions found: #{multi_questions.length}"



    multi_questions.each_with_index do |question, index|    multi_questions.each_with_index do |question, index|

      question_number = question[:text].match(/^(\d+)\./)[1] if question[:text].match(/^(\d+)\./)      question_number = question[:text].match(/^(\d+)\./)[1] if question[:text].match(/^(\d+)\./)

      puts "  #{index + 1}. Question #{question_number}: #{question[:text][0..60]}..."      puts "  #{index + 1}. Question #{question_number}: #{question[:text][0..60]}..."

    end    end

  end

    # Check if we have the pre-generated JSON file for comparison

  puts "\n✅ JSON extraction complete!"    json_file_path = File.join(__dir__, '..', 'test', 'fixtures', 'files', 'Phy-3ques_questions.json')

  puts "💡 Use Docx::Questions.extract_questions_json(path) for JSON string output"    if File.exist?(json_file_path)

  puts "💡 Use Docx::Questions.extract_questions(path) for Ruby object output"      puts "\n📄 Pre-generated JSON file found: #{File.basename(json_file_path)}"

  puts "💡 Use Docx::Questions.extract_text(path) for backward-compatible text output"      saved_json = JSON.parse(File.read(json_file_path))

else      puts "  Saved JSON contains #{saved_json.length} questions"

  puts "\n❌ Sample DOCX file not found at: #{docx_path}"    end

  puts "Please ensure test fixtures are available."  end

end
  puts "\n✅ JSON extraction complete!"
  puts "💡 Use Docx::Questions.extract_questions_json(path) for JSON string output"
  puts "💡 Use Docx::Questions.extract_questions(path) for Ruby object output"
  puts "💡 Use Docx::Questions.extract_text(path) for backward-compatible text output"
else
  puts "\n❌ Sample DOCX file not found at: #{docx_path}"
  puts "Please ensure test fixtures are available."
end
