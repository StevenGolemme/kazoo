%%%-------------------------------------------------------------------
%%% @copyright (C) 2015, 2600Hz
%%% @doc
%%%
%%% @end
%%% @contributors
%%%-------------------------------------------------------------------
-module(ci_parsers_sup).

-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).
-export([start_child/2
         ,stop_child/1
         ,children/0
         ,child/1
        ]).

-include("../call_inspector.hrl").

%% ===================================================================
%% API functions
%% ===================================================================

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Starts the supervisor
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> startlink_ret().
start_link() ->
    supervisor:start_link({'local', ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

%%--------------------------------------------------------------------
%% @public
%% @doc
%% Whenever a supervisor is started using supervisor:start_link/[2,3],
%% this function is called by the new process to find out about
%% restart strategy, maximum restart frequency and child
%% specifications.
%% @end
%%--------------------------------------------------------------------
-spec init([]) -> sup_init_ret().
init([]) ->
    RestartStrategy = 'one_for_one',
    MaxRestarts = 5,
    MaxSecondsBetweenRestarts = 10,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    {'ok', {SupFlags, []}}.

-type parser() :: 'ci_parser_freeswitch' | 'ci_parser_kamailio' | 'ci_parser_hep'.
-spec start_child(parser(), [{'parser_args',_,_} | {'parser_args',_,_,_}]) ->
                         {'ok', atom()}.
start_child(Module, Args) ->
    Id = ci_parsers_util:make_name(lists:keyfind('parser_args', 1, Args)),
    ChildSpec = ?WORKER_NAME_ARGS(Module, Id, Args),
    {'ok', _Pid} = supervisor:start_child(?MODULE, ChildSpec),
    {'ok', Id}.

-spec stop_child(atom()) -> 'ok'.
stop_child(Id) ->
    'ok' = supervisor:terminate_child(?MODULE, Id),
    'ok' = supervisor:delete_child(?MODULE, Id).

-spec children() -> [atom()].
children() ->
    [Id
     || {Id, _Pid, _Type, _Modules} <- supervisor:which_children(?MODULE)
    ].

-spec child(pid()) -> api_atom().
child(PID) ->
    case [Id
          || {Id, Pid, _Type, _Modules} <- supervisor:which_children(?MODULE),
             Pid =:= PID
         ]
    of
        [Id] -> Id;
        [] -> 'undefined'
    end.

%% Internals

%% End of Module.
