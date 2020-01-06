expand :: [Char] -> [String]
expand str = map expand' strList
   where {
      strList = words replaceCommas;
      replaceCommas = foldr (\val acm ->
                      if val == ',' then ' ':acm else val:acm) "" str;
      root = unwords $ take 1 strList;
      
      expand' :: String -> String;
      expand' suffix@(h:t)
         | suffix == root = root
         | h == '#' = root ++ ( last root : t)
         | h == '@' = take (length root - 1) root ++ t
         | otherwise = root ++ suffix;
   }
