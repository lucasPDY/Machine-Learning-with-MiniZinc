%
% Vehicle Routing Problem
%

% Name of the instance
string: Name;

% Location data

% Each customer is represented as a pair of x and y coordinates.
% The final location is that of the depot.

% x coordinates of location
array[int] of float: locX;
% y coordinates of location
array[int] of float: locY;

% Locations
int: NumLocs = length(locX);
set of int: Locations = 1..NumLocs;

% Customers
int: NumCusts = NumLocs - 1;
set of int: Customers = 1..NumCusts;
% 1..NumCusts represent customer nodes, anything greater is a Depot Node

% Vehicles
int: NumVehicles = 2*NumCusts*2;
int: NumRoutes = NumVehicles;
set of int: Vehicles = 1..4*NumCusts;
set of int: Routes = 1..NumRoutes;   

% Survey Time
int: surveyTime = 70000;

% Euclidian distance between locations, computed from
% x/y coordinates
array [Locations, Locations] of int: dist = 
    array2d (
        Locations, Locations,
        [ round (1000.0 * sqrt( (locX[a] - locX[b]) * (locX[a] - locX[b]) +
                                (locY[a] - locY[b]) * (locY[a] - locY[b]))
          )
        | a, b in Locations
        ]
    );


% =====================================
% Model
% =====================================

include "globals.mzn";

% Define sets of nodes



% Survey Location have 2 states, start and end state
set of int: ArriveSurvey = 1..NumCusts;
set of int: LeaveSurvey = NumCusts+1..2*NumCusts;

% At the worst case, A taxi will visit all 2n survey sites
set of int: TaxiStart1 = 2*NumCusts+1..4*NumCusts;
set of int: TaxiStart2  = 4*NumCusts+1..6*NumCusts;
set of int: TaxiEnd1 = 6*NumCusts+1..8*NumCusts;
set of int: TaxiEnd2 = 8*NumCusts+1..10*NumCusts;

set of int: Visits = 1..max(TaxiEnd2);
set of int: CustsPlusStarts = 1..max(TaxiStart2);

% Start/end visits
% Number of Starting Nodes = Number of Available Routes = Number of Ending Nodes
% set of int: StartVisits = NumCusts+1..NumCusts+NumRoutes;
% set of int: EndVisits = NumCusts+NumRoutes+1..NumCusts+2*NumRoutes;
% set of int: Visits = 1..max(EndVisits);
% set of int: CustsPlusStarts = 1..max(StartVisits);

% Array of Distances between 2 points i and j
% Extended array of distances, including the depot start/end nodes.
array[Visits,Visits] of int: visit_dist = array2d(Visits,Visits,
  [if i> 2 * NumCusts /\ j > 2 * NumCusts then 0  % Distance between Depots
   elseif i > 2 * NumCusts then dist[NumLocs,(j mod NumCusts) + 1] % Distance between Depots and Customer (i > Customer)
   elseif j> 2 * NumCusts then dist[(i mod NumCusts)+1,NumLocs] % Distance between Customer and Depot (j > Customer)
   elseif i + NumCusts = j then 0
   elseif j + NumCusts = i then 0               % Distance between the same depots is 0
   else dist[(i mod NumCusts)+1 ,(j mod NumCusts)+1] endif | i,j in Visits]); % Euclidean Distance for the rest

% =====================================
% Decision variables
% =====================================

% Successor representation
array[Visits] of var Visits: successor;

% % Time
array[Visits] of var 0..infinity: time;

array[1..NumCusts] of var 0..infinity: surveyStart;

% Survey i should start after or at the time the survey team reaches survey site i
constraint forall(i in ArriveSurvey)(surveyStart[i] >= time[i]);
% The time the taxi leaves from survey site i should be after 1800 seconds from the time the survey starts
constraint forall(i in ArriveSurvey)(surveyStart[i] + surveyTime <= time[i + NumCusts]);

constraint cumulative(surveyStart, [surveyTime | i in 1..NumCusts], [1 | i in 1..NumCusts], 2);

% Accumulate Time
constraint forall(i in Visits where i != 4 * NumCusts - 1 /\ i != 6 * NumCusts - 1)(time[successor[i]] >= time[i] + visit_dist[i, successor[i]]);

% Starting Taxi times are 0, at 2n + 1 and 4n + 1
constraint time[2 * NumCusts + 1] = 0;
constraint time[4 * NumCusts + 1] = 0;

% Ending Depot Time should be the same as the next Starting Depot Time
constraint forall(i in 1..2, j in 1..2*NumCusts-1)(time[6*NumCusts + j + (i-1)*NumCusts] = time[2*NumCusts + j + 1 + (i-1)*NumCusts]);
  


% Mapping from visits to route (vehicle) number
array[Visits] of var Vehicles: routeOf;

% =====================================
% Problem Constraints
% =====================================

% The successors form a circuit (grand tour representation)
constraint circuit (successor) ::domain;

% Assign each vehicle depot start node to its route
constraint forall (k in 1..4*NumCusts) ( routeOf[2*NumCusts + k] = k);

% Assign each vehicle depot end node to its route
constraint forall (k in 1..4*NumCusts) ( routeOf[6*NumCusts + k] = k);

% successor of end is start of next, wraps around to first depot node
constraint
  forall (k in 1..4*NumCusts)
    ( successor[2 * NumCusts + 4 * NumCusts + k] = ( 2*NumCusts + 1 + (k mod NumRoutes) ) );

% Successor of starting survey node can only be a depot node or an ending survey node
constraint forall(k in ArriveSurvey)(successor[k] > NumCusts);
% Sucessor of ending survey node can only be a depot node or a starting survey node
constraint forall(k in LeaveSurvey)(successor[k] <= NumCusts \/ successor[k] >= 2*NumCusts + 1);
    

% Link up the routeOf and successor variables:
% Each visit is on the same route as its successor.
% This is true for all customer and start visits, but not for the end visits.
constraint forall (i in CustsPlusStarts) ( routeOf[i] = routeOf[successor[i]] );

% Objective function:
% Maximum time taken to complete all surveys
var int: objective = max(time);


% =====================================
% Symmetry breaking
% =====================================

% If the successor of the i-th starting taxi node is its ending taxi node, then the successor of 
% the (i+1)-th starting taxi node will also be its corresponding ending taxi node

constraint forall(i in 1..2*NumCusts-1) (successor[2*NumCusts+i] = 6*NumCusts + i -> successor[2*NumCusts+i+1] = 6*NumCusts + i + 1);

% =====================================
% Solve and output
% =====================================

% We want to minimize the time taken to complete all surveys
solve
  :: int_search ( successor, first_fail, indomain_min, complete)
  minimize (objective);


output
[ "name ", show(Name), "\n" ] ++
[ "time ", show(objective), "\n" ] ++
[ "successor = ", show(successor), ";\n" ] ++
[ "routeOf = ", show(routeOf), ";\n"] 
++ [ "time = ", show(time), ";\n"]
++ [ "surveyTime = ", show(surveyStart), ";\n"];