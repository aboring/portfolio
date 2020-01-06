#$hash = {}
#$aryCount = 0
#$hashCount = 0
#$str = ""

def label args
   $hash = {}
   $aryCount = 0
   $hashCount = 0
   $str = ""
   labelHelper args
   return $str
end

def labelHelper val
   if !val then
      return
   end

   if val.is_a? Array then

      if !$hash[val.object_id] then
         $aryCount += 1
         $hash[val.object_id] = "a#{$aryCount}"
         $str << "#{$hash[val.object_id]}:["
      
         i = 0
         while i < val.length do
            labelHelper val[i]
            if val[i+1] then
               $str << ","
            end
            i += 1
         end
         $str << "]"
      else
         $str << "#{$hash[val.object_id]}"
      end
   end 

   if val.is_a? Hash then
      if !$hash[val.object_id] then
         $hashCount += 1
         $hash[val.object_id] = "h#{$hashCount}"
         $str << "#{$hash[val.object_id]}:{"
   
         i = 1   
         for key in val.keys
            labelHelper key
            $str << "=>"
            labelHelper val[key]
            if i < val.length then
               $str << ","
            end
            i += 1
         end
         $str << "}"
      else
         $str << "#{$hash[val.object_id]}"
      end
   end

   if (val.is_a? Fixnum) || (val.is_a? Bignum ) then
      $str << "#{val}"
   end
   if (val.is_a? String) then
      $str << "\"#{val}\""
   end
end
