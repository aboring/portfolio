def gf spec
   r1 = /(?<sing>[a-z]+)\/(?<plur>[a-z]+)=(?<int>[0-9]+)/ 
   r2 = /(?<sing>[a-z]+)\((?<plur>[a-z]+)\)=(?<int>[0-9]+)/  
   st = /^/
   src = spec

   while $' != "" do
      if /#{st}#{r1}/ =~ src then
         eval "class Fixnum\n\tdef #{$~["sing"]}; self*#{$~["int"]} end\n end"
         eval "class Fixnum\n\tdef #{$~["plur"]}; self*#{$~["int"]} end\n end"
         eval "class Fixnum\n\tdef in_#{$~["plur"]}; self/#{$~["int"]}.0 end\n end"
         st,src = /^,/,$'
      elsif /#{st}#{r2}/ =~ src then
         eval "class Fixnum\n\tdef #{$~["sing"]}; self*#{$~["int"]} end\n end"
         eval "class Fixnum\n\tdef #{$~["sing"] << $~["plur"]}; self*#{$~["int"]} end\n end"
         eval "class Fixnum\n\tdef in_#{$~["sing"] << $~["plur"]}; self/#{$~["int"]}.0 end\n end"
         st,src = /^,/,$'
      else
         puts "bad spec: \'#{spec}\'"
         return false;
      end 
   end

   true
end
