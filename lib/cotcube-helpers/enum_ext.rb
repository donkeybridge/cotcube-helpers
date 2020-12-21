class Enumerator
  def shy_peek
    begin
      ret = self.peek
    rescue
      ret = nil
    end
    ret
  end
end

