-module(compiler).

-export([start/0]).

start() ->
    io:format("-------------------------------------------------------~n", []),
    io:format("Modules compilation started!~n", []),
    io:format("-------------------------------------------------------~n", []),
    Files = ["conn_handler.erl",
             "conn_handler_main.erl",
             "connection.erl",
             "connection_main.erl",
             "client_sample.erl"],
    case compile_files(Files) of
        ok ->
            io:format("-------------------------------------------------------~n", []),
            io:format("Modules compiled successfully!~n");
        {error, {File, Reason}} ->
            io:format("Failed on ~p: ~p~n", [File, Reason])
    end,
    io:format("-------------------------------------------------------~n", []).

compile_files([]) ->
    ok;
compile_files([File | Rest]) ->
    io:format(" -> Compilation ~p...", [File]),
    case compile:file(File) of
        {ok, _} ->
            io:format(" compiled!~n", []),
            compile_files(Rest);
        Error ->
            io:format(" failed!~n", []),
            {error, {File, Error}}
    end.