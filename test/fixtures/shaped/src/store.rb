class Store
  def self.open(path, mode = "r")
    new(path, mode)
  end

  def read(key)
    key
  end

  def write(key, value)
    key
  end
end

class Store
  def read(key, default)
    default
  end
end
