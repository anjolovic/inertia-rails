# frozen_string_literal: true

module InertiaRailsMCP
  module Tools
    class ChangelogTool
      def description
        'Look up changes, new features, and breaking changes in Inertia-rails versions'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            version: {
              type: 'string',
              description: 'Specific version to look up (e.g., "3.0.0") or "latest"'
            },
            search: {
              type: 'string',
              description: 'Search for specific features or changes'
            }
          }
        }
      end

      def call(arguments)
        version = arguments['version']
        search = arguments['search']
        
        changelog_path = File.expand_path('../../../CHANGELOG.md', __dir__)
        
        unless File.exist?(changelog_path)
          return "CHANGELOG.md not found"
        end
        
        content = File.read(changelog_path)
        
        if version
          find_version_info(content, version)
        elsif search
          search_changelog(content, search)
        else
          latest_changes(content)
        end
      end

      private

      def find_version_info(content, version)
        if version == 'latest'
          latest_changes(content)
        else
          # Find specific version section
          version_pattern = /^##?\s*\[?v?#{Regexp.escape(version)}\]?.*$/i
          
          if content =~ version_pattern
            start_index = content.index(version_pattern)
            # Find next version header
            remaining = content[start_index..-1]
            next_version = remaining.index(/^##?\s*\[?v?\d+\.\d+\.\d+/, 1)
            
            section = if next_version
              remaining[0...next_version]
            else
              remaining
            end
            
            "📋 Version #{version}:\n\n#{section.strip}"
          else
            "Version #{version} not found in changelog"
          end
        end
      end

      def search_changelog(content, search)
        results = []
        current_version = nil
        
        content.lines.each_with_index do |line, index|
          # Track current version
          if line =~ /^##?\s*\[?v?(\d+\.\d+\.\d+)\]?/
            current_version = $1
          end
          
          # Search for term
          if line.downcase.include?(search.downcase) && current_version
            results << {
              version: current_version,
              line: line.strip,
              context: extract_context(content.lines, index)
            }
          end
        end
        
        if results.empty?
          "No results found for '#{search}'"
        else
          format_search_results(results, search)
        end
      end

      def latest_changes(content)
        # Find the first version section
        first_version = content.match(/^##?\s*\[?v?(\d+\.\d+\.\d+)\]?.*$/)
        return "No version information found" unless first_version
        
        start_index = content.index(first_version[0])
        remaining = content[start_index..-1]
        
        # Find next version or take up to 50 lines
        next_version = remaining.index(/^##?\s*\[?v?\d+\.\d+\.\d+/, 1)
        
        section = if next_version
          remaining[0...next_version]
        else
          remaining.lines.first(50).join
        end
        
        "📋 Latest changes:\n\n#{section.strip}"
      end

      def extract_context(lines, index)
        start = [index - 1, 0].max
        finish = [index + 1, lines.length - 1].min
        lines[start..finish].map(&:strip).join("\n")
      end

      def format_search_results(results, search)
        output = ["🔍 Search results for '#{search}':\n"]
        
        grouped = results.group_by { |r| r[:version] }
        
        grouped.each do |version, items|
          output << "\n📌 Version #{version}:"
          items.each do |item|
            output << "  • #{item[:line]}"
          end
        end
        
        output.join("\n")
      end
    end
  end
end