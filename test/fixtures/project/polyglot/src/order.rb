class Order
  # The upstream feed calls this a Purchase.
  def self.open(id, mode)
    new(id, mode)
  end
end

# An identifier spells a concept rather than naming it, so the constant below is
# walked past. A reading that answered for every line would not walk past it.
Purchase = Struct.new(:lines)
