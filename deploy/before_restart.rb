current_path = "/data/#{config.app}/current"
environment  = config.node[:environment][:framework_env]

# cron
if config.node[:instance_role] == 'solo' || config.node[:instance_role] == 'app_master'
  run "cd #{config.release_path} && bundle exec whenever --update-crontab '#{config.app}' --set 'rails_root=#{current_path}&environment=#{environment}'"
end