# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_Consent_session',
  :secret      => '1b06bf035baf98690a0b74f59895b97bf63eb8b089c0bbf2186b5783b76b1a2e7766505c8acebe5fd43fc7abc379b12b9a0dbc4284b296ace00400dca72b5b20'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
