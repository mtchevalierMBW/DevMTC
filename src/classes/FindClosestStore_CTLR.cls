/**
 * FindClosestStore_CTLR
 * Tested by: FindClosestStore_TEST
 *
 *	2015-10-15	B. Leaman	IT# 13679 Written
 *	2016-08-26	B. Leaman	Only show locations we're auto-assigning to leads.
 *	2017-02-13	B. Leaman	Replace dealer__Address__c with dealer__Street__c on location object.
 */
public with sharing class FindClosestStore_CTLR {

	public GeoLocationResult loc {get; private set;}
	public String address {get; set;}
    public Double latitude {get;set;}
    public Double longitude {get;set;}
    public Double maxdistance {get;set;}
    public Integer maxresults {get;set;}

	public FindClosestStore_CTLR() {
		loc = null;
		maxdistance = 500;
		maxresults = 5;
	}

    public void GeoLookup() {
    	loc = GeoLocationHelper.getAddressLocation(address);
    	latitude = loc.latitude;
    	longitude = loc.longitude;
    }

    // Copied & adjusted from LeadGeoProxy
    public List<LocationWrapperObj> getLocationsByDistance() {  // was dealer__Dealer_Location__c
        List<LocationWrapperObj> dealer_locs = new List<LocationWrapperObj>();
        Double miles;
	
		if (latitude!=null && longitude!=null) {

        try {
            Location loc = Location.newInstance(latitude, longitude);
            if (loc!=null) {
	            List<dealer__Dealer_Location__c> dl = Database.query(
	                     'SELECT Id, Name, dealer__Street__c, dealer__City__c, dealer__Company_Number__c, ' 	// BLL3c
	                   + 'dealer__Email__c, dealer__Main_Phone__c,dealer__State__c, dealer__Postal_Code__c, '
	                   + 'dealer__Physical_Location__c '
	                   + 'FROM dealer__Dealer_Location__c '
	                   + 'where DISTANCE(dealer__Physical_Location__c,GEOLOCATION(' + latitude + ',' + longitude + '),\'mi\') < ' + maxdistance + ' '
	                   + ' and AutoAssignRetail__c=true '	// BLL1a
	                   + 'ORDER BY DISTANCE(dealer__Physical_Location__c,GEOLOCATION(' + latitude + ',' + longitude + '),\'mi\') '
	                   + 'LIMIT ' + maxresults);
	            for(dealer__Dealer_Location__c d : dl) {
	                //miles = calcMilesDistance((Double) d.dealer__Physical_Location__Latitude__s, (Double) d.dealer__Physical_Location__Longitude__s,
	                //       latitude, longitude);
	                miles = d.dealer__Physical_Location__c.getDistance(loc, 'mi');
	                dealer_locs.add(new LocationWrapperObj( d, (Integer) miles ));
	            }
            }
        } catch(Exception e) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        
		}
        
        return dealer_locs;
    }


   public class LocationWrapperObj {
      public Integer distance {get;set;}
      public dealer__Dealer_Location__c location {get;set;}
      public Account locationReference {get;set;}
      public LocationWrapperObj(dealer__Dealer_Location__c loc, Integer m) {
          location = loc;
          distance = m;
          locationReference = new Account(Store_Location__c=loc.Id);
      }
   }


}