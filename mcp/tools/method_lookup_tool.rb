# frozen_string_literal: true

module InertiaRailsMCP
  module Tools
    class MethodLookupTool
      def description
        'Look up Inertia-rails methods, their signatures, and usage examples'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            method_name: {
              type: 'string',
              description: 'Name of the method to look up (e.g., "render", "inertia_share")'
            },
            include_source: {
              type: 'boolean',
              description: 'Include source code location',
              default: false
            }
          },
          required: ['method_name']
        }
      end

      def call(arguments)
        method_name = arguments['method_name']
        include_source = arguments['include_source'] || false
        
        # Load inertia_rails to inspect methods
        require 'inertia_rails' rescue nil
        
        method_info = find_method_info(method_name)
        
        if method_info.empty?
          "Method '#{method_name}' not found in Inertia-rails"
        else
          format_method_info(method_info, include_source)
        end
      end

      private

      def find_method_info(method_name)
        methods = {
          'render' => {
            signature: 'render inertia: component_name, props: {}, view_data: {}',
            description: 'Render an Inertia response with the specified component and props',
            module: 'InertiaRails::Controller',
            example: <<~'RUBY'
              def index
                render inertia: 'Users/Index', props: {
                  users: User.all.map { |user|
                    { id: user.id, name: user.name, email: user.email }
                  }
                }
              end
            RUBY
          },
          'inertia_share' => {
            signature: 'inertia_share(key => value) or inertia_share { hash }',
            description: 'Share data globally across all Inertia responses',
            module: 'InertiaRails::Controller',
            example: <<~'RUBY'
              class ApplicationController < ActionController::Base
                inertia_share do
                  {
                    current_user: current_user&.slice(:id, :name, :email),
                    flash: flash.to_hash
                  }
                end
              end
            RUBY
          },
          'use_inertia_instance_props' => {
            signature: 'use_inertia_instance_props(only: [], except: [])',
            description: 'Automatically use controller instance variables as Inertia props',
            module: 'InertiaRails::Controller',
            example: <<~'RUBY'
              class UsersController < ApplicationController
                use_inertia_instance_props only: [:user, :users]
                
                def show
                  @user = User.find(params[:id])
                  render inertia: 'Users/Show'
                  # @user will be automatically passed as a prop
                end
              end
            RUBY
          },
          'inertia_config' => {
            signature: 'inertia_config(option => value)',
            description: 'Configure Inertia settings for the controller',
            module: 'InertiaRails::Controller',
            example: <<~'RUBY'
              class AdminController < ApplicationController
                inertia_config(
                  component_path_resolver: ->(path:, action:) { "Admin/#{path}/#{action}" },
                  ssr_enabled: false
                )
              end
            RUBY
          },
          'inertia_location' => {
            signature: 'inertia_location(url)',
            description: 'Perform a client-side redirect in Inertia',
            module: 'InertiaRails::Controller',
            example: <<~'RUBY'
              def create
                @user = User.create(user_params)
                if @user.save
                  inertia_location user_path(@user)
                else
                  render inertia: 'Users/New', props: { errors: @user.errors }
                end
              end
            RUBY
          },
          'lazy' => {
            signature: 'lazy { value }',
            description: 'Create a lazy-loaded prop that only evaluates when explicitly requested',
            module: 'InertiaRails',
            example: <<~'RUBY'
              render inertia: 'Dashboard', props: {
                user: current_user,
                stats: lazy { 
                  expensive_calculation 
                }
              }
            RUBY
          },
          'optional' => {
            signature: 'optional { value }',
            description: 'Create an optional prop that is only included during partial reloads',
            module: 'InertiaRails',
            example: <<~'RUBY'
              render inertia: 'Users/Index', props: {
                users: User.all,
                filters: optional { 
                  available_filters 
                }
              }
            RUBY
          },
          'defer' => {
            signature: 'defer(group: nil) { value }',
            description: 'Create a deferred prop that loads after the initial page render',
            module: 'InertiaRails',
            example: <<~'RUBY'
              render inertia: 'Dashboard', props: {
                user: current_user,
                notifications: defer(group: :secondary) { 
                  current_user.notifications.unread 
                }
              }
            RUBY
          },
          'merge' => {
            signature: 'merge { value }',
            description: 'Create a mergeable prop for handling paginated data',
            module: 'InertiaRails',
            example: <<~'RUBY'
              render inertia: 'Posts/Index', props: {
                posts: merge { 
                  Post.page(params[:page]).map { |post|
                    { id: post.id, title: post.title }
                  }
                }
              }
            RUBY
          }
        }
        
        # Search for exact match or partial match
        if methods[method_name]
          [methods[method_name].merge(name: method_name)]
        else
          methods.select { |name, _| name.include?(method_name.downcase) }
                 .map { |name, info| info.merge(name: name) }
        end
      end

      def format_method_info(method_infos, include_source)
        output = []
        
        method_infos.each do |info|
          output << "📚 #{info[:name]}"
          output << "\nSignature: #{info[:signature]}"
          output << "Module: #{info[:module]}" if info[:module]
          output << "\n#{info[:description]}"
          
          if info[:example]
            output << "\nExample:"
            output << "```ruby"
            output << info[:example].strip
            output << "```"
          end
          
          if include_source && info[:module]
            output << "\nSource: lib/inertia_rails/controller.rb" 
          end
          
          output << "\n---" if method_infos.size > 1
        end
        
        output.join("\n").strip
      end
    end
  end
end