# ImportGraphFromTxt.new('graph.txt', 'MyGraph').call
class ImportGraphFromTxt
  include SimpleCommand

  def initialize(file_path, graph_name)
    @file_path = file_path
    @graph_name = graph_name
  end

  def call
    return unless File.exist?(@file_path)

    graph = Graph.create(name: @graph_name)

    File.open(@file_path, 'r') do |file|
      nodes_count, edges_count = parse_first_line(file.readline.strip)

      node_map = {}

      (1..nodes_count).each do |i|
        node_map[i] = Node.create(name: i.to_s, graph: graph)
      end

      file.each_line do |line|
        from_id, to_id = parse_edge_line(line.strip)
        from_node = node_map[from_id]
        to_node = node_map[to_id]

        Edge.create(from_node: from_node, to_node: to_node, bidirectional: true)
      end
    end

    true
  end

  private

  def parse_first_line(line)
    nodes, edges = line.split(',').map(&:to_i)
    [nodes, edges]
  end

  def parse_edge_line(line)
    from, to = line.split(',').map(&:to_i)
    [from, to]
  end
end
