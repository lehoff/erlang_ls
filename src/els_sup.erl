%%==============================================================================
%% Top Level Supervisor
%%==============================================================================
-module(els_sup).

%%==============================================================================
%% Behaviours
%%==============================================================================
-behaviour(supervisor).

%%==============================================================================
%% Exports
%%==============================================================================

%% API
-export([ start_link/1 ]).

%% Supervisor Callbacks
-export([ init/1 ]).

%%==============================================================================
%% Defines
%%==============================================================================
-define(SERVER, ?MODULE).

%%==============================================================================
%% API
%%==============================================================================
-spec start_link(module()) -> {ok, pid()}.
start_link(Transport) ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, [Transport]).

%%==============================================================================
%% Supervisor callbacks
%%==============================================================================
-spec init([module()]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([Transport]) ->
  SupFlags = #{ strategy  => rest_for_one
              , intensity => 5
              , period    => 60
              },
  ChildSpecs = [ #{ id       => els_server
                  , start    => {els_server, start_link, [Transport]}
                  }
               ,
                 #{ id       => els_transport
  				       , start    => {Transport, start_listener, []}
  				       }
               , #{ id       => els_config
                  , start    => {els_config, start_link, []}
                  }
               , #{ id       => els_indexer
                  , start    => {els_indexer, start_link, []}
                  }
               , #{ id       => els_providers_sup
                  , start    => {els_providers_sup, start_link, []}
                  , type     => supervisor
                  }
               ],
  {ok, {SupFlags, ChildSpecs}}.
