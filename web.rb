require 'sinatra'
require 'json'

post '/deployer' do
  push = JSON.parse(request.body)
  puts "Payload: #{push}"
end