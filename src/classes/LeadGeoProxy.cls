/**
 * LeadGeoProxy
 * Tested by: Test_LeadClasses
 *
 *	2016-09-26	B. Leaman	BLL1 - do not include locations that shouldn't be assigned to leads.
 *
 **/
public with sharing class LeadGeoProxy {
    public Lead lead {get;set;}
    public Double latitude {get;set;}
    public Double longitude {get;set;}
    public Double distance = 1000;
    public Boolean lookupSuccess {get;set;}
    public LeadGeoProxy(ApexPages.StandardController controller) {
        String[] af = new String[]{'PostalCode'};
        if(!Test.isRunningTest()) {             
            controller.addFields(af);
        }       
        lead = (Lead)controller.getRecord();
        latitude = lead.Latitude;
        longitude = lead.Longitude;
    }

    public Boolean latlon() {
        if(lead.PostalCode==null) { return false; }
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');
            req.setEndpoint('https://apsv1.dealerteam.com/api/geo/LatLon?ZIP='+lead.PostalCode);
            Map<String,String> responseMap = null;
            if (Test.isRunningTest()) {
            	responseMap = (Map<String,String>)JSON.deSerialize(getSampleResult() ,Map<String,String>.class);
            } else {
            	HTTPResponse res = http.send(req);
            	responseMap = (Map<String,String>)JSON.deSerialize(res.getBody(),Map<String,String>.class);
            }

            if(responseMap.get('Latitude')!=null) {
                latitude = Double.valueOf(responseMap.get('Latitude'));
                longitude= Double.valueOf(responseMap.get('Longitude'));
                System.debug('Retrieved lat/lng from webservice');
                return true;
            }
        return false;
    } 
    
    //public Double deg2rad(Double deg) {
    //  return (deg/180) * Math.pi;
    //}
    
    //public Double calcMilesDistance(Double lat1, Double lng1, Double lat2, Double lng2) {
    //   Double dlat; Double dlng;
    //   Double ps_dlat;
    //   Double ps_dlng;
    //   Double c_lat1;
    //   Double c_lat2;
    //   Double a;
    //   Double c;

    //   dlat = lat1-lat2;
    //   dlng = lng1-lng2;
    //   ps_dlat = Math.pow(Math.sin(deg2rad(dlat/2)),2);
    //   ps_dlng = Math.pow(Math.sin(deg2rad(dlng/2)),2);
    //   c_lat1 = Math.cos(deg2rad(lat1));
    //   c_lat2 = Math.cos(deg2rad(lat2));
    //   a = ps_dlat + (c_lat1 * c_lat2 * ps_dlng);
    //   c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
       
    //   return 3961.0 * c;
    //}

    public List<LocationWrapperObj> getLocationsByDistance() {  // was dealer__Dealer_Location__c
        List<LocationWrapperObj> dealer_locs = new List<LocationWrapperObj>();
        Double miles;
        //if(lead.PostalCode!=null) {
            //if(!latlon()) {
            // Only retrieve lat/lon if not already there!
            if ((latitude==null || longitude==null)) {
               if (lead.PostalCode==null || !latlon()) { 
                   return dealer_locs;
               }
            }
            Location loc = Location.newInstance(latitude, longitude);
            List<dealer__Dealer_Location__c> dl = Database.query(
                     'SELECT Id, Name, dealer__Street__c, dealer__City__c, dealer__Company_Number__c, ' 
                   + 'dealer__Email__c, dealer__Main_Phone__c,dealer__State__c, dealer__Postal_Code__c, '
                   + 'dealer__Physical_Location__c '
                   + 'FROM dealer__Dealer_Location__c '
                   + 'where DISTANCE(dealer__Physical_Location__c,GEOLOCATION(' + latitude + ',' + longitude + '),\'mi\') < ' + distance + ' '
                   + ' and AutoAssignRetail__c=true '	// BLL1a
                   + 'ORDER BY DISTANCE(dealer__Physical_Location__c,GEOLOCATION(' + latitude + ',' + longitude + '),\'mi\') '
                   + 'LIMIT 3');
            for(dealer__Dealer_Location__c d : dl) {
                //miles = calcMilesDistance((Double) d.dealer__Physical_Location__Latitude__s, (Double) d.dealer__Physical_Location__Longitude__s,
                //       latitude, longitude);
                miles = d.dealer__Physical_Location__c.getDistance(loc, 'mi');
                dealer_locs.add(new LocationWrapperObj( d, (Integer) miles ));
            }
            //return dealer_locs;
        //} else {
        //  return new List<LocationWrapperObj>();
        //}
        return dealer_locs;
    }


   public String getSampleResult() {
   	   return '{'
   	    	+ '"Latitude" : 40.851368,' 
			+ '"Longitude" : -81.290533' 
			+ '}';
   }



   public class LocationWrapperObj {
      public Integer distance {get;set;}
      public dealer__Dealer_Location__c location {get;set;}
      public LocationWrapperObj(dealer__Dealer_Location__c loc, Integer m) {
          location = loc;
          distance = m;
      }
   }

}