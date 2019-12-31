# frozen_string_literal: true

module SolidusAvataxCertified
  module Spree
    module AddressDecorator
      def self.prepended(base)
        base.include ToAvataxHash
        base.singleton_class.prepend ClassMethods
      end

      module ClassMethods
        def validation_enabled_countries
          ::Spree::Avatax::Config.address_validation_enabled_countries
        end
      end

      def validation_enabled?
        ::Spree::Avatax::Config.address_validation && country_validation_enabled?
      end

      def country_validation_enabled?
        ::Spree::Address.validation_enabled_countries.include?(country.try(:name))
      end

      def avatax_cache_key
        key = ['Spree::Address']
        key << address1&.downcase
        key << zipcode
        key.compact.join('-')
      end

      ::Spree::Address.prepend self
    end
  end
end
