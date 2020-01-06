class VString 
   include Enumerable

   def [] (n, len = 1)
      n = self.size + n if n < 0
      return nil if n >= self.size
      str = ""

      last = n + len
      last = self.size if last > self.size

      for i in n...last
         str << self.char_at(i)
      end    
      str
   end
   
   def to_s 
      str = ""
      self.each{ |x| str << x }
      str
   end

   def each
      for i in 0...self.size
         yield self[i]
      end
      self
   end
end


class ReplString < VString
   def initialize (s, n)
      @str = s
      @n = n if n > 0
      @n = 1 if n <= 0
      self
   end
   attr_accessor :str, :n
 
   def size
      @str.size * @n
   end

   def inspect
      "ReplString(#{@str.inspect},#{@n})"
   end

   def char_at n
      return "" if n >= self.size || n < -self.size
      @str[n % @str.size]
   end
end


class MirrorString < VString
   def initialize s
      @str =  s
   end
   attr_accessor :str

   def size
      @str.size * 2
   end

   def inspect
      "MirrorString(#{@str.inspect})"
   end

   def char_at n
      n = self.size + n if n < 0
      return "" if n >= self.size
      return @str[n] if n < @str.size
      return @str[self.size - (n+1)]
   end
end


class IspString < VString
   def initialize (s1, s2)
      @str = s1
      @str2 = s2
   end
   attr_accessor :str, :str2
   
   def size
      @str.size + @str2.size * (@str.size - 1)
   end

   def inspect
      "IspString(#{@str.inspect},#{@str2.inspect})"
   end

   def char_at n
      n = self.size + n if n < 0
      return "" if n >= self.size
      index1 = n / (@str2.size + 1)
      index2 = n % (@str2.size + 1)

      return @str[index1] if index2 == 0
      return @str2[index2 - 1]
   end
end

if !defined? RS
   RS=ReplString
   MS=MirrorString
   IS=IspString
end
