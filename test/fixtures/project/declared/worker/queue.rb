class Queue
  def self.push(job)
    job
  end
end

# The API definition registers Store#write and does not include this file.
# A class here spelling the same name defines nothing for it.
class Store
  def write(key, value)
    [key, value]
  end
end
