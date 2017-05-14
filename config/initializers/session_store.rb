# Be sure to restart your server when you modify this file.

# Example for a cookie store, with secure flag set for SSL hosting in production mode
#
Rails.application.config.session_store :cookie_store,
                                      key: '_frab_session',
                                      secure: Rails.env == 'production' && ENV['FRAB_PROTOCOL'] == 'https',
                                      httponly: true,
                                      expire_after: 60.minutes
