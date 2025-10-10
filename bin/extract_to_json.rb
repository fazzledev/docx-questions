#!/usr/bin/env ruby

require 'bundler/setup'
require_relative '../lib/docx/questions'

if ARGV.length != 2
  puts "Usage: extract_to_json.rb <input.docx> <output.json>"
  exit 1
end

input_file = ARGV[0]
output_file = ARGV[1]

unless File.exist?(input_file)
  puts "Error: Input file '#{input_file}' does not exist."
  exit 1
end

begin
  # Extract questions with mathematical symbols preservation
  questions = Docx::Questions.extract_questions(input_file)
  
  # Write to JSON file
  File.write(output_file, JSON.pretty_generate(questions))
  
  # Display summary
  puts "Successfully extracted #{questions.length} questions to #{output_file}"
  puts "\nQuestion breakdown:"
  questions.each_with_index do |q, i|
    qstem_text = q[:qstem] ? q[:qstem].gsub(/\s+/, ' ').strip : 'No stem'
    qstem_preview = qstem_text.length > 80 ? "#{qstem_text[0..77]}..." : qstem_text
    puts "  #{i+1}. #{qstem_preview}"
    
    # Count non-nil options
    option_count = [q[:optA], q[:optB], q[:optC], q[:optD]].count { |opt| !opt.nil? }
    puts "     Options: #{option_count}, Answer: #{q[:key] || 'N/A'}, Hint: #{q[:hint] ? 'Yes' : 'No'}"
  end
  
rescue => e
  puts "Error processing file: #{e.message}"
  exit 1
end
