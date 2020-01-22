/**
 * Test class for Geolocation tools and related triggers on Lead and dealer__Dealer_Location__c
 * Triggers tested: LeadClosestStore, DealerLocation_PhsyicalLoc
 * Classes tested: GeoLocationResult, GeoLocationHelper, ClosestStoreFuture
 * 04/28/2015  B. Leaman   Written
 *
 * 	2016-01-29	B. Leaman	BLL1 - Set flags to use lat/lng trigger code.
 *	2016-07-29	B. Leaman	BLL2 - Test account location routine.
 *	2018-09-07	B. Leaman	BLL3 - increase code coverage
 */ 
@isTest
private class Location_MW_TEST {

    @isTest
    private static void AssignDealerLatLng() {
    	insert(new MW_TriggerControls__c(Name=' DealerLocationLatLng',Enabled__c=true));
    	Test.startTest();

        dealer__Dealer_Location__c dlr = new dealer__Dealer_Location__c(
           Name='Test Dealer',
           dealer__Address__c = '810 Moe Dr.', dealer__City__c = 'Akron', dealer__State__c = 'OH',	
           dealer__Postal_Code__c = '44310', dealer__Company_Number__c='__T'
        );
        insert(dlr);
        dealer__Dealer_Location__c dlr2 = [select Id, Name, 
              dealer__Physical_Location__Latitude__s, dealer__Physical_Location__Longitude__s
              from dealer__Dealer_Location__c 
              where Id=:dlr.Id limit 1];
        dlr2.dealer__City__c = 'Akron'; // correct city name
        update(dlr2);
        Test.stopTest();  // cause future methods from trigger to run

        dealer__Dealer_Location__c newdlr = [select Id, Name, 
              dealer__Physical_Location__Latitude__s, dealer__Physical_Location__Longitude__s
              from dealer__Dealer_Location__c 
              where Id=:dlr.Id limit 1];
        System.assert(newdlr.Id<>null, 'Not able to read the dealer location again');
    }

    @isTest
    private static void AssignLeadLatLngStore() {
    	insert(new MW_TriggerControls__c(Name=' DealerLocationLatLng',Enabled__c=true));
    	insert(new MW_TriggerControls__c(Name=' LeadClearLatLng',Enabled__c=true));
    	insert(new MW_TriggerControls__c(Name=' LeadClosestStore ',Enabled__c=true));
        RecordType rt = [select Id, Name 
                         from RecordType 
                         where SObjectType='Lead' and Name like 'Retail%'
                         limit 1];
    	Test.startTest();
    	// BLL3c dont assign city/state so routine will do that from the postal code
        Lead l = new Lead( RecordTypeId=rt.Id, 
                     FirstName='LatLng', LastName='TestLead', Phone='(555) 555-1213',
                     eMail='testlatlng@example.com',
                     City=null, State=null, PostalCode='44306'
                 );
        insert(l);
        List<Id> updids = new List<Id>();
        updids.add(l.Id);
        ClosestStoreFuture.Lead_LocateAddress(updids);

        Lead newlead = [select Id, Name, Desired_Vehicles__c 
                        from Lead
                        where Id=:l.Id 
                        limit 1];
        newlead.City='Akron'; newlead.State='OH'; newlead.PostalCode='44307';
        upsert(newlead);
        
        Test.stopTest();  // cause future methods from trigger to run

        Lead finallead = [select Id, Name, Desired_Vehicles__c 
                        from Lead
                        where Id=:l.Id 
                        limit 1];
        System.assert(finallead.Id<>null, 'Not able to read the lead again');
    }  

    @isTest
    private static void ReAssignLeadStore() {
    	insert(new MW_TriggerControls__c(Name=' DealerLocationLatLng',Enabled__c=true));
    	insert(new MW_TriggerControls__c(Name=' LeadClearLatLng',Enabled__c=true));
    	insert(new MW_TriggerControls__c(Name=' LeadClosestStore ',Enabled__c=true));
        RecordType rt = [select Id, Name 
                         from RecordType 
                         where SObjectType='Lead' and Name like 'Retail%'
                         limit 1];
    	// BLL3c dont assign city/state so routine will do that from the postal code
        Lead l = new Lead( RecordTypeId=rt.Id, 
                     FirstName='LatLng', LastName='TestLead', Phone='(555) 555-1213',
                     eMail='testlatlng@example.com',
                     City='Akron', State='OH', PostalCode='44306'
                 );
        insert(l);

        dealer__Dealer_Location__c dlr = new dealer__Dealer_Location__c(
           Name='Test Dealer', AutoAssignRetail__c = true, 
           dealer__Address__c = '810 Moe Dr.', dealer__City__c = 'Akron', dealer__State__c = 'OH',	
           dealer__Postal_Code__c = '44310', dealer__Company_Number__c='__T'
        );
        insert(dlr);

    	Test.startTest();

		l.Latitude=41.1070027;
		l.Longitude=-81.48628979999999;
		l.Store_Location__c=null;
		update(l);

        Test.stopTest();  // cause future methods from trigger to run

        Lead finallead = [select Id, Name, Store_Location__c
                        from Lead
                        where Id=:l.Id 
                        limit 1];
        System.assert(finallead.Store_Location__c<>null, 'Did not re-assign store to lead');
    }  


    @isTest
    private static void RetrieveLatLng() {
    	GeoLocationResult geo = GeoLocationHelper.getAddressLocation('810 Moe Dr Akron OH');
    	System.assert(geo<>null, 'Did not retrieve a geo location');
    }
    
    
    // BLL2a
    private static testmethod void AccountLatLng() {
    	TestHelper_MW th = new TestHelper_MW();
    	Test.startTest();
    	Account a = th.getPersonAccount('1');
    	a.BillingPostalCode='44641';
    	update(a);
    	List<Id> accts =new List<Id>();
    	accts.add(a.Id);
    	ClosestStoreFuture.Account_LocateAddress(accts);
		Test.stopTest();
    }
    // BLL2a end
}