-module(els_transport).

-callback start_listener()      -> {ok, pid()}.
-callback init(any())           -> any().
-callback send(any(), binary()) -> ok.
