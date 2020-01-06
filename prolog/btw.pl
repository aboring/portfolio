btw([],_,_) :- fail.
btw2([X],_,[X]).

btw([H|T],X,[H,X|R]) :- btw2(T,X,R).
btw([H|T],X,[H|R]) :- btw(T,X,R).

btw2([H|T],X,[H|R]) :- btw2(T,X,R).
