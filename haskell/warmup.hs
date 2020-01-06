mp :: (a -> b) -> [a] -> [b]
mp _ [] = []
mp func (a:b) = func a : mp func b

filt :: (a -> Bool) -> [a] -> [a]
filt _ [] = []
filt func (a:b)
   | func a == True = a : filt func b
   | otherwise = filt func b


fl :: (a -> b -> a) -> a -> [b] -> a
fl _ acm [] = acm
fl func acm (a:b) =  fl func ( func acm a ) b

fr :: (a -> b -> b) -> b -> [a] -> b
fr _ acm [] = acm
fr func acm (a:b) = func a (fr func acm b)

myany :: (a -> Bool) -> [a] -> Bool
myany _ [] = False
myany func (a:b)
   | func a == True = True
   | otherwise = myany func b

myall :: (a -> Bool) -> [a] -> Bool
myall _ [] = True
myall func (a:b)
   | func a == False = False
   | otherwise = myall func b


zw :: (a -> b -> c) -> [a] -> [b] -> [c]
zw _ [] _ = []
zw _ _ [] = []
zw func (a:b) (x:y) = func a x : zw func b y
