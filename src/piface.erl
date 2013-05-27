%%%---- BEGIN COPYRIGHT -------------------------------------------------------
%%%
%%% Copyright (C) 2007 - 2013, Rogvall Invest AB, <tony@rogvall.se>
%%%
%%% This software is licensed as described in the file COPYRIGHT, which
%%% you should have received as part of this distribution. The terms
%%% are also available at http://www.rogvall.se/docs/copyright.txt.
%%%
%%% You may opt to use, copy, modify, merge, publish, distribute and/or sell
%%% copies of the Software, and permit persons to whom the Software is
%%% furnished to do so, under the terms of the COPYRIGHT file.
%%%
%%% This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
%%% KIND, either express or implied.
%%%
%%%---- END COPYRIGHT ---------------------------------------------------------
%%% @author tony <tony@rogvall.se>
%%% @doc
%%%    Piface interface
%%%
%%% Created : Apr 2013 by Tony Rogvall
%%% @end

-module(piface).
-behaviour(gen_server).
-include_lib("spi/include/spi.hrl").


%% API
-export([start_link/0,
	 stop/0]).

-export([gpio_get/1, 
	 gpio_set/1, 
	 gpio_clr/1]).

-export([init_interrupt/0]).

-export([read_input/0, 
	 read_output/0,
	 write_output/1]).


%% gen_server callbacks
-export([init/1, 
	 handle_call/3, 
	 handle_cast/2, 
	 handle_info/2,
	 terminate/2, 
	 code_change/3]).

-define(PIFACE_SRV, piface_srv).

-define(SPI_BUS, 0).
-define(SPI_DEVICE, 0).

-define(TRANSFER_LEN,   3).
-define(TRANSFER_DELAY, 5).
-define(TRANSFER_SPEED, 1000000).
-define(TRANSFER_BPW,   8).

-define(SPI_WRITE_CMD,  16#40).
-define(SPI_READ_CMD,   16#41).

%% Port configuration
-define(IODIRA, 16#00).    %% I/O direction A
-define(IODIRB, 16#01).    %% I/O direction B
-define(IOCON,  16#0A).     %% I/O config
-define(GPIOA,  16#12).     %% port A
-define(GPIOB,  16#13).     %% port B
-define(GPPUA,  16#0C).     %% port A pullups
-define(GPPUB,  16#0D).     %% port B pullups
-define(OUTPUT_PORT, ?GPIOA).
-define(INPUT_PORT,  ?GPIOB).
-define(GPINTENA, 16#04).
-define(GPINTENB, 16#05).
-define(DEFVALA,  16#06).
-define(DEFVALB,  16#07).
-define(INTCONA,  16#08).
-define(INTCONB,  16#09).

-define(IOCON_HAEN,   2#00001000).
-define(IOCON_MIRROR, 2#01000000).

-record(ctx,
	{
	  state = init
	}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server.
%%
%% @end
%%--------------------------------------------------------------------
-spec start_link() ->  
			{ok, Pid::pid()} | 
			{error, Reason::atom()}.
start_link()->
    io:format("piface: start_link\n", []),
    gen_server:start_link({local, ?PIFACE_SRV}, ?MODULE, [], []).

%%--------------------------------------------------------------------
%% @doc
%% Stops the server.
%% @end
%%--------------------------------------------------------------------
-spec stop() -> ok | {error, Error::term()}.

stop() ->
    gen_server:call(?PIFACE_SRV, stop).


%%--------------------------------------------------------------------
-spec init_interrupt() -> ok.

init_interrupt() ->
    spi_write(?INTCONB,  16#00), %% interrupt on any change
    spi_write(?GPINTENB, 16#FF), %% enable interrupts on B
    ok.

%%--------------------------------------------------------------------
-spec gpio_get(Pin::uint8()) -> boolean().

gpio_get(Pin) when ?is_uint8(Pin) ->
    Bits = read_input(),
    Bits band (1 bsl Pin) =/= 0.
 
%%--------------------------------------------------------------------
-spec gpio_set(Pin::uint8()) -> ok | {error,posix()}.

gpio_set(Pin) when ?is_uint8(Pin) ->
    Bits = read_output(),
    write_output(Bits bor (1 bsl Pin)).

%%--------------------------------------------------------------------
-spec gpio_clr(Pin::uint8()) -> ok | {error,posix()}.

gpio_clr(Pin) when ?is_uint8(Pin) ->
    Bits = read_output(),
    write_output(Bits band (bnot (1 bsl Pin))).

%%--------------------------------------------------------------------
-spec read_input() -> ok.

read_input() ->
    spi_read(?INPUT_PORT).

%%--------------------------------------------------------------------
-spec read_output() -> ok.

read_output() ->
    spi_read(?OUTPUT_PORT).

%%--------------------------------------------------------------------
-spec write_output(Value::integer()) -> ok.

write_output(Value) ->
    spi_write(?OUTPUT_PORT, Value).

%%--------------------------------------------------------------------
%% @private
%% @doc
%%
%% Initializes the server.
%% set up some ports
%% enable hardware addressing + mirror interrupts
%% I am not sure if MIRROR is needed, because I have not got a up-to-date
%% schematic of the piface card.
%% @end
%%--------------------------------------------------------------------
-spec init([]) -> 
		  {ok, Ctx::#ctx{}} |
		  {stop, Reason::atom()}.
init([]) ->
    ok = spi:open(?SPI_BUS, ?SPI_DEVICE),
    spi_write(?IOCON,  ?IOCON_HAEN bor ?IOCON_MIRROR),
    spi_write(?IODIRA, 0),     %% set port A as outputs
    spi_write(?IODIRB, 16#FF), %% set port B as inputs
    spi_write(?GPIOA,  16#FF), %% set port A on
    %% spi_write(?GPIOB,  0xFF), %% set port B on
    spi_write(?GPPUA,  16#FF), %% set port A pullups on
    spi_write(?GPPUB,  16#FF), %% set port B pullups on
    write_output(16#00),       %% lower all outputs
    {ok, #ctx{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-type call_request()::
	stop.

-spec handle_call(Request::call_request(),
		  From::{pid(), term()}, Ctx::#ctx{}) ->
			 {reply, Reply::term(), Ctx::#ctx{}} |
			 {noreply, Ctx::#ctx{}} |
			 {stop, Reason::term(), Reply::term(), Ctx::#ctx{}}.



handle_call(stop, _From, Ctx) ->
    {stop, normal, ok, Ctx};

handle_call(_Request, _From, Ctx) ->
    {reply, {error, bad_call}, Ctx}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec handle_cast(Msg::term(), Ctx::#ctx{}) -> 
			 {noreply, Ctx::#ctx{}} |
			 {noreply, Ctx::#ctx{}, Timeout::timeout()} |
			 {stop, Reason::term(), Ctx::#ctx{}}.

handle_cast(_Msg, Ctx) ->
    {noreply, Ctx}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec handle_info(Info::term(), Ctx::#ctx{}) -> 
			 {noreply, Ctx::#ctx{}}.

handle_info(_Info, Ctx) ->
    {noreply, Ctx}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process loop data when code is changed
%%
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn::term(), Ctx::#ctx{}, Extra::term()) -> 
			 {ok, NewCtx::#ctx{}}.

code_change(_OldVsn, Ctx, _Extra) ->
    {ok, Ctx}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, Ctx) -> void()
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason::term(), Ctx::#ctx{}) -> 
		       no_return().

terminate(_Reason, _Ctx) ->
    ok.

%%--------------------------------------------------------------------
%% Utilities
%%--------------------------------------------------------------------
spi_write(Port, Value) ->
    case spi:transfer(?SPI_BUS, ?SPI_DEVICE,
		      <<?SPI_WRITE_CMD, Port, Value>>,
		      ?TRANSFER_LEN,
		      ?TRANSFER_DELAY,
		      ?TRANSFER_SPEED,
		      ?TRANSFER_BPW, 0) of
	{ok,_Data} -> ok;
	Error -> Error
    end.

spi_read(Port) ->
    case spi:transfer(?SPI_BUS, ?SPI_DEVICE,
		      <<?SPI_READ_CMD, Port, 16#ff>>,
		      ?TRANSFER_LEN,
		      ?TRANSFER_DELAY,
		      ?TRANSFER_SPEED,
		      ?TRANSFER_BPW, 0) of
	{ok, <<_,_,Bits>>} -> Bits;
	{ok, _} -> {error,badbits};
	Error -> Error
    end.
