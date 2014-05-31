api_file = Rails.root.join('config','api.yml')

if api_file.exist?
  API_TOKEN = YAML.load_file(Rails.root.join('config','api.yml'))['api_token']
else
  API_TOKEN = 'YOUR API TOKEN'
end
