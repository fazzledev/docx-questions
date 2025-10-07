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

    def self.convert_mathtype_to_latex(ole_data)
      # Create a temporary file to store the OLE data
      temp_file = Tempfile.new(["equation", ".bin"])
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

            # Extract text content
            node.xpath(".//w:t", namespaces).each do |text_node|
              curr_text = text_node.text
              para_parts << curr_text if curr_text && !curr_text.strip.empty?
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
              current_question = [para_text]
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
            next unless inside_question && (ole_object = node.at_xpath(".//o:OLEObject", namespaces))

            rel_id = ole_object["r:id"]
            next unless (target = relationship_targets[rel_id])

            # Read the OLE object data
            ole_entry = zip_file.find_entry("word/#{target}")
            next unless ole_entry

            begin
              ole_data = ole_entry.get_input_stream.read
              mathml = convert_mathtype_to_latex(ole_data)
              current_question << mathml
            rescue StandardError
              # If conversion fails, skip this equation
              next
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
