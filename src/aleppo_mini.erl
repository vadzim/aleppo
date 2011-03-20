% the goal is to expand simple defines in aleppo_parser.erl to be able to compile it

-module(simple_define).

-export([
	process/1
%	, main/1
	]).

%main(_) ->
%	{ok, Tokens, _} = erl_scan:string(
%		"-module(yyy).\nx() -> 1.\n-define(XXX, {\"1.4\", 987}).\ny() -> begin\n{?XXX, ?MODULE, ?LINE}\nend."),
%	%io:format("~p", [Tokens]).
%	io:format("~p", [process(Tokens)]).

process(Tokens) -> process(Tokens, [
	{'MACHINE', [{atom, 1, erlang:list_to_atom(erlang:system_info(machine))}]}
], []).

process_define(DefName, [{')', _}, {dot, _} | Tail], Defines, Current, Acc) ->
	process(Tail, [{DefName, Current} | Defines], Acc);

process_define(DefName, [Head | Tail], Defines, Current, Acc) ->
	process_define(DefName, Tail, Defines, [Head | Current], Acc);

process_define(_, _, _, _, _) -> {error, 'not terminated define'}.

process([{'-', _}, {atom, _, Command} | _], _, _)
	when
		Command == ifdef;
		Command == ifndef;
		Command == else;
		Command == endif;
		Command == undef;
		Command == include;
		Command == include_lib
->
	{error, Command};

process([{'-', _}, {atom, _, define = Command}, {'(', _}, {_, _, _}, {'(', _} | _], _, _) ->
	{error, Command};

process([{'-', _}, {atom, _, define}, {'(', _}, {A, _, DefName}, {',', _} | Tail], Defines, Acc)
	when A == atom; A == var
->
	process_define(DefName, Tail, Defines, [], Acc);

process([{'-', _} = Head | [{atom, _, module}, {'(', _}, {atom, L, ModuleName} = Module, {')', _},
	{dot, _} | _] = Tail], Defines, Acc)
->
	process(Tail, [{'MODULE', [Module]},
		{'MODULE_NAME', [{atom, L, erlang:atom_to_list(ModuleName)}]}
		| Defines], [Head | Acc]);

process([{'?', _}, {A, L, DefName} | Tail], Defines, Acc)
	when A == atom; A == var
->
	case lists:keyfind(DefName, 1, Defines) of
		{DefName, DefVal} -> process(Tail, Defines, DefVal ++ Acc);
		_ when DefName == 'LINE' -> process(Tail, Defines, [{integer, L, L} | Acc]);
		_ -> {error, {'?', DefName, Defines}}
	end;

process([Head | Tail], Defines, Acc) -> process(Tail, Defines, [Head | Acc]);

process([], _, Acc) -> {ok, lists:reverse(Acc)}.
