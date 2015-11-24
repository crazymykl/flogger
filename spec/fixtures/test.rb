def foo
  :bar
end

def baz
  foo ? 3 : 4
end

def quux
  baz.times do
    baz if baz if baz if baz
  end if baz
end

def glorp a, b, c, d
  a.times do |a|
    b.times do |b|
      c.times do |c|
        d.boink if d.tubes > 2 and c == 3
        puts "#{a + b}"
        glorp a - 1, b, c, d / 2
      end
    end
  end
end
