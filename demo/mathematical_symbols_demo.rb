#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for the Mathematical Symbols library
require_relative '../lib/docx/mathematical_symbols'

puts "📚 Mathematical Symbols Library Demo"
puts "=" * 40

# Test key mathematical symbols
test_symbols = [
  [ "F0B4", "Symbol", "×" ], # Multiplication
  [ "F070", "Symbol", "π" ], # Pi
  [ "F044", "Symbol", "Δ" ], # Delta
  [ "F0A5", "Symbol", "∞" ], # Infinity
  [ "F0F2", "Symbol", "∫" ] # Integral
]

puts "\n🔢 Symbol Conversions:"
test_symbols.each do |char_code, font, expected|
  unicode = Docx::MathematicalSymbols.convert(char_code, font)
  puts "  #{char_code} → #{unicode} (#{expected})"
end

puts "\n📊 Statistics:"
puts "  Fonts: #{Docx::MathematicalSymbols.supported_fonts.join(', ')}"
puts "  Symbol mappings: #{Docx::MathematicalSymbols.supported_codes('symbol').count}"

puts "\n✅ Mathematical symbols ready for JSON extraction!"
