# frozen_string_literal: true

module SolidusAvataxCertified
  module Spree
    module RefundDecorator
      def self.prepended(base)
        base.has_one :avalara_transaction
        base.after_create :avalara_capture_finalize, if: :avalara_tax_enabled?
      end

      def avalara_tax_enabled?
        ::Spree::Avatax::Config.tax_calculation
      end

      def avalara_capture_finalize
        super
      end

      def logger
        @logger ||= SolidusAvataxCertified::AvataxLog.new('Spree::Refund class', 'Start refund capture')
      end

      ::Spree::Refund.prepend self
    end
  end
end
