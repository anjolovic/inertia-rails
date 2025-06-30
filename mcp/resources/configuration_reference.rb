# frozen_string_literal: true

module InertiaRailsMCP
  module Resources
    class ConfigurationReference
      def name
        'Inertia Rails Configuration Guide'
      end

      def description
        'Comprehensive guide to configuring Inertia-rails in your application'
      end

      def mime_type
        'text/markdown'
      end

      def content
        <<~'MARKDOWN'
          # Inertia Rails Configuration Guide

          ## Initial Setup

          ### 1. Add to Gemfile
          ```ruby
          gem 'inertia_rails'
          ```

          ### 2. Install Generator
          ```bash
          rails generate inertia:install react
          # or: vue, svelte
          ```

          ### 3. Configure Initializer
          Create `config/initializers/inertia.rb`:

          ```ruby
          InertiaRails.configure do |config|
            # Configuration options
          end
          ```

          ## Configuration Options

          ### Version Management
          Control when to force page refreshes:

          ```ruby
          config.version = '1.0'
          # or use a lambda for dynamic versions
          config.version = -> { Rails.application.assets_manifest.version }
          ```

          ### Default Rendering
          Automatically render Inertia responses:

          ```ruby
          config.default_render = true
          ```

          ### Component Path Resolution
          Customize component name resolution:

          ```ruby
          # Default behavior
          config.component_path_resolver = ->(path:, action:) { "#{path}/#{action}" }

          # Add prefix
          config.component_path_resolver = ->(path:, action:) { "Pages/#{path}/#{action}" }

          # Based on controller namespace
          config.component_path_resolver = ->(path:, action:) {
            controller_namespace = controller.class.name.deconstantize
            "#{controller_namespace}/#{path}/#{action}"
          }
          ```

          ### Shared Data
          Configure how shared data is merged:

          ```ruby
          # Deep merge shared data (default: false)
          config.deep_merge_shared_data = true
          ```

          ### Server-Side Rendering (SSR)

          ```ruby
          # Enable/disable SSR
          config.ssr_enabled = true

          # SSR server URL
          config.ssr_url = ENV.fetch('INERTIA_SSR_URL', 'http://localhost:13714')

          # Skip SSR conditionally
          config.skip_ssr = ->(request) {
            # Skip for bots
            request.bot? ||
            # Skip for specific paths
            request.path.start_with?('/admin') ||
            # Skip in development
            Rails.env.development?
          }
          ```

          ### History Encryption
          Enable encrypted history for back/forward navigation:

          ```ruby
          config.encrypt_history = true
          config.encrypt_cookie = 'inertia.encrypt_auth_token'
          ```

          ## Controller-Level Configuration

          Override global settings per controller:

          ```ruby
          class AdminController < ApplicationController
            inertia_config(
              ssr_enabled: false,
              component_path_resolver: ->(path:, action:) { "Admin/#{path}/#{action}" }
            )
          end
          ```

          ## Frontend Configuration

          ### Vite Integration
          Configure `vite.config.js`:

          ```javascript
          export default {
            plugins: [
              // Framework plugin (react, vue, etc.)
            ],
            resolve: {
              alias: {
                '@': '/app/javascript',
              }
            }
          }
          ```

          ### Application Layout
          Update `app/views/layouts/application.html.erb`:

          ```erb
          <!DOCTYPE html>
          <html>
            <head>
              <%= csrf_meta_tags %>
              <%= csp_meta_tag %>
              <%= vite_client_tag %>
              <%= vite_javascript_tag 'application' %>
              <!--
                To load Inertia Page props in production, we need to include app css as well.
                This ensures that vite will process the JavaScript file containing the props.
              -->
              <%= vite_stylesheet_tag 'application' %>
            </head>
            <body>
              <%= yield %>
            </body>
          </html>
          ```

          ### Frontend Entry Point
          Configure `app/javascript/application.js`:

          ```javascript
          import { createApp, h } from 'vue'
          import { createInertiaApp } from '@inertiajs/vue3'

          createInertiaApp({
            resolve: name => {
              const pages = import.meta.glob('./Pages/**/*.vue', { eager: true })
              return pages[`./Pages/${name}.vue`]
            },
            setup({ el, App, props, plugin }) {
              createApp({ render: () => h(App, props) })
                .use(plugin)
                .mount(el)
            },
          })
          ```

          ## Environment-Specific Configuration

          ### Development
          ```ruby
          # config/environments/development.rb
          config.inertia.default_render = true
          ```

          ### Production
          ```ruby
          # config/environments/production.rb
          config.inertia.version = -> { 
            Rails.application.assets_manifest.find_sources('application.js').first&.integrity 
          }
          config.inertia.ssr_enabled = true
          ```

          ### Testing
          ```ruby
          # config/environments/test.rb
          config.inertia.default_render = false
          config.inertia.ssr_enabled = false
          ```

          ## Common Patterns

          ### Multi-tenant Configuration
          ```ruby
          class ApplicationController < ActionController::Base
            before_action :configure_inertia_for_tenant
            
            private
            
            def configure_inertia_for_tenant
              if current_tenant.custom_theme?
                inertia_config(
                  component_path_resolver: ->(path:, action:) { 
                    "Tenants/#{current_tenant.slug}/#{path}/#{action}" 
                  }
                )
              end
            end
          end
          ```

          ### API/Web Hybrid Apps
          ```ruby
          class ApplicationController < ActionController::Base
            # Skip Inertia for API requests
            inertia_config(
              default_render: -> { !request.path.start_with?('/api') }
            )
          end
          ```

          ## Troubleshooting

          ### Common Issues

          1. **Version Mismatch Errors**
             - Ensure version config matches between deploys
             - Clear browser cache/storage

          2. **SSR Not Working**
             - Check SSR server is running
             - Verify SSR URL is accessible
             - Check for JavaScript errors in SSR build

          3. **Props Not Available**
             - Verify default_render is enabled
             - Check for before_action filters
             - Ensure props are serializable

          ### Debug Mode
          ```ruby
          # Enable detailed logging
          Rails.logger.level = :debug
          
          # Log Inertia requests
          config.after_action_proc = -> {
            Rails.logger.debug "Inertia: #{@_inertia_props}"
          }
          ```
        MARKDOWN
      end
    end
  end
end