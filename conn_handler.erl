-module(conn_handler).
%%--------------------------------------------------------------------
%% API module for Connection Handler (CH).
%% Main functionalities:
%% 1. Start CH process with registered name;
%% 2. Open TCP socket on specified port;
%% 3. Wait for attach requests and spawn a process-per-connection
%%--------------------------------------------------------------------
%% EXPORT
%%--------------------------------------------------------------------
-export([start/1,
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
start(PortNo) ->
    conn_handler_main:start(PortNo).

%%--------------------------------------------------------------------
-spec exit() -> Result when
    Result :: ok.
%%--------------------------------------------------------------------
%% Running on recovery controlling process
%%--------------------------------------------------------------------
exit() ->
    conn_handler_main:exit().