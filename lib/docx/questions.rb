# frozen_string_literal: true

require_relative "questions/version"
require "zip"
require "nokogiri"
require "mathtype_to_mathml"
require "tempfile"

module Docx
  module Questions
    class Error < StandardError; end

    def self.is_question?(text)
      # Check if the text starts with a whole number followed by a dot and then a capital letter
      # This matches "6.The", "17.The", "18.Assertion" but excludes "1.1", "SESSION", etc.
      text.strip.match?(/^\d+\.[A-Z]/)
    end

    def self.convert_symbol_to_unicode(char_code, font)
      # Comprehensive mapping of symbol character codes to Unicode equivalents
      # Using hash for better performance and no duplicate issues
      
      return nil unless char_code
      
      case font&.downcase
      when "symbol"
        # Symbol font character mappings (most common in mathematical documents)
        symbol_map = {
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
        }
        
        symbol_map[char_code&.upcase] || "[#{char_code}]"
        
      when "wingdings", "webdings"
        # Handle other symbol fonts if needed
        wingdings_map = {
          "F04A" => "☺",        # Smiley face
          "F04B" => "☻"         # Black smiley face
        }
        
        wingdings_map[char_code&.upcase] || "[#{char_code}]"
        
      else
        # Unknown font or no font specified
        "[#{char_code}]"
      end
    end

    def self.convert_office_math_to_mathml(math_node, namespaces)
      # Convert Office Math (m:oMath) to MathML
      elements = []

      # Handle subscripts (m:sSub)
      math_node.xpath(".//m:sSub", namespaces).each do |sub|
        base = sub.at_xpath(".//m:e//m:t", namespaces)&.text
        subscript = sub.at_xpath(".//m:sub//m:t", namespaces)&.text
        elements << "<msub><mi>#{base}</mi><mn>#{subscript}</mn></msub>" if base && subscript
      end

      # Handle fractions (m:f)
      math_node.xpath(".//m:f", namespaces).each do |frac|
        num = frac.at_xpath(".//m:num//m:t", namespaces)&.text
        den = frac.at_xpath(".//m:den//m:t", namespaces)&.text
        elements << "<mfrac><mrow><mi>#{num}</mi></mrow><mrow><mn>#{den}</mn></mrow></mfrac>" if num && den
      end

      # Handle operators and equals
      elements << "<mo>=</mo>" if math_node.to_xml.include?("=")

      if elements.empty?
        ""
      else
        "<math display=\"block\"><mrow>#{elements.join}</mrow></math>"
      end
    end

    def self.convert_mathtype_to_latex(ole_data)
      # Create a temporary file to store the OLE data
      temp_file = Tempfile.new([ "equation", ".bin" ])
      begin
        temp_file.binmode
        temp_file.write(ole_data)
        temp_file.close

        # Convert using the file path
        mathml = MathTypeToMathML::Converter.new(temp_file.path).convert
        # Extract just the <math> tag part and remove extra whitespace
        mathml = ::Regexp.last_match(1).gsub(/\s+/, " ").strip if mathml =~ %r{(<math.*?</math>)}m
        mathml
      rescue StandardError => e
        puts "Conversion error: #{e.class} - #{e.message}"
        puts e.backtrace
        nil
      ensure
        temp_file.unlink
      end
    end

    def self.extract_text(docx_path)
      text_content = []

      Zip::File.open(docx_path) do |zip_file|
        # Find and read the main document XML file and relationships file
        document_xml = zip_file.find_entry("word/document.xml")
        rels_xml = zip_file.find_entry("word/_rels/document.xml.rels")
        next unless document_xml && rels_xml

        # Parse the XML content
        doc = Nokogiri::XML(document_xml.get_input_stream.read)
        rels = Nokogiri::XML(rels_xml.get_input_stream.read)

        # Create a map of relationship IDs to targets
        relationship_targets = {}
        rels.xpath("//xmlns:Relationship").each do |rel|
          relationship_targets[rel["Id"]] = rel["Target"]
        end

        # Define namespaces for XPath queries
        namespaces = {
          "w" => "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
          "m" => "http://schemas.openxmlformats.org/officeDocument/2006/math",
          "o" => "urn:schemas-microsoft-com:office:office"
        }

        # Process the document body
        body = doc.at_xpath("//w:body", namespaces)
        if body
          current_question = []
          inside_question = false

          # Process nodes in document order
          body.children.each do |node|
            next unless node.name == "p"

            para_parts = []

            # Extract text content with proper handling of special characters including math operators
            node.xpath(".//w:r", namespaces).each do |run|
              # Extract regular text nodes
              text_nodes = run.xpath(".//w:t", namespaces)
              text_nodes.each do |text_node|
                curr_text = text_node.text
                para_parts << curr_text if curr_text && !curr_text.strip.empty?
              end
              
              # Extract symbol nodes (mathematical and special symbols)
              symbol_nodes = run.xpath(".//w:sym", namespaces)
              symbol_nodes.each do |symbol_node|
                char_code = symbol_node["w:char"]
                font = symbol_node["w:font"]
                
                # Convert symbol character codes to their Unicode equivalents
                symbol = convert_symbol_to_unicode(char_code, font)
                para_parts << symbol if symbol
              end
            end

            para_text = para_parts.join

            # Check if this paragraph starts a new question
            if !para_text.empty? && is_question?(para_text)
              # Save previous question if we have one
              if inside_question && !current_question.empty?
                question_text = current_question.join(" ").strip
                text_content << question_text unless question_text.empty?
              end

              # Start new question
              current_question = [ para_text ]
              inside_question = true
            elsif inside_question && !para_text.empty?
              # Continue current question
              current_question << para_text
            end

            # If this paragraph contains an image and we're inside a question
            if inside_question && (node.at_xpath(".//w:drawing",
                                                 namespaces) || node.at_xpath(".//w:pict", namespaces))
              current_question << "<img>"
            end

            # If this paragraph contains an OLE object and we're inside a question
            if inside_question && (ole_object = node.at_xpath(".//o:OLEObject", namespaces))
              rel_id = ole_object["r:id"]
              if (target = relationship_targets[rel_id])
                # Read the OLE object data
                ole_entry = zip_file.find_entry("word/#{target}")
                if ole_entry
                  begin
                    ole_data = ole_entry.get_input_stream.read
                    mathml = convert_mathtype_to_latex(ole_data)
                    current_question << mathml if mathml
                  rescue StandardError
                    # If conversion fails, skip this equation
                    # Don't break the loop, just continue
                  end
                end
              end
            end

            # Process Office Math (m:oMath) elements if we're inside a question
            next unless inside_question

            node.xpath(".//m:oMath", namespaces).each do |math_obj|
              mathml = convert_office_math_to_mathml(math_obj, namespaces)
              current_question << mathml unless mathml.empty?
            end
          end

          # Don't forget the last question
          if inside_question && !current_question.empty?
            question_text = current_question.join(" ").strip
            text_content << question_text unless question_text.empty?
          end
        end
      end

      text_content.join("\n\n")
    end
  end
end
