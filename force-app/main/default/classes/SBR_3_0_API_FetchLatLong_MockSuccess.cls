public with sharing class SBR_3_0_API_FetchLatLong_MockSuccess implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        if(request.getEndpoint().endsWithIgnoreCase('token')){
            response.setBody('{"access_token":"test"}');
        } else if(request.getEndpoint().contains('geotime')){
            response.setBody('{"data": {"geoInfo": {"streetAddress": "Arizona Biltmore Estates","city": "Phoenix","province": "Arizona","country": "United States","latitude": 33.5160515,"longitude": -112.0222999},"timezone": {"id": "America/Phoenix","name": "Mountain Standard Time","dstOffset": 0,"rawOffset": -25200,"rmOffsetForStandardTime": -20,"rmOffsetForDaylightSavingTime": -30}}}');
        } else{
            response.setBody('{ "data": { "results": [ { "addressComponents": [ { "longName": "6365", "shortName": "6365", "types": [ "street_number" ] }, { "longName": "Multiplex Drive", "shortName": "Multiplex Dr", "types": [ "route" ] }, { "longName": "Centreville", "shortName": "Centreville", "types": [ "locality", "political" ] }, { "longName": "Fairfax County", "shortName": "Fairfax County", "types": [ "administrative_area_level_2", "political" ] }, { "longName": "Virginia", "shortName": "VA", "types": [ "administrative_area_level_1", "political" ] }, { "longName": "United States", "shortName": "US", "types": [ "country", "political" ] }, { "longName": "20121", "shortName": "20121", "types": [ "postal_code" ] } ], "formattedAddress": "6365 Multiplex Dr, Centreville, VA 20121, USA", "geometry": { "location": { "latitude": 38.82717, "longitude": -77.439927 }, "locationType": "ROOFTOP", "viewport": { "northeast": { "latitude": 38.8286634802915, "longitude": -77.43860981970849 }, "southwest": { "latitude": 38.8259655197085, "longitude": -77.44130778029151 } } }, "placeId": "ChIJC0C2DMJEtokR4Kx6xT21ctk", "types": [ "street_address" ] } ] } }');
        }
        response.setStatusCode(200);
        return response; 
    }
}