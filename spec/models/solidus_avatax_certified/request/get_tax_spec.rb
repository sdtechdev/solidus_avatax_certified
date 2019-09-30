require 'spec_helper'

RSpec.describe SolidusAvataxCertified::Request::GetTax, :vcr do
  let(:service) { described_class.new(order, commit: false, doc_type: 'SalesOrder') }
  let(:order) { create(:avalara_order, line_items_count: 2) }

  before do
    VCR.use_cassette('order_capture', allow_playback_repeats: true) do
      order
    end
  end

  describe '#generate' do
    subject(:generate) { service.generate }

    shared_examples 'build tax request' do
      it 'creates a hash' do
        expect(generate).to be_kind_of Hash
      end

      it 'Commit has value of false' do
        expect(generate[:createTransactionModel][:commit]).to be false
      end

      it 'has ReferenceCode from base_tax_hash' do
        expect(generate[:createTransactionModel][:referenceCode]).to eq(order.number)
      end
    end

    context 'when store uses default config' do
      before do
        Spree::AvataxConfiguration.company_code = 'DEFAULT_COMPANY_CODE'
      end

      it_behaves_like 'build tax request'

      it 'uses default company code' do
        expect(generate[:companyCode]).to eq('DEFAULT_COMPANY_CODE')
      end
    end

    context 'when store has its own config' do
      before do
        order.store.update(avatax_config:  { company_code: 'STORE_COMPANY_CODE' })
      end

      it 'uses store company code' do
        expect(generate[:companyCode]).to eq('STORE_COMPANY_CODE')
      end
    end
  end
end
