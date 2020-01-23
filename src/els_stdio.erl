-module(els_stdio).

-behaviour(els_transport).

-export([ start_listener/0
        , init/1
        , send/2
        ]).

-export([ loop/3 ]).

%%==============================================================================
%% els_transport callbacks
%%==============================================================================
-spec start_listener() -> {ok, pid()}.
start_listener() ->
  {ok, IoDevice} = application:get_env(erlang_ls, io_device),
  {ok, proc_lib:spawn_link(?MODULE, init, [IoDevice])}.

-spec init(any()) -> no_return().
init(IoDevice) ->
  lager:info("Starting stdio server..."),
  ok = io:setopts(IoDevice, [binary]),
  ok = els_server:set_connection(IoDevice),
  loop([], IoDevice, [return_maps]).

-spec send(any(), binary()) -> ok.
send(Connection, Payload) ->
  io:format(Connection, Payload, []).

%%==============================================================================
%% Listener loop function
%%==============================================================================

-spec loop([binary()], any(), [any()]) -> no_return().
loop(Lines, IoDevice, JsonOpts) ->
  case io:get_line(IoDevice, "") of
    <<"\n">> ->
      Headers       = parse_headers(Lines),
      BinLength     = proplists:get_value(<<"content-length">>, Headers),
      Length        = binary_to_integer(BinLength),
      %% Use file:read/2 since it reads bytes
      {ok, Payload} = file:read(IoDevice, Length),
      Request       = jsx:decode(Payload, JsonOpts),
      els_server:process_requests([Request]),
      loop([], IoDevice, JsonOpts);
    eof ->
      lager:debug("Shutting down els_stdio process..."),
      els_server:process_requests([#{
          <<"method">> => <<"exit">>,
          <<"params">> => []
        }]);
    Line ->
      loop([Line | Lines], IoDevice, JsonOpts)
  end.

-spec parse_headers([binary()]) -> [{binary(), binary()}].
parse_headers(Lines) ->
  [parse_header(Line) || Line <- Lines].

-spec parse_header(binary()) -> {binary(), binary()}.
parse_header(Line) ->
  [Name, Value] = binary:split(Line, <<":">>),
  {string:trim(string:lowercase(Name)), string:trim(Value)}.