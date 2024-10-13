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

  def create_group
    data = HTTParty.post('http://localhost:8000/grupo', 
      headers: { 'Content-Type' => 'application/json' },
      body: { nome: params["name"] }.to_json
    )

    render json: data
  end

  def create_labirint
    data = HTTParty.post('http://localhost:8000/labirinto', 
      headers: { 'Content-Type' => 'application/json' },
      body: {
        "vertices": [
          {
            "id": 0,
            "labirintoId": 0,
            "adjacentes": [2, 3],
            "tipo": 1
          },
          {
            "id": 1,
            "labirintoId": 0,
            "adjacentes": [4],
            "tipo": 2
          },
          {
            "id": 2,
            "labirintoId": 0,
            "adjacentes": [0],
            "tipo": 0
          },
          {
            "id": 3,
            "labirintoId": 0,
            "adjacentes": [0, 4],
            "tipo": 0
          },
          {
            "id": 4,
            "labirintoId": 0,
            "adjacentes": [1, 3],
            "tipo": 0
          }
        ],
        "entrada": 0,
        "dificuldade": "Basiquinho e pequeno"
      }.to_json
    )

    render json: data
  end

  def get_url
    grupo_id = params[:grupo_id]
    labirinto_id = params[:labirinto_id]

    response = HTTParty.post("http://localhost:8000/generate-websocket?grupo_id=#{grupo_id}&labirinto_id=#{labirinto_id}")
    data = JSON.parse(response.body)
    render json: data
  end
end
