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
    # Extract as structured data
    questions = Docx::Questions.extract_questions(file)

    puts "📊 Found #{questions.length} questions"

    questions.each_with_index do |q, i|
      puts "\n📝 Question #{i + 1}:"

      # Show qstem preview
      qstem = q[:qstem] || "No stem"
      qstem_preview = qstem.length > 80 ? "#{qstem[0..77]}..." : qstem
      puts "   Stem: #{qstem_preview}"

      # Count options
      option_count = [ :optA, :optB, :optC, :optD ].count { |opt| q[opt] }
      puts "   Options: #{option_count}"
      puts "   Answer: #{q[:key] || 'N/A'}"
      puts "   Hint: #{q[:hint] ? 'Yes' : 'No'}"

      # Check for mathematical content
      has_math = [ q[:qstem], q[:optA], q[:optB], q[:optC], q[:optD], q[:hint] ]
                   .compact.any? { |text| text.include?('<math>') }
      puts "   Math symbols: #{has_math ? 'Yes' : 'No'}"
    end

    # Save as JSON
    json_file = file.gsub('.docx', '_demo_output.json')
    File.write(json_file, JSON.pretty_generate(questions))
    puts "\n💾 Saved JSON to: #{json_file}"

  rescue => e
    puts "❌ Error processing #{file}: #{e.message}"
  end
end

puts "\n✅ Demo complete!"
