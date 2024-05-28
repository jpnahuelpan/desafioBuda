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