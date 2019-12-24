# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'registrations',
    passwords:     'passwords',
    unlocks:       'unlocks',
    sessions:      'sessions'
  }

  # Force login for Tor
  constraints CannotAccessWebsite do
    root to: redirect('/users/sign_in'), as: nil
    match '*path', to: redirect('/users/sign_in'), via: :all
  end

  namespace :filters, module: 'filters' do
    resource :current, only: [:show, :update]
    resource :spoiler, only: [:create, :destroy]
    resource :hide,    only: [:create, :destroy]
  end
  resources :filters

  resources :forums do
    resources :topics, except: [:index] do
      scope module: 'topics' do
        resource :lock,  only: [:create, :destroy]
        resource :stick, only: [:create, :destroy]
        resource :hide,  only: [:create, :destroy]
        resource :move,  only: [:create]

        resources :posts, except: [:index, :show] do
          scope module: 'posts' do
            resource :hide,    only: [:create, :destroy]
            resource :history, only: [:show]
          end
        end

        resource :poll, only: [] do
          scope module: 'polls' do
            resources :voters, only: [:index]
          end
        end
      end
    end
  end

  resources :dnp_entries, path: 'dnp' do
    scope module: 'dnp_entries' do
      resource :rescind, only: [:create]
    end
  end

  # Top-Level Post Controller functionality.
  namespace :posts, module: 'posts' do
    resource :posted,  only: [:show]
    resource :preview, only: [:create]
  end
  resources :posts, only: [:index]

  resources :poll_votes, only: [:create]

  namespace :api do
    namespace :v2 do
      get 'images/show'
      get 'images/fetch_many'
      get 'tags/show'
      get 'tags/fetch_many'
      get 'users/current'
      get 'users/show'
      get 'users/fetch_many'
      get 'notifications/unread'
      put 'notifications/watch'
      put 'notifications/unwatch'
      put 'notifications/mark_read'
      get 'interactions/interacted'
      put 'interactions/vote'
      put 'interactions/fave'
      put 'interactions/hide'
    end
  end

  resources :channels

  resources :profiles, except: [:index, :new, :create, :destroy] do
    scope module: 'profiles' do
      resource :details,         only:   [:show]
      resource :downvotes,       only:   [:destroy]
      resource :fp_history,      only:   [:show]
      resource :ip_history,      only:   [:show]
      resource :scratchpad,      only:   [:edit, :update]
      resource :votes_and_faves, only:   [:destroy]
      resources :aliases,        only:   [:index]
      resources :badge_awards,   except: [:index]
      resources :source_changes, only:   [:index]
      resources :tag_changes,    only:   [:index]
    end
  end

  # Lists
  get '/lists' => 'lists#index'
  get '/lists/user_comments/:user_id' => 'lists#my_comments'
  get '/lists/my_comments'
  get '/lists/recent_comments'

  # Activity
  resource :activity, only: [:show]

  # Notifications
  resources :notifications, only: [:index]

  # Settings
  resource :settings, only: [:edit, :update]
  get '/settings', to: redirect('/settings/edit')

  get '/search/reverse' => 'search#reverse'
  get 'search/reverse'
  post 'search/reverse'
  get '/search/syntax' => 'search#syntax'
  get 'search/syntax'
  get 'search/index', action: :index, controller: :search
  get '/search' => 'search#index'
  get 'images/search' => 'search#index'
  post 'images/scrape_url' => 'images#scrape_url', as: :scrape_url

  namespace :conversations, module: 'conversations' do
    resource :hide_batch, only: [:create]
  end
  resources :conversations do
    scope module: 'conversations' do
      resource :hide,      only: [:create, :destroy]
      resource :read,      only: [:create, :destroy]
      resources :messages, only: [:new, :create]
    end
  end

  resources :duplicate_reports, except: [:update] do
    scope module: 'duplicate_reports' do
      resource :accept,         only: [:create]
      resource :accept_reverse, only: [:create]
      resource :claim,          only: [:create]
      resource :reject,         only: [:create]
    end
  end

  namespace :images, module: 'images' do
    resource :watched, only: [:show]
    resource :preview, only: [:create]
  end
  resources :images do
    scope module: 'images' do
      resource :comment_lock,     only: [:create, :destroy]
      resource :description_lock, only: [:create, :destroy]
      resource :description,      only: [:update]
      resource :feature,          only: [:create]
      resource :file,             only: [:update]
      resource :hash,             only: [:destroy]
      resource :hide,             only: [:create, :update, :destroy]
      resource :related,          only: [:show]
      resource :repair,           only: [:create]
      resource :reporting,        only: [:show]
      resource :scratchpad,       only: [:edit, :update]
      resource :source_history,   only: [:destroy]
      resource :source,           only: [:update]
      resource :tag_lock,         only: [:create, :destroy]
      resource :tags,             only: [:update]
      resource :uploader,         only: [:update]
      resources :favorites,       only: [:index]
      resources :source_changes,  only: [:index]
      resources :tag_changes,     only: [:index]
      resources :votes,           only: [:destroy]

      resources :comments do
        scope module: 'comments' do
          resource :hide,    only: [:create, :destroy]
          resource :history, only: [:show]
        end
      end
    end
  end

  # oEmbed API
  resource :oembed, only: [:show]

  resources :reports, only: [:index, :new, :create]

  namespace :tags, module: 'tags' do
    resource :autocomplete, only: [:show]
    resources :aliases,     only: [:index]
    resources :ratings,     only: [:index]
  end
  resources :tags do
    scope module: 'tags' do
      resource :watch,        only: [:create, :destroy]
      resource :usage,        only: [:show]
      resources :tag_changes, only: [:index]
    end
  end

  resources :comments, only: [:index]

  resources :tag_changes do
    collection { delete :mass_revert }
  end
  resources :source_changes

  resources :adverts, only: [:show]

  resources :galleries do
    scope module: 'galleries' do
      resource :random,  only: [:show]
      resource :order,   only: [:update]
      resources :images, only: [:create, :destroy]
    end
  end

  resources :commissions do
    scope module: 'commissions' do
      resources :items
    end
  end

  resources :user_links

  namespace :admin do
    constraints CanAccessJobs do
      mount Sidekiq::Web => '/sidekiq'
    end

    constraints CanAccessFlipper do
      mount Flipper::UI.app($flipper) => '/flipper'
    end

    resources :forums
    resources :mod_notes
    resources :user_bans
    resources :user_whitelists
    resources :subnet_bans
    resources :fingerprint_bans
    resources :site_notices
    resources :adverts

    resources :badges do
      scope module: 'badges' do
        resources :users, only: [:index]
      end
    end

    resources :users do
      scope module: 'users' do
        resource :activation, only: [:create, :destroy]
        resource :api_key,    only: [:destroy]
        resource :wipe,       only: [:create]
      end
    end

    resources :user_links do
      scope module: 'user_links' do
        resource :transition, only: [:create]
      end
    end

    resources :tags do
      scope module: 'tags' do
        resource :reindex, only: [:create]
        resource :slug,    only: [:create]
      end
    end

    resources :reports do
      scope module: 'reports' do
        resource :close, only: [:create, :destroy]
        resource :claim, only: [:create, :destroy]
      end
    end

    resources :dnp_entries do
      scope module: 'dnp_entries' do
        resource :transition, only: [:create]
      end
    end

    namespace :donations, module: 'donations' do
      resources :users, only: [:show]
    end
    resources :donations

    namespace :batch, module: 'batch' do
      resource :tags, only: [:update]
    end

    resources :polls, only: [:edit, :update, :destroy] do
      scope module: 'polls' do
        resources :votes, only: [:destroy]
      end
    end
  end

  resources :ip_profiles, constraints: { id: /[\w.\:]+/ }, only: [:show] do
    scope module: 'ip_profiles' do
      resources :tag_changes,    only: [:index]
      resources :source_changes, only: [:index]
    end
  end

  resources :fingerprint_profiles, only: [:show] do
    scope module: 'fingerprint_profiles' do
      resources :tag_changes,    only: [:index]
      resources :source_changes, only: [:index]
    end
  end

  resources :captchas, only: [:create]

  resources :static_pages, path: 'pages' do
    scope module: 'static_pages' do
      resources :versions, only: [:index]
    end
  end

  resource :stats, only: [:show] do
    scope module: 'stats' do
      resource :chart, only: [:show]
    end
  end

  resource :staff,        only: [:show]
  resource :spoiler_type, only: [:update]
  resource :changelog,    only: [:show]

  root to: 'activities#show'

  get '/errors/not_found'

  constraints(id: /[0-9]+/) do
    get '/:id' => 'images#show', :as => 'short_image'
    get '/next/:id' => 'images#navigate', :as => 'next_image', :do => 'next'
    get '/prev/:id' => 'images#navigate', :as => 'prev_image', :do => 'prev'
    get '/find/:id' => 'images#navigate', :as => 'find_image', :do => 'find'
  end
  constraints(id: /[a-z]+/) do
    get ':id', controller: 'forums', action: 'show'
    get '/:id' => 'forums#show', as: 'short_forum'
  end
  constraints(forum_id: /(?!users)(?!pages)(?!thumbs)(?!media)[a-z]+/) do
    get '/:forum_id/:id' => 'topics#show', as: 'short_topic'
    get '/forums/:forum_id/:id' => 'topics#show'
    get '/:forum_id/topics/:id' => 'topics#show'

    get '/:forum_id/:id/last' => 'topics#show_last_page'
    get '/forums/:forum_id/topics/:id/last' => 'topics#show_last_page'
    get '/:forum_id/topics/:id/last' => 'topics#show_last_page'

    constraints(page: /[0-9]+/) do
      get '/:forum_id/:id/:page' => 'topics#show'
      get '/:forum_id/topics/:id/:page' => 'topics#show'
    end

    get '/:forum_id/:id/post/:post_id' => 'topics#show', as: 'short_topic_post'
    get '/:forum_id/topics/:id/post/:post_id' => 'topics#show'
  end

  mount ActionCable.server => '/cable'

  match '*path', controller: 'errors', action: 'not_found', via: :all
end
