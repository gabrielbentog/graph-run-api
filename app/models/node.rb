class Node < ApplicationRecord
  belongs_to :graph
  has_many :outgoing_edges, class_name: 'Edge', foreign_key: 'from_node_id', dependent: :destroy
  has_many :incoming_edges, class_name: 'Edge', foreign_key: 'to_node_id', dependent: :destroy

  has_many :adjacent_nodes, through: :outgoing_edges, source: :to_node
end
