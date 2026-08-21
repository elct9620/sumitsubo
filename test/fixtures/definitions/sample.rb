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

class Signed
  def positional(one, two = 2)
  end

  def keyworded(three:, four: 4)
  end

  def gathered(*rest, **opts, &block)
  end

  def anonymous(*, **, &)
  end

  def unusual((first, second), ...)
  end

  def strict(one, **nil)
  end

  def bare()
  end

  def self.singular(one, two: 2)
  end
end
