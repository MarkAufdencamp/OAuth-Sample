set :application, "OAuth-Sample"
set :home_dir, "/home/iluviya.net"
set :web_dir, "#{home_dir}/htdocs"
set :apps_dir, "#{home_dir}/railsapps"
set :deploy_to, "#{apps_dir}/#{application}"

set :use_sudo, false

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :repository,  "git@github.com:MarkAufdencamp/OAuth-Sample.git"
set :user, "iluviya.net"

role :web, "inet-srvr-00.iluviya.net"                          # Your HTTP server, Apache/etc
role :app, "inet-srvr-00.iluviya.net"                          # This may be the same as your `Web` server
role :db,  "inet-srvr-00.iluviya.net", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
   desc "Start the Applicationm"
   task :start, roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
   end

   desc "Stop the Application"
   task :stop, roles => :app do
  # Nothing
   end

   desc "Restart the Application"
   task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_release}/tmp/restart.txt"
   end

   desc "Create Passenger Symbolic Link - #{web_dir}/#{application}"
   task :symlink_passenger do
  run "ln -s #{apps_dir}/#{application}/current/public #{web_dir}/#{application}"
   end

   desc "Create Shared Symbolic Link"
   task :symlink_shared do
  run "ln -nfs #{apps_dir}/config/database.yml #{release_path}/config/database.yml"
   end

end

desc "List Libraries"
task :search_libs, :hosts => "" do
  run "ls -xl /usr/lib"
end
