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