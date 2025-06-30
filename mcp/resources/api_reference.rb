# frozen_string_literal: true

module InertiaRailsMCP
  module Resources
    class ApiReference
      def name
        'Inertia Rails API Reference'
      end

      def description
        'Complete API reference for Inertia-rails methods, modules, and configuration options'
      end

      def mime_type
        'text/markdown'
      end

      def content
        <<~'MARKDOWN'
          # Inertia Rails API Reference

          ## Controller Methods

          ### render inertia:
          Renders an Inertia response.

          ```ruby
          render inertia: 'ComponentName', props: {}, view_data: {}
          ```

          **Parameters:**
          - `inertia:` (String) - The component path/name to render
          - `props:` (Hash) - Data to pass to the component
          - `view_data:` (Hash) - Data to pass to the layout

          ### inertia_share
          Share data globally across all Inertia responses.

          ```ruby
          # With block
          inertia_share do
            { key: value }
          end

          # With hash
          inertia_share key: value
          ```

          ### use_inertia_instance_props
          Automatically use controller instance variables as props.

          ```ruby
          use_inertia_instance_props
          use_inertia_instance_props only: [:user, :posts]
          use_inertia_instance_props except: [:internal_var]
          ```

          ### inertia_config
          Configure Inertia settings for the controller.

          ```ruby
          inertia_config(
            ssr_enabled: true,
            component_path_resolver: ->(path:, action:) { "Custom/#{path}/#{action}" }
          )
          ```

          ### inertia_location
          Perform a client-side visit to a URL.

          ```ruby
          inertia_location(url)
          ```

          ## Prop Types

          ### lazy
          Create lazy-loaded props that only evaluate when requested.

          ```ruby
          lazy { expensive_calculation }
          ```

          ### optional  
          Props only included during partial reloads.

          ```ruby
          optional { data }
          ```

          ### defer
          Props loaded after initial page render.

          ```ruby
          defer { data }
          defer(group: :secondary) { data }
          ```

          ### merge
          Props that merge with existing data (for pagination).

          ```ruby
          merge { paginated_data }
          ```

          ## Configuration

          ### InertiaRails.configure
          Global configuration in initializer.

          ```ruby
          InertiaRails.configure do |config|
            # Request configurations
            config.version = '1.0'
            config.default_render = true
            
            # SSR configurations
            config.ssr_enabled = true
            config.ssr_url = 'http://localhost:13714'
            config.skip_ssr = ->(request) { request.bot? }
            
            # Component resolution
            config.component_path_resolver = ->(path:, action:) { "#{path}/#{action}" }
            
            # Deep merging for shared data
            config.deep_merge_shared_data = false
            
            # Encryption for history
            config.encrypt_history = false
            config.encrypt_cookie = 'inertia.encrypt_auth_token'
          end
          ```

          ## Request/Response Headers

          ### Request Headers
          - `X-Inertia` - Identifies Inertia requests
          - `X-Inertia-Version` - Current asset version
          - `X-Inertia-Partial-Data` - Requested props for partial reload
          - `X-Inertia-Partial-Component` - Component for partial reload
          - `X-Inertia-Partial-Except` - Props to exclude
          - `X-Inertia-Error-Bag` - Error bag identifier

          ### Response Headers  
          - `X-Inertia` - Confirms Inertia response
          - `X-Inertia-Location` - URL for client-side redirect
          - `Vary: X-Inertia` - Caching header

          ## Middleware

          The InertiaRails middleware handles:
          - Asset version checking (409 responses)
          - Redirect status codes (303 for PUT/PATCH/DELETE)
          - Shared data processing
          - CSRF token cookies

          ## Testing

          ### RSpec Matchers

          ```ruby
          # Check component
          expect_inertia.to render_component('Users/Index')

          # Check props
          expect_inertia.to have_props(users: array_including(...))
          expect_inertia.to have_exact_props(name: 'John')

          # Check shared data
          expect_inertia.to have_shared_data(user: hash_including(...))
          ```

          ## Generators

          ### install
          ```bash
          rails generate inertia:install [framework]
          # frameworks: react, vue, svelte
          ```

          ### controller
          ```bash  
          rails generate inertia:controller Users index show
          ```

          ### scaffold
          ```bash
          rails generate inertia:scaffold Post title:string body:text
          ```
        MARKDOWN
      end
    end
  end
end