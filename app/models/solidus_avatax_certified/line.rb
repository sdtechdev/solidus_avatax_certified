require 'spree/tax/tax_helpers'

module SolidusAvataxCertified
  class Line
    attr_reader :order, :lines
    include Spree::Tax::TaxHelpers

    def initialize(order, invoice_type, refund = nil, override_tax = nil)
      @order = order
      @invoice_type = invoice_type
      @lines = []
      @refund = refund
      @refund_reason = refund&.reason
      @override_tax = override_tax
      @refunds = []
      build_lines
    end

    def build_lines
      if %w(ReturnInvoice ReturnOrder).include?(@invoice_type)
        refund_lines
      else
        item_lines_array
        shipment_lines_array
      end
    end

    def item_line(line_item)
      {
        number: "#{line_item.avatax_id}-LI",
        description: line_item.name[0..255],
        taxCode: line_item.tax_category.try(:tax_code) || '',
        itemCode: line_item.variant.sku,
        quantity: line_item.quantity,
        amount: line_item.amount.to_f,
        discounted: true,
        taxIncluded: false,
        addresses: {
          shipFrom: get_stock_location(line_item),
          shipTo: ship_to
        }
      }.merge(base_line_hash)
    end

    def item_lines_array
      order.line_items.each do |line_item|
        lines << item_line(line_item)
      end
    end

    def shipment_lines_array
      order.shipments.each do |shipment|
        next unless shipment.tax_category
        lines << shipment_line(shipment)
      end
    end

    def shipment_line(shipment)
      {
        number: "#{shipment.avatax_id}-FR",
        itemCode: shipment.shipping_method.name,
        quantity: 1,
        amount: shipment_cost(shipment),
        description: 'Shipping Charge',
        taxCode: shipment.shipping_method_tax_code,
        discounted: false,
        taxIncluded: false,
        addresses: {
          shipFrom: shipment.stock_location.to_avatax_hash,
          shipTo: ship_to
        }
      }.merge(base_line_hash)
    end

    def refund_lines
      return lines << refund_line if @refund.reimbursement.nil?

      return_authorization = @refund.reimbursement.return_items.first.return_authorization
      return {} if return_authorization.nil?

      if return_authorization.actual_return_items.present?
        return_authorization.actual_return_items.each do |return_item|
          lines << return_item_line(
            return_item.line_item,
            return_item.quantity,
            return_item.price_paid * return_item.quantity
          )
        end
      else
        return_request = return_authorization.return_requests.first

        return_request.request_items.each do |request_item|
          lines << return_item_line(
            request_item.line_item,
            request_item.quantity,
            request_item.price * request_item.quantity
          )
        end
      end
    end

    def refund_line
      refund_line =
        {
          number: "#{@refund.id}-RA",
          itemCode: @refund.transaction_id || 'Refund',
          quantity: 1,
          amount: -@refund.amount.to_f,
          description: 'Refund',
          taxIncluded: true,
          addresses: {
            shipFrom: default_ship_from,
            shipTo: ship_to
          }
        }.merge(base_line_hash)
      refund_line.merge(tax_override_hash)
    end

    def return_item_line(line_item, quantity, amount)
      return_item_line =
        {
          number: "#{line_item.id}-LI",
          description: line_item.name[0..255],
          taxCode: line_item.tax_category.try(:tax_code) || '',
          itemCode: line_item.variant.sku,
          quantity: quantity,
          amount: -amount.to_f,
          addresses: {
            shipFrom: get_stock_location(line_item),
            shipTo: ship_to
          }
        }.merge(base_line_hash)
      return_item_line.merge(tax_override_hash(amount))
    end

    def get_stock_location(li)
      inventory_units = li.inventory_units

      return default_ship_from if inventory_units.blank?

      stock_loc = inventory_units.first.try(:shipment).try(:stock_location)

      stock_loc.nil? ? {} : stock_loc.to_avatax_hash
    end

    def ship_to
      order.ship_address.to_avatax_hash
    end

    def default_ship_from
      Spree::StockLocation.order_default.first.to_avatax_hash
    end

    private

    def base_line_hash
      @base_line_hash ||= {
        customerUsageType: order.customer_usage_type,
        businessIdentificationNo: business_id_no,
        exemptionCode: order.user.try(:exemption_number)
      }
    end

    def tax_override_hash(amount = nil)
      if @override_tax == 'no_tax'
        {
          taxOverride: {
            type: 'TaxAmount',
            taxAmount: 0.0,
            reason: @refund_reason.name
          }
        }
      elsif @override_tax == 'full_tax'
        {
          taxOverride: {
            type: 'TaxAmount',
            taxAmount: -(amount || @refund.amount).to_f,
            reason: @refund_reason.name
          }
        }
      else
        {}
      end
    end

    def business_id_no
      order.user.try(:vat_id)
    end

    def shipment_cost(shipment)
      cost = shipment.discounted_amount.to_f
      cost.positive? ? order.taxable_shipping_total.to_f : 0
    end
  end
end
