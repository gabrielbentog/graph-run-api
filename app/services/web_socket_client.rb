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
      # Extraindo o vértice atual e a lista de adjacentes
      vertex_match = message.match(/Vértice atual: (\d+)/)
      adjacents_match = message.match(/Adjacentes: \[(.*)\]/)
  
      unless vertex_match && adjacents_match
        puts "Mensagem não está no formato esperado: #{message}"
        return
      end
  
      current_vertex = vertex_match[1]
      adjacents = adjacents_match[1].split(',').map(&:strip).map { |a| a.delete("'") }
  
      # Adicionando o nó atual ao banco de dados, se ainda não existir
      current_node = Node.find_or_create_by!(name: current_vertex, graph: @graph)
  
      # Verificar se o vértice atual já foi visitado
      if @visited_states.include?(current_vertex)
        unvisited_adjacent = adjacents.find { |v| !@visited_states.include?(v) }
        if unvisited_adjacent
          puts "Explorando o vértice: #{unvisited_adjacent}"
          # Adicionar o nó adjacente ao banco de dados, se ainda não existir
          adjacent_node = Node.find_or_create_by!(name: unvisited_adjacent, graph: @graph)
          # Criar uma aresta entre o nó atual e o adjacente
          Edge.find_or_create_by!(from_node: current_node, to_node: adjacent_node, bidirectional: true)
          send_message("ir: #{unvisited_adjacent}")
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
        next_vertex = adjacents.find { |v| !@visited_states.include?(v) }
        if next_vertex
          puts "Explorando o vértice: #{next_vertex}"
          # Adicionar o nó adjacente ao banco de dados, se ainda não existir
          adjacent_node = Node.find_or_create_by!(name: next_vertex, graph: @graph)
          # Criar uma aresta entre o nó atual e o próximo
          Edge.find_or_create_by!(from_node: current_node, to_node: adjacent_node, bidirectional: true)
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
