# frozen_string_literal: true

require_relative "questions/version"
require_relative "mathematical_symbols"
require "zip"
require "nokogiri"
require "mathtype_to_mathml"
require "tempfile"

module Docx
  module Questions
    class Error < StandardError; end

    def self.is_question?(text)
      # Check if the text starts with a whole number followed by a dot and then a capital letter
      # This matches "6.The", "17.The", "18.Assertion", "10. An" but excludes "1.1", "SESSION", etc.
      text.strip.match?(/^\d+\.\s*[A-Z]/)
    end

    def self.convert_symbol_to_unicode(char_code, font)
      # Delegate to the dedicated mathematical symbols library
      symbol = MathematicalSymbols.convert(char_code, font)
      symbol || "[#{char_code}]"
    end

    def self.extract_hint_safely(hint_text)
      # Extract hint text but stop at the next question boundary
      return hint_text unless hint_text

      # Look for the next question pattern (number.space.Capital letter)
      next_question_match = hint_text.match(/(\d+\.\s*[A-Z].*)/)
      if next_question_match
        # Return only the part before the next question
        hint_text[0, next_question_match.begin(0)].strip
      else
        hint_text.strip
      end
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

    def self.extract_options(text)
      # Extract options using the pattern a) ... b) ... c) ... d) ...
      parts = text.split(/([a-d]\))/)
      options = {}

      (1...parts.length).step(2) do |i|
        letter = parts[i].gsub(")", "")
        text_part = parts[i+1] || ""
        options[letter] = text_part.strip
      end

      options
    end

    def self.remove_options_from_text(text)
      # Remove options pattern from text to get clean question text
      # Split by options and take only the first part (before any options)
      parts = text.split(/([a-d]\))/)
      parts[0].strip
    end

    def self.extract_image_from_node(node, zip_file, relationship_targets, question_number)
      # Define namespaces for image extraction
      image_namespaces = {
        "w" => "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
        "a" => "http://schemas.openxmlformats.org/drawingml/2006/main",
        "r" => "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
      }

      # Look for image relationships in the node
      image_rel = node.at_xpath(".//a:blip", image_namespaces)

      if image_rel && image_rel["r:embed"]
        rel_id = image_rel["r:embed"]
        if (target = relationship_targets[rel_id])
          # Read the image data
          image_entry = zip_file.find_entry("word/#{target}")
          if image_entry
            @image_counter += 1
            image_data = image_entry.get_input_stream.read

            # Determine file extension from target
            extension = File.extname(target).downcase
            extension = ".jpg" if extension.empty? # Default to jpg

            filename = "image_#{@image_counter}#{extension}"

            # Store image data for this specific question
            @question_images[question_number] ||= {}
            @question_images[question_number][filename] = image_data

            return filename
          end
        end
      end

      nil
    end

    def self.extract_questions(docx_path, debug: false)
      questions = []
      @image_counter = 0
      @question_images = {}
      @debug = debug

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
                unless question_text.empty?
                  # Extract question number and text
                  if question_text.match(/^(\d+)\.(.+)$/)
                    question_number = $1.to_i
                    question_content = $2.strip

                    # Extract key and hint from question content
                    if question_content.include?("Hint:")
                      parts = question_content.split("Hint:")
                      puts "DEBUG: Hint split parts: #{parts.inspect}" if @debug
                      main_content = parts[0].strip
                      hint_text = extract_hint_safely(parts[1])
                      puts "DEBUG: hint_text: #{hint_text.inspect}" if @debug

                      # Extract key from main content
                      if main_content.include?("Key:")
                        key_parts = main_content.split("Key:")
                        puts "DEBUG: Key split parts: #{key_parts.inspect}" if @debug
                        main_text = key_parts[0].strip
                        key_text = key_parts[1]&.strip
                        puts "DEBUG: key_text: #{key_text.inspect}" if @debug

                        # Extract options from main text
                        options = extract_options(main_text)
                        question_text = remove_options_from_text(main_text)

                        questions << { number: question_number, text: question_text, options: options, key: key_text, hint: hint_text }
                      else
                        # Extract options from main content
                        options = extract_options(main_content)
                        question_text = remove_options_from_text(main_content)

                        questions << { number: question_number, text: question_text, options: options, key: nil, hint: hint_text }
                      end
                    else
                      # No hint, check for key only
                      puts "DEBUG: No hint found, question_content: #{question_content.inspect}" if @debug
                      if question_content.include?("Key:")
                        key_parts = question_content.split("Key:")
                        puts "DEBUG: Key split parts (no hint): #{key_parts.inspect}" if @debug
                        main_text = key_parts[0].strip
                        key_text = key_parts[1]&.strip
                        puts "DEBUG: key_text (no hint): #{key_text.inspect}" if @debug

                        # Extract options from main text
                        options = extract_options(main_text)
                        question_text = remove_options_from_text(main_text)

                        questions << { number: question_number, text: question_text, options: options, key: key_text, hint: nil }
                      else
                        # Extract options from question content
                        options = extract_options(question_content)
                        question_text = remove_options_from_text(question_content)

                        questions << { number: question_number, text: question_text, options: options, key: nil, hint: nil }
                      end
                    end
                  else
                    # Fallback if pattern doesn't match
                    options = extract_options(question_text)
                    clean_text = remove_options_from_text(question_text)
                    questions << { number: nil, text: clean_text, options: options, key: nil, hint: nil }
                  end
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
              # We need to determine the current question number
              current_q_num = nil
              if inside_question && !current_question.empty?
                question_text = current_question.join(" ").strip
                if question_text.match(/^(\d+)\./)
                  current_q_num = $1.to_i
                end
              end

              image_filename = extract_image_from_node(node, zip_file, relationship_targets, current_q_num)
              if image_filename
                current_question << "<img src=\"#{image_filename}\"/>"
              else
                current_question << "<img>"
              end
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
            unless question_text.empty?
              # Extract question number and text
              if question_text.match(/^(\d+)\.(.+)$/)
                question_number = $1.to_i
                question_content = $2.strip

                # Extract key and hint from question content
                if question_content.include?("Hint:")
                  parts = question_content.split("Hint:")
                  main_content = parts[0].strip
                  hint_text = extract_hint_safely(parts[1])

                  # Extract key from main content
                  if main_content.include?("Key:")
                    key_parts = main_content.split("Key:")
                    main_text = key_parts[0].strip
                    key_text = key_parts[1].strip

                    # Extract options from main text
                    options = extract_options(main_text)
                    question_text = remove_options_from_text(main_text)

                    questions << { number: question_number, text: question_text, options: options, key: key_text, hint: hint_text }
                  else
                    # Extract options from main content
                    options = extract_options(main_content)
                    question_text = remove_options_from_text(main_content)

                    questions << { number: question_number, text: question_text, options: options, key: nil, hint: hint_text }
                  end
                else
                  # No hint, check for key only
                  if question_content.include?("Key:")
                    key_parts = question_content.split("Key:")
                    main_text = key_parts[0].strip
                    key_text = key_parts[1].strip

                    # Extract options from main text
                    options = extract_options(main_text)
                    question_text = remove_options_from_text(main_text)

                    questions << { number: question_number, text: question_text, options: options, key: key_text, hint: nil }
                  else
                    # Extract options from question content
                    options = extract_options(question_content)
                    question_text = remove_options_from_text(question_content)

                    questions << { number: question_number, text: question_text, options: options, key: nil, hint: nil }
                  end
                end
              else
                # Fallback if pattern doesn't match
                options = extract_options(question_text)
                clean_text = remove_options_from_text(question_text)
                questions << { number: nil, text: clean_text, options: options, key: nil, hint: nil }
              end
            end
          end
        end
      end

      questions
    end

    def self.extract_json(docx_path, debug: false)
      questions = extract_questions(docx_path, debug: debug)
      create_questions_zip(questions)
    end

    def self.create_questions_zip(questions)
      require "zip"
      require "json"
      require "tempfile"

      # Create a temporary zip file
      temp_zip = Tempfile.new([ "questions", ".zip" ])
      temp_zip.close

      Zip::OutputStream.open(temp_zip.path) do |zip|
        questions.each_with_index do |question, index|
          # Create folder name for each question
          folder_name = "question_#{question[:number] || (index + 1)}"

          # Create JSON content for this question
          question_json = JSON.pretty_generate(question)

          # Add the question.json file to the zip
          zip.put_next_entry("#{folder_name}/question.json")
          zip.write(question_json)

          # Add images folder and images for this question
          question_number = question[:number] || (index + 1)
          if @question_images && @question_images[question_number] && !@question_images[question_number].empty?
            zip.put_next_entry("#{folder_name}/images/")
            @question_images[question_number].each do |filename, image_data|
              zip.put_next_entry("#{folder_name}/images/#{filename}")
              zip.write(image_data)
            end
          end
        end
      end

      # Read the zip file content and return it
      zip_content = File.read(temp_zip.path)
      temp_zip.unlink

      zip_content
    end
  end
end
