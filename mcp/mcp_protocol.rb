# frozen_string_literal: true

require 'json'

module InertiaRailsMCP
  module MCPProtocol
    private

    def read_request
      headers = {}
      
      # Read headers until empty line
      loop do
        line = $stdin.gets
        return nil unless line
        
        line = line.strip
        break if line.empty?
        
        if line.match(/^([^:]+):\s*(.+)$/)
          headers[$1.downcase] = $2
        end
      end

      # Read content based on Content-Length
      content_length = headers['content-length']&.to_i
      return nil unless content_length

      content = $stdin.read(content_length)
      JSON.parse(content)
    rescue JSON::ParserError => e
      $stderr.puts "Failed to parse JSON: #{e.message}"
      nil
    end

    def write_response(response)
      json = JSON.generate(response)
      
      $stdout.puts "Content-Length: #{json.bytesize}"
      $stdout.puts
      $stdout.print json
      $stdout.flush
    end

    def write_error_response(id, code, message)
      write_response({
        jsonrpc: '2.0',
        id: id,
        error: {
          code: code,
          message: message
        }
      })
    end

    def success_response(id, result)
      {
        jsonrpc: '2.0',
        id: id,
        result: result
      }
    end

    def error_response(id, code, message)
      {
        jsonrpc: '2.0',
        id: id,
        error: {
          code: code,
          message: message
        }
      }
    end
  end
end