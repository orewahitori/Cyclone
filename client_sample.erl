-module(client_sample).

-export([start/2,
         client/1,
         receiver/0]).

start(PortN, Username) ->
    Host = "localhost",
    case gen_tcp:connect(Host, PortN, [binary, {active, false},
                         {packet, 0}]) of
        {ok, Sock} ->
            io:format("Connect success, starting client~n"),
            Pid = spawn(?MODULE, receiver, []),
            gen_tcp:controlling_process(Sock, Pid),
            inet:setopts(Sock, [{active, true}]),
            gen_tcp:send(Sock, list_to_binary(Username)),
            client(Sock);
        {error, Reason} ->
            {error, Reason}
    end.

client(Sock) ->
    Receiver = string:trim(io:get_line("Enter receiver: ")),
    Msg = io:get_line("Enter a message: "),
    case Msg of
        "closeconn\n" ->
            gen_tcp:close(Sock),
            io:format("Connection to ~w is closed now!", [Sock]);
        Msg ->
            gen_tcp:send(Sock, term_to_binary({Receiver, Msg})),
            client(Sock)
    end.

receiver() ->
    receive
        {tcp, S, Data} ->
            Msg = binary_to_term(Data),
            io:format("Received: ~p~n", [Msg]),
            inet:setopts(S, [{active, true}]),
            receiver();
        {tcp_closed, S} ->
            io:format("Socket ~w closed [~w]~n", [S, self()]),
            ets:delete(users, get(username))
    end.