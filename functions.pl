/*
 * Name:   Blake McWilliam
 * SiD:    1594150
 * CruzId: bcmcwill@ucsc.edu
 * /

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
    Distance is Dist * 3961.

/*
 *  FLIGHT CALCULATIONS:
 */

flight_distance(AirportOfDeparture, AirportOfArrival, Result) :-
    % Finds the great circle distance between two airports.
    airport( AirportOfDeparture, _, Lat1, Lon1 ),
    airport( AirportOfArrival,   _, Lat2, Lon2 ),
    haversine( Lat1, Lon1, Lat2, Lon2, Distance ),
    Result is Distance.
