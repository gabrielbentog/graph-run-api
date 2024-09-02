# GenerateGraphFromTxt.new('graph.txt').call
class GenerateGraphFromTxt
  include SimpleCommand

  def initialize(file_path)
    @file_path = file_path
    @nodes = {}
    @visited = {}
    @edges = []
  end

  def call
    read_file_and_build_temp_graph
    dfs(@start_node)
    create_graph_in_db
  end

  private

  def read_file_and_build_temp_graph
    lines = File.readlines(@file_path).map(&:strip)
    node_count, edge_count = lines.shift.split(',').map(&:to_i)

    lines.each do |line|
      from, to = line.split(',').map(&:strip)
      @nodes[from] ||= []
      @nodes[to] ||= []
      @nodes[from] << to
    end

    # Assume que o nó inicial é o primeiro nó lido
    @start_node = lines.first.split(',').first.strip
  end

  def dfs(node)
    return if @visited[node]

    @visited[node] = true

    @nodes[node].each do |adjacent|
      dfs(adjacent)
      @edges << [node, adjacent]
    end
  end

  def create_graph_in_db
    graph = Graph.create!(name: "Graph from #{@file_path}")

    # Crie os nós e armazene-os em um hash para referência rápida
    db_nodes = {}
    @visited.keys.each do |node_name|
      db_nodes[node_name] = Node.create(name: node_name, graph: graph)
    end

    # Crie as arestas usando os nós criados
    @edges.each do |(from, to)|
      from_node = db_nodes[from]
      to_node = db_nodes[to]
      Edge.create(from_node: from_node, to_node: to_node)
    end
  end
end
