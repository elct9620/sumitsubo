module Outer
  module Inner
    def self.load(path)
      path
    end

    def check(text)
      text
    end
  end
end

module Flat::Scoped
  def self.of(path)
    path
  end
end

class Alone
  def solo
  end
end

def loose
end

class Reopened
  class << self
    def built
    end
  end
end
