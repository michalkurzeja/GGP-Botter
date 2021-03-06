:- module(server, [start/2]).

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_client)).
:- use_module(library(debug)).

:- use_module(parameters).
:- use_module(botLoader).
:- use_module(requestData).
:- use_module(requestHandler).
:- use_module(rules).

%% Routing:
:- http_handler(root(.), getRequest, []).

%% Server init - entry point to application
start(Port, Bot) :-
	%% tspy(game:findAllLegal/3),
	%% debug(request),
	parameters:parse,
	parameters:params(BotDir),
	botLoader:load(BotDir, Bot),
	assertz(port(Port)),
	runServer(Port).

%% Action handlers
handleRequest(['INFO'|_], Response) :- Response = 'available'.
handleRequest(['START', GameId, Role, Rules, StartClock, PlayClock], Response) :-
	requestHandler:handleStart(GameId, Role, Rules, StartClock, PlayClock),
	Response = 'ready'.
handleRequest(['PLAY', GameId, Moves], Response) :-
	requestHandler:handlePlay(GameId, Moves, Played),
	debug(request, 'Played:~n~p', [Played]),
	port(Port),
	logger:log(Port, ['Received moves:', Moves]),
	logger:log(Port, ['Played:', Played]),
	Response = Played.
handleRequest(['STOP', GameId, Move], Response) :-
	requestHandler:handleStop(GameId, Move),
	Response = 'ready'.
handleRequest(['ABORT', GameId], Response) :-
	requestHandler:handleAbort(GameId),
	Response = 'aborted'.

% Do we want to handle this case?
handleRequest(['PREVIEW'|_], Response) :- Response = 'done'.

% Unknown data
handleRequest([_], Response) :- Response = 'nil'.

%% Request handlers:
getRequest(Request) :-
	http_read_data(Request, RequestData, []),
	requestData:parseRequest(RequestData, Data),
	handleRequest(Data, Response),
	formatResponse(Response).

formatResponse(Response) :-
	format('Content-type: text/acl~n~n'),
    format(Response).

runServer(Port) :-
	format('~nStarting player...~n'),
	http_server(http_dispatch, [port(Port)]),
	format('Player ready!~n~n').

post(Address, Data) :-
	http_post(Address, Data, _, []).