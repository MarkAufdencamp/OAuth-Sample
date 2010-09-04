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

gem "json"

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