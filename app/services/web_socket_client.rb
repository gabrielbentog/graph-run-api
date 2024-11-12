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
      # Extraindo o vértice atual, tipo e lista de adjacentes com pesos
      vertex_match = message.match(/Vértice atual: (\d+), Tipo: (\d+)/)
      adjacents_match = message.match(/Adjacentes\(Vertice, Peso\): \[(.*)\]/)

      unless vertex_match && adjacents_match
        puts "Mensagem não está no formato esperado: #{message}"
        return
      end

      current_vertex = vertex_match[1]
      node_type = vertex_match[2].to_i
      adjacents = adjacents_match[1].scan(/\((\d+), (\d+)\)/).map { |a, w| [a, w.to_i] }

      # Adicionando o nó atual ao banco de dados, se ainda não existir, com o tipo correto
      current_node = Node.find_or_initialize_by(name: current_vertex, graph: @graph)
      current_node.node_type = node_type
      current_node.save!

      if node_type == 2
        puts "Nó de saída encontrado: #{current_vertex}. Encerrando conexão."
        @ws.close
        return
      end

      # Verificar se o vértice atual já foi visitado
      unless @visited_states.include?(current_vertex)
        # Marcar o vértice atual como visitado
        @visited_states.add(current_vertex)
        @queue.push(current_vertex)  # Adiciona o vértice à fila para explorar em BFS
      end

      # Processar o próximo vértice na fila, se houver
      if @queue.any?
        next_vertex = @queue.shift  # Retira o próximo vértice da fila
        puts "Processando o vértice: #{next_vertex}"
        current_node = Node.find_or_create_by!(name: next_vertex, graph: @graph)

        # Explorar o próximo vértice adjacente não visitado
        unvisited_adjacent = adjacents.find { |adjacent_vertex, _| !@visited_states.include?(adjacent_vertex) }

        if unvisited_adjacent
          adjacent_vertex, weight = unvisited_adjacent
          unless @visited_states.include?(adjacent_vertex)
            adjacent_node = Node.find_or_create_by!(name: adjacent_vertex, graph: @graph)
            Edge.find_or_create_by!(from_node: current_node, to_node: adjacent_node, weight: weight, bidirectional: true)
            puts "Explorando o vértice: #{adjacent_vertex} com peso #{weight}"
            send_message("ir: #{adjacent_vertex}")  # Envia a mensagem de navegação para o próximo vértice

            # Adiciona o vértice adjacente à fila para exploração posterior
            @queue.push(adjacent_vertex)
          end
        end

        # Após explorar os adjacentes, verifica se há mais na fila
        if @queue.empty?
          puts "Todos os vértices foram visitados. BFS concluído."
          @ws.close
        end
      else
        puts "Fila vazia, BFS concluído."
        @ws.close
      end
    rescue StandardError => e
      puts "Erro ao processar mensagem: #{e.message}"
    end
  end
end
