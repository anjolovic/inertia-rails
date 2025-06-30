# frozen_string_literal: true

require 'pathname'

module InertiaRailsMCP
  module Tools
    class DocumentationTool
      def description
        'Search and retrieve Inertia-rails documentation'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'Search query for documentation (e.g., "render", "props", "shared data")'
            },
            category: {
              type: 'string',
              enum: ['guide', 'cookbook', 'api', 'all'],
              description: 'Documentation category to search in',
              default: 'all'
            }
          },
          required: ['query']
        }
      end

      def call(arguments)
        query = arguments['query'] || ''
        category = arguments['category'] || 'all'
        
        results = search_documentation(query, category)
        
        if results.empty?
          "No documentation found for '#{query}'"
        else
          format_results(results, query)
        end
      end

      private

      def search_documentation(query, category)
        docs_path = File.expand_path('../../../docs', __dir__)
        results = []
        
        search_paths = case category
        when 'guide'
          [File.join(docs_path, 'guide')]
        when 'cookbook'
          [File.join(docs_path, 'cookbook')]
        when 'api'
          [File.join(docs_path, 'api')]
        else
          [docs_path]
        end
        
        search_paths.each do |path|
          next unless File.directory?(path)
          
          Dir.glob("#{path}/**/*.md").each do |file|
            content = File.read(file)
            next unless content.downcase.include?(query.downcase)
            
            # Extract relevant sections
            sections = extract_relevant_sections(content, query)
            next if sections.empty?
            
            results << {
              file: file.sub(docs_path + '/', ''),
              sections: sections
            }
          end
        end
        
        results
      end

      def extract_relevant_sections(content, query)
        sections = []
        lines = content.lines
        
        lines.each_with_index do |line, index|
          next unless line.downcase.include?(query.downcase)
          
          # Find the section header
          header = find_section_header(lines, index)
          
          # Extract context around the match
          context_start = [index - 2, 0].max
          context_end = [index + 2, lines.length - 1].min
          
          context = lines[context_start..context_end].join.strip
          
          sections << {
            header: header,
            content: context,
            line: index + 1
          }
        end
        
        sections.first(3) # Limit to 3 most relevant sections
      end

      def find_section_header(lines, index)
        # Search backwards for the nearest header
        (0..index).reverse_each do |i|
          if lines[i] =~ /^#+\s+(.+)$/
            return $1.strip
          end
        end
        'Introduction'
      end

      def format_results(results, query)
        output = ["Documentation for '#{query}':\n"]
        
        results.each do |result|
          output << "\n📄 #{result[:file]}"
          
          result[:sections].each do |section|
            output << "\n  § #{section[:header]} (line #{section[:line]})"
            output << "  #{section[:content].lines.map { |l| '    ' + l }.join}"
          end
        end
        
        output.join("\n")
      end
    end
  end
end