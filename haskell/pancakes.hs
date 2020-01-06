pancakes :: [[Int]] -> IO()
pancakes stack = putStr result
   where {
      result = foldedList;
     
      newStack = map plusZeroes stack;
      plusZeroes list = replicate (maxHeight - length list) 0 ++ list;

      maxHeight = maximum $ map length stack;
      flippedList = map (f starList) [0..(maxHeight-1)];
      f list n = map (!! n) list;

      starList = map starify newStack;
      starify list = map (\ num -> if num == 0 then replicate (maximum list) ' '
                                else spaces list num ++ replicate num '*' ++ spaces list num) list;
      spaces list num = replicate ((maximum list - num) `quot` 2) ' ';

      squishedList = map unwords flippedList;

      foldedList = foldl (\acm val -> acm ++ val ++ "\n") "" squishedList;
   }
