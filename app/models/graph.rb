class Graph < ApplicationRecord
  has_many :nodes, dependent: :destroy

  def graph_nodes
    graph_nodes = {}
    self.nodes.each do |node|
      graph_nodes[node.name] = node.adjacent_nodes.pluck(:name)
    end
    graph_nodes
  end
end
