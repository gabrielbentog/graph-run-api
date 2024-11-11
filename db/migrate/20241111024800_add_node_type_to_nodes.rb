class AddNodeTypeToNodes < ActiveRecord::Migration[7.2]
  def change
    add_column :nodes, :node_type, :integer, default: 0, null: false
  end
end
