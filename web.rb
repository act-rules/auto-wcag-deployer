require 'sinatra'
require 'json'

get '/' do
  'Auto WCAG Deployer'
end

post '/deployer' do
  push = JSON.parse(request.body)
  puts "Payload: #{push}"
end