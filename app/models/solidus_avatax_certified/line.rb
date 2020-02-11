# frozen_string_literal: true

require 'spree/tax/tax_helpers'

module SolidusAvataxCertified
  class Line
    attr_reader :order, :lines
    include ::Spree::Tax::TaxHelpers

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
        itemCode: truncateLine(line_item.variant.sku),
        quantity: line_item.quantity,
        amount: line_item.amount.to_f,
        discounted: true,
        taxIncluded: false,
        addresses: {
          shipFrom: ship_from_address(line_item),
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
        itemCode: truncateLine(shipment.shipping_method.name),
        quantity: 1,
        amount: shipment_cost(shipment),
        description: 'Shipping Charge',
        taxCode: shipment.shipping_method_tax_code,
        discounted: false,
        taxIncluded: false,
        addresses: {
          shipFrom: ship_from_address(nil, shipment),
          shipTo: ship_to
        }
      }.merge(base_line_hash)
    end

    def refund_lines
      return lines << refund_line if @refund.reimbursement.nil?

      return_items = @refund.reimbursement.customer_return.return_items
      inventory_units = ::Spree::InventoryUnit.where(id: return_items.pluck(:inventory_unit_id))

      inventory_units.group_by(&:line_item_id).each_value do |inv_unit|
        inv_unit_ids = inv_unit.map(&:id)
        return_items = ::Spree::ReturnItem.where(inventory_unit_id: inv_unit_ids)
        quantity = inv_unit.uniq.count

        amount = if return_items.first.respond_to?(:amount)
                   return_items.sum(:amount)
                 else
                   return_items.sum(:pre_tax_amount)
        end

        lines << return_item_line(inv_unit.first.line_item, quantity, amount)
      end
    end

    def refund_line
      refund_line = {
        number: "#{@refund.id}-RA",
        itemCode: truncateLine(@refund.transaction_id) || 'Refund',
        quantity: 1,
        amount: -@refund.amount.to_f,
        description: 'Refund',
        taxIncluded: true,
        addresses: {
          shipFrom: ship_from_address,
          shipTo: ship_to
        }
      }.merge(base_line_hash)

      refund_line.merge(tax_override_hash)
    end

    def return_item_line(line_item, quantity, amount)
      return_item_line = {
        number: "#{line_item.id}-LI",
        description: line_item.name[0..255],
        taxCode: line_item.tax_category.try(:tax_code) || '',
        itemCode: truncateLine(line_item.variant.sku),
        quantity: quantity,
        amount: -amount.to_f,
        addresses: {
          shipFrom: ship_from_address(line_item),
          shipTo: ship_to
        }
      }.merge(base_line_hash)

      return_item_line.merge(tax_override_hash(amount))
    end

    def ship_to
      order.ship_address.to_avatax_hash
    end

    def truncateLine(line)
      return if line.nil?

      line.truncate(50)
    end

    private

    def base_line_hash
      @base_line_hash ||= {
        customerUsageType: order.customer_usage_type,
        businessIdentificationNo: business_id_no,
        exemptionCode: order.user.try(:exemption_number)
      }
    end

    def business_id_no
      order.user.try(:vat_id)
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

    def shipment_cost(shipment)
      cost = shipment.discounted_amount.to_f
      cost.positive? ? order.taxable_shipping_total.to_f : 0
    end

    def canada_ship_from
      {
        line1: '420 Green St',
        line2: 'Unit 206',
        city: 'Whitby',
        region: 'ON',
        country: 'CA',
        postalCode: 'L1N8R1'
      }
    end

    def usa_ship_from
      {
        line1: '1000 N West St',
        line2: 'STE 1200',
        city: 'Wilmington',
        region: 'DE',
        country: 'US',
        postalCode: '19801'
      }
    end

    def ship_from_address(line_item = nil, shipment = nil)
     return canada_ship_from if order.store.canada?

     stock_location = if line_item.present?
                        line_item.inventory_units&.first&.shipment&.stock_location
                      elsif shipment.present?
                        shipment.stock_location
                      end
     return usa_ship_from unless stock_location && stock_location.state.abbr.in?(['MO','PA'])

     stock_location.to_avatax_hash
    end
  end
end
