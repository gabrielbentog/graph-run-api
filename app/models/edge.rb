class Edge < ApplicationRecord
  belongs_to :from_node, class_name: 'Node'
  belongs_to :to_node, class_name: 'Node'

  after_create :create_bidirectional_edge, if: :bidirectional?

  private

  def create_bidirectional_edge
    Edge.create(from_node: to_node, to_node: from_node, bidirectional: false) unless Edge.exists?(from_node: to_node, to_node: from_node)
  end
end
