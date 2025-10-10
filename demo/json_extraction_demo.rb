#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for JSON question extraction
require_relative '../lib/docx/questions'
require 'json'

puts "📄 DOCX Questions JSON Extraction Demo"
puts "=" * 40

# Test files
test_files = [
  './test/fixtures/files/p6.docx',
  './test/fixtures/files/Phy-3ques.docx'
]

test_files.each do |file|
  next unless File.exist?(file)

  puts "\n🔍 Processing: #{File.basename(file)}"
  puts "-" * 30

  begin
    questions = Docx::Questions.extract_questions(file)
    puts "📊 Found #{questions.length} questions"

    questions.each_with_index do |q, i|
      puts "\n📝 Question #{i + 1}:"
      qstem_preview = q[:qstem].length > 80 ? "#{q[:qstem][0..77]}..." : q[:qstem]
      puts "   Stem: #{qstem_preview}"
      puts "   Answer: #{q[:key]}"

      has_math = q.values.compact.any? { |text| text.include?('<math>') }
      puts "   Math symbols: #{has_math ? 'Yes' : 'No'}"
    end

    # Output as JSON
    puts "\n💾 JSON Output:"
    puts JSON.pretty_generate(questions)

  rescue => e
    puts "❌ Error: #{e.message}"
  end
end

puts "\n✅ Demo complete!"
