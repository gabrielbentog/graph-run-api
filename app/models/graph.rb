class Graph < ApplicationRecord
  has_many :nodes, dependent: :destroy

  def adjacency_list
    adjacency_list = {}
    self.nodes.includes(:adjacent_nodes).each do |node|
      adjacency_list[node.name] = node.adjacent_nodes.pluck(:name)
    end
    adjacency_list
  end

  def find_cycles
    visited = {}
    stack = []
    cycles = []

    adjacency_list.keys.each do |node|
      next if visited[node]

      find_cycles_from_node(node, visited, stack, cycles)
    end

    cycles.uniq
  end

  private

  def find_cycles_from_node(node, visited, stack, cycles)
    return if visited[node] && !stack.include?(node)

    visited[node] = true
    stack.push(node)

    adjacency_list[node].each do |adjacent|
      if stack.include?(adjacent)
        cycle_start_index = stack.index(adjacent)
        cycle = stack[cycle_start_index..-1] + [adjacent]
        cycles << cycle unless cycle == cycle.reverse
      elsif !visited[adjacent]
        find_cycles_from_node(adjacent, visited, stack, cycles)
      end
    end

    stack.pop
  end
end