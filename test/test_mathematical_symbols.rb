# frozen_string_literal: true

require "test_helper"

module Docx
  class TestMathematicalSymbols < Minitest::Test
    def test_convert_basic_arithmetic_operators
      assert_equal "×", MathematicalSymbols.convert("F0B4", "Symbol")
      assert_equal "÷", MathematicalSymbols.convert("F0B8", "Symbol")
      assert_equal "±", MathematicalSymbols.convert("F0B1", "Symbol")
      assert_equal "∓", MathematicalSymbols.convert("F0F1", "Symbol")
    end

    def test_convert_greek_letters
      assert_equal "α", MathematicalSymbols.convert("F061", "Symbol")
      assert_equal "β", MathematicalSymbols.convert("F062", "Symbol")
      assert_equal "π", MathematicalSymbols.convert("F070", "Symbol")
      assert_equal "Δ", MathematicalSymbols.convert("F044", "Symbol")
      assert_equal "Ω", MathematicalSymbols.convert("F057", "Symbol")
    end

    def test_convert_advanced_mathematical_symbols
      assert_equal "∞", MathematicalSymbols.convert("F0A5", "Symbol")
      assert_equal "∫", MathematicalSymbols.convert("F0F2", "Symbol")
      assert_equal "∑", MathematicalSymbols.convert("F0E5", "Symbol")
      assert_equal "√", MathematicalSymbols.convert("F0D6", "Symbol")
      assert_equal "∂", MathematicalSymbols.convert("F0B6", "Symbol")
    end

    def test_convert_logic_and_set_symbols
      assert_equal "∈", MathematicalSymbols.convert("F0CE", "Symbol")
      assert_equal "∀", MathematicalSymbols.convert("F0A0", "Symbol")
      assert_equal "∃", MathematicalSymbols.convert("F024", "Symbol")
      assert_equal "∧", MathematicalSymbols.convert("F0D9", "Symbol")
      assert_equal "∨", MathematicalSymbols.convert("F0DA", "Symbol")
    end

    def test_convert_arrows
      assert_equal "→", MathematicalSymbols.convert("F0AE", "Symbol")
      assert_equal "←", MathematicalSymbols.convert("F0AC", "Symbol")
      assert_equal "⇒", MathematicalSymbols.convert("F0DE", "Symbol")
      assert_equal "⇔", MathematicalSymbols.convert("F0DB", "Symbol")
    end

    def test_convert_fractions
      assert_equal "½", MathematicalSymbols.convert("F0BD", "Symbol")
      assert_equal "¼", MathematicalSymbols.convert("F0BC", "Symbol")
      assert_equal "¾", MathematicalSymbols.convert("F0BE", "Symbol")
    end

    def test_convert_case_insensitive
      assert_equal "×", MathematicalSymbols.convert("f0b4", "symbol")
      assert_equal "×", MathematicalSymbols.convert("F0B4", "SYMBOL")
      assert_equal "×", MathematicalSymbols.convert("f0B4", "Symbol")
    end

    def test_convert_wingdings_font
      assert_equal "✁", MathematicalSymbols.convert("F021", "Wingdings")
      assert_equal "✂", MathematicalSymbols.convert("F022", "Wingdings")
    end

    def test_convert_webdings_font
      assert_equal "♠", MathematicalSymbols.convert("F021", "Webdings")
      assert_equal "♣", MathematicalSymbols.convert("F022", "Webdings")
    end

    def test_convert_returns_nil_for_unknown_codes
      assert_nil MathematicalSymbols.convert("F999", "Symbol")
      assert_nil MathematicalSymbols.convert("F0B4", "UnknownFont")
      assert_nil MathematicalSymbols.convert(nil, "Symbol")
      assert_nil MathematicalSymbols.convert("F0B4", nil)
    end

    def test_symbol_info_returns_detailed_information
      info = MathematicalSymbols.symbol_info("F0B4", "Symbol")

      assert_equal "F0B4", info[:char_code]
      assert_equal "symbol", info[:font]
      assert_equal "×", info[:unicode]
      assert_equal "Multiplication operator", info[:description]
    end

    def test_symbol_info_returns_nil_for_unknown
      assert_nil MathematicalSymbols.symbol_info("F999", "Symbol")
      assert_nil MathematicalSymbols.symbol_info("F0B4", "UnknownFont")
    end

    def test_supported_fonts
      fonts = MathematicalSymbols.supported_fonts
      assert_includes fonts, "symbol"
      assert_includes fonts, "wingdings"
      assert_includes fonts, "webdings"
      assert_equal 3, fonts.length
    end

    def test_supported_codes
      symbol_codes = MathematicalSymbols.supported_codes("symbol")
      assert_includes symbol_codes, "F0B4"
      assert_includes symbol_codes, "F070"
      assert symbol_codes.length > 90  # Should have many symbol mappings

      wingdings_codes = MathematicalSymbols.supported_codes("wingdings")
      assert_includes wingdings_codes, "F021"
      assert wingdings_codes.length >= 2
    end

    def test_font_supported
      assert MathematicalSymbols.font_supported?("Symbol")
      assert MathematicalSymbols.font_supported?("WINGDINGS")
      assert MathematicalSymbols.font_supported?("webdings")
      refute MathematicalSymbols.font_supported?("UnknownFont")
    end

    def test_statistics
      stats = MathematicalSymbols.statistics
      assert_equal 3, stats[:total_fonts]
      assert stats[:total_symbols] > 90
      assert stats[:fonts]["symbol"] > 90
      assert stats[:fonts]["wingdings"] >= 2
      assert stats[:fonts]["webdings"] >= 2
    end
  end
end
