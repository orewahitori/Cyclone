-module(core_be).

-export([start/1,
         server/1]).

start(LPort) ->
    case gen_tcp:listen(LPort, [binary, {packet, 0},
                                {active, false}]) of
        {ok, LSock} ->
            io:format("Listen success, starting server~n"),
            start_server(LSock),
            {ok, Port} = inet:port(LSock),
            Port;
        {error, Reason} ->
            {error, Reason}
    end.

start_server(LSock) ->
    spawn(?MODULE, server, [LSock]).

server(LS) ->
    io:format("Server started~n"),
    case gen_tcp:accept(LS) of
        {ok, Sock} ->
            io:format("Socket was accepted~n"),
            do_recv(Sock),
            server(LS);
        Other ->
            io:format("gen_tcp:accept/1 returned ~w!~n", [Other]),
            ok
    end.

do_recv(Sock) ->
    inet:setopts(Sock, [{active, once}]),
    receive
        {tcp, S, Data} ->
            io:format("Received: ~s~n", [binary_to_list(Data)]),
            gen_tcp:send(S, "Delivered!"),
            do_recv(Sock);
        {tcp_closed, S} ->
            io:format("Socket ~w closed [~w]~n", [S, self()]),
            ok
    end.