PontoRa::Application.routes.draw do
  mount_roboto
  resource :session

  # Routes for user model
  resources :users do
    member do
      put 'hide'
      get 'report'
    end
  end

  # Route for extra admin reports
  scope '/reports' do
    get 'index', to: 'reports#index', as: 'reports'
    get 'absences', to: 'reports#absences', as: 'users_absences'
    get 'simple', to: 'reports#simple', as: 'users_simple_report'
    get 'detailed', to: 'reports#detailed', as: 'users_detailed_report'
  end

  # Routes for punches
  resources :punches do
    collection do
      get 'token'
    end
  end


  # Stats
  get 'stats', to: 'stats#index'
  get 'gecko_daily_avg_30_days',    to: 'stats#gecko_daily_avg_30_days'
  get 'gecko_last_week_pie',        to: 'stats#gecko_last_week_pie'
  get 'gecko_last_month_pie',       to: 'stats#gecko_last_month_pie'
  get 'gecko_this_week_pie',        to: 'stats#gecko_this_week_pie'
  get 'gecko_this_month_pie',       to: 'stats#gecko_this_month_pie'
  get 'gecko_from_checkpoint_pie',  to: 'stats#gecko_from_checkpoint_pie'
  get 'gecko_latest_punches',       to: 'stats#gecko_latest_punches'
  get 'reports_punch',              to: 'stats#reports_punch'
  root to: 'punches#index'

  # API
  namespace :api do
    resources :punches
    controller "punches" do
      post "login", action: "login"
      post "mobile_punch", action: "mobile_punch"
      post "list_mobile", action: "list_mobile"
    end
  end

end
