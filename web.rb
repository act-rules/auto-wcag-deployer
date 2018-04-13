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

get "/" do
  "Auto WCAG Deployer: Which listens to GitHub Webhook to rebuild gh-pages."
end

post "/deploy" do

  request.body.rewind
  body = request.body.read

  #  TODO: verify_signature(payload_body)
  
  data = JSON.parse body

  def clone_repo(gitUri, branchName, destDir)
    puts "log: cloning: #{gitUri}, branch #{branchName}"
    u = URI(gitUri)
    project_name = u.path.split('/').last
    directory_name = project_name.split('.').first + "-#{branchName}"
    Dir.chdir(destDir)
    unless File.directory?("./#{directory_name}")  
      system "git clone --branch #{branchName} #{gitUri} #{directory_name}"
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

  def copy_folder_contents(fromDir, toDir, ignoreFiles)
    contains = Dir.new(fromDir).entries

    def copy_with_path(src, dst)
      FileUtils.mkdir_p(File.dirname(dst))
      FileUtils.cp(src, dst)
    end

    Dir[fromDir + "/**/*.*"].each do |old_dest| 
      new_dest = old_dest.gsub(fromDir, toDir)

      # puts new_dest
      should_not_copy = ignoreFiles.any? { |s| new_dest.end_with?(s) }

      if !should_not_copy
        puts new_dest
        copy_with_path(old_dest, new_dest);
      end
    end
  end

  if(data && data["ref"] && data["ref"] == CONFIG["GIT_WEBHOOK_REF"])

    puts "log: webhook for master branch"

    # Set Git Defaults
    system "git config --global user.email '#{ENV['GIT_EMAIL']}' "
    system "git config --global user.name '#{ENV['GIT_USERNAME']}' "

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
    system "git reset HEAD~1" # This triggers a re-build of gh-pages

    # Copy generated site to gh-pages directory
    puts "log: copying contents"
    FileUtils.cp_r "#{cloned_master_dir}/_site/.", ".", :verbose => true
    
    # Add and commit changes
    system "git status"
    system "git add ."
    system "git commit -m 'Re-generated static site' "
    system "git push -ff" # May be look into not doing a forced update.
 
    # Clean tmp dir
    clean_dir(tmp_dir)

    # Remove tmp dir
    remove_dir(tmp_dir)

    # return
    result = "Completed!!!"
    puts result
    result
  else
    
    "Webhook triggered for non master branch, and for ref: #{data['ref']}. Ignoring re-build for gh-pages."

  end

 
  
end

# def verify_signature(payload_body)
#   signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
#   return halt 500, "Signatures didn't match!" unless Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
# end
