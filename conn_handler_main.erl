-module(conn_handler_main).
%%--------------------------------------------------------------------
%% The main module for Connection Handler (CH).
%% Main functionalities:
%% 1. Start CH process with registered name;
%% 2. Open TCP socket on specified port;
%% 3. Wait for attach requests and spawn a process-per-connection
%%--------------------------------------------------------------------
%% EXPORT
%%--------------------------------------------------------------------
-export([start/1,
         start_conn_handler/1,
         exit/0]).

%%--------------------------------------------------------------------
%% FUNCTIONS
%%--------------------------------------------------------------------
-spec start(LPort) -> Result when
    LPort  :: pos_integer(),
    Result :: {ok, inet:port_number()} | {error, any()}.
%%--------------------------------------------------------------------
%% Running on recovery controlling process TBD.
%% Open TCP socket on given port number, spawn conn_handler process
%% and return actual socket's port.
%%--------------------------------------------------------------------
start(LPort) ->
    ets:new(users, [set, public, named_table]), % TBR!!!
    case gen_tcp:listen(LPort, [binary, {packet, 0},
                                {active, false}]) of
        {ok, LSock} ->
            io:format("Listen success, starting server~n"),
            spawn(?MODULE, start_conn_handler, [LSock]),
            inet:port(LSock);
        {error, Reason} ->
            {error, Reason}
    end.

%%--------------------------------------------------------------------
-spec exit() -> Result when
    Result :: ok.
%%--------------------------------------------------------------------
%% Running on recovery controlling process
%%--------------------------------------------------------------------
exit() ->
    exit(conn_handler, "Exited by operator~n").

%%--------------------------------------------------------------------
-spec start_conn_handler(LSocket) -> Result when
    LSocket :: inet:socket(),
    Result  :: any().
%%--------------------------------------------------------------------
%% Running on conn_handler.
%% The place conn_handler starts taking place, register his name and
%% wait for attached user in accept loop.
%%--------------------------------------------------------------------
start_conn_handler(LSocket) ->
    register(conn_handler, self()),
    io:format("conn_handler registered~n", []),
    accept_loop(LSocket).

%%--------------------------------------------------------------------
-spec accept_loop(LSocket) -> Result when
    LSocket :: inet:socket(),
    Result  :: any().
%%--------------------------------------------------------------------
%% Running on conn_handler.
%% Main logic is running in this loop, wait for an accept coming from
%% attaching user and spawn corresponding process who's purpose is to
%% listen to user's messages.
%%--------------------------------------------------------------------
accept_loop(LSocket) ->
    case gen_tcp:accept(LSocket) of
        {ok, Socket} ->
            {ok, Pid} = connection:start(Socket),
            io:format("Calling connection:start for socket ~p~nPid ~p~n~n", [Socket, Pid]),
            gen_tcp:controlling_process(Socket, Pid),
            Pid ! socket_ready,
            accept_loop(LSocket);
        {error, closed} ->
            io:format("Listen socket closed, exiting accept_loop~n"),
            ok;
        {error, Reason} ->
            io:format("Accept error: ~p~n", [Reason]),
            accept_loop(LSocket)
    end.