# frozen_string_literal: true

module SolidusAvataxCertified
  module Request
    class ReturnTax < SolidusAvataxCertified::Request::Base
      def initialize(order, opts = {})
        super
        @refund = opts[:refund]
        @override_tax = opts[:override_tax]
      end

      def generate
        {
          createTransactionModel: {
            code: order.number.to_s + '.' + @refund.id.to_s,
            date: doc_date,
            commit: @commit,
            type: @doc_type || 'ReturnOrder',
            lines: sales_lines
          }.merge(base_tax_hash)
        }
      end

      protected

      def doc_date
        Date.current.strftime('%F')
      end

      def base_tax_hash
        super.merge(tax_override)
      end

      def tax_override
        return {} if @override_tax.present?

        {
          taxOverride: {
            type: 'TaxDate',
            reason: @refund&.reason&.name&.truncate(255) || 'Return',
            taxDate: order.completed_at.strftime('%F')
          }
        }
      end

      def sales_lines
        @sales_lines ||= SolidusAvataxCertified::Line.new(order, @doc_type, @refund, @override_tax).lines
      end
    end
  end
end
