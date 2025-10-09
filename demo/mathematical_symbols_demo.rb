#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for the Mathematical Symbols library
require_relative '../lib/docx/mathematical_symbols'

puts "📚 Mathematical Symbols Library Demo"
puts "=" * 40

# Test some common mathematical symbols
test_symbols = [
  [ "F0B4", "Symbol", "Multiplication" ],
  [ "F0B8", "Symbol", "Division" ],
  [ "F070", "Symbol", "Pi" ],
  [ "F044", "Symbol", "Delta (uppercase)" ],
  [ "F061", "Symbol", "Alpha (lowercase)" ],
  [ "F0A5", "Symbol", "Infinity" ],
  [ "F0F2", "Symbol", "Integral" ],
  [ "F0E5", "Symbol", "Summation" ],
  [ "F0AE", "Symbol", "Right arrow" ],
  [ "F0BD", "Symbol", "One half" ]
]

puts "\n🔢 Symbol Conversion Examples:"
test_symbols.each do |char_code, font, name|
  unicode = Docx::MathematicalSymbols.convert(char_code, font)
  puts "  #{char_code} (#{font}) → #{unicode} (#{name})"
end

puts "\n📊 Library Statistics:"
puts "  Supported fonts: #{Docx::MathematicalSymbols.supported_fonts.join(', ')}"
puts "  Symbol font mappings: #{Docx::MathematicalSymbols.supported_codes('symbol').count}"
puts "  Wingdings mappings: #{Docx::MathematicalSymbols.supported_codes('wingdings').count}"

puts "\n🔍 Symbol Information Example:"
info = Docx::MathematicalSymbols.symbol_info("F0B4", "Symbol")
if info
  puts "  Character Code: #{info[:char_code]}"
  puts "  Font: #{info[:font]}"
  puts "  Unicode: #{info[:unicode]}"
  puts "  Description: #{info[:description]}"
end

puts "\n✨ Mathematical Expression Examples:"
puts "  Physics: F = ma, E = mc²"
puts "  Chemistry: H₂O + NaCl → reaction"
puts "  Math: ∫₀^∞ e^(-x²) dx = √π/2"
puts "  Logic: ∀x ∈ ℝ, ∃y ∈ ℝ such that x + y = 0"

puts "\n✅ All systems ready for comprehensive mathematical symbol extraction!"
