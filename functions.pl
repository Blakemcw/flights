/*
 * Name:   Blake McWilliam
 * SiD:    1594150
 * CruzId: bcmcwill@ucsc.edu
 */

/*
 *  PROLOG VERSION OF NOT
 */

not( X ) :- X, !, fail.
not( _ ).

/*
 *  TIME:
 */

hours_to_time(HoursAsDecimal, time(Hours, Minutes)) :-
    % Converts Hours in decimal form to time in Hours and Minutes.
    Hours   is floor(   HoursAsDecimal ),
    Minutes is floor( ( HoursAsDecimal - Hours ) * 60 ).

compare_times(time(Hours1, Minutes1), time(Hours2, Minutes2)) :-
    % Returns true if the first time is greater than the second time.
    (Hours1 * 60) + Minutes1 > (Hours2 * 60) + Minutes2.

add_times(time(Hours1, Minutes1), time(Hours2, Minutes2), time(HoursR, MinutesR)) :-
    % Adds two times together and checks if the minutes are valid.
    HoursA   is Hours1   + Hours2,
    MinutesA is Minutes1 + Minutes2,
    minutes_overflow(time(HoursA, MinutesA), time(HoursR, MinutesR)).

minutes_overflow(time(Hours, Mins), time(HoursR, MinsR)) :-
    % Fixes minutes overflow if it occurs.
    Mins > 59,
    MinutesOverflow is floor(Mins / 60),
    HoursR is Hours + MinutesOverflow,
    MinsR  is Mins  - MinutesOverflow * 60.
minutes_overflow(time(Hours, Mins), time(HoursR, MinsR)) :-
    % Returns the itself if there is no minute overflow.
    Mins < 60,
    HoursR is Hours,
    MinsR  is Mins.

/*
 *  GENERAL MATH:
 */

degmin_to_radians(degmin(Degrees, Minutes), Radians) :-
    % Function for converting from (degrees, minutes) to radians.
    Radians is ( Degrees + ( Minutes / 60 ) ) * pi / 180.

haversine( Lat1, Lon1, Lat2, Lon2, Distance ) :-
    % Find the distance between any 2 ariports given their respective
    % latitudes and longitudes that are given in 
    % degmin(degrees, minutes).
    degmin_to_radians( Lat1, Lat1Radians ),
    degmin_to_radians( Lon1, Lon1Radians ),
    degmin_to_radians( Lat2, Lat2Radians ),
    degmin_to_radians( Lon2, Lon2Radians ),
    Dlon is Lon2Radians - Lon1Radians,
    Dlat is Lat2Radians - Lat1Radians,
    A is sin( Dlat / 2 ) ** 2
        + cos( Lat1Radians ) 
        * cos( Lat2Radians ) 
        * sin( Dlon / 2 ) ** 2,
    Dist is 2 * atan2( sqrt( A ), sqrt( 1 - A )),
    Distance is Dist * 3959.

/*
 *  FLIGHT CALCULATIONS:
 */

flight_distance(AirportA, AirportB, Result) :-
    % Finds the great circle distance between two airports.
    airport(  AirportA, _, Lat1, Lon1 ),
    airport(  AirportB, _, Lat2, Lon2 ),
    haversine( Lat1, Lon1, Lat2, Lon2, Distance ),
    Result is Distance.

flight_arrival(AirportA, AirportB, time(HourA, MinA), ArrivalTime) :-
    % Finds the arrival time of a flight.
    flight_distance(AirportA, AirportB, Distance),
    FlightDuration is Distance / 500,
    hours_to_time(FlightDuration, time(Dhours, Dmin)),
    add_times(time(Dhours, Dmin), time(HourA, MinA), ArrivalTime).

/*
 *  GRAPH SEARCHING:
 */

checkpath( FlightList ) :-
    checkpath( FlightList, time(0, 0) ).
checkpath( [], _ ).
checkpath( [flight(Departure, Arrival, Time)|Tail], PrevArrivalTime) :-
    % Checks if a path to any airport is valid.

    % (1) Check that the next flight is at least 30 minutes after our
    %     previous flight lands
    compare_times( Time, PrevArrivalTime ),

    % (2) Get arrival time of current flight.
    flight_arrival( Departure, Arrival, Time, ArrivalTime ),

    % (3) Add 29 minutes to Arrival time and make sure that it doesn't
    %     land after midnight.
    add_times(ArrivalTime, time(0, 29), Result),
    compare_times( time(24,0), ArrivalTime ),
    
    % (4) Call recursively with the tail of the list and pass the
    %     current arrival time to
    checkpath( Tail, Result).
 
writeflight(flight(Depart, Arrive, time(DepHour, DepMin))) :-
    % Prints out flight in the format of,
    %   (depart) (3 letter tag) (Aiport Name) (Departure Time)
    %   (arrive) (3 letter tag) (Aiport Name) (Arrival Time)
    airport(Depart, DepartName, _, _),
    airport(Arrive, ArriveName, _, _),
    flight_arrival(Depart, 
                   Arrive, 
                   time(DepHour, DepMin), 
                   time(ArrHour, ArrMin)),
    to_upper(Depart, DepartUpper),
    to_upper(Arrive, ArriveUpper),
    write( 'depart ' ), 
    write(DepartUpper), 
    write(' '), 
    write(DepartName),
    write(DepHour), 
    write(':'), 
    write(DepMin), nl,
    write( 'arrive ' ), 
    write(ArriveUpper), 
    write(' '), 
    write(ArriveName),
    write(ArrHour), 
    write(':'), 
    write(ArrMin), nl.

writepath( [] ) :-
    nl.
writepath( [Head|Tail] ) :-
    writeflight( Head ), writepath( Tail ).
 
listpath( Node, End, Outlist) :-
    listpath( Node, End, [Node], Outlist).
listpath( Node, Node, _, [] ).
listpath( Node, End, Tried, [flight(Node, Next, Time)|List]) :-
    % Finds a path from one airport to another.
    flight( Node, Next, Time ),
    not( member( Next, Tried )),
    listpath( Next, End, [Node|Tried], List).

/*
 *  MISC:
 */

to_upper( Lower, Upper) :-
    % Converts an atom to uppercase.
    atom_chars( Lower, Lowerlist),
    maplist( lower_upper, Lowerlist, Upperlist),
    atom_chars( Upper, Upperlist).

/*
 *  MAIN:
 */

fly( Node, Node ) :-
    % Handles case of trying to fly to itself.
    to_upper(Node, AirportCode),
    format("Can't fly from ~w to ~w.", 
        [AirportCode, AirportCode]), nl.
fly( Node, Next ) :-
    % Main function. Finds an itenerary for a given travel request.
    % -? fly(AirportA, AirportZ) finds:
    %        AirportA -> [AirportB...AirportY] -> AirportZ
    %        where everyting in brackets occurs 0 or more times.

    listpath( Node, Next, [Node], List),
    checkpath( List ),
    writepath( List ),
    fail.
