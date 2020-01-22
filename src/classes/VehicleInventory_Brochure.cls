/**
 * VehicleInventory_Brochure
 * Tested by: VehicleInventory_Brochure_TC
 *
 *	2015-09-23	B. Leaman	BLL1 - Change field used for suggested retail price
 *	2016-05-12  RedTeal     RT1 - changes to use the Inventory Media object to get the url of images hosted on amazon instead of MBW website
 *	2016-06-24	B. Leaman	BLL2 - Ignore error if printed price is empty and let preview show with no price.
 *							Also handle missing images (null image id).
 *	2016-10-04	A. Bangle	ACB1 - Added in variables for email, phone, mobile and to remove all contact information from brochure printout
 */
public with sharing class VehicleInventory_Brochure {

    public dealer__Vehicle_Inventory__c vehicle {get;set;}
    public dealer__Dealer_Location__c location { get;set; }
    public User user { get;set; }

    public String imageSeq1 { get;set; }
    public String imageSeq2 { get;set; }
    public String imageSeq3 { get;set; }
    public String imageSeq4 { get;set; }

    public Decimal price { get;set; }
    public Decimal printedPrice { get;set; }
    //ACB1
    public String printedName { get;set; }
    public String printedEmail { get;set; }
    public String printedPhone { get;set; }
    public String printedMobile { get;set; }
    public String removeContact { get;set; }
    //ACB1 END

    //RT1
    public Map<Id, dealer__Inventory_Images__c> imageMap {get; set;}
    public List<dealer__Inventory_Images__c> imageList {get; set;}
    
    // ACB1
    // public void donothing() {}

	public VehicleInventory_Brochure(ApexPages.StandardController controller) {

        // Get all the custom field for use in the VF UI
        Map<String, Schema.SObjectField> M = Schema.SObjectType.dealer__Vehicle_Inventory__c.fields.getMap();
        List<String> af = new List<String>();
        Set<String> fieldnames = M.keySet(); 
        af.addAll(fieldnames);
        af.add('Conversion__r.dealer__Description__c');
        fieldnames.remove('dealer__location_region__c');
        if(!Test.isRunningTest()) {             
            controller.addFields(af);
        }
        


        // Get Vehicle Record
        vehicle = (dealer__Vehicle_Inventory__c)controller.getRecord();
        //BLL1d price = vehicle.Suggested_Retail_Price__c;
        price = vehicle.SuggestedRetailPrice__c;  // BLL1a

        // Set Location
        user = [Select Id, Name,Phone,MobilePhone, Email, Division from User where Id=:UserInfo.getUserId() limit 1];
        dealer__Dealer_Location__c[] loc = [SELECT Id, Name, PackLocal__c, dealer__General_Manager__c, Sales_Admin__c, dealer__Service_Director__c, Tax_Equipment__c, dealer__Address__c, dealer__City__c, 
        Customer_Pay_Labor_Rate__c, Internal_Labor_Rate__c, dealer__Main_Phone__c, dealer__State__c, dealer__Postal_Code__c , DealerNumber__c
                FROM dealer__Dealer_Location__c 
                where dealer__Company_Number__c =:user.Division limit 1];
        if(loc.size()!=1) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must be logged into to a Location before working within a vehicle.  Please select a Dealership Location as your Default.'));
        }

        if( loc.size() > 0 ) {
	        location = loc[0];    
        }

        //RT1
        imageMap  = new Map<Id, dealer__Inventory_Images__c>([Select Id, Name, dealer__Height__c, dealer__Width__c, dealer__Image_URL__c, dealer__MIME_Type__c, dealer__Photographer__c,
                dealer__Sequence_Number__c , dealer__Thumbnail__c , dealer__Thumbnail_URL__c ,dealer__UUID__c ,dealer__Vehicle_Inventory__c,
                dealer__Publish__c, dealer__Image_Name__c
                from dealer__Inventory_Images__c 
                where dealer__Vehicle_Inventory__c =:controller.getId() 
                order by dealer__Sequence_Number__c asc
                limit 1000]);
        //RT1
        imageList = imageMap.values();

        if(ApexPages.currentPage().getParameters().get('price')!=null) {
            price = Decimal.valueOf( ApexPages.currentPage().getParameters().get('price') );
        }     
        if(ApexPages.currentPage().getParameters().get('imageseq1')!=null && ApexPages.currentPage().getParameters().get('imageseq1')!=''&& ApexPages.currentPage().getParameters().get('imageseq1')!='null') {	// BLL2c
            imageSeq1 = imageMap.get(ApexPages.currentPage().getParameters().get('imageseq1')).dealer__Image_URL__c; //RT1
        }
        if(ApexPages.currentPage().getParameters().get('imageseq2')!=null && ApexPages.currentPage().getParameters().get('imageseq2')!=''&& ApexPages.currentPage().getParameters().get('imageseq2')!='null') {	// BLL2c
            imageSeq2 = imageMap.get(ApexPages.currentPage().getParameters().get('imageseq2')).dealer__Image_URL__c; //RT1
        }
        if(ApexPages.currentPage().getParameters().get('imageseq3')!=null && ApexPages.currentPage().getParameters().get('imageseq3')!=''&& ApexPages.currentPage().getParameters().get('imageseq3')!='null') {	// BLL2c
            imageSeq3 = imageMap.get(ApexPages.currentPage().getParameters().get('imageseq3')).dealer__Image_URL__c; //RT1
        }
        if(ApexPages.currentPage().getParameters().get('imageseq4')!=null && ApexPages.currentPage().getParameters().get('imageseq4')!=''&& ApexPages.currentPage().getParameters().get('imageseq4')!='null') {	// ACB1
            imageSeq4 = imageMap.get(ApexPages.currentPage().getParameters().get('imageseq4')).dealer__Image_URL__c; //ACB1
        }
        if(ApexPages.currentPage().getParameters().get('printedprice')!=null) {
        	try {	// BLL2a 
        		printedPrice = Decimal.valueOf( ApexPages.currentPage().getParameters().get('printedprice') );
        	} catch(Exception e) { }	// BLL2a
        }
        // ACB1
        if(ApexPages.currentPage().getParameters().get('printedname')!=null) {
        	try {
        		printedName = String.valueOf( ApexPages.currentPage().getParameters().get('printedname') );
        	} catch(Exception e) { }
        }
        if(ApexPages.currentPage().getParameters().get('printedemail')!=null) {
        	try {
        		printedEmail = String.valueOf( ApexPages.currentPage().getParameters().get('printedemail') );
        	} catch(Exception e) { }
        }
        if(ApexPages.currentPage().getParameters().get('printedphone')!=null) {
        	try {
        		printedPhone = String.valueOf( ApexPages.currentPage().getParameters().get('printedphone') );
        	} catch(Exception e) { }
        }
        if(ApexPages.currentPage().getParameters().get('printedmobile')!=null) {
        	try {
        		printedMobile = String.valueOf( ApexPages.currentPage().getParameters().get('printedmobile') );
        	} catch(Exception e) { }
        }
        if(ApexPages.currentPage().getParameters().get('removecontact')!=null) {
        	try {
        		removeContact = String.valueOf( ApexPages.currentPage().getParameters().get('removecontact') );
        	} catch(Exception e) { }
        }
        // ACB1 END
        
        System.debug(imageSeq1);
        System.debug(imageSeq2);
        System.debug(imageSeq3);
        System.debug(imageSeq4);
        
	}

	/*public String getHTMLContent() {
		String url = 'http://www.mobilityworks.com/wheelchair-vans-for-sale/inventory_detail.php?stock='+vehicle.dealer__Stock_Number__c;

		// Instantiate a new http object
		Http h = new Http();

		// Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
		HttpRequest req = new HttpRequest();
		req.setEndpoint(url);
		req.setMethod('GET');

		// Send the request, and return a response
		HttpResponse res = h.send(req);
		return res.getBody();
	}*/

    public PageReference returnToRecord() {
        PageReference p = new PageReference('/'+vehicle.Id);
        p.setRedirect(false); // false retains view state
        return p;
    }

}