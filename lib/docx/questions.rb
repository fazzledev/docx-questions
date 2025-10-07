# frozen_string_literal: true

require_relative "questions/version"
require "zip"
require "nokogiri"
require "mathtype_to_mathml"
require "tempfile"

module Docx
  module Questions
    class Error < StandardError; end
    
    def self.convert_mathtype_to_latex(ole_data)
      # Create a temporary file to store the OLE data
      temp_file = Tempfile.new(['equation', '.bin'])
      begin
        temp_file.binmode
        temp_file.write(ole_data)
        temp_file.close
        
        # Convert using the file path
        mathml = MathTypeToMathML::Converter.new(temp_file.path).convert
        # Extract just the <math> tag part and remove extra whitespace
        if mathml =~ /(<math.*?<\/math>)/m
          mathml = $1.gsub(/\s+/, ' ').strip
        end
        mathml
      rescue => e
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
        rels.xpath('//xmlns:Relationship').each do |rel|
          relationship_targets[rel['Id']] = rel['Target']
        end

        # Define namespaces for XPath queries
        namespaces = {
          'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
          'm' => 'http://schemas.openxmlformats.org/officeDocument/2006/math',
          'o' => 'urn:schemas-microsoft-com:office:office'
        }

        # Process the document body
        body = doc.at_xpath('//w:body', namespaces)
        if body
          text_parts = []
          
          # Process nodes in document order
          body.children.each do |node|
            if node.name == 'p'
              para_text = []
              node.xpath('.//w:t', namespaces).each do |text_node|
                curr_text = text_node.text
                if curr_text && !curr_text.strip.empty?
                  para_text << curr_text
                end
              end

              # Add text from this paragraph
              para_content = para_text.join
              text_parts << para_content unless para_content.empty?
              
              # If this paragraph contains an image, add the img tag after the paragraph text
              if node.at_xpath('.//w:drawing', namespaces) || node.at_xpath('.//w:pict', namespaces)
                text_parts << '<img>'
              end
              
              # If this paragraph contains an OLE object, convert it to LaTeX
              if ole_object = node.at_xpath('.//o:OLEObject', namespaces)
                rel_id = ole_object['r:id']
                if target = relationship_targets[rel_id]
                  # Read the OLE object data
                  ole_entry = zip_file.find_entry("word/#{target}")
                  if ole_entry
                    begin
                      ole_data = ole_entry.get_input_stream.read
                      mathml = convert_mathtype_to_latex(ole_data)
                      text_parts << "#{mathml} "
                    rescue => e
                      # If conversion fails, skip this equation
                      next
                    end
                  else
                    next
                  end
                end
              end
            end
          end
          
          text = text_parts.join
          text_content << text.strip unless text.empty?
        end
      end

      text_content.join
    end
  end
end
