# frozen_string_literal: true

# Standalone routing contract: does not boot the extension's dummy application.
require 'action_controller/railtie'
require 'rspec'

RSpec.describe 'AvaTax routes on the supported Rails runtime' do
  let(:routes) { ActionDispatch::Routing::RouteSet.new }

  before do
    engine = Class.new
    # Capture the real RouteSet outside the singleton method's receiver.
    route_set = routes
    engine.define_singleton_method(:routes) { route_set }
    stub_const('Spree::Core::Engine', engine)
    load File.expand_path('../config/routes.rb', __dir__)
  end

  %w[ping_my_service download_avatax_log erase_data validate_address].each do |action|
    it "preserves the #{action} admin GET route and helper" do
      name = "#{action}_admin_avatax_settings"
      route = routes.named_routes.get(name.to_sym)
      expect(route.verb).to eq('GET')
      expect(route.defaults).to include(controller: 'admin/avatax_settings', action: action)
      expect(routes.url_helpers.public_send("#{name}_path")).to eq("/admin/avatax_settings/#{action}")
    end
  end

  it 'preserves the checkout validation route' do
    expect(routes.url_helpers.validate_address_path).to eq('/checkout/validate_address')
  end

  it 'preserves both user information verbs' do
    user_routes = routes.routes.select { |route| route.defaults[:action] == 'avalara_information' }
    expect(user_routes.map(&:verb)).to contain_exactly('GET', 'PUT')
  end
end
