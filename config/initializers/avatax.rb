# DO NOT MODIFY FILE
AVATAX_CLIENT_VERSION = "a0o33000004FH8l"
AVATAX_HEADERS = { 'X-Avalara-UID' => AVATAX_CLIENT_VERSION }

module Spree
  module Avatax
    Config = Spree::AvataxConfiguration.new
  end
end

Spree::Avatax::Config.account = ENV['AVATAX_ACCOUNT'] if ENV['AVATAX_ACCOUNT']
Spree::Avatax::Config.license_key = ENV['AVATAX_LICENSE_KEY'] if ENV['AVATAX_LICENSE_KEY']
Spree::Avatax::Config.company_code = ENV['AVATAX_COMPANY_CODE'] if ENV['AVATAX_COMPANY_CODE']
Spree::Avatax::Config.connection_timout = ENV['CONNECTION_TIMEOUT'] if ENV['CONNECTION_TIMEOUT']
Spree::Avatax::Config.connection_retry_limit = ENV['CONNECTION_RETRY_LIMIT'] if ENV['CONNECTION_RETRY_LIMIT']
Spree::Avatax::Config.connection_retry_exception = ENV['CONNECTION_RETRY_EXCEPTION'] if ENV['CONNECTION_RETRY_EXCEPTION']
