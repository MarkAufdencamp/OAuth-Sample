# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_OAuth Sample Application_session',
  :secret      => '84267f0edf59ca2122a9d3bec302ecec22a01a14268bc22967be097acfade328479e8f680eebd462d61fb5139a395e9e0d0d52b100b33fd45e475266e3cb3a99'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
ActionController::Base.session_store = :active_record_store
