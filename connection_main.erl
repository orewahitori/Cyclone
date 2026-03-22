-module(connection_main).
%%--------------------------------------------------------------------
%% The main module for Connection.
%% Main functionalities:
%% I       Start a connection process;
%% II 1.a) Register user;
%% II 1.b) Dispatch to receiver;
%% II 2.   Close connection;
%% II      Handle dispatched message
%%--------------------------------------------------------------------
%% EXPORT
%%--------------------------------------------------------------------
%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1,
         handle_info/2,
         terminate/2]).

%%--------------------------------------------------------------------
%% RECORDS
%%--------------------------------------------------------------------
-record(message, {sender,
                  receiver,
                  type,
                  text,
                  time}).
-record(user, {username}).
-record(state, {user = undefined,
                socket}).

%%--------------------------------------------------------------------
%% FUNCTIONS
%%--------------------------------------------------------------------
%% API
%%--------------------------------------------------------------------
%% Running on conn_handler process.
%% Spawns a temporary process for given socket whenever an user
%% is trying to get online.
%%--------------------------------------------------------------------
start_link(Socket) ->
    gen_server:start_link(?MODULE, Socket, []).

%%--------------------------------------------------------------------
%% gen_server callbacks
%%--------------------------------------------------------------------
-spec init(Socket) -> Result when
    Socket :: inet:socket(),
    Result :: {ok, #state{}}.
%%--------------------------------------------------------------------
%% Initial call from gen_server
%%--------------------------------------------------------------------
init(Socket) ->
    io:format("tmp connection started~n", []),
    {ok, #state{socket=Socket}}.

%%--------------------------------------------------------------------
-spec handle_info(Msg, State) -> Result when
    Msg    :: term(),
    State  :: #state{},
    Result :: {noreply, #state{}} | {stop, normal, #state{}}.
%%--------------------------------------------------------------------
%% Running on tmp connection process.
%% Receives messages and decides how to proceed with them:
%% 1.a. Register user;
%% 1.b. Dispatch to receiver;
%% 2.   Close connection;
%% 3.   Handle dispatched message
%%--------------------------------------------------------------------
handle_info(socket_ready, State = #state{socket = Socket}) ->
    inet:setopts(Socket, [{active, once}]),
    {noreply, State};
handle_info({tcp, Socket, Data}, State) ->
    Msg = decode(Data),
    io:format("Received: ~p~n", [Msg]),

    {Reply, NewState} = handle_msg(Msg, State),
    send(Socket, Reply),
    inet:setopts(Socket, [{active, once}]),
    {noreply, NewState};
handle_info({tcp_forward, Msg}, State = #state{socket = Socket}) ->
    send(Socket, Msg),
    {noreply, State};
handle_info({tcp_closed, Socket}, State = #state{user=User}) ->
    io:format("Socket ~p closed~n", [Socket]),
    ets:delete(users, User#user.username),
    {stop, normal, State};
handle_info(Msg, State) ->
    io:format("Unrecognized message received: ~p~nState: ~p", [Msg, State]),
    {stop, normal, State}.

%%--------------------------------------------------------------------
-spec terminate(_Reason, State) -> Result when
    State  :: #state{},
    Result :: ok.
%%--------------------------------------------------------------------
%% Terminate single connection process, since the socket is close
%% simply unregister him.
%%--------------------------------------------------------------------
terminate(_Reason, #state{user = User}) ->
    case User of
        undefined ->
            ok;
        _ ->
            ets:delete(users, User#user.username)
    end,
    ok.

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------
-spec handle_msg(Msg, State) -> Result when
    Msg    :: #message{},
    State  :: #state{},
    Result :: {string(), #state{}}.
%%--------------------------------------------------------------------
%% Running on tmp connection process.
%% Decides whether does it need to turn the user status to online or
%% to dispatch the message to the process responsible for connection
%% towards destination side.
%%--------------------------------------------------------------------
handle_msg(#message{type = connect, sender = Sender} = Msg, State) ->
    ets:insert_new(users, {Sender#user.username, self()}),
    io:format("Username registered: ~p~n", [Sender]),
    Reply = Msg#message{text = "Connected sucessfully",
                        time = erlang:universaltime(),
                        sender = #user{username = "Server"},
                        receiver = Sender},
    {Reply, State#state{user = Sender}};
handle_msg(#message{receiver = Receiver,
                    sender = Sender} = Msg, State) ->
    ReplyTxt = case ets:lookup(users, Receiver#user.username) of
        [] ->
            "Invalid receiver username";
        [{_, Pid}] ->
            Pid ! {tcp_forward, Msg},
            "Delivered!"
    end,
    Reply = Msg#message{receiver = Sender,
                        sender = #user{username = "Server"},
                        text = ReplyTxt,
                        time = erlang:universaltime()},
    {Reply, State}.


send(Socket, Msg) ->
    case gen_tcp:send(Socket, encode(Msg)) of
        ok -> ok;
        {error, _} -> exit(normal)
    end.
%% To be implemented later, simply binary/term transforming for now
encode(Msg) ->
    term_to_binary(Msg).
decode(Data) ->
    binary_to_term(Data).
