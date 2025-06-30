#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'pathname'

# Add the gem lib directory to the load path
lib_path = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

require_relative 'mcp_protocol'
require_relative 'tools/documentation_tool'
require_relative 'tools/method_lookup_tool'
require_relative 'tools/changelog_tool'
require_relative 'tools/example_tool'
require_relative 'resources/api_reference'
require_relative 'resources/configuration_reference'

module InertiaRailsMCP
  class Server
    include MCPProtocol

    def initialize
      @tools = {
        'documentation' => Tools::DocumentationTool.new,
        'method_lookup' => Tools::MethodLookupTool.new,
        'changelog' => Tools::ChangelogTool.new,
        'example' => Tools::ExampleTool.new
      }

      @resources = {
        'api_reference' => Resources::ApiReference.new,
        'configuration' => Resources::ConfigurationReference.new
      }

      @server_info = {
        name: 'inertia-rails-mcp',
        version: '1.0.0',
        protocol_version: '2024-11-05'
      }
    end

    def run
      loop do
        request = read_request
        next unless request

        response = handle_request(request)
        write_response(response)
      rescue => e
        write_error_response(request['id'], -32603, "Internal error: #{e.message}")
      end
    end

    private

    def handle_request(request)
      case request['method']
      when 'initialize'
        handle_initialize(request)
      when 'tools/list'
        handle_tools_list(request)
      when 'tools/call'
        handle_tool_call(request)
      when 'resources/list'
        handle_resources_list(request)
      when 'resources/read'
        handle_resource_read(request)
      when 'completion/complete'
        handle_completion(request)
      else
        error_response(request['id'], -32601, "Method not found: #{request['method']}")
      end
    end

    def handle_initialize(request)
      success_response(request['id'], {
        protocolVersion: @server_info[:protocol_version],
        capabilities: {
          tools: {},
          resources: {},
          completion: {}
        },
        serverInfo: @server_info
      })
    end

    def handle_tools_list(request)
      tools = @tools.map do |name, tool|
        {
          name: "inertia_rails_#{name}",
          description: tool.description,
          inputSchema: tool.input_schema
        }
      end

      success_response(request['id'], { tools: tools })
    end

    def handle_tool_call(request)
      tool_name = request['params']['name'].sub(/^inertia_rails_/, '')
      tool = @tools[tool_name]

      unless tool
        return error_response(request['id'], -32602, "Tool not found: #{request['params']['name']}")
      end

      result = tool.call(request['params']['arguments'] || {})
      success_response(request['id'], {
        content: [
          {
            type: 'text',
            text: result
          }
        ]
      })
    end

    def handle_resources_list(request)
      resources = @resources.map do |name, resource|
        {
          uri: "inertia-rails://#{name}",
          name: resource.name,
          description: resource.description,
          mimeType: resource.mime_type
        }
      end

      success_response(request['id'], { resources: resources })
    end

    def handle_resource_read(request)
      uri = request['params']['uri']
      resource_name = uri.sub(/^inertia-rails:\/\//, '')
      resource = @resources[resource_name]

      unless resource
        return error_response(request['id'], -32602, "Resource not found: #{uri}")
      end

      success_response(request['id'], {
        contents: [
          {
            uri: uri,
            mimeType: resource.mime_type,
            text: resource.content
          }
        ]
      })
    end

    def handle_completion(request)
      # Basic completion support for Inertia-rails methods and options
      ref = request['params']['ref'] || {}
      argument = request['params']['argument'] || {}
      
      completions = []
      
      # Add method completions
      if argument['name'] == 'method'
        completions = [
          { value: 'render inertia:', description: 'Render an Inertia response' },
          { value: 'inertia_share', description: 'Share data across all Inertia responses' },
          { value: 'use_inertia_instance_props', description: 'Use instance variables as props' },
          { value: 'inertia_config', description: 'Configure Inertia settings' },
          { value: 'inertia_location', description: 'Redirect with Inertia' }
        ]
      end

      success_response(request['id'], {
        completion: {
          values: completions,
          total: completions.length,
          hasMore: false
        }
      })
    end
  end
end

# Run the server
InertiaRailsMCP::Server.new.run if __FILE__ == $0