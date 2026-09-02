class Store
  def self.open(path)
    new(path)
  end

  def read(key)
    key
  end
end
