/**
 * GeoLocationResult
 * Tested by: Location_MW_TEST
 *
 *	2016-11-12	B. Leaman	BLL1 - add trustworthy flag - set to false if more than one city, state or country returned in results.
 *	2016-11-14	B. Leaman	BLL2 - add partialmatch flag returned from Google API.
 */
// For returning results from address lookup
public with sharing class GeoLocationResult {
    public Double Latitude {get;set;}
    public Double Longitude {get;set;}
    public String Street {get;set;}
    public String City {get;set;}
    public String State {get;set;}
    public String StateCode {get;set;}
    public String PostalCode {get;set;}
    public String Country {get;set;}
    public String CountryCode {get;set;}
    public String Township {get;set;}
    public String County {get;set;}
    public boolean Trustworthy {get;set;}
    public boolean PartialMatch {get;set;}	// BLL2a
   
    public GeoLocationResult() {
        Latitude = null;
        Longitude = null;
        Street = null;
        City = null;
        State = null;
        StateCode = null;
        PostalCode = null;
        Country = null;
        CountryCode = null;
        Township = null;
        County = null;
        PartialMatch = false;
    }
}