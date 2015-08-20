-module(beam_stats_consumer_statsd_SUITE).

-include_lib("beam_stats/include/beam_stats.hrl").

-export(
    [ all/0
    , groups/0
    ]).

%% Test cases
-export(
    [ t_send/1
    ]).

-define(GROUP, beam_stats_consumer_statsd).

%% ============================================================================
%% Common Test callbacks
%% ============================================================================

all() ->
    [{group, ?GROUP}].

groups() ->
    Tests =
        [ t_send
        ],
    Properties = [],
    [{?GROUP, Properties, Tests}].

%% =============================================================================
%%  Test cases
%% =============================================================================

t_send(_Cfg) ->
    BEAMStats = #beam_stats
    { timestamp = {1, 2, 3}
    , node_id   = 'node_foo@host_bar'
    , memory    = [{mem_type_foo, 1}]
    },
    ServerPort = 8125,
    {ok, ServerSocket} = gen_udp:open(ServerPort, [binary, {active, false}]),
    BEAMStatsQ = queue:in(BEAMStats, queue:new()),
    Options = [{dst_port, ServerPort}],
    {_, State1} = beam_stats_consumer_statsd:init(Options),
    State2 = beam_stats_consumer_statsd:consume(BEAMStatsQ, State1),
    {} = beam_stats_consumer_statsd:terminate(State2),
    ResultOfReceive = gen_udp:recv(ServerSocket, 0),
    ok = gen_udp:close(ServerSocket),
    {ok, {_, _, Data}} = ResultOfReceive,
    <<"beam_stats.node_foo_host_bar.mem_type_foo:1|g\n">> = Data.
