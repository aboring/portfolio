fsort([_],[]).

fsort(L,Flips)       :- max_list(L,Max), length(L,Len), nth1(Len,L,Max), !, append(L2,[_],L), fsort(L2,Flips).
fsort(L,[Len|Flips]) :- max_list(L,Max), length(L,Len), nth1(1,L,Max), !, reverse(L,Rev), fsort(Rev,Flips).

fsort(L,[Index|Flips]) :- !, max_list(L,Max), nth1(Index,L,Max), append(Left,Right,L), length(Left,Len), Len = Index, 
reverse(Left,Rev), append(Rev,Right,New), fsort(New,Flips).
