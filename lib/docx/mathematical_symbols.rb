# frozen_string_literal: true

module Docx
  # Mathematical symbol conversion library for DOCX symbol character codes
  # Converts symbol font character codes to their Unicode equivalents
  class MathematicalSymbols
    # Symbol font mappings (most common in mathematical documents)
    SYMBOL_FONT_MAP = {
      # Basic arithmetic operators
      "F02B" => { unicode: "+", description: "Plus" },
      "F02D" => { unicode: "−", description: "Minus (Unicode minus, not hyphen)" },
      "F0B4" => { unicode: "×", description: "Multiplication operator" },
      "F0B8" => { unicode: "÷", description: "Division operator" },
      "F0B1" => { unicode: "±", description: "Plus-minus" },
      "F0F1" => { unicode: "∓", description: "Minus-plus" },

      # Comparison and equality
      "F03D" => { unicode: "=", description: "Equals" },
      "F0B9" => { unicode: "≠", description: "Not equal" },
      "F03C" => { unicode: "<", description: "Less than" },
      "F03E" => { unicode: ">", description: "Greater than" },
      "F0A3" => { unicode: "≤", description: "Less than or equal" },
      "F0B3" => { unicode: "≥", description: "Greater than or equal" },
      "F0BB" => { unicode: "≈", description: "Approximately equal" },
      "F040" => { unicode: "≅", description: "Congruent" },
      "F07E" => { unicode: "∼", description: "Similar" },

      # Greek letters (lowercase)
      "F061" => { unicode: "α", description: "Alpha (lowercase)" },
      "F062" => { unicode: "β", description: "Beta (lowercase)" },
      "F067" => { unicode: "γ", description: "Gamma (lowercase)" },
      "F064" => { unicode: "δ", description: "Delta (lowercase)" },
      "F065" => { unicode: "ε", description: "Epsilon (lowercase)" },
      "F07A" => { unicode: "ζ", description: "Zeta (lowercase)" },
      "F068" => { unicode: "η", description: "Eta (lowercase)" },
      "F071" => { unicode: "θ", description: "Theta (lowercase)" },
      "F069" => { unicode: "ι", description: "Iota (lowercase)" },
      "F06B" => { unicode: "κ", description: "Kappa (lowercase)" },
      "F06C" => { unicode: "λ", description: "Lambda (lowercase)" },
      "F06D" => { unicode: "μ", description: "Mu (lowercase)" },
      "F06E" => { unicode: "ν", description: "Nu (lowercase)" },
      "F078" => { unicode: "ξ", description: "Xi (lowercase)" },
      "F06F" => { unicode: "ο", description: "Omicron (lowercase)" },
      "F070" => { unicode: "π", description: "Pi" },
      "F072" => { unicode: "ρ", description: "Rho (lowercase)" },
      "F073" => { unicode: "σ", description: "Sigma (lowercase)" },
      "F074" => { unicode: "τ", description: "Tau (lowercase)" },
      "F075" => { unicode: "υ", description: "Upsilon (lowercase)" },
      "F066" => { unicode: "φ", description: "Phi (lowercase)" },
      "F063" => { unicode: "χ", description: "Chi (lowercase)" },
      "F079" => { unicode: "ψ", description: "Psi (lowercase)" },
      "F077" => { unicode: "ω", description: "Omega (lowercase)" },

      # Greek letters (uppercase)
      "F041" => { unicode: "Α", description: "Alpha (uppercase)" },
      "F042" => { unicode: "Β", description: "Beta (uppercase)" },
      "F047" => { unicode: "Γ", description: "Gamma (uppercase)" },
      "F044" => { unicode: "Δ", description: "Delta (uppercase)" },
      "F045" => { unicode: "Ε", description: "Epsilon (uppercase)" },
      "F05A" => { unicode: "Ζ", description: "Zeta (uppercase)" },
      "F048" => { unicode: "Η", description: "Eta (uppercase)" },
      "F051" => { unicode: "Θ", description: "Theta (uppercase)" },
      "F049" => { unicode: "Ι", description: "Iota (uppercase)" },
      "F04B" => { unicode: "Κ", description: "Kappa (uppercase)" },
      "F04C" => { unicode: "Λ", description: "Lambda (uppercase)" },
      "F04D" => { unicode: "Μ", description: "Mu (uppercase)" },
      "F04E" => { unicode: "Ν", description: "Nu (uppercase)" },
      "F058" => { unicode: "Ξ", description: "Xi (uppercase)" },
      "F04F" => { unicode: "Ο", description: "Omicron (uppercase)" },
      "F050" => { unicode: "Π", description: "Pi (uppercase)" },
      "F052" => { unicode: "Ρ", description: "Rho (uppercase)" },
      "F053" => { unicode: "Σ", description: "Sigma (uppercase)" },
      "F054" => { unicode: "Τ", description: "Tau (uppercase)" },
      "F055" => { unicode: "Υ", description: "Upsilon (uppercase)" },
      "F046" => { unicode: "Φ", description: "Phi (uppercase)" },
      "F043" => { unicode: "Χ", description: "Chi (uppercase)" },
      "F059" => { unicode: "Ψ", description: "Psi (uppercase)" },
      "F057" => { unicode: "Ω", description: "Omega (uppercase)" },

      # Mathematical operators and symbols
      "F0A5" => { unicode: "∞", description: "Infinity" },
      "F0D1" => { unicode: "∇", description: "Nabla (gradient)" },
      "F0B6" => { unicode: "∂", description: "Partial derivative" },
      "F0F2" => { unicode: "∫", description: "Integral" },
      "F0E5" => { unicode: "∑", description: "Summation" },
      "F0D5" => { unicode: "∏", description: "Product" },
      "F0D6" => { unicode: "√", description: "Square root" },
      "F0D0" => { unicode: "∠", description: "Angle" },

      # Set theory and logic
      "F0CE" => { unicode: "∈", description: "Element of" },
      "F0CF" => { unicode: "∋", description: "Contains" },
      "F0C9" => { unicode: "∉", description: "Not element of" },
      "F0C7" => { unicode: "∩", description: "Intersection" },
      "F0C8" => { unicode: "∪", description: "Union" },
      "F0C6" => { unicode: "∅", description: "Empty set" },
      "F0C5" => { unicode: "⊂", description: "Subset of" },
      "F0C3" => { unicode: "⊃", description: "Superset of" },
      "F0CA" => { unicode: "⊆", description: "Subset of or equal" },
      "F0CB" => { unicode: "⊇", description: "Superset of or equal" },

      # Logic symbols
      "F0D9" => { unicode: "∧", description: "Logical AND" },
      "F0DA" => { unicode: "∨", description: "Logical OR" },
      "F0D8" => { unicode: "¬", description: "Logical NOT" },
      "F0A0" => { unicode: "∀", description: "For all (universal quantifier)" },
      "F024" => { unicode: "∃", description: "There exists (existential quantifier)" },

      # Arrows
      "F0AC" => { unicode: "←", description: "Left arrow" },
      "F0AE" => { unicode: "→", description: "Right arrow" },
      "F0AD" => { unicode: "↑", description: "Up arrow" },
      "F0AF" => { unicode: "↓", description: "Down arrow" },
      "F0AB" => { unicode: "↔", description: "Left-right arrow" },
      "F0DC" => { unicode: "⇐", description: "Left double arrow" },
      "F0DE" => { unicode: "⇒", description: "Right double arrow" },
      "F0DD" => { unicode: "⇑", description: "Up double arrow" },
      "F0DF" => { unicode: "⇓", description: "Down double arrow" },
      "F0DB" => { unicode: "⇔", description: "Left-right double arrow" },

      # Fractions and numbers
      "F0BD" => { unicode: "½", description: "One half" },
      "F0BC" => { unicode: "¼", description: "One quarter" },
      "F0BE" => { unicode: "¾", description: "Three quarters" }
    }.freeze

    # Wingdings font mappings (limited selection)
    WINGDINGS_FONT_MAP = {
      "F021" => { unicode: "✁", description: "Scissors" },
      "F022" => { unicode: "✂", description: "Scissors (solid)" }
    }.freeze

    # Webdings font mappings (limited selection)
    WEBDINGS_FONT_MAP = {
      "F021" => { unicode: "♠", description: "Spade suit" },
      "F022" => { unicode: "♣", description: "Club suit" }
    }.freeze

    # Font mapping registry
    FONT_MAPPINGS = {
      "symbol" => SYMBOL_FONT_MAP,
      "wingdings" => WINGDINGS_FONT_MAP,
      "webdings" => WEBDINGS_FONT_MAP
    }.freeze

    class << self
      # Convert a character code and font to its Unicode equivalent
      # @param char_code [String] The character code (e.g., "F0B4")
      # @param font [String] The font name (case insensitive)
      # @return [String, nil] The Unicode character or nil if not found
      def convert(char_code, font)
        return nil unless char_code && font

        normalized_font = font.downcase.strip
        normalized_code = char_code.upcase.strip

        font_map = FONT_MAPPINGS[normalized_font]
        return nil unless font_map

        symbol_info = font_map[normalized_code]
        symbol_info ? symbol_info[:unicode] : nil
      end

      # Get detailed information about a symbol
      # @param char_code [String] The character code
      # @param font [String] The font name
      # @return [Hash, nil] Hash with symbol information or nil if not found
      def symbol_info(char_code, font)
        return nil unless char_code && font

        normalized_font = font.downcase.strip
        normalized_code = char_code.upcase.strip

        font_map = FONT_MAPPINGS[normalized_font]
        return nil unless font_map

        symbol_info = font_map[normalized_code]
        return nil unless symbol_info

        {
          char_code: normalized_code,
          font: normalized_font,
          unicode: symbol_info[:unicode],
          description: symbol_info[:description]
        }
      end

      # Get list of supported fonts
      # @return [Array<String>] Array of supported font names
      def supported_fonts
        FONT_MAPPINGS.keys
      end

      # Get list of supported character codes for a font
      # @param font [String] The font name
      # @return [Array<String>] Array of character codes
      def supported_codes(font)
        normalized_font = font.downcase.strip
        font_map = FONT_MAPPINGS[normalized_font]
        font_map ? font_map.keys : []
      end

      # Check if a font is supported
      # @param font [String] The font name
      # @return [Boolean] True if font is supported
      def font_supported?(font)
        normalized_font = font.downcase.strip
        FONT_MAPPINGS.key?(normalized_font)
      end

      # Get statistics about symbol mappings
      # @return [Hash] Hash with mapping statistics
      def statistics
        {
          total_fonts: FONT_MAPPINGS.size,
          total_symbols: FONT_MAPPINGS.values.sum(&:size),
          fonts: FONT_MAPPINGS.transform_values(&:size)
        }
      end
    end

    # Hash of Unicode symbols to their descriptions for reverse lookups
    UNICODE_DESCRIPTIONS = SYMBOL_FONT_MAP.each_with_object({}) do |(code, info), hash|
      hash[info[:unicode]] = info[:description]
    end.merge(
      WINGDINGS_FONT_MAP.each_with_object({}) do |(code, info), hash|
        hash[info[:unicode]] = info[:description]
      end
    ).merge(
      WEBDINGS_FONT_MAP.each_with_object({}) do |(code, info), hash|
        hash[info[:unicode]] = info[:description]
      end
    ).freeze
  end
end
