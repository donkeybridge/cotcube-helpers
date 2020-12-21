class String
  def is_valid_json?
     JSON.parse(self)
     return true
  rescue JSON::ParserError => e
     return false
  end
end

