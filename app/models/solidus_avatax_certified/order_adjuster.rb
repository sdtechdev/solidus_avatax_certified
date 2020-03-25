# frozen_string_literal: true

module SolidusAvataxCertified
  class OrderAdjuster < ::Spree::Tax::OrderAdjuster
    def adjust!
      if !order.force_tax_recalculation && %w[cart address delivery].include?(order.state)
        return (order.line_items + order.shipments)
      end

      super
    end
  end
end
