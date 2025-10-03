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

        # Extract text from all text nodes in the document
        doc.xpath("//w:t").each do |text_node|
          text_content << text_node.text
        end
      end

      text_content.join
    end
  end
end
