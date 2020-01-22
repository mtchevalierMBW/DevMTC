/**
 * GeoLocationHelper
 * Tested by: Location_MW_TEST
 * Coverage:
 *	2017-10-30	85% (63/74)
 *	2018-05-23	86%	(67/78)
 * 
 * Sample request: 
 * https://maps.googleapis.com/maps/api/geocode/json?key=AIzaSyDataRYAliVszM2AxLg823fz5tiRaodHyk&address=44641
 * 
 *	2016-07-29	B. Leaman	BLL1 Add support for county & township.
 *							Usage note: Last 30 days 4125 requests, max 324 in one day; Limit is 2500/day  
 *	2016-10-12	B. Leaman	BLL2 - add trustworthy indicator - we can trust the result if we only found 1 city/locality in the results.
 *	2016-11-15	B. Leaman	BLL3 - enhance trustworthy indicator -- if partial match, resulting city & state -or- zip must match inputs.
 *	2017-10-30	B. Leaman	BLL4 - handle ZIP+4 better.
 *	2018-05-23	B. Leaman	BLL5 - soft-code Google API geocode API key.
 */
 
// Helper methods for Geolocation functions
public with sharing class GeoLocationHelper {

   // Find the latitude/longitude for a given address (using Google API)
   // Uses free API: Limitations 2500/day and 5/sec
   // Key obtained under bryan.leaman@mobilityworks.com login to Google
   public static GeoLocationResult getAddressLocation(String address) {
       GeoLocationResult returnLoc=new GeoLocationResult();
       MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();	// BLL5a
       String apiKey = mfs.GoogleGeocodeAPIkey__c;	// BLL5a
       if (String.isBlank(apiKey)) apiKey = 'AIzaSyDataRYAliVszM2AxLg823fz5tiRaodHyk';	// BLL5a
       try {
           HttpRequest req = new HttpRequest();
           req.setEndpoint('https://maps.googleapis.com/maps/api/geocode/json'
                  //BLL5d + '?key=AIzaSyCZegYd-aBP3CvUnEJpsDkEQfdWgMBiwY4'
                  + '?key=' + apiKey	// BLL5a
                  + '&address=' + EncodingUtil.urlEncode(address, 'UTF-8'));
           req.setMethod('GET');
           HttpResponse res = null;
           if (Test.isRunningTest()) {
           	   res = testResponse(req);
           } else {
               res = new Http().send(req);
           } 
           
           // Shortcut if service is down
           Integer statuscode = res.getStatusCode();
           if (statuscode < 200 || statuscode == 300 || statuscode > 304) {
           	  return returnLoc;
           }
           
           // Handle result
           System.debug(res.getBody());
           Map<String, Object> jsonmap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
           List<Object> results = (List<Object>) jsonmap.get('results');
           
           // BLL2a Count different localities
           Set<String> locality = new Set<String>();
           for(Object r : results) {
              Map<String,Object> resultmap = (Map<String,Object>) r;
              List<Object> addrcomponents = (List<Object>) resultmap.get('address_components');
              for(Integer i=0; i<addrcomponents.size(); i++) {
              	 Map<String,Object> componentmap = (Map<String,Object>) addrcomponents[i];
           	     String sname = (String) componentmap.get('short_name');
           	     List<Object> types = (List<Object>) componentmap.get('types');
           	     String firsttype = (String) types[0];
           	     System.debug('Location component type '+((String) types[0])+'='+sname);
          	     if (firsttype.equalsIgnoreCase('locality')) locality.add(sname);
              }
           }
           System.debug(locality);
           returnloc.Trustworthy = locality.size()<2;
           // BLL2a end
           
           Map<String, Object> firstresultmap = (Map<String, Object>) results[0];
           Map<String, Object> geometry = (Map<String, Object>) firstresultmap.get('geometry');
           Map<String, Object> locationmap = (Map<String, Object>) geometry.get('location');
           Double lat = (Double) locationmap.get('lat');
           Double lng = (Double) locationmap.get('lng');
           returnLoc.Latitude = lat;
           returnLoc.Longitude = lng;
           String streetSeparator = '';
           returnLoc.Street = '';
           
           returnloc.PartialMatch = firstresultmap.containsKey('partial_match');	// BLL3a

           // Break out City, State, Country
           List<Object> address_components = (List<Object>) firstresultmap.get('address_components');
           for(Integer i=0; i<address_components.size(); i++) {
           	   Map<String, Object> component = (Map<String, Object>) address_components[i];
           	   String lname = (String) component.get('long_name');
           	   String sname = (String) component.get('short_name');
           	   List<Object> types = (List<Object>) component.get('types');
           	   String firsttype = (String) types[0];
           	   System.debug('Location component type '+((String) types[0])+'='+lname);
           	   if (firsttype.equalsIgnoreCase('locality')) {
           	   	   returnLoc.City = lname;
           	   	   System.debug('City='+lname);
           	   } else if (firsttype.equalsIgnoreCase('administrative_area_level_1')) {
           	   	   returnLoc.State = lname;
           	   	   returnLoc.StateCode = sname;
           	   	   System.debug('State='+sname);
           	   } else if (firsttype.equalsIgnoreCase('administrative_area_level_2')) {
           	   	   returnLoc.County = lname.removeEndIgnoreCase('County');
           	   	   System.debug('County='+lname);
           	   } else if (firsttype.equalsIgnoreCase('administrative_area_level_3')) {
           	   	   returnLoc.Township = lname.removeEndIgnoreCase('Township');
           	   	   System.debug('Township='+lname);
           	   } else if (firsttype.equalsIgnoreCase('country')) {
           	   	   returnLoc.Country = lname;
           	   	   returnLoc.CountryCode = sname;
           	   	   System.debug('Country='+sname);
           	   } else if (firsttype.equalsIgnoreCase('postal_code')) {
           	   	   returnLoc.PostalCode = sname;
           	   	   System.debug('PostalCode='+sname);
           	   // BLL4a
           	   } else if (firsttype.equalsIgnoreCase('postal_code_suffix')) {
           	   	   if (!String.isBlank(returnLoc.PostalCode)) returnLoc.PostalCode += '-' + sname;
           	   	   System.debug('PostalCode='+returnLoc.PostalCode);
           	   // BLL4a end
           	   } else if (firsttype.equalsIgnoreCase('street_number')) {
           	   	   returnLoc.Street += streetSeparator + sname;
           	   	   streetSeparator = ' ';
           	   } else if (firsttype.equalsIgnoreCase('route')) {
           	   	   returnLoc.Street += streetSeparator + sname;
           	   	   streetSeparator = ' ';
           	   }
           }
           
       } catch(Exception e) {
       	   System.debug('Error in GeoLocation_GoogleAPI.getAddressLocation: ' + e);
       }
   	   return returnLoc;
   }

   // Mock response for testing
   public static HTTPResponse testResponse(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"results" : ['
                    + '{ "address_components" : [ {"long_name":"Test One", "short_name":"Test1", "types":["locality"]}, '
                    + '{"long_name":"Test One", "short_name":"Test1", "types":["administrative_area_level_1"]}, '
                    + '{"long_name":"Test One", "short_name":"Test1", "types":["administrative_area_level_2"]}, '
                    + '{"long_name":"Test One", "short_name":"Test1", "types":["administrative_area_level_3"]}, '
                    + '{"long_name":"Test One", "short_name":"Test1", "types":["country"]}, '
                    + '{"long_name":"Test One", "short_name":"Test1", "types":["postal_code"]} '
                  + '], '
                  + ' "geometry" : { "location" : { "lat" : 41.107065, "lng" : -81.485952 } } } ], "status" : "OK" }');
        res.setStatusCode(200);
        return res;
   }

}