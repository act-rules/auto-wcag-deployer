require_relative '../server.rb'  
require 'rspec'  
require 'rack/test'

set :environment, :test

describe 'Server Service' do

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "API: GET: should load root page" do
    get '/'
      expect(last_response).to be_ok
    end

  it "API: GET: should not load other random pages" do
    get '/random'
    expect(last_response).to_not be_ok
  end

 
  it 'API: POST: should not be deployed' do
    data = {
      "ref": "refs/heads/not-master-branch"
    }
    post '/deploy', 
      data.to_json,
      "CONTENT_TYPE" => "application/json"
    expect(last_response.body).to eq("Webhook triggered for non master branch. Ignoring re-build for gh-pages.")
  end

  it 'API: POST: should be deployed' do
    data = {
      "ref": "refs/heads/master"
    }
    # this payload tests all the helper methods, so no individual helper method tests are covered.
    post '/deploy', 
      data.to_json,
      "CONTENT_TYPE" => "application/json"
    expect(last_response.body).to eq("log: webhook for master branch - executing in background thread - check https://dashboard.heroku.com/apps/secret-sea-89054/logs for updates.")
  end
  
end  
