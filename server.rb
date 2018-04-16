require "sinatra"
require "json"
require "fileutils"
require "git"
require 'uri'

CONFIG = {
  "GIT_WEBHOOK_REF" => "refs/heads/master",
  "GIT_REPO_URI" => "https://#{ENV['GIT_USERNAME']}:#{ENV['GIT_ACCESS_TOKEN']}@github.com/auto-wcag/auto-wcag.git",
  "GIT_REPO_NAME" => "auto-wcag",
  "GIT_REPO_BRANCH_MASTER" => "master",
  "GIT_REPO_BRANCH_GH_PAGES" => "gh-pages",
  "DIR_TMP" => "tmp"
}

# HELPER Methods
def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['GIT_WEBHOOK_SECRET'], payload_body)
  return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end

def clone_repo(gitUri, branchName, destDir)
  puts "log: cloning: #{gitUri}, branch #{branchName}"
  u = URI(gitUri)
  project_name = u.path.split('/').last
  directory_name = project_name.split('.').first + "-#{branchName}"
  Dir.chdir(destDir)
  unless File.directory?("./#{directory_name}")
    system "git clone --branch #{branchName} #{gitUri} #{directory_name}"
    system "git fetch"
    system "git pull"
  end
  cloned_dir = destDir + "/#{directory_name}"
  cloned_dir
end

def remove_dir(dir)
  puts "log: remove dir #{dir}"
  FileUtils.rm_rf Dir.glob("#{dir}")
end

def clean_dir(dir)
  puts "log: clean dir #{dir}"
  FileUtils.rm_rf Dir.glob("#{dir}/*")
end

def run_deployer_in_background()
  background_pid = Process.fork do

    # global git config
    system "git config --global user.email 'jey.nandakumar@gmail.com' "
    system "git config --global user.name 'jkodu' "
    system "git config --global push.default matching"

    # base dir
    base_dir = __dir__

    # Make tmp directory
    puts Dir.pwd
    system ("mkdir #{CONFIG['DIR_TMP']}")

    # Clean the tmp directory
    tmp_dir = __dir__ + "/" + CONFIG['DIR_TMP']
    clean_dir(tmp_dir)

    # Clone gh-pages branch
    cloned_gh_pages_dir = clone_repo(CONFIG["GIT_REPO_URI"], CONFIG["GIT_REPO_BRANCH_GH_PAGES"], tmp_dir)
    
    # Clone master branch
    puts "log: cloing master branch"
    cloned_master_dir = clone_repo(CONFIG["GIT_REPO_URI"], CONFIG["GIT_REPO_BRANCH_MASTER"], tmp_dir)
    puts cloned_master_dir
    Dir.chdir(cloned_master_dir)
    
    # Generating site from master branch
    puts "log: generating static site"   
    system "gem install bundler"
    system "bundle install" 
    system "bundle exec jekyll build"

    # reset gh-pages to previous commit & update
    Dir.chdir(cloned_gh_pages_dir)

    # Copy generated site to gh-pages directory
    puts "log: copying contents"
    FileUtils.cp_r "#{cloned_master_dir}/_site/.", ".", :verbose => true

    # Create a nojekyll file to prevent page build error
    system "touch .nojekyll"
    
    # Add and commit changes
    system "git status"
    system "git add ."
    system "git commit -m 'Re-generated static site' "
    system "git push -ff" # May be look into not doing a forced update.

    # Change working dir to root.
    Dir.chdir(base_dir)

    # Clean tmp dir
    clean_dir(tmp_dir)

    # # Remove tmp dir
    remove_dir(tmp_dir)

    # return
    result = "Completed!!!"
    puts result

    Process.exit
  end
  background_pid
end

# API methods
get "/" do
  returnValue =  "Auto WCAG Deployer: Which listens to GitHub Webhook to rebuild gh-pages."
  puts returnValue
  status 200
  body returnValue
end

post "/deploy" do
  request.body.rewind
  body = request.body.read

  # verify_signature(body)
  
  data = JSON.parse body
  
  STDOUT.sync = true

  returnValue = nil

  if(data && data["ref"] && data["ref"] == CONFIG["GIT_WEBHOOK_REF"])
    Process.detach run_deployer_in_background
    returnValue =  "log: webhook for master branch - executing in background thread - check https://dashboard.heroku.com/apps/secret-sea-89054/logs for updates."
  else
    returnValue =  "Webhook triggered for non master branch. Ignoring re-build for gh-pages."
  end

  puts returnValue
  status 200
  body returnValue
end
