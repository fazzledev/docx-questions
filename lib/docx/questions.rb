# frozen_string_literal: true

require_relative "questions/version"
require_relative "mathematical_symbols"
require "zip"
require "nokogiri"
require "mathtype_to_mathml"
require "tempfile"
require "json"

module Docx
  module Questions
    class Error < StandardError; end

    def self.is_question?(text)
      # Check if the text starts with a whole number followed by a dot and then a capital letter
      # This matches "6.The", "17.The", "18.Assertion" but excludes "1.1", "SESSION", etc.
      text.strip.match?(/^\d+\.[A-Z]/)
    end

    def self.extract_questions_json(docx_path)
      # Extract questions as JSON string
      questions = extract_questions(docx_path)
      questions.to_json
    end

    def self.extract_questions(docx_path)
      # Extract questions as array of objects (same logic as extract_text but returns structured data)
      questions = []

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

            # Extract text content with superscript/subscript handling
            temp_parts = []

            node.xpath(".//w:r", namespaces).each do |run|
              # Check if this run has superscript or subscript formatting
              vert_align = run.at_xpath(".//w:vertAlign", namespaces)
              text_nodes = run.xpath(".//w:t", namespaces)

              text_nodes.each do |text_node|
                curr_text = text_node.text
                next if curr_text.nil? || curr_text.strip.empty?

                if vert_align
                  case vert_align["w:val"]
                  when "superscript"
                    temp_parts << { type: :superscript, text: curr_text }
                  when "subscript"
                    temp_parts << { type: :subscript, text: curr_text }
                  else
                    temp_parts << { type: :normal, text: curr_text }
                  end
                else
                  temp_parts << { type: :normal, text: curr_text }
                end
              end

              # Handle symbol fonts
              sym_nodes = run.xpath(".//w:sym", namespaces)
              sym_nodes.each do |sym_node|
                char_code = sym_node["w:char"]
                font = sym_node["w:font"]
                if char_code && font
                  symbol = convert_symbol_to_unicode(char_code, font)
                  temp_parts << { type: :normal, text: symbol }
                end
              end
            end

            # Process the parts to create proper MathML
            i = 0
            while i < temp_parts.length
              part = temp_parts[i]

              if part[:type] == :superscript && i > 0 && temp_parts[i-1][:type] == :normal
                # Look for pattern like "10" followed by superscript
                prev_text = temp_parts[i-1][:text]
                if prev_text.match?(/\d+$/)
                  base = prev_text.match(/(\d+)$/)[1]
                  prefix = prev_text.gsub(/#{Regexp.escape(base)}$/, "")
                  para_parts.pop if para_parts.any? # Remove the last added part
                  para_parts << prefix unless prefix.empty?
                  para_parts << "<math><msup><mn>#{base}</mn><mn>#{part[:text]}</mn></msup></math>"
                else
                  para_parts << part[:text] # Just add as normal text if no pattern
                end
              elsif part[:type] == :subscript && i > 0 && temp_parts[i-1][:type] == :normal
                # Look for pattern like "v" followed by subscript
                prev_text = temp_parts[i-1][:text]
                if prev_text.match?(/[A-Za-z]$/)
                  base = prev_text.match(/([A-Za-z])$/)[1]
                  prefix = prev_text.gsub(/#{Regexp.escape(base)}$/, "")
                  para_parts.pop if para_parts.any? # Remove the last added part
                  para_parts << prefix unless prefix.empty?
                  para_parts << "<math><msub><mi>#{base}</mi><mn>#{part[:text]}</mn></msub></math>"
                else
                  para_parts << part[:text] # Just add as normal text if no pattern
                end
              elsif part[:type] == :normal
                para_parts << part[:text]
              else
                para_parts << part[:text] # Fallback
              end

              i += 1
            end

            para_text = para_parts.join

            # Check if this paragraph starts a new question
            if !para_text.empty? && is_question?(para_text)
              # Save previous question if we have one
              if inside_question && !current_question.empty?
                question_text = current_question.join(" ").strip
                question_text = strip_question_number(question_text)
                unless question_text.empty?
                  questions << { text: question_text }
                end
              end

              # Start new question
              current_question = [ para_text ]
              inside_question = true
            elsif inside_question && !para_text.empty?
              # Continue current question
              current_question << para_text
            end

            # Process all special elements in this paragraph if we're inside a question
            next unless inside_question

            # Check for images
            if node.at_xpath(".//w:drawing", namespaces) || node.at_xpath(".//w:pict", namespaces)
              current_question << "<img>"
            end

            # Check for OLE objects (MathType equations)
            if (ole_object = node.at_xpath(".//o:OLEObject", namespaces))
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

            # Check for Office Math elements
            node.xpath(".//m:oMath", namespaces).each do |math_obj|
              mathml = convert_office_math_to_mathml(math_obj, namespaces)
              current_question << mathml unless mathml.empty?
            end
          end

          # Don't forget the last question
          if inside_question && !current_question.empty?
            question_text = current_question.join(" ").strip
            question_text = strip_question_number(question_text)
            unless question_text.empty?
              questions << { text: question_text }
            end
          end
        end
      end

      questions
    end

    def self.convert_symbol_to_unicode(char_code, font)
      # Delegate to the dedicated mathematical symbols library
      symbol = MathematicalSymbols.convert(char_code, font)
      symbol || "[#{char_code}]"
    end

    def self.convert_office_math_to_mathml(math_node, namespaces)
      # Convert Office Math (m:oMath) to MathML by processing elements in document order
      elements = []

      # Process direct children of m:oMath in order
      math_node.children.each do |child|
        case child.name
        when "sSub"
          # Handle subscript
          base = child.at_xpath(".//m:e//m:t", namespaces)&.text
          # Collect all text nodes in the subscript
          subscript_nodes = child.xpath(".//m:sub//m:t", namespaces)
          subscript = subscript_nodes.map(&:text).join
          elements << "<msub><mi>#{base}</mi><mn>#{subscript}</mn></msub>" if base && !subscript.empty?
        when "sSup"
          # Handle superscript
          base = child.at_xpath(".//m:e//m:t", namespaces)&.text
          # Collect all text nodes in the superscript to handle cases like "-19"
          superscript_nodes = child.xpath(".//m:sup//m:t", namespaces)
          superscript = superscript_nodes.map(&:text).join
          elements << "<msup><mi>#{base}</mi><mn>#{superscript}</mn></msup>" if base && !superscript.empty?
        when "f"
          # Handle fraction
          elements << convert_fraction_to_mathml(child, namespaces)
        when "r"
          # Handle run (text/operators)
          text = child.at_xpath(".//m:t", namespaces)&.text
          if text
            case text.strip
            when "="
              elements << "<mo>=</mo>"
            when "×", "*"
              elements << "<mo>×</mo>"
            when "+"
              elements << "<mo>+</mo>"
            when "-"
              elements << "<mo>-</mo>"
            else
              elements << "<mi>#{text}</mi>" unless text.strip.empty?
            end
          end
        end
      end

      if elements.empty?
        ""
      else
        "<math display=\"block\"><mrow>#{elements.join}</mrow></math>"
      end
    end

    def self.convert_fraction_to_mathml(frac_node, namespaces)
      # Handle fraction with proper numerator and denominator processing
      num_content = []
      den_content = []

      # Process numerator
      num_node = frac_node.at_xpath(".//m:num", namespaces)
      if num_node
        num_node.children.each do |child|
          case child.name
          when "sSub"
            base = child.at_xpath(".//m:e//m:t", namespaces)&.text
            subscript = child.at_xpath(".//m:sub//m:t", namespaces)&.text
            num_content << "<msub><mi>#{base}</mi><mn>#{subscript}</mn></msub>" if base && subscript
          when "r"
            text = child.at_xpath(".//m:t", namespaces)&.text
            num_content << "<mi>#{text}</mi>" if text && !text.strip.empty?
          end
        end
      end

      # Process denominator
      den_node = frac_node.at_xpath(".//m:den", namespaces)
      if den_node
        den_node.children.each do |child|
          case child.name
          when "r"
            text = child.at_xpath(".//m:t", namespaces)&.text
            den_content << "<mn>#{text}</mn>" if text && !text.strip.empty?
          end
        end
      end

      "<mfrac><mrow>#{num_content.join}</mrow><mrow>#{den_content.join}</mrow></mfrac>"
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

            # Extract text content with superscript/subscript handling
            temp_parts = []

            node.xpath(".//w:r", namespaces).each do |run|
              # Check if this run has superscript or subscript formatting
              vert_align = run.at_xpath(".//w:vertAlign", namespaces)

              # Extract regular text nodes
              text_nodes = run.xpath(".//w:t", namespaces)
              text_nodes.each do |text_node|
                curr_text = text_node.text
                next if curr_text.nil? || curr_text.strip.empty?

                if vert_align
                  case vert_align["w:val"]
                  when "superscript"
                    temp_parts << { type: :superscript, text: curr_text }
                  when "subscript"
                    temp_parts << { type: :subscript, text: curr_text }
                  else
                    temp_parts << { type: :normal, text: curr_text }
                  end
                else
                  temp_parts << { type: :normal, text: curr_text }
                end
              end

              # Extract symbol nodes (mathematical and special symbols)
              symbol_nodes = run.xpath(".//w:sym", namespaces)
              symbol_nodes.each do |symbol_node|
                char_code = symbol_node["w:char"]
                font = symbol_node["w:font"]

                # Convert symbol character codes to their Unicode equivalents
                symbol = convert_symbol_to_unicode(char_code, font)
                if symbol
                  if vert_align
                    case vert_align["w:val"]
                    when "superscript"
                      temp_parts << { type: :superscript, text: symbol }
                    when "subscript"
                      temp_parts << { type: :subscript, text: symbol }
                    else
                      temp_parts << { type: :normal, text: symbol }
                    end
                  else
                    temp_parts << { type: :normal, text: symbol }
                  end
                end
              end
            end

            # Process the parts to create proper MathML
            i = 0
            while i < temp_parts.length
              part = temp_parts[i]

              if part[:type] == :superscript && i > 0 && temp_parts[i-1][:type] == :normal
                # Look for pattern like "10" followed by superscript
                prev_text = temp_parts[i-1][:text]
                if prev_text.match?(/\d+$/)
                  base = prev_text.match(/(\d+)$/)[1]
                  prefix = prev_text.gsub(/#{Regexp.escape(base)}$/, "")
                  para_parts.pop if para_parts.any? # Remove the last added part
                  para_parts << prefix unless prefix.empty?
                  para_parts << "<math><msup><mn>#{base}</mn><mn>#{part[:text]}</mn></msup></math>"
                else
                  para_parts << part[:text] # Just add as normal text if no pattern
                end
              elsif part[:type] == :subscript && i > 0 && temp_parts[i-1][:type] == :normal
                # Look for pattern like "v" followed by subscript
                prev_text = temp_parts[i-1][:text]
                if prev_text.match?(/[A-Za-z]$/)
                  base = prev_text.match(/([A-Za-z])$/)[1]
                  prefix = prev_text.gsub(/#{Regexp.escape(base)}$/, "")
                  para_parts.pop if para_parts.any? # Remove the last added part
                  para_parts << prefix unless prefix.empty?
                  para_parts << "<math><msub><mi>#{base}</mi><mn>#{part[:text]}</mn></msub></math>"
                else
                  para_parts << part[:text] # Just add as normal text if no pattern
                end
              elsif part[:type] == :normal
                para_parts << part[:text]
              else
                para_parts << part[:text] # Fallback
              end

              i += 1
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

            # Process all special elements in this paragraph if we're inside a question
            next unless inside_question

            # Check for images
            if node.at_xpath(".//w:drawing", namespaces) || node.at_xpath(".//w:pict", namespaces)
              current_question << "<img>"
            end

            # Check for OLE objects (MathType equations)
            if (ole_object = node.at_xpath(".//o:OLEObject", namespaces))
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

            # Check for Office Math elements
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

    private

    def self.strip_question_number(text)
      # Remove question numbers like "6.", "17.", "18." from the beginning of questions
      # while preserving mathematical symbols and content
      text.gsub(/^\d+\./, '').strip
    end
  end
end
