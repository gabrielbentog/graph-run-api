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
        send_message({ type: 'state_update' }.to_json)
      end

      @ws.on :message do |event|
        p [:message, event.data]
        sleep 1
        handle_message(event.data)
      end

      @ws.on :close do |event|
        p [:close, event.code, event.reason]
        @ws = nil
      end
    }
  end

  def send_message(message)
    @ws.send(message) if @ws
  end

  def handle_message(message)
    begin
      data = JSON.parse(message)
      
      case data['type']
      when 'state'
        handle_state_message(data)
      when 'state_request'
        handle_state_request(data)
      else
        puts "Tipo de mensagem desconhecido: #{data['type']}"
      end
    rescue JSON::ParserError => e
      puts "Erro ao decodificar JSON: #{e.message}"
    end
  end

  def handle_state_message(data)
    current_state_name = data['current_state']
    transitions = data['possible_transitions']

    puts "Recebendo estado: #{current_state_name}"
    puts "Transições possíveis: #{transitions.join(', ')}"

    current_state = @graph.nodes.find_or_create_by(name: current_state_name)

    transitions.each do |transition|
      target_node = Node.find_or_create_by(name: transition, graph: @graph)
      Edge.find_or_create_by(from_node: current_state, to_node: target_node)
    end

    if @visited_states.include?(current_state_name)
      puts "Estado '#{current_state_name}' já processado, ignorando..."
      return
    end

    @visited_states.add(current_state_name)
    @state_stack.concat(transitions)

    process_next_state if @state_stack.any?
  end

  def handle_state_request(data)
    current_state_name = data['current_state']
    puts "Recebendo pedido de estado para: #{current_state_name}"
  end

  def process_next_state
    next_state_name = @state_stack.pop
    send_message({ type: 'state_request', current_state: next_state_name }.to_json)
  end
end
