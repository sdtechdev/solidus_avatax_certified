module SolidusAvataxCertified
  module Request
    class GetTax < SolidusAvataxCertified::Request::Base
      def generate
        {
          createTransactionModel: {
            code: order.number,
            date: doc_date,
            discount: order.discount_for_tax.to_s,
            commit: @commit,
            type: @doc_type ? @doc_type : 'SalesOrder',
            lines: sales_lines
          }.merge(base_tax_hash)
        }
      end

      protected

      def base_tax_hash
        super.merge(tax_override)
      end

      def tax_override
        return {} unless order.completed?

        {
          taxOverride: {
            type: 'TaxDate',
            reason: 'Order Completion Time',
            taxDate: order.completed_at.strftime('%F')
          }
        }
      end

      def doc_date
        date = order.respond_to?(:doc_date) ? order.doc_date : Date.current

        date.strftime('%F')
      end
    end
  end
end
