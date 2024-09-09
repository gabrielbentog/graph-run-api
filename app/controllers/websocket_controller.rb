# app/controllers/websocket_controller.rb
class WebsocketController < ApplicationController
  def connect
    ws_client = WebSocketClient.new("ws://localhost:8765")
    ws_client.connect

    # Espera para garantir que a conexão foi estabelecida
    sleep 4

    # Enviar uma mensagem de teste
    ws_client.send_message("Hello from Rails!")

    render plain: "Message sent!"
  end
end
