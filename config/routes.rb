Idocus::Application.routes.draw do
  root :to => "homepage#index"

  devise_for :super_users
  devise_for :users
  
  resources :maintenances

  resources :pages do
    resources :page_contents do
      resources :page_content_items
    end
  end
  
  namespace :account do
    root :to => "account/documents#index"
    resource :document_tags
    resources :documents do
      get 'invoice', :on => :member
      get 'packs', :on => :collection
      get 'find_tag', :on => :collection
      get 'find_by_tag', :on => :collection
      post 'update_tag', :on => :collection
      post 'reorder', :on => :collection
      post 'share', :on => :collection
    end
    resources :addresses
    resource :profile
    resource :paypal, :only => [] do
      member do
        post :success
        get :success
        get :cancel
        post :notify
      end
    end
    resource :cmcic, :only => [] do
      member do
        post :callback
        get :success
        get :cancel
      end
    end
    resource :debit_mandate do
      get 'return', :on => :member
    end
    resources :compositions do
      post 'reorder', :on => :member
      delete 'delete_document', :on => :member
    end
  end

  namespace :tunnel do
    resource :order do
      member do
        get :address_choice
        post :option_choice
        get :summary
        post :pay
      end
    end

    resources :addresses
  end

  namespace :admin do
    root :to => "admin#index"
    resources :users do
      post 'update_confirm_status', :on => :member
    end
    resources :orders
    resources :homepages
    resource :thumbnail_task do
      get 'start'
      get 'stop'
      get 'status'
      get 'remain'
    end
    resources :slides do
      post 'update_is_invisible_status', :on => :member
    end
    resources :pavets do
      post 'update_is_invisible_status', :on => :member
    end
    resources :page_types
    resources :pages do
      post 'update_is_invisible_status', :on => :member
    end
    resources :cms_images
    resources :products
    resources :product_options
  end
end
