-module(client_sample).

-export([start/2,
         client/3,
         receiver/1]).

-record(message, {sender,
                  receiver,
                  type,
                  text,
                  time}).
-record(user, {username}).

start(PortN, Username) ->
    User = #user{username = Username},
    Host = "localhost",
    case gen_tcp:connect(Host, PortN, [binary, {active, once},
                         {packet, 0}]) of
        {ok, Socket} ->
            io:format("-------------------------------------------------------~n", []),
            io:format("Connect success, starting client~n"),
            io:format("-------------------------------------------------------~n", []),
            ReceiveP = spawn(?MODULE, receiver, [User]),
            gen_tcp:controlling_process(Socket, ReceiveP),
            
            ReceiveP ! {send_connect, Socket, User},
            client(Socket, User, ReceiveP);
        {error, Reason} ->
            {error, Reason}
    end.

client(Sock, User, ReceiveP) ->
    Receiver = string:trim(io:get_line("Enter receiver: ")),
    io:format("-------------------------------------------------------~n", []),
    Txt = io:get_line("Enter a message: "),
    io:format("-------------------------------------------------------~n", []),
    case Txt of
        "\n" ->
            ReceiveP ! {close_tcp, Sock};
        _ ->
            ReceiveP ! {send_tcp, Sock, {Receiver, Txt}},
            client(Sock, User, ReceiveP)
    end.

receiver(User) ->
    receive
        {send_connect, Socket, User} ->
            Msg = #message{sender = User,
                           time = erlang:universaltime(),
                           type = connect},
            io:format("Registration started on receiver...~n", []),
            gen_tcp:send(Socket, term_to_binary(Msg)),
            inet:setopts(Socket, [{active, once}]),
            io:format("Waiting for ack...~n", []),
            io:format("-------------------------------------------------------~n", []),
            receiver(User);
        {send_tcp, Socket, {Receiver, Txt}} ->
            Msg = #message{sender = User,
                           receiver = #user{username = Receiver},
                           type = user_message,
                           text = Txt,
                           time = erlang:universaltime()},
            gen_tcp:send(Socket, term_to_binary(Msg)),
            receiver(User);
        {tcp, Socket, Data} ->
            print_message(binary_to_term(Data)),
            inet:setopts(Socket, [{active, once}]),
            receiver(User);
        {close_tcp, Socket} ->
            gen_tcp:close(Socket),
            io:format("Connection to ~w is closed now!~n", [Socket]),
            io:format("-------------------------------------------------------~n", []);
        {tcp_closed, Socket} ->
            io:format("Socket ~w closed [~w]~n", [Socket, self()]),
            io:format("-------------------------------------------------------~n", [])
    end.

print_message(#message{time = Time, text = Txt,
                       sender = Sender, receiver = Receiver}) ->
    io:format("Received! ~n", []),
    io:format("Time: ~p~nSender: ~p~nReceiver: ~p~n", [Time, Sender#user.username, Receiver#user.username]),
    io:format("Message: ~p~n", [Txt]),
    io:format("-------------------------------------------------------~n", []).