# frozen_string_literal: true

# Monkey patching the Ruby Core class String
class String
  # ...
  def valid_json?
    JSON.parse(self)
    true
  rescue JSON::ParserError
    false
  end

  def escape_regex
    chars.map{|z| %w[ . | ( ) [ ] { } \ ^ $ + * ? ].include?(z) ? "\\#{z}" : z }.join
  end

  alias is_valid_json? valid_json?
end
