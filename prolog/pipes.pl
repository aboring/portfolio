:-dynamic(echo/0).

set1 :-
	assert(pipe(a,10,1)),
	assert(pipe(b,5,1)),
	assert(pipe(c,20,2)).

run :- prompt(_, '\nCommand? '), repeat, read(T), echorun(T), do(T), T = q, !.

echorun(T) :- echo, !, format('\nCommand: ~w\n', T).
echorun(_). 

do(q).

do(pipes) :- findall(P,pipe(P,_,_),List), msort(List,L2), member(E,L2), pipe(E,L,D), 
	     format('~w, length: ~w, diameter: ~w\n',[E,L,D]), fail.
do(pipes).

do(weld(P1,P2)) :- exists(P1), pipe(P1,L1,D1), exists(P2), pipe(P2,L2,D2), diamcheck(D1,D2), !, 
		   retract(pipe(P1,_,_)), retract(pipe(P2,_,_)), NewLen is L1 + L2, 
		   assert(pipe(P1,NewLen,D1)), format('~w welded onto ~w\n',[P2,P1]).

do(cut(P1,L,P2)) :- exists(P1), pipe(P1,L1,D1), already(P2), lencheck(L1,L), retract(pipe(P1,_,_)), NewLen is L1 - L, 
		    assert(pipe(P1,NewLen,D1)), assert(pipe(P2,L,D1)),
		    format('~w cut from ~w to form ~w\n',[L,P1,P2]).

do(trim(P,Len)) :- pipe(P,L,D), lencheck(L,Len), retract(pipe(P,_,_)), !, NewLen is L - Len, assert(pipe(P,NewLen,D)),
		   format('~w trimmed from ~w\n',[Len,P]).

do(echo) :- echo, retract(echo), prompt(_, '\nCommand? '),
	    writeln('Echo turned off; prompt turned on'), !.
do(echo) :- \+echo, assert(echo), prompt(_,''),
	    writeln('Echo turned on; prompt turned off').

do(help) :- writeln('pipes -- show the current set of pipes'),
	    writeln('weld(P1,P2) -- weld P2 onto P1'),
	    writeln('cut(P1,P2Len,P2) -- cut P2Len off P1, forming P2'),
	    writeln('trim(P,Length) -- trim Length off of P'),
	    writeln('echo -- toggle command echo'),
 	    writeln('help -- print this message'),
	    writeln('q -- quit').

exists(P) :- \+pipe(P,_,_), format('~w: No such pipe\n',P), !, fail.
exists(_).

diamcheck(D1,D2) :- D1 =\= D2, writeln('Can\'t weld: differing diameters'), !, fail.
diamcheck(_,_).

lencheck(PL,L) :- PL =< L, writeln('Cut is too long!'), !, fail.
lencheck(_,_).

already(P) :- pipe(P,_,_), format('~w: pipe already exists\n',P), !, fail.
already(_).
