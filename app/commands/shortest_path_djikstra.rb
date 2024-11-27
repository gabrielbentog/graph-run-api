require 'set'

class ShortestPathDjikstra
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

    dijkstra(start_node, end_node)
  end

  private

  def dijkstra(start_node, end_node)
    # Usando um array para implementar a fila de prioridade
    pq = [[start_node, 0]] # A fila contém pares (nó, custo)
    
    # Hash para armazenar os custos mínimos conhecidos para cada nó
    distances = { start_node.id => 0 }
    # Inicializar todos os nós com distância infinita, exceto o nó inicial
    @graph.nodes.each { |node| distances[node.id] ||= Float::INFINITY }
    
    # Hash para armazenar o caminho para reconstrução
    previous_nodes = {}

    while !pq.empty?
      # Ordena a fila pela distância acumulada (menor custo vem primeiro)
      pq.sort_by! { |_, distance| distance }
      
      current_node, current_distance = pq.shift # Pega o nó com o menor custo acumulado

      # Se chegamos ao nó final, podemos reconstruir o caminho
      if current_node.id == end_node.id
        return reconstruct_path(previous_nodes, end_node)
      end

      # Explora os nós adjacentes
      current_node.adjacent_nodes.each do |neighbor|
        # Calcula a nova distância através do nó atual
        edge_weight = Edge.find_by(from_node: current_node, to_node: neighbor).weight
        new_distance = current_distance + edge_weight

        # Se encontramos um caminho mais curto até o vizinho, atualizamos
        if new_distance < distances[neighbor.id] || distances[neighbor.id] == Float::INFINITY
          distances[neighbor.id] = new_distance
          previous_nodes[neighbor.id] = current_node
          pq.push([neighbor, new_distance]) # Adiciona o vizinho à fila com a nova distância
        end
      end
    end

    puts "Nenhum caminho encontrado"
    nil
  end

  # Método para reconstruir o caminho a partir do nó final
  def reconstruct_path(previous_nodes, end_node)
    path = []
    current_node = end_node
    total_weight = 0  # Variável para acumular o peso total do caminho

    while current_node
      path.unshift(current_node)
      break unless previous_nodes[current_node.id]  # Se não houver nó anterior, break
      # Calcula o peso da aresta entre o nó atual e o nó anterior
      edge_weight = Edge.find_by(from_node: previous_nodes[current_node.id], to_node: current_node).weight
      total_weight += edge_weight
      current_node = previous_nodes[current_node.id]
    end

    # Exibe o caminho e os pesos das arestas
    path_names = path.map(&:name)
    path_weights = path.each_cons(2).map do |from, to|
      Edge.find_by(from_node: from, to_node: to).weight
    end

    puts "Caminho encontrado: #{path_names.join(' -> ')}"
    puts "Pesos das arestas: #{path_weights.join(' -> ')}"
    puts "Peso total: #{total_weight}"
    path
  end
end
