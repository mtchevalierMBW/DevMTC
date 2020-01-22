/**
 * VehicleInventory_Brochure_TC
 * Tests: VehicleInventory_Brochure
 *
 *	2016-06-24	B. Leaman	BLL1	Fix invalid image id during test.
 *	2016-10-05	A. Bangle	ACB1	Added getParameters for new printed variables in class
 */
@isTest
Public Class VehicleInventory_Brochure_TC{

	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        //dealer.TestClassUtil tc = new dealer.TestClassUtil();
        //tc.insertDMSSettings();
	}

    Static testmethod Void Myunittest(){

		FFAdata.refresh(); 
                        
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
    
    	dealer__Vehicle_Inventory__c  dvi = new  dealer__Vehicle_Inventory__c();
        dvi.dealer__VIN__c ='Test';  
        //dvi.dealer__Company_Number__c ='';
        dvi.dealer__Make__c='Test';
        dvi.dealer__Model__c='Test';
        dvi.dealer__Stock_Number__c='123';
        dvi.dealer__Year__c='2013';
        dvi.dealer__Store_Location__c=FFAdata.DealerLocation.Id;	// BLL1a
        insert dvi;
        
        List<dealer__Inventory_Images__c> images = new List<dealer__Inventory_Images__c>();
        images.add(new dealer__Inventory_Images__c(
			dealer__Height__c=240, dealer__Width__c=320, 
			dealer__Image_URL__c='/noimage.jpg', dealer__MIME_Type__c='image/jpeg', dealer__Photographer__c=null,
			dealer__Sequence_Number__c=1, dealer__Thumbnail__c=false, dealer__Thumbnail_URL__c=null, dealer__UUID__c=null, 
			dealer__Vehicle_Inventory__c=dvi.Id,
			dealer__Publish__c=true, dealer__Image_Name__c='Test image'
		));
		insert(images);        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(dvi);
        ApexPages.currentPage().getParameters().put('id', dvi.Id);
        ApexPages.currentPage().getParameters().put('printedprice', '50000');
        //BLL1d ApexPages.currentPage().getParameters().put('imageseq1', '2');
        //BLL1d ApexPages.currentPage().getParameters().put('imageseq2', '2');
        //BLL1d ApexPages.currentPage().getParameters().put('imageseq3', '2');
        // BLL1a
        ApexPages.currentPage().getParameters().put('imageseq1', images[0].Id);
        ApexPages.currentPage().getParameters().put('imageseq2', images[0].Id);
        ApexPages.currentPage().getParameters().put('imageseq3', images[0].Id);
        // BLL1a end
        ApexPages.currentPage().getParameters().put('price', '50000');
        	// ACB1
        	ApexPages.currentPage().getParameters().put('printedname', 'Test');
            ApexPages.currentPage().getParameters().put('printedemail', 'test@mobilityworks.com');
            ApexPages.currentPage().getParameters().put('printedphone', '1234567890');
            ApexPages.currentPage().getParameters().put('printedmobile', '1234567890');
            ApexPages.currentPage().getParameters().put('removeContact', 'false');

        VehicleInventory_Brochure print = new VehicleInventory_Brochure(sc);
        print.returnToRecord();
        
		}
	}
}