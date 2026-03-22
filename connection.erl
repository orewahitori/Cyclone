-module(connection).
%%--------------------------------------------------------------------
%% API module for Connection.
%% 
%%--------------------------------------------------------------------
%% EXPORT
%%--------------------------------------------------------------------
-export([start/1]).

%%--------------------------------------------------------------------
%% FUNCTIONS
%%--------------------------------------------------------------------
-spec start(Socket) -> Result when
    Socket :: inet:socket(),
    Result :: pid().
%%--------------------------------------------------------------------
%% Running on conn_handler process.
%% Spawns a temporary process for given socket whenever an user
%% is trying to get online.
%%--------------------------------------------------------------------
start(Socket) ->
    connection_main:start_link(Socket).
