-module(client_sample).

-export([start/1,
         client/1]).

start(PortN) ->
    Host = "localhost",
    case gen_tcp:connect(Host, PortN, [binary, {active, false},
                         {packet, 0}]) of
        {ok, Sock} ->
            io:format("Connect success, starting client~n"),
            client(Sock);
        {error, Reason} ->
            {error, Reason}
    end.

client(Sock) ->
    Msg = io:get_line("Enter a message: "),
    case Msg of
        "close_connection\n" ->
            gen_tcp:close(Sock),
            io:format("Connection to ~w is closed now!", [Sock]);
        Msg ->
            gen_tcp:send(Sock, Msg),
            {ok, Answer} = gen_tcp:recv(Sock, 0),
            io:format("Answer: ~s~n~n", [binary_to_list(Answer)]),
            client(Sock)
    end.