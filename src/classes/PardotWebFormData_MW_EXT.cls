/**
 * PardotWebFormData_EXT
 * for Pardot_Web_From_Data page (to be placed into standard Lead view)
 * Tested by: PardotWebFormData_EXT_TEST
 *
 * 2015-09-23	B. Leaman	BLL1 - Change field used for suggested retail price
 * 2018-08-10	B. Leaman	BLL2 - Fix web link to vehicle inventory 
 */

public with sharing class PardotWebFormData_MW_EXT {
    public Lead theLead {get; set;} 
    private ApexPages.StandardController stdController;
    public List<VehicleInformation> Vehicles {get;private set;}
    public List<String> VehicleInfo; 
    
    public PardotWebFormData_MW_EXT(ApexPages.StandardController ctlr) {
       Vehicles = new List<VehicleInformation>();
       List<String> fields = new List<String>();
       fields.add('Desired_Vehicles__c');
       if(!Test.isRunningTest()) {             
           ctlr.addFields(fields);
       }   
       theLead = (Lead) ctlr.getRecord();
       stdController = ctlr;
       
       // Get list of stock numbers (separated by semi-colons & trimmed)
       List<String> stock = new List<String>();
       List<String> tmp = new List<String>();
	   String onlystock = '';
	   List<String> stocksplit = new List<String>(); 
       if (!String.isBlank(theLead.Desired_Vehicles__c)) {
           tmp = theLead.Desired_Vehicles__c.split(';');
           for(String s : tmp) {
           	   stocksplit = s.split('\\(');
               stock.add(stocksplit[0].trim());
               System.debug('Stock#: ' + stocksplit[0].trim());
           }
       } 
       
       //System.debug(stock);
       //stock.add(theLead.Desired_Vehicles__c);
       for(dealer__Vehicle_Inventory__c vi: [
           select Id, Name, dealer__Stock_Number__c, dealer__Year__c, dealer__Make__c, dealer__Model__c,
                  Suggested_Retail_Price__c, dealer__Retail_Price__c, SuggestedRetailPrice__c  // BLL1c
           from   dealer__Vehicle_Inventory__c
           where  dealer__Stock_Number__c in :stock]) {
           System.debug(vi.dealer__Stock_Number__c);
           String description = vi.Name;
           // Show price (or should it be dealer__Retail_Price__c) - BLL1c: should be SuggestedRetailPrice__c
           //if (vi.dealer__Retail_Price__c!=null) {
           ////	   description += ' ($' + vi.dealer__Retail_Price__c.setScale(0).format() + ') ';
           //	   description += ' ($' + vi.SuggestedRetailPrice__c.setScale(0).format() + ') ';
           //}
           //if (!String.isBlank(vi.Conv_MFG__c)) {
           //	  description = description + '; ' + vi.Conv_MFG__c;
           //} 
           //if (!String.isBlank(vi.Conversion_Model__c)) {
           //	  description = description + '; ' + vi.Conversion_Model__c;
           //} 
           //BLL2d String weblink = 'http://www.mobilityworks.com/inventory/inventory_detail.php?stock=' + vi.dealer__Stock_Number__c;
           String weblink = 'https://www.mobilityworks.com/wheelchair-vans-for-sale/?vin=' + vi.dealer__Stock_Number__c;	// BLL2a
           Vehicles.add(new VehicleInformation(vi.dealer__Stock_Number__c, description, '//'+vi.Id, weblink));
       }  	  
    }
    
    public class VehicleInformation {
    	public String stocknbr {get;set;}
    	public String name {get;set;}
    	public String inventorylink {get;set;}
    	public String websitelink {get;set;}
    	public VehicleInformation(String stock, String n, String link, String website) {
    		stocknbr = stock;
    		name = n;
    		inventorylink = link;
    		websitelink = website;
    	}
    }
}