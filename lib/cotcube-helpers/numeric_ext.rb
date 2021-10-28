class Numeric
  def with_delimiter(deli=nil)
    raise ArgumentError, "Param delimiter can't be nil" if deli.nil?
    pre, post = self.to_s.split('.')
    pre = pre.chars.to_a.reverse.each_slice(3).map(&:join).join(deli).reverse
    post.nil? ? pre : [pre,post].join('.')
  end
end
