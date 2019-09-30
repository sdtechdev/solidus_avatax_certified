class AddAvataxConfigIntoSpreeStores < ActiveRecord::Migration
  def change
    add_column :spree_stores, :avatax_config, :json, default: {}
  end
end
