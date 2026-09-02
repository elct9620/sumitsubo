class Order
  # The customer's Purchase is settled here.
  def total = 0

  # Purchases and repurchase are different words; whole-word, case
  # sensitive matching has to leave both alone.
  def repurchase = nil
end

# An identifier is a spelling of the concept, not its name, so the scan walks
# past the constant below.
Purchase = Struct.new(:lines)
