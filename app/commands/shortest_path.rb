class ShortestPath
  def initialize(graph)
    @graph = graph
  end

  def call
    # Encontrar os nós de tipo 'inicial' e 'final'
    start_node = @graph.nodes.find_by(node_type: 1)
    end_node = @graph.nodes.find_by(node_type: 2)

    if start_node.nil? || end_node.nil?
      puts "Nó inicial ou final não encontrado"
      return nil
    end

    bfs(start_node, end_node)
  end

  private

  def bfs(start_node, end_node)
    queue = [[start_node]] # Caminho com apenas o nó inicial
    visited = Set.new([start_node.id])
  
    while queue.any?
      path = queue.shift
      node = path.last
  
      # Exibe o estado da fila com os nomes dos nós
      puts "Estado da fila: #{queue.map { |p| p.last.name }.join(', ')}"
      puts "Explorando nó #{node.name}"

      # Verifique se o nó final foi encontrado
      if node.id == end_node.id
        # Exibe o caminho encontrado e os pesos das arestas
        path_names = path.map(&:name)
        path_weights = path.each_cons(2).map do |from, to|
          Edge.find_by(from_node: from, to_node: to).weight
        end
        puts "Caminho encontrado: #{path_names.join(' -> ')}"
        puts "Pesos das arestas: #{path_weights.join(' -> ')}"
        return path
      end
  
      # Explora os nós adjacentes
      node.adjacent_nodes.each do |neighbor|
        unless visited.include?(neighbor.id)
          visited.add(neighbor.id)
          queue.push(path + [neighbor]) # Adiciona o vizinho ao caminho
        end
      end
    end
  
    puts "Nenhum caminho encontrado"
    nil
  end
end
