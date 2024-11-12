# app/services/websocket_client.rb
require 'faye/websocket'
require 'eventmachine'
require 'json'

class WebSocketClient
  def initialize(url)
    @url = url
    @ws = nil
    @graph = Graph.create(name: "grafo_#{DateTime.now.strftime('%d%m%Y%H%M%S')}")
    @state_stack = []
    @visited_states = Set.new
  end

  def connect
    EM.run {
      @ws = Faye::WebSocket::Client.new(@url)
      
      @ws.on :open do |event|
        p [:open]
      end

      @ws.on :message do |event|
        p [:message, event.data]
        sleep 1
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
      current_node = Node.find_or_create_by!(name: current_vertex, graph: @graph, node_type: node_type)
  
      if node_type == 2
        puts "Nó de saída encontrado: #{current_vertex}. Encerrando conexão."
        @ws.close
        return
      end

      # Verificar se o vértice atual já foi visitado
      if @visited_states.include?(current_vertex)
        unvisited_adjacent = adjacents.find { |v, _| !@visited_states.include?(v) }
        if unvisited_adjacent
          adjacent_vertex, weight = unvisited_adjacent
          puts "Explorando o vértice: #{adjacent_vertex} com peso #{weight}"
          adjacent_node = Node.find_or_create_by!(name: adjacent_vertex, graph: @graph)
          Edge.find_or_create_by!(from_node: current_node, to_node: adjacent_node, weight: weight, bidirectional: true)
          p "ir: #{adjacent_vertex}"
          send_message("ir: #{adjacent_vertex}")
        else
          @state_stack.pop
          if @state_stack.empty?
            puts "Todos os vértices foram visitados. DFS concluído."
            @ws.close
          else
            previous_vertex = @state_stack.last
            puts "Voltando para o vértice: #{previous_vertex}"
            send_message("ir: #{previous_vertex}")
          end
        end
      else
        # Marcar o vértice atual como visitado
        @visited_states.add(current_vertex)
        @state_stack.push(current_vertex)
  
        # Explorar o próximo vértice não visitado
        next_adjacent = adjacents.find { |v, _| !@visited_states.include?(v) }
        if next_adjacent
          next_vertex, weight = next_adjacent
          puts "Explorando o vértice: #{next_vertex} com peso #{weight}"
          adjacent_node = Node.find_or_create_by!(name: next_vertex, graph: @graph)
          Edge.find_or_create_by!(from_node: current_node, to_node: adjacent_node, weight: weight, bidirectional: true)
          send_message("ir: #{next_vertex}")
        else
          @state_stack.pop
          if @state_stack.empty?
            puts "Todos os vértices foram visitados. DFS concluído."
            @ws.close
          else
            previous_vertex = @state_stack.last
            puts "Voltando para o vértice: #{previous_vertex}"
            send_message("ir: #{previous_vertex}")
          end
        end
      end
    rescue StandardError => e
      puts "Erro ao processar mensagem: #{e.message}"
    end
  end
end
