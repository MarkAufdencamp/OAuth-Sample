I. Create Repository Account
	A. Subversion - Private iluviya.net
	
	B. GitHub - Public github.com


II. Configure GitHub Access via SSH Key - github.com/Development Workstation (Ubuntu/OS X/Windows 7)
	A. Linux
		http://help.github.com/linux-git-installation/
		http://help.github.com/linux-key-setup/
		http://help.github.com/troubleshooting-ssh/
	
	B. OS X
		http://help.github.com/mac-git-installation/
		http://help.github.com/mac-key-setup/
	
	C. Windows 
		http://help.github.com/win-git-installation/
		http://help.github.com/msysgit-key-setup/
	
	D. Passphrases and Troubleshooting
		http://help.github.com/working-with-key-passphrases/

	E. Line Endings
		http://help.github.com/dealing-with-lineendings/


III. Create Repository
	A. Subversion - iluviya.net
	
	B. GitHub - github.com
		1. Create New Repository
			http://help.github.com/creating-a-repo/
	
		2. Fork existing Repository
			http://help.github.com/forking/
		

IV. Create Initial Rails Project - Development Workstation (Ubuntu/OS X/Windows 7)
  A. Install Ruby, Gems, SQLite3
  	sudo apt-get install ruby irb ri rdoc ruby1.8-dev rake build-essential libopenssl-ruby rubygems
  	sudo apt-get install sqlite3 sqlite3-dev
  	sudo nano /etc/bash/bash.bashrc
  		RUBY_GEMS_HOME=/var/lib/gems/1.8
  		PATH=$PATH:$RUBY_GEMS_HOME/bin
  
  B. Perform System Upgrade of Gems
  	sudo gem install rubygems-update
  	sudo update-rubygems
  	sudo gem env
  	gem env
  
  C. Rake
  	gem install rake
  
  D. Rails, ActiveSupport, Rack, ActionPack, ActionMailer, ActiveRecord, ActiveResource
  	gem install rails 
  
  E. SQLite3-Ruby
  	gem install sqlite3-ruby
  
  F. Bundler
  	gem install bundler
  
  G. Capistrano, Capistrano-ext
  	gem install capistrano
  	gem install capistrano-ext
  
  H. Create Initial Rails Project
  	cd ~/%workspace%
  	rails %projname%
  
  I. MyEclipse/RadRails/Subclipse/JGit/EGit
  	1. MyEclipse IDE
  		http://myeclipseide.com
  	2. RadRails 		
  	3. Subclipse
  	4. JGit/EGit
  	5. http://www.vogella.de/articles/EGit/article.html
  
  
V. Place Rails Project into GitHub - Development Workstation (Ubuntu/OS X/Windows 7)
  A. Subversion
  
  B. GitHub
  	1. Install Git
  		sudo apt-get install git-core
  		git config --global user.name "%First% %Last%"
  		git config --global user.email "%email_name%@%domain%.%tld%"
	  
	2. Initialize Git Control of Project
	  	cd ~/%workspace%/%projname%
	  	git init
	  
	3. Add Project Components to Git
	  	git add 
	  
	4. Add Remote Repository
	  	git remote add origin git+ssh://git@github.com/%git_account%/%projname%.git
	  
	5. Push to Remote Repository
	  	git push
	  	
	6. Git Reference
	  	http://gitref.org/


VIII. Add Bundler Support
  A. Install bundler gem
    gem install bundler
  
  B. Modify config/boot.rb - bottom before Rails.boot!
	# Bundler Hook
	class Rails::Boot
	  def run
	    load_initializer
	  
	    Rails::Initializer.class_eval do
	      def load_gems
	        @bundler_loaded ||= Bundler.require :default, Rails.env
	      end
	    end
	  
	    Rails::Initializer.run(:set_load_path)
	  end
	end
  
  C. Create config/preinitializer.rb
	begin
	  require "rubygems"
	  require "bundler"
	rescue LoadError
	  raise "Could not load the bundler gem. Install it with 'gem install bundler'."
	end
	
	if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.24")
	  raise RuntimeError, "Your bundler version is to old." +
	    "Run 'gem install bundler' to upgrade."
	end
	
	begin
	  # Set up load paths for all bundled gems
	  ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile",__FILE__)
	  Bundler.setup
	rescue Bundler::GemNotFound
	  raise RuntimeError, "Bundler counldn't find some gems." +
	    "Did you run 'bundle install'?"
	end  

  D. Gemfile -  Run bundler locally with the "bundle install --without test production"
	source :rubygems
	source :rubyforge
	source :gemcutter
	
	gem "rake"
	gem "activesupport"
	gem "rack"
	gem "actionpack"
	gem "actionmailer"
	gem "activerecord"
	gem "activeresource"
	gem "rails", "2.3.8"
	
	gem "capistrano"
	gem "capistrano-ext"
	
	group :development do
		gem "sqlite3-ruby", :require => "sqlite3"
	    gem "oauth"
		gem "oauth-plugin"
	end
	
	group :test do
		gem "sqlite3-ruby", :require => "sqlite3"
	    gem "oauth"
		gem "oauth-plugin"
	end
	
	group :production do
		gem "mysql", ">= 2.8"
	    gem "oauth"
		gem "oauth-plugin"
	end
  
  
IX. Capify the Project
  A. Initialize Capistrano for Project
  	cd %projname%
  	capify .
  
  B. Add Base Server Parameters
	set :application, "%projname%"
	set :home_dir, "/home/%vhost%"
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
  
  C. Create Passenger Symbolic Link - #{web_dir}/#{application}
   task :symlink_passenger do
  	run "ln -nfs #{apps_dir}/#{application}/current/public #{web_dir}/#{application}"
   end
  
  D. Create Shared Symbolic Links - Database, OAuth-Key, etc.
   task :symlink_shared do
  	run "ln -nfs #{apps_dir}/config/OAuth-Sample-database.yml #{release_path}/config/database.yml"
  	run "ln -nfs #{apps_dir}/config/OAuth-Sample-Key.yml #{release_path}/config/oauth-key.yml"
   end
  
  E. Create Bundler Tasks
	namespace :bundler do
	  desc ""
	  task :symlink_bundle do
	    shared_dir = File.join(shared_path, 'bundle')
	    release_dir = File.join(current_release,'.bundle')
	    run "mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}"
	  end
	  
	  desc "Bundle Dependencies"
	  task :bundle_new_release do
	    bundler.symlink_bundle
	    run "cd #{release_path} && bundle install --without development test"
	  end
	end
  
  F. Link in Shared Symlink and Bundler Tasks
	after 'deploy:update_code', 'deploy:symlink_shared', 'bundler:bundle_new_release', 'deploy:symlink_passenger'

 
X. Configure Staging/Production Server - Ubuntu
  A. Install Ruby and Gems
  	1. sudo apt-get install ruby irb ri rdoc ruby1.8-dev rake build-essential libopenssl-ruby rubygems
  	
  	2. sudo nano /etc/bash/bash.bashrc
  		RUBY_GEMS_HOME=/var/lib/gems/1.8
  		PATH=$PATH:$RUBY_GEMS_HOME/bin
  
	3. Perform System Upgrade of Gems
  		sudo gem install rubygems-update
  		sudo update-rubygems
  		sudo gem env
  		gem env
  
  C. Install Bundler and Rake
  	1. Install Rake
		sudo gem install rake
  	
	2. Install Bundler - bundler >= 1.0 (--path didn't exist in prior versions)
		sudo gem install bundler
	
	Note: All other Gems will be installed via the applications .bundler directory.
		!! No Gem version issues among users or applications !!
  
  B. Install Apache/Nginx
  	sudo apt-get install apache2 apache2-prefork-dev
  
  C. Install MySQL Server
  	sudo apt-get install mysql mysqlclient15-dev
  
  D. Configure Apache/Nginx Passenger Module
  
  E. Configure staging/production Host Account
  	1. sudo groupadd -g %gid% %vhost%
  	2. sudo useradd -g %gid% -u %uid% -d /home/%vhost% -s /bin/bash -m %vhost%
  	3. sudo passwd %vhost% 
  
  F. Configure Apache Virtual Host
  	1. Create ~/htdocs
  		a. sudo mkdir /home/%vhost%/htdocs
  	2. Create ~/log
  		a. sudo mkdir /home/%vhost%/log
  	3. Create ~/htdocs/index.html
  		a. sudo cat <html><head><title>%vhost%</title></head><body><h1><a href="http://%vhost%/index.html">%vhost%</a></h1></body></html> /home/%vhost%/htdocs/
  	5. Create /etc/apache2/sites-available/%vhost%
  	
  	6. Enable Site
  		a. a2ensite %vhost%
  	7. Reload Apache
  		a. sudo service apache2 reload
  
  G. Install git
  	sudo apt-git install git-core
  
  H. Configure GitHub SSH Key
  	1. Copy public/private key to .ssh
  	2. Remove PEM Key
		sudo openssl rsa -in id_rsa -out id_rsa
  
  I. Create %apps_dir%
  	1. sudo mkdir /home/%vhost%/railsapps
  
  J. Create Production Application Database
    1. mysql -u root -p
    2. CREATE DATABASE %projname%_production;
    3. GRANT ALL ON %projname%_production.* TO '%db_uid%'@'%localhost%' IDENTIFIED '%db_passwd%' WITH GRANT OPTION;
  
  K. Create Private Symlinked Config Files
  	1. database.yml
		production:
		  adapter: mysql
		  encoding: utf8
		  reconnect: false
		  database: %projname%_production
		  pool: 5
		  username: %db_uid%
		  password: %db_passwd%
		  socket: /var/run/mysqld/mysqld.sock
  	2. OAuth-Sample-Key.yml
  
  
XI. Deploy to Staging/Production
  A. cap deploy:setup
  
  B. cap deploy:cold
  
  c. cap db:migrate


XII. Welcome Page
  A. Rename public/index.html to index-default.html

  B. Add Welcome Controller
  
  C. Add Welcome View
  
  D. Add Welcome Layout
  
  E. Add Stylesheets
  
  F. Set Root Route to Welcome Controller

XIII. Postfix Mail Services


XIV. Administration Detail
  A. Database Backup
  	1. MySQL %projname%_production
  
  B. Logfile Rotation
  	1. Apache/Nginx
  	2. Rails
  
  C. Repository Backup
  
  D. Host Account Backup
  