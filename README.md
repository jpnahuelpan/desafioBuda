### Desafío técnico:

#### BlackBuda
Imagina que el 1 de marzo de 2024, en el lapso de una hora, de 12:00 a 13:00, [Buda.com](buda.com) lanzó una oferta especial llamada BlackBuda. Durante este período, ¡todos los usuarios que operaran en el mercado BTC-CLP disfrutaron de un asombroso 100% de descuento en las comisiones de transacción! 

Fue una oportunidad increíble para comprar y vender bitcoin  y ahora necesitamos de tu ayuda para evaluar el desempeño del BlackBuda.

Utilizando nuestra [API pública](https://api.buda.com/#la-api-de-buda-com), necesitamos que recopiles la información necesaria para analizar las siguientes situaciones. 

Supuestos:
- Las comisiones se cobran en CLP.
- Para todos los cálculos utilizar el horario entre 12:00 y 13:00, ambos inclusive, considera la zona horaria GMT -03:00.
- Para todas las respuestas truncar en 2 decimales, ocupando un punto como separador de decimales.
- Recuerda que en un mercado del tipo Moneda_1-Moneda_2, la cantidad transada está en Moneda_1 y el precio en Moneda_2.

##### Preguntas

1. <a name="p1"></a>¿Cuánto dinero (en CLP) se transó durante el evento "Black Buda" BTC-CLP ? (truncar en 2 decimales).
2. <a name="p2"></a>En comparación con el mismo día del año anterior, ¿cuál fue el aumento porcentual en el volumen de transacciones (en BTC)? (truncar en 2 decimales).
3. <a name="p3"></a>Considerando que la comisión normal corresponde a un 0.8% ¿Cuánto dinero (en CLP) se dejó de ganar debido a la liberación de comisiones durante el BlackBuda? (truncar en 2 decimales).
4. <a name="p4"></a>Agregando una perspectiva de producto, reflexiona brevemente sobre los problemas que surgen durante eventos como el "BlackBuda" y propón cómo priorizarías su corrección o mejora. (Máximo 1500 caracteres).
5. <a name="p5"></a>Basándote en la documentación de la API pública de [Buda.com](buda.com), describe o modela brevemente cómo imaginas el diseño de la base de datos. (Aquí no existe una respuesta correcta).

##### Solución

###### Enfoque preliminar
1. Crear un script que recolecte los datos en Ruby (collector.rb) usando faraday o httparty.
2. Crear un script para el análisis de los datos usando daru o Nmatrix (analysis.rb).
3. Responder [1](#p1), [2](#p2), [3](#p3) y [4](#p4) según los datos obtenidos.

4. Modelar la DDBB segun la documentación de la API, para respoder el [5](#p5).

###### Desarrollo de la solución (antes de codificar)
1. Primero hay que identificar el conjunto de endpoints para minar, en este caso, creo que es suficiente con 'https://www.buda.com/api/v2/markets/{market_id}/trades', teniendo en cuenta que la estructura del response es:
```json
{
  "trades": {
    "timestamp": string,
    "last_timestamp": string,
    "market_id": string,
    "entries": [
      [timestamp, amount, price, direction, entry_id],
      ...
    ]
  }
}
```
Nota: estoy infiriendo que el quinto valor 'entry_id' es el ID de cada entrada, pues los valores son corralativos y en la documentación no sale especificado.

2. Elegir el método de recolección, teniendo en cunta que solo podemos especificar la fecha más cercana ose en otras palabras solo podemeos agregar como argumento al endpoint el el timestamp de tope y un máximo de 100 entradas hacia atras. Entonces lo que puedo hacer, es hacer peticiones de forma iterativa hasta llegar al límite inferior osea las 13:00 hrs.

3. Hora que variables debo almacenar?, puedo inferir que el según el enunciado, el 'amount' es la cantidad operada (no en el quirofano, sino más bien comprada o vendida) y que 'price' es el valor por unidad. Teniendo esto en cuenta, con estas variables es suficiente para hacer los calculos requeridos para los ejercicios [1](#p1), [2](#p2) y [3](#p3), pero viendo que en el ejercicio [4](#p4) necesito considerar los demas datos pues se requiere un perspectiva más global del 'BlackBuda'.

4. Una ves recolectado todos los datos hacer los respectivos análisis.


###### Hora nos vamos al código
1. Definiré las constantes en este caso es el mercado y los limites de los periodos de interes en formato timestamp en milisegundos, los cuales agruparé en un modulo para que no molesten en el archivo principal o main.

```ruby
module Constants
  MARKET_ID = "btc-clp"
  TIMESTAMP_2023_INIT = Time.new(2023, 3, 1, 12, 0, 0, "-03:00").to_i * 1000
  TIMESTAMP_2023_END = Time.new(2023, 3, 1, 13, 0, 0, "-03:00").to_i * 1000
  TIMESTAMP_2024_INIT = Time.new(2024, 3, 1, 12, 0, 0, "-03:00").to_i * 1000
  TIMESTAMP_2024_END = Time.new(2024, 3, 1, 13, 0, 0, "-03:00").to_i * 1000
end
```

2. Crear la clase Collector que se encargara he hacer la peticiones y formatear los datos a un estructura que nos permita hacer análisis y sacar información relevante para el desafío.
```ruby
class Collector
  def initialize(conn)
    @_conn = conn
    @_data = []
  end

  def get_data(init_limit, end_limit)
    self.fill_data(init_limit, end_limit)
    @_data
  end

  def fill_data(init_limit, end_limit)
    is_collecting = true
    el = end_limit
    while is_collecting
      response = self.get_response(el)
      last_timestamp = response['last_timestamp']
      insert_entries(response['trades']['entries'], init_limit)
      break if last_timestamp.to_i <= init_limit
    end
  end

  def insert_entries(entries, init_limit)
    entries.each do |entry|
      break if entry[0].to_i < init_limit
      @_data.append(formating_entry(entry))
    end
  end

  def get_response(timestamp)
    response = @_conn.get("/api/v2/markets/btc-clp/trades") do |req|
      req.params['limit'] = 100 # hardcode
      req.params['timestamp'] = "#{timestamp}"
      req.headers['Content-Type'] = 'application/json'
    end
    if response.status == 200
      response.body
    else
      response = "Error: #{response.status}"
    end
  end

  def formating_entry(entry)
    formated_entry = {
      timestamp: entry[0],
      amount: entry[1],
      price: entry[2],
      direction: entry[3]
    }
    formated_entry
  end
end
```
Nota: el 'entry_id' decidí no almacenarlo dado que no se necesita para las operaciones.

3. Crear una clase o modulo para agrupar las operaciones que realizare a los datos, para no tener el main lleno de definiciones de funciones que pueden molestar.

```ruby
module Operations
  def self.operation_amount(data, direction)
    # es la sumatoria de todas las operaciones en un dirección <sell | buy>.
    result = 0.0
    data.each do |e|
      if e[:direction] == direction
        result += e[:price].to_f * e[:amount].to_f
      end
    end
    result
  end
end
```
Nota: pense que iba a usar más métodos pero no fue así, pero se ve ordenado :`).

##### Por ultimo nos vamos a los resultados. (solo se responden las primeras 3 preguntas con el script) el resto son mas análiticas.

###### Ejecución si tienes instalado Ruby en tu pc linux.
```bash
$ git clone <this repo>
$ cd <folder repo>
$ ruby app.rb
```
###### Si eres de los mios que no le gusta instalar nada, puedes usar Podman o Docker.
```bash
$ sudo su
$ podman build -t prueba_buda .
:
: 
$ podman run --rm -it -v ./:/pruebaBuda localhost/prueba_buda
```
Nota: Podras editar los script si quieres.






