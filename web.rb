require 'sinatra'
require 'json'

get '/' do
  'Auto WCAG Deployer'
end

post '/api' do
  request.body.rewind
  data = JSON.parse request.body.read
  "Hello #{data}!"
end