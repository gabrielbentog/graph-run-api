class AddWeightToEdges < ActiveRecord::Migration[7.2]
  def change
    add_column :edges, :weight, :float, null: false, default: 0.0
  end
end
