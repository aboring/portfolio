def mirror x = []
   rev = []
   for elem in x do
      rev << elem
   end
   sl = rev.size - 2
   
   while sl >= 0 do
      rev << rev[sl]
      sl -= 1
   end
 
   for elem in rev do
      yield elem
   end
end
