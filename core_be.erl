-module(core_be).

-export([start/1,
         server/1,
         adm_loop/1]).

start(LPort) ->
    ets:new(users, [set, public, named_table]),
    case gen_tcp:listen(LPort, [binary, {packet, 0},
                                {active, false}]) of
        {ok, LSock} ->
            io:format("Listen success, starting server~n"),
            start_adm(LSock),
            {ok, Port} = inet:port(LSock),
            Port;
        {error, Reason} ->
            {error, Reason}
    end.

start_adm(LSock) ->
    spawn(?MODULE, adm_loop, [LSock]).

adm_loop(LS) ->
    {ok, Socket} = gen_tcp:accept(LS),
    Pid = spawn(?MODULE, server, [Socket]),
    gen_tcp:controlling_process(Socket, Pid),
    adm_loop(LS).

server(Sock) ->
    io:format("Socket was accepted~n"),
    inet:setopts(Sock, [{active, once}]),
    receive
        {tcp, _, Data} ->
            Username = binary_to_list(Data),
            ets:insert(users, {Username, self()}),
            put(username, Username),
            io:format("Username registered: ~s~n", [Username]);
        {tcp_closed, S} ->
            io:format("Registration failed, no Username received~n"),
            exit(S)
    end,
    do_recv(Sock).

do_recv(Sock) ->
    inet:setopts(Sock, [{active, once}]),
    receive
        {tcp, S, Data} ->
            Msg = binary_to_term(Data),
            io:format("Received: ~p~n", [Msg]),
            Answer = case forward_msg(Msg) of
                nok ->
                    "Invalid receiver username";
                _ ->
                    "Delivered!"
            end,
            gen_tcp:send(S, term_to_binary(Answer)),
            do_recv(Sock);
        {tcp_closed, S} ->
            io:format("Socket ~w closed [~w]~n", [S, self()]),
            ets:delete(users, get(username));
        {tcp_forward, Data} ->
            io:format("Msg to forward: ~p~n", [Data]),
            gen_tcp:send(Sock, term_to_binary(Data)),
            do_recv(Sock)
    end.

forward_msg({Receiver, Msg}) ->
    Sender = get(username),
    case ets:lookup(users, Receiver) of
        [] ->
            nok;
        [{_, Pid}] ->
            Pid ! {tcp_forward, {Sender, Msg}}
    end.