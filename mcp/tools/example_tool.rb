# frozen_string_literal: true

module InertiaRailsMCP
  module Tools
    class ExampleTool
      def description
        'Get code examples for common Inertia-rails use cases'
      end

      def input_schema
        {
          type: 'object',
          properties: {
            topic: {
              type: 'string',
              enum: ['basic_setup', 'shared_data', 'authentication', 'file_upload', 'pagination', 
                     'validation', 'ssr', 'lazy_loading', 'typescript', 'testing'],
              description: 'Topic for which to show examples'
            }
          },
          required: ['topic']
        }
      end

      def call(arguments)
        topic = arguments['topic']
        
        examples = get_examples
        
        if examples[topic]
          format_example(topic, examples[topic])
        else
          "No example found for topic '#{topic}'"
        end
      end

      private

      def get_examples
        {
          'basic_setup' => {
            description: 'Basic Inertia-rails controller setup',
            code: <<~'RUBY'
              class UsersController < ApplicationController
                def index
                  users = User.all.map do |user|
                    {
                      id: user.id,
                      name: user.name,
                      email: user.email,
                      created_at: user.created_at.to_s
                    }
                  end
                  
                  render inertia: 'Users/Index', props: {
                    users: users
                  }
                end
                
                def show
                  user = User.find(params[:id])
                  
                  render inertia: 'Users/Show', props: {
                    user: {
                      id: user.id,
                      name: user.name,
                      email: user.email,
                      posts_count: user.posts.count
                    }
                  }
                end
              end
            RUBY
          },
          'shared_data' => {
            description: 'Sharing data across all Inertia responses',
            code: <<~'RUBY'
              class ApplicationController < ActionController::Base
                # Method 1: Using a block
                inertia_share do
                  {
                    auth: {
                      user: current_user&.slice(:id, :name, :email, :avatar_url)
                    },
                    flash: flash.to_hash,
                    errors: session.delete(:errors) || {}
                  }
                end
                
                # Method 2: Using a hash
                inertia_share app_name: 'My Awesome App'
                
                # Method 3: Conditional sharing
                before_action :share_notifications
                
                private
                
                def share_notifications
                  if current_user
                    inertia_share do
                      {
                        notifications_count: current_user.notifications.unread.count
                      }
                    end
                  end
                end
              end
            RUBY
          },
          'authentication' => {
            description: 'Authentication flow with Inertia',
            code: <<~'RUBY'
              class SessionsController < ApplicationController
                def new
                  render inertia: 'Auth/Login'
                end
                
                def create
                  user = User.find_by(email: params[:email])
                  
                  if user&.authenticate(params[:password])
                    session[:user_id] = user.id
                    redirect_to root_path
                  else
                    flash.now[:error] = 'Invalid email or password'
                    render inertia: 'Auth/Login', props: {
                      errors: { email: ['Invalid credentials'] }
                    }
                  end
                end
                
                def destroy
                  session.delete(:user_id)
                  redirect_to login_path
                end
              end
              
              # In ApplicationController
              class ApplicationController < ActionController::Base
                inertia_share do
                  {
                    auth: {
                      user: current_user&.slice(:id, :name, :email)
                    }
                  }
                end
                
                private
                
                def current_user
                  @current_user ||= User.find(session[:user_id]) if session[:user_id]
                end
              end
            RUBY
          },
          'file_upload' => {
            description: 'Handling file uploads with Inertia',
            code: <<~'RUBY'
              class ProfilesController < ApplicationController
                def edit
                  render inertia: 'Profile/Edit', props: {
                    user: current_user.slice(:id, :name, :email, :avatar_url)
                  }
                end
                
                def update
                  if current_user.update(profile_params)
                    # Handle avatar upload
                    if params[:avatar]
                      current_user.avatar.attach(params[:avatar])
                    end
                    
                    redirect_to profile_path, notice: 'Profile updated successfully'
                  else
                    render inertia: 'Profile/Edit', props: {
                      user: current_user.slice(:id, :name, :email, :avatar_url),
                      errors: current_user.errors
                    }
                  end
                end
                
                private
                
                def profile_params
                  params.require(:user).permit(:name, :email, :bio)
                end
              end
              
              # Frontend (React example)
              // Use FormData for file uploads
              // const formData = new FormData()
              // formData.append('user[name]', data.name)
              // formData.append('avatar', avatarFile)
              // 
              // Inertia.post('/profile', formData)
            RUBY
          },
          'pagination' => {
            description: 'Implementing pagination with Inertia',
            code: <<~'RUBY'
              class PostsController < ApplicationController
                def index
                  posts = Post.page(params[:page]).per(10)
                  
                  render inertia: 'Posts/Index', props: {
                    posts: {
                      data: posts.map { |post|
                        {
                          id: post.id,
                          title: post.title,
                          excerpt: post.excerpt,
                          author: post.author.name,
                          published_at: post.published_at.to_s
                        }
                      },
                      meta: {
                        current_page: posts.current_page,
                        total_pages: posts.total_pages,
                        total_count: posts.total_count,
                        per_page: posts.limit_value
                      }
                    },
                    filters: {
                      search: params[:search],
                      category: params[:category]
                    }
                  }
                end
              end
              
              # For infinite scroll, use merge:
              class PostsController < ApplicationController
                def index
                  posts = Post.page(params[:page]).per(10)
                  
                  render inertia: 'Posts/Index', props: {
                    posts: merge {
                      posts.map { |post| serialize_post(post) }
                    }
                  }
                end
              end
            RUBY
          },
          'validation' => {
            description: 'Form validation with Inertia',
            code: <<~'RUBY'
              class UsersController < ApplicationController
                def create
                  @user = User.new(user_params)
                  
                  if @user.save
                    redirect_to user_path(@user), notice: 'User created successfully'
                  else
                    render inertia: 'Users/New', props: {
                      user: @user.attributes.except('password_digest'),
                      errors: @user.errors.to_hash
                    }
                  end
                end
                
                private
                
                def user_params
                  params.require(:user).permit(:name, :email, :password)
                end
              end
              
              # Better error handling with form helper
              class ApplicationController < ActionController::Base
                private
                
                def form_errors(model)
                  model.errors.to_hash.transform_values(&:first)
                end
              end
              
              # Usage:
              render inertia: 'Users/New', props: {
                errors: form_errors(@user)
              }
            RUBY
          },
          'ssr' => {
            description: 'Server-side rendering setup',
            code: <<~'RUBY'
              # config/initializers/inertia.rb
              InertiaRails.configure do |config|
                config.ssr_enabled = Rails.env.production?
                config.ssr_url = ENV.fetch('INERTIA_SSR_URL', 'http://localhost:13714')
                
                # Skip SSR for specific requests
                config.skip_ssr = ->(request) {
                  request.bot? || request.path.start_with?('/admin')
                }
              end
              
              # app/controllers/application_controller.rb
              class ApplicationController < ActionController::Base
                # Disable SSR for specific controllers
                inertia_config(
                  ssr_enabled: false
                )
              end
              
              # Running SSR server (package.json)
              # "scripts": {
              #   "ssr": "node ssr.js"
              # }
            RUBY
          },
          'lazy_loading' => {
            description: 'Lazy loading expensive data',
            code: <<~'RUBY'
              class DashboardController < ApplicationController
                def index
                  render inertia: 'Dashboard/Index', props: {
                    # Always loaded
                    user: current_user.slice(:id, :name),
                    
                    # Lazy loaded - only when explicitly requested
                    stats: lazy {
                      {
                        total_revenue: calculate_revenue,
                        active_users: User.active.count,
                        recent_orders: recent_orders_stats
                      }
                    },
                    
                    # Optional - only loaded on partial reloads
                    notifications: optional {
                      current_user.notifications.unread.limit(5).map { |n|
                        { id: n.id, message: n.message, created_at: n.created_at }
                      }
                    },
                    
                    # Deferred - loaded after initial render
                    activity_feed: defer(group: :secondary) {
                      ActivityFeed.recent.limit(20).map { |activity|
                        serialize_activity(activity)
                      }
                    }
                  }
                end
              end
              
              # Frontend usage:
              // const { data, reload } = usePage()
              // 
              // // Load lazy props
              // reload({ only: ['stats'] })
              // 
              // // Load deferred props
              // reload({ only: ['activity_feed'] })
            RUBY
          },
          'typescript' => {
            description: 'TypeScript integration example',
            code: <<~'RUBY'
              # Controller remains the same
              class ProductsController < ApplicationController
                def show
                  product = Product.find(params[:id])
                  
                  render inertia: 'Products/Show', props: {
                    product: {
                      id: product.id,
                      name: product.name,
                      price: product.price,
                      description: product.description,
                      inStock: product.in_stock?
                    }
                  }
                end
              end
              
              # TypeScript types (types/index.d.ts)
              export interface Product {
                id: number
                name: string
                price: number
                description: string
                inStock: boolean
              }
              
              export interface PageProps {
                product: Product
                auth: {
                  user: User | null
                }
                flash: {
                  notice?: string
                  alert?: string
                }
              }
              
              # Component (Products/Show.tsx)
              import { PageProps } from '@/types'
              
              export default function Show({ product }: PageProps) {
                return (
                  <div>
                    <h1>{product.name}</h1>
                    <p>${product.price}</p>
                  </div>
                )
              }
            RUBY
          },
          'testing' => {
            description: 'Testing Inertia responses',
            code: <<~'RUBY'
              # spec/rails_helper.rb
              require 'inertia_rails/rspec'
              
              RSpec.configure do |config|
                config.include InertiaRails::RSpec, type: :request
              end
              
              # spec/requests/users_spec.rb
              require 'rails_helper'
              
              RSpec.describe 'Users', type: :request do
                describe 'GET /users' do
                  it 'returns users list' do
                    users = create_list(:user, 3)
                    
                    get users_path
                    
                    expect_inertia.to render_component('Users/Index')
                    expect_inertia.to have_props(
                      users: array_including(
                        hash_including(id: users.first.id)
                      )
                    )
                  end
                end
                
                describe 'POST /users' do
                  context 'with valid params' do
                    it 'creates user and redirects' do
                      post users_path, params: {
                        user: { name: 'John', email: 'john@example.com' }
                      }
                      
                      expect(response).to redirect_to(user_path(User.last))
                    end
                  end
                  
                  context 'with invalid params' do
                    it 'renders form with errors' do
                      post users_path, params: {
                        user: { name: '', email: 'invalid' }
                      }
                      
                      expect_inertia.to render_component('Users/New')
                      expect_inertia.to have_props(
                        errors: hash_including(
                          name: array_including(String),
                          email: array_including(String)
                        )
                      )
                    end
                  end
                end
              end
            RUBY
          }
        }
      end

      def format_example(topic, example)
        output = []
        output << "📝 Example: #{topic.tr('_', ' ').capitalize}"
        output << "\n#{example[:description]}"
        output << "\n```ruby"
        output << example[:code].strip
        output << "```"
        
        output.join("\n")
      end
    end
  end
end