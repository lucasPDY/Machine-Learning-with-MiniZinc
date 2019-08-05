%
% Vehicle Routing Problem
%

% Location data

% Locations
int: NumLocs;
set of int: Locations = 1..NumLocs;

array [Locations, Locations] of int: dist;


% Survey
int: N = NumLocs - 1;

% Vehicles
int: NumRoutes = 4*N; % Worst Case 
set of int: Vehicles = 1..NumRoutes;  % One Vehicle for each Route

% Survey Time
% We assume that the amount of time it takes to do a survey is constant, e.g. 70000 seconds
int: surveyTime;


% =====================================
% Model
% =====================================

include "globals.mzn";

% Define sets of nodes

% Survey locations have 2 states, a start and an end state
set of int: ArriveSurvey = 1..N;
set of int: LeaveSurvey = N+1..2*N;
% 1..2*N represent survey nodes, anything greater is a Depot Node  
% At the worst case, A taxi will visit all survey nodes
set of int: TaxiStart1 = 2*N+1..4*N;  % All Starting Nodes for Taxi 1
set of int: TaxiStart2  = 4*N+1..6*N; % All Starting Nodes for Taxi 2
set of int: Taxi = 1..4*N; % All Taxis
set of int: TaxiEnd1 = 6*N+1..8*N; % All Ending Nodes for Taxi 1
set of int: TaxiEnd2 = 8*N+1..10*N; % All Ending Nodes for Taxi 2

% All Nodes
set of int: Visits = 1..max(TaxiEnd2);
% All Survey Nodes plus Taxi Starting Nodes
set of int: SurveyPlusStarts = 1..max(TaxiStart2);


% Array of Distances between 2 points i and j
% Extended array of distances, including the depot start/end nodes.
array[Visits,Visits] of int: visit_dist = array2d(Visits,Visits,
  [if i> 2 * N /\ j > 2 * N then 0  % Distance between Depots
   elseif i > 2 * N then dist[NumLocs,(j mod N) + 1] % Distance between Depots and Survey (i > Survey)
   elseif j> 2 * N then dist[(i mod N)+1,NumLocs] % Distance between Survey and Depot (j > Survey)
   elseif i + N = j then 0
   elseif j + N = i then 0               % Distance between the same depots is 0
   else dist[(i mod N)+1 ,(j mod N)+1] endif | i,j in Visits]); % Euclidean Distance for the rest

% =====================================
% Decision variables
% =====================================

% Successor representation
array[Visits] of var Visits: successor;

% Time (i-th element is the time when the taxi visits the i-th node)
array[Visits] of var 0..infinity: time;
% Time (i-th element is the time when the i-th survey starts)
array[ArriveSurvey] of var 0..infinity: surveyStart;

% Mapping from visits to route (vehicle) number
array[Visits] of var Vehicles: routeOf;

% Objective function:
% Maximum time taken to complete all surveys
var int: objective = max(time);

% =====================================
% Problem Constraints
% =====================================

% Route & Successor Constraints
% =====================================

% Assign each vehicle depot start node to its route
constraint forall (k in Taxi) ( routeOf[2*N + k] = k);

% Assign each vehicle depot end node to its route
constraint forall (k in Taxi) ( routeOf[6*N + k] = k);

% The successors form a circuit (grand tour representation)
constraint circuit (successor) ::domain;

% successor of an ending taxi node is the next starting taxi node, wraps around to first depot node
constraint
  forall (k in Taxi)
    ( successor[6*N + k] = ( 2*N + 1 + (k mod NumRoutes) ) );

% Successor of starting survey node can only be a depot node or an ending survey node
constraint forall(k in ArriveSurvey)(successor[k] > N);
% Sucessor of ending survey node can only be a depot node or a starting survey node
constraint forall(k in LeaveSurvey)(successor[k] <= N \/ successor[k] >= 2*N + 1);
    
% Link up the routeOf and successor variables:
% Each visit is on the same route as its successor.
% This is true for all survey and start visits, but not for the end visits.
constraint forall (i in SurveyPlusStarts) ( routeOf[i] = routeOf[successor[i]] );


% =====================================
% Survey Constraints
% =====================================

% Survey i should start after or at the time the survey team reaches survey site i
constraint forall(i in ArriveSurvey)(surveyStart[i] >= time[i]);
% The time the taxi leaves from survey site i should be after 1800 seconds from the time the survey starts
constraint forall(i in ArriveSurvey)(surveyStart[i] + surveyTime <= time[i + N]);

% This constraint makes sure that at any given time, only 2 surveys maybe be done in parallel
% It takes in an array of start times, the amount of time it takes to finish the survey, how many survey teams are used for that survey, and the maximum number of survey teams available
constraint cumulative(surveyStart, [surveyTime | i in 1..N], [1 | i in 1..N], 2);

% =====================================
% Time Constraints
% =====================================

% Accumulate Time
constraint forall(i in Visits where i != 4 * N - 1 /\ i != 6 * N - 1)(time[successor[i]] >= time[i] + visit_dist[i, successor[i]]);

% Starting Taxi times are 0, at 2n + 1 and 4n + 1
constraint time[2 * N + 1] = 0;
constraint time[4 * N + 1] = 0;

% Ending Depot Time should be the same as the next Starting Depot Time, for each Taxi
constraint forall(i in 1..2, j in 1..2*N-1)(time[6*N + j + (i-1)*N] = time[2*N + j + 1 + (i-1)*N]);
  

% =====================================
% Symmetry breaking
% =====================================

% If the successor of the i-th starting taxi node is its ending taxi node, then the successor of 
% the (i+1)-th starting taxi node will also be its corresponding ending taxi node
constraint forall(i in 1..2*N-1) (successor[2*N+i] = 6*N + i -> successor[2*N+i+1] = 6*N + i + 1);

% =====================================
% Solve and output
% =====================================

% We want to minimize the time taken to complete all surveys
solve
  :: int_search ( successor, dom_w_deg, indomain_min, complete)
  minimize (objective);

output
[ "duration = ", show(objective), "\n" ] ++
[ "successor = ", show(successor), ";\n" ] ++
[ "routeOf = ", show(routeOf), ";\n"] 
++ [ "time = ", show(time), ";\n"]
++ [ "surveyStart = ", show(surveyStart), ";\n"];