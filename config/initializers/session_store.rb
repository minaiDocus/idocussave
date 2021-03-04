# Be sure to restart your server when you modify this file.

Idocus::Application.config.session_store :cookie_store, :key => '_idocus_session'
# Idocus::Application.config.session_store :active_record_store, :key => '_idocus_session'

# Idocus::Application.config.session_store ActionDispatch::Session::CacheStore, expire_after: nil

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# Idocus::Application.config.session_store :active_record_store, :key => '_idocus_session'
