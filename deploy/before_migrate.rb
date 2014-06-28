# Recommended way to use private configuration files in EY
if File.exist?("#{config.shared_path}/config/api.yml")
  run "ln -nfs #{config.shared_path}/config/api.yml #{config.release_path}/config/api.yml"
end
