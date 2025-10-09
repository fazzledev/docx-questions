# frozen_string_literal: true

module Docx
  # Mathematical symbol conversion library for DOCX symbol character codes
  # Converts symbol font character codes to their Unicode equivalents
  class MathematicalSymbols
    # Symbol font mappings (most common in mathematical documents)
    SYMBOL_FONT_MAP = {
      # Basic arithmetic operators
      "F02B" => "+",        # Plus
      "F02D" => "−",        # Minus (Unicode minus, not hyphen)
      "F0B4" => "×",        # Multiplication
      "F0B8" => "÷",        # Division
      "F0B1" => "±",        # Plus-minus
      "F0F1" => "∓",        # Minus-plus

      # Comparison and equality
      "F03D" => "=",        # Equals
      "F0B9" => "≠",        # Not equal
      "F03C" => "<",        # Less than
      "F03E" => ">",        # Greater than
      "F0A3" => "≤",        # Less than or equal
      "F0B3" => "≥",        # Greater than or equal
      "F0BB" => "≈",        # Approximately equal
      "F040" => "≅",        # Congruent
      "F07E" => "∼",        # Similar

      # Greek letters (lowercase)
      "F061" => "α",        # Alpha
      "F062" => "β",        # Beta
      "F067" => "γ",        # Gamma
      "F064" => "δ",        # Delta
      "F065" => "ε",        # Epsilon
      "F07A" => "ζ",        # Zeta
      "F068" => "η",        # Eta
      "F071" => "θ",        # Theta
      "F069" => "ι",        # Iota
      "F06B" => "κ",        # Kappa
      "F06C" => "λ",        # Lambda
      "F06D" => "μ",        # Mu
      "F06E" => "ν",        # Nu
      "F078" => "ξ",        # Xi
      "F06F" => "ο",        # Omicron
      "F070" => "π",        # Pi
      "F072" => "ρ",        # Rho
      "F073" => "σ",        # Sigma
      "F074" => "τ",        # Tau
      "F075" => "υ",        # Upsilon
      "F066" => "φ",        # Phi
      "F063" => "χ",        # Chi
      "F079" => "ψ",        # Psi
      "F077" => "ω",        # Omega

      # Greek letters (uppercase)
      "F041" => "Α",        # Alpha
      "F042" => "Β",        # Beta
      "F047" => "Γ",        # Gamma
      "F044" => "Δ",        # Delta
      "F045" => "Ε",        # Epsilon
      "F05A" => "Ζ",        # Zeta
      "F048" => "Η",        # Eta
      "F051" => "Θ",        # Theta
      "F049" => "Ι",        # Iota
      "F04B" => "Κ",        # Kappa
      "F04C" => "Λ",        # Lambda
      "F04D" => "Μ",        # Mu
      "F04E" => "Ν",        # Nu
      "F058" => "Ξ",        # Xi
      "F04F" => "Ο",        # Omicron
      "F050" => "Π",        # Pi
      "F052" => "Ρ",        # Rho
      "F053" => "Σ",        # Sigma
      "F054" => "Τ",        # Tau
      "F055" => "Υ",        # Upsilon
      "F046" => "Φ",        # Phi
      "F043" => "Χ",        # Chi
      "F059" => "Ψ",        # Psi
      "F057" => "Ω",        # Omega

      # Mathematical operators and symbols
      "F0A5" => "∞",        # Infinity
      "F0B0" => "°",        # Degree
      "F027" => "∀",        # For all
      "F024" => "∃",        # There exists
      "F0D1" => "∇",        # Nabla/Del
      "F0B6" => "∂",        # Partial differential
      "F0F2" => "∫",        # Integral
      "F0E5" => "∑",        # Summation
      "F0D5" => "∏",        # Product
      "F0D6" => "√",        # Square root
      "F0B5" => "∝",        # Proportional to
      "F0A4" => "∴",        # Therefore
      "F0C8" => "∈",        # Element of
      "F0CA" => "∋",        # Contains
      "F0CC" => "∩",        # Intersection
      "F0CD" => "∪",        # Union
      "F0CE" => "∅",        # Empty set
      "F0CF" => "∧",        # Logical and
      "F0D0" => "∨",        # Logical or
      "F0A8" => "¬",        # Logical not
      "F0E0" => "∠",        # Angle

      # Arrows
      "F0AC" => "←",        # Left arrow
      "F0AE" => "→",        # Right arrow
      "F0AD" => "↑",        # Up arrow
      "F0AF" => "↓",        # Down arrow
      "F0DB" => "↔",        # Left right arrow
      "F0DC" => "⇐",        # Left double arrow
      "F0DD" => "⇒",        # Right double arrow
      "F0DE" => "⇔",        # Left right double arrow

      # Fractions
      "F0BD" => "½",        # One half
      "F0BC" => "¼",        # One quarter
      "F0BE" => "¾"         # Three quarters
    }.freeze

    # Wingdings font mappings
    WINGDINGS_FONT_MAP = {
      "F04A" => "☺",        # Smiley face
      "F04B" => "☻"         # Black smiley face
    }.freeze

    # Webdings font mappings (can be extended as needed)
    WEBDINGS_FONT_MAP = {
      # Add webdings mappings here as needed
    }.freeze

    class << self
      # Convert a symbol character code to its Unicode equivalent
      # @param char_code [String] The character code (e.g., "F0B4")
      # @param font [String] The font name (e.g., "Symbol", "Wingdings")
      # @return [String, nil] The Unicode character or nil if not found
      def convert(char_code, font = nil)
        return nil unless char_code

        case font&.downcase
        when "symbol"
          SYMBOL_FONT_MAP[char_code.upcase]
        when "wingdings"
          WINGDINGS_FONT_MAP[char_code.upcase]
        when "webdings"
          WEBDINGS_FONT_MAP[char_code.upcase]
        else
          # Try Symbol font as default fallback for unknown fonts
          SYMBOL_FONT_MAP[char_code.upcase]
        end
      end

      # Get all supported character codes for a specific font
      # @param font [String] The font name
      # @return [Array<String>] Array of supported character codes
      def supported_codes(font = "symbol")
        case font.downcase
        when "symbol"
          SYMBOL_FONT_MAP.keys
        when "wingdings"
          WINGDINGS_FONT_MAP.keys
        when "webdings"
          WEBDINGS_FONT_MAP.keys
        else
          []
        end
      end

      # Get all supported fonts
      # @return [Array<String>] Array of supported font names
      def supported_fonts
        %w[symbol wingdings webdings]
      end

      # Check if a character code is supported for a given font
      # @param char_code [String] The character code
      # @param font [String] The font name
      # @return [Boolean] True if supported, false otherwise
      def supported?(char_code, font = "symbol")
        return false unless char_code

        case font.downcase
        when "symbol"
          SYMBOL_FONT_MAP.key?(char_code.upcase)
        when "wingdings"
          WINGDINGS_FONT_MAP.key?(char_code.upcase)
        when "webdings"
          WEBDINGS_FONT_MAP.key?(char_code.upcase)
        else
          false
        end
      end

      # Get symbol information
      # @param char_code [String] The character code
      # @param font [String] The font name
      # @return [Hash, nil] Hash with symbol info or nil if not found
      def symbol_info(char_code, font = "symbol")
        unicode = convert(char_code, font)
        return nil unless unicode

        {
          char_code: char_code.upcase,
          font: font.downcase,
          unicode: unicode,
          description: describe_symbol(unicode)
        }
      end

      private

      # Provide human-readable descriptions for symbols
      # @param unicode [String] The Unicode character
      # @return [String] Description of the symbol
      def describe_symbol(unicode)
        descriptions = {
          "×" => "Multiplication operator",
          "÷" => "Division operator",
          "±" => "Plus-minus operator",
          "≠" => "Not equal operator",
          "≤" => "Less than or equal operator",
          "≥" => "Greater than or equal operator",
          "α" => "Greek letter alpha (lowercase)",
          "β" => "Greek letter beta (lowercase)",
          "π" => "Greek letter pi (lowercase)",
          "Δ" => "Greek letter delta (uppercase)",
          "∞" => "Infinity symbol",
          "∫" => "Integral symbol",
          "∑" => "Summation symbol",
          "∂" => "Partial differential symbol",
          "→" => "Right arrow",
          "←" => "Left arrow"
        }

        descriptions[unicode] || "Mathematical symbol"
      end
    end
  end
end
