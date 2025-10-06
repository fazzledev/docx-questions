# frozen_string_literal: true

require_relative "questions/version"
require "zip"
require "nokogiri"

module Docx
  module Questions
    class Error < StandardError; end

    def self.extract_text(docx_path)
      text_content = []

      Zip::File.open(docx_path) do |zip_file|
        # Find and read the main document XML file
        document_xml = zip_file.find_entry("word/document.xml")
        next unless document_xml

        # Parse the XML content
        doc = Nokogiri::XML(document_xml.get_input_stream.read)

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
              
              # If this paragraph contains equations or math objects, add the eqn tag
              if node.at_xpath('.//m:oMath', namespaces) || node.at_xpath('.//m:oMathPara', namespaces) || 
                 node.at_xpath('.//w:object', namespaces) || node.at_xpath('.//o:OLEObject', namespaces)
                text_parts << '<eqn> '
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
