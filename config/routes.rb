PontoRa::Application.routes.draw do
  resource :session

  # Routes for user model
  resources :users do
    member do
      put 'hide'
      get 'report'
    end
  end

  # Route for extra admin reports
  scope '/admin' do
    get 'absences', to: 'users#absences', as: 'users_absences'
    get 'reports', to: 'users#report_all', as: 'users_reports'
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

  root to: 'punches#index'

end