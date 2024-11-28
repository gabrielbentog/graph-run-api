class WebSocketClient
  def initialize(url)
    @url = url
    @ws = nil
    @graph = Graph.create(name: "grafo_#{DateTime.now.strftime('%d%m%Y%H%M%S')}")
    @visited_states = Set.new
    @queue = []  # Fila para BFS
  end

  def connect
    EM.run {
      @ws = Faye::WebSocket::Client.new(@url)

      @ws.on :open do |event|
        p [:open]
      end

      @ws.on :message do |event|
        p [:message, event.data]
        sleep 1  # Aguarda um pouco entre as mensagens para não sobrecarregar
        handle_message(event.data)
      end

      @ws.on :close do |event|
        p [:close, event.code, event.reason]
        @ws = nil
        EM.stop
      end
    }
  end

  def send_message(message)
    @ws.send(message) if @ws
  end

  def handle_message(message)
    begin
      # Extraindo informações do vértice atual
      vertex_match = message.match(/Vértice atual: (\d+), Tipo: (\d+)/)
      adjacents_match = message.match(/Adjacentes\(Vertice, Peso\): \[(.*)\]/)
  
      unless vertex_match && adjacents_match
        puts "Mensagem não está no formato esperado: #{message}"
        return
      end
  
      current_vertex = vertex_match[1]
      node_type = vertex_match[2].to_i
      adjacents = adjacents_match[1].scan(/\((\d+), (\d+)\)/).map { |a, w| [a, w.to_i] }
  
      # Adicionando ou atualizando o nó atual
      current_node = Node.find_or_initialize_by(name: current_vertex, graph: @graph)
      current_node.node_type = node_type
      current_node.save!

      # Atualizando a lista de adjacência apenas para os vértices válidos
      adjacents.each do |adjacent_vertex, weight|
        adjacent_node = Node.find_or_create_by!(name: adjacent_vertex, graph: @graph)
        Edge.find_or_create_by!(
          from_node: current_node,
          to_node: adjacent_node,
          weight: weight,
          bidirectional: true
        )
      end
  
      # Encerrar conexão ao encontrar um nó de saída
      if node_type == 2
        puts "Nó de saída encontrado: #{current_vertex}. Encerrando conexão."
        @ws.close
        return
      end
  
      # Se não houver mais vértices para explorar
      if adjacents.empty?
        puts "Sem vértices adjacentes para explorar. Conexão encerrada."
        @ws.close
        return
      end
  
      # Processar o próximo vértice adjacente
      unvisited_adjacent = adjacents.find { |adjacent_vertex, _| !@visited_states.include?(adjacent_vertex) }
  
      if unvisited_adjacent
        # Marcar o vértice como visitado
        @visited_states.add(current_vertex)
  
        adjacent_vertex, weight = unvisited_adjacent
        puts "Explorando o vértice: #{adjacent_vertex} com peso #{weight}"
  
        # Enviar mensagem para explorar o próximo vértice adjacente
        send_message("ir: #{adjacent_vertex}")
      else
        # Permitir voltar para explorar vértices ainda não processados
        puts "Todos os adjacentes foram visitados. Voltando para explorar outros caminhos."
        @queue.pop unless @queue.empty?
  
        if @queue.any?
          previous_vertex = @queue.last
          puts "Voltando para o vértice: #{previous_vertex}"
          send_message("ir: #{previous_vertex}")
        else
          puts "Exploração concluída. Encerrando conexão."
          @ws.close
        end
      end
    rescue StandardError => e
      puts "Erro ao processar mensagem: #{e.message}"
    end
  end
  
end
