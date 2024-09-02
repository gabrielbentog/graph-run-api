class CreateEdges < ActiveRecord::Migration[7.2]
  def change
    create_table :edges do |t|
      t.references :from_node, null: false, foreign_key: { to_table: :nodes }
      t.references :to_node, null: false, foreign_key: { to_table: :nodes }
      t.boolean :bidirectional, default: true, null: false

      t.timestamps
    end
  end
end
