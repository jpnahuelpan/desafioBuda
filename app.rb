#!/usr/bin/env ruby
require './lib/pruebaBuda.rb'
require 'faraday'

def main
  conn = Faraday.new(url: 'https://www.buda.com') do |buldier|
    buldier.response :json # me aseguro que se pueda parsear a json.
  end
  coll = Collector.new(conn)
  # Obtenemos los datos para realizar los calculos más adelante.
  entries_2023 = coll.get_data(
    Constants::TIMESTAMP_2023_INIT,
    Constants::TIMESTAMP_2023_END,
  )

  entries_2024 = coll.get_data(
    Constants::TIMESTAMP_2024_INIT,
    Constants::TIMESTAMP_2024_END,
  )
  # los montos transados en el 2024
  amount_sell_2024 = Operations.operation_amount(entries_2024, 'sell')
  amount_buy_2024 = Operations.operation_amount(entries_2024, 'buy')
  amount_traded_2024 = amount_buy_2024 + amount_sell_2024

  # aumento porcentual de volumen de transacciones.
  difference = entries_2024.length - entries_2023.length
  percent = (difference / entries_2024.length) * 100

  # respuestas a las preguntas del enunciado.
  question1 = "Cuánto dinero (en CLP) se transó durante el evento \"Black Buda\" BTC-CLP?"
  question2 = "En comparación con el mismo día del año anterior, ¿cuál fue el aumento porcentual en el volumen de transacciones (en BTC)?"
  question3 = "Considerando que la comisión normal corresponde a un 0.8% ¿Cuánto dinero (en CLP) se dejó de ganar debido a la liberación de comisiones durante el BlackBuda? "

  puts "#{question1}\n Respuesta: #{'%.2f' % amount_traded_2024}\n"
  puts "#{question2}\n Respuesta: #{'%.2f' % percent}\%"

  # aplicando el porcentaje comisión en el enunciado es 0.8%
  puts "#{question3}\n Respuesta: #{'%.2f' % (amount_traded_2024 * 0.08)}"
end

if __FILE__ == $0
  main
end