# frozen_string_literal: true

require "test_helper"
require_relative "../lib/docx/mathematical_symbols"

class TestMathematicalSymbols < Minitest::Test
  def test_basic_arithmetic_operators
    assert_equal "×", Docx::MathematicalSymbols.convert("F0B4", "Symbol")
    assert_equal "÷", Docx::MathematicalSymbols.convert("F0B8", "Symbol")
    assert_equal "±", Docx::MathematicalSymbols.convert("F0B1", "Symbol")
  end

  def test_greek_letters
    assert_equal "α", Docx::MathematicalSymbols.convert("F061", "Symbol")
    assert_equal "β", Docx::MathematicalSymbols.convert("F062", "Symbol")
    assert_equal "π", Docx::MathematicalSymbols.convert("F070", "Symbol")
    assert_equal "Δ", Docx::MathematicalSymbols.convert("F044", "Symbol")
  end

  def test_case_insensitive_char_codes
    assert_equal "×", Docx::MathematicalSymbols.convert("f0b4", "Symbol")
    assert_equal "×", Docx::MathematicalSymbols.convert("F0B4", "symbol")
  end

  def test_unsupported_char_code
    assert_nil Docx::MathematicalSymbols.convert("F999", "Symbol")
  end

  def test_supported_fonts
    fonts = Docx::MathematicalSymbols.supported_fonts
    assert_includes fonts, "symbol"
    assert_includes fonts, "wingdings"
    assert_includes fonts, "webdings"
  end

  def test_supported_check
    assert Docx::MathematicalSymbols.supported?("F0B4", "Symbol")
    refute Docx::MathematicalSymbols.supported?("F999", "Symbol")
  end

  def test_symbol_info
    info = Docx::MathematicalSymbols.symbol_info("F0B4", "Symbol")
    assert_equal "F0B4", info[:char_code]
    assert_equal "symbol", info[:font]
    assert_equal "×", info[:unicode]
    assert_includes info[:description], "Multiplication"
  end

  def test_wingdings_support
    assert_equal "☺", Docx::MathematicalSymbols.convert("F04A", "Wingdings")
  end

  def test_fallback_to_symbol_font
    # When font is unknown, should try Symbol font as fallback
    assert_equal "×", Docx::MathematicalSymbols.convert("F0B4", "UnknownFont")
  end
end