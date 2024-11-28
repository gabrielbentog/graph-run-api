class WebSocketClient
  def initialize(url)
    @url = url
    @ws = nil
    @graph = Graph.create(name: "grafo_#{DateTime.now.strftime('%d%m%Y%H%M%S')}")
    @visited_states = Set.new
    @path_history ||= {}
  end

  def connect
    EM.run {
      @ws = Faye::WebSocket::Client.new(@url)

      @ws.on :open do |event|
        p [:open]
      end

      @ws.on :message do |event|
        p [:message, event.data]
        sleep 0.4
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
      no_adjascent_match = message.match(/Vértice sem adjacentes./)

      if no_adjascent_match
        puts "Vértice sem adjacentes. Encerrando conexão."
        @ws.close
        return
      end

      # Verificando se a mensagem tem o formato esperado
      unless vertex_match && adjacents_match
        puts "Mensagem não está no formato esperado: #{message}"
        # Se for uma mensagem de erro não esperada, ignore e retorne
        if message.include?("Vértice inválido") || message.include?("Conexão encerrada por inatividade")
          puts "Mensagem de erro: #{message}. Ignorando."
          return
        end
        return
      end
  
      current_vertex = vertex_match[1].to_i
      node_type = vertex_match[2].to_i
      adjacents = adjacents_match[1].scan(/\((\d+), (\d+)\)/).map { |a, w| [a.to_i, w.to_i] }
  
      # Adicionando ou atualizando o nó atual
      current_node = Node.find_or_initialize_by(name: current_vertex, graph: @graph)
      current_node.node_type = node_type
      current_node.save!
  
      # Atualizando a lista de adjacência e criando arestas unidimensionais (não bidirecionais)
      adjacents.each do |adjacent_vertex, weight|
        adjacent_node = Node.find_or_create_by!(name: adjacent_vertex, graph: @graph)
  
        # Verificar se a aresta já existe
        edge = Edge.find_by(from_node: current_node, to_node: adjacent_node, weight: weight)

        unless edge
          # Criar apenas a aresta na direção atual -> adjacente (sem criar a reversa)
          Edge.create!(
            from_node: current_node,
            to_node: adjacent_node,
            weight: weight,
            bidirectional: false
          )
        end
      end
  
      # Marcar o nó atual como visitado e registrar o caminho
      @visited_states.add(current_vertex)
      @path_history[current_vertex] = current_node
  
      # Encerrar a conexão ao encontrar um nó de saída ou se todos os nós forem visitados
      if node_type == 2
        puts "Nó de saída encontrado: #{current_vertex}. Encerrando conexão."
        @ws.close
        return
      end
  
      # Verifique se todos os vértices foram visitados antes de encerrar
      if @visited_states.size == Node.where(graph: @graph).count
        puts "Todos os vértices foram visitados. Encerrando conexão."
        @ws.close
        return
      end
  
      # Exploração continua se não encontrou a saída e nem visitou todos os vértices
      next_vertex = adjacents.reject { |v, _| @visited_states.include?(v) }.first
      if next_vertex
        # Registrar o próximo vértice na pilha de exploração
        @path_stack ||= []
        @path_stack.push(current_vertex)
  
        puts '=-=' * 30
        puts "Mensagem: #{message}"
        puts "Adjacents: #{adjacents}"
        puts "Explorando próximo vértice: #{next_vertex[0]}"
        puts "ir: #{next_vertex[0]}"
        puts '=-=' * 30
        send_message("ir: #{next_vertex[0]}")
      else
        # Se todos os adjacentes foram visitados, tentar voltar para o próximo vértice na lista de adjacentes
        if @path_stack.any?
          # Recuperar o vértice anterior
          previous_vertex = @path_stack.pop
          puts "Voltando para o vértice anterior: #{previous_vertex}"
  
          # Verificar se o vértice anterior está nos adjacentes
          next_adjacent = adjacents.reject { |v, _| @visited_states.include?(v) && v == previous_vertex }.first
          if next_adjacent
            send_message("ir: #{next_adjacent[0]}")
          else
            # Se não houver próximo, volte para o vértice anterior
            puts "Explorando vértice anterior: #{previous_vertex}"
            send_message("ir: #{previous_vertex}")
          end
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
