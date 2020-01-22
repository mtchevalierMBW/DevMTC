/**
 * TestServiceEstimateCustomControls
 * Tests: 
 * 
 * Modifications:
 *	2018-04-19	B. Leaman	BLL1 - use valid values from restricted pick-list - dealer__Labor_Type__c.
 *	2018-04-22	B. Leaman	BLL2 - remove partpricematrix test - using routine that already existed.
 *	2019-07-22	B. Leaman	BLL3 - New validation rule - contacts must reference accounts on an RO
 *	2019-09-18	B. Leaman	BLL4 - DT  5.x requirement that est and sro be for the same location
 * 
**/
@isTest
private class TestServiceEstimateCustomControls {
    
	@testSetup static void setup() {
        
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

		// BLL1a
        DescribeFieldResult lbrtype = dealer__Service_Estimate_Line__c.dealer__Labor_Type__c.getDescribe();
		List<Schema.PicklistEntry> ltplvs = lbrtype.getPicklistValues();
		// ltplvs[n].getLabel(), ltplvs[n].getValue()
		String customer_labor_type;
		String warranty_labor_type;
		for(Integer i=0; i<ltplvs.size(); i++) {
			if (ltplvs[i].getValue().length()>1) {
				if (String.isBlank(customer_labor_type)) customer_labor_type = ltplvs[i].getValue();
				else if (String.isBlank(warranty_labor_type)) warranty_labor_type = ltplvs[i].getValue();
			}
		}
        // Service Payment
        List<ServicePaymentType__c> spts = new List<ServicePaymentType__c>();    
        spts.add(new ServicePaymentType__c (
			Name = customer_labor_type,
			Payment_Type__c = 'C',
			Default_Labor_Rate__c = 70
		));
        spts.add(new ServicePaymentType__c (
			Name = warranty_labor_type,
			Payment_Type__c = 'W',   
			Default_Labor_Rate__c = 90
		));
        insert spts;
        System.debug(spts);
		// BLL1a end
        
    }
	
    /**
     * 		Test when Labor_Type__c field on Service_Estimate_Line__c is updated.
     * 		Related to ServiceEstimateLineDefaults trigger
     * */
    @isTest static void testIsMeaningfullyChanged(){
        ServicePaymentType__c cpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'C' limit 1];
        ServicePaymentType__c wpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'W' limit 1];
         
        dealer__Service_Estimate__c se = new dealer__Service_Estimate__c(dealer__Cosmetic_Notes__c='Repair / Repaint Bumper');
        insert se;   
        
        dealer__Service_Estimate_Line__c sel = new dealer__Service_Estimate_Line__c(
			dealer__Service_Estimate__c=se.Id,
			dealer__Labor__c=100,
			dealer__Parts__c=50,
			dealer__Labor_Type__c = cpt.Name	// BLL1c was 'C'
        );
        insert sel;
        
        Test.startTest();
        
        //sel.dealer__Labor_Type__c = 'W';	// BLL1d
        sel.dealer__Labor_Type__c = wpt.Name;	// BLL1a 
		update sel;
        
        dealer__Service_Estimate_Line__c selTest = [Select Id, dealer__Labor_Type__c From dealer__Service_Estimate_Line__c where Id=: sel.Id];
        system.assertEquals(wpt.Name /* 'W' */, selTest.dealer__Labor_Type__c);
       	
        Test.stopTest();
      
    }
    
    /**
     * 		Test that Labor_Rate__c field on Service_Estimate_SubLine__c is set
     * 		when Line_Type__c='Labor'
     * 		Related to ServiceEstimateSubLineDefaults trigger
     * */
    @isTest static void testForcedLaborRate(){               
        ServicePaymentType__c cpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'C' limit 1];
        ServicePaymentType__c wpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'W' limit 1];
           	
        // Service Payment
        //BLL1d ServicePaymentType__c spt = new ServicePaymentType__c (
        //BLL1d     		Name = customer_labor_type, 	//BLL1d 'C',  //Same as Service Estimate Subline, 
        //BLL1d     		Default_Labor_Rate__c = 70);
        //BLL1d insert spt;
		System.debug(cpt.Name);
        ServicePaymentType__c spt =  [select Name, Default_Labor_Rate__c from ServicePaymentType__c where Name=:cpt.Name limit 1];	// BLL1a
        
        //Service Estimate
        dealer__Service_Estimate__c se = new dealer__Service_Estimate__c(dealer__Cosmetic_Notes__c='Repair / Repaint Bumper');
        	
        insert se;
        
        //Service Estimate Line
        dealer__Service_Estimate_Line__c sel = new dealer__Service_Estimate_Line__c(
            		dealer__Service_Estimate__c=se.Id,
                	dealer__Labor_Type__c = cpt.Name);	// BLL1c 'C');
        
        insert sel;

        // Sub Line
        dealer__Service_Estimate_SubLine__c newSubLine = new dealer__Service_Estimate_SubLine__c(
                    dealer__Labor_Rate__c=90,
                    dealer__Line_Type__c='Labor',
                    dealer__Service_Estimate_Line__c=sel.Id);
        
        Test.startTest();
            
        insert newSubLine;
        
        List<dealer__Service_Estimate_SubLine__c> ses = [SELECT dealer__Labor_Rate__c FROM dealer__Service_Estimate_SubLine__c where Id=: newSubLine.Id];
                                                         
        Test.stopTest();
        
        System.assertEquals(spt.Default_Labor_Rate__c, ses[0].dealer__Labor_Rate__c);        
    }
    
     /**
     * 		Test that Part_Price__c field on Service_Estimate_SubLine__c is set
     * 		when Parts_Master__c != null
     * 		Related to ServiceEstimateSubLineDefaults trigger
     * */
    @isTest static void testForcedPartsPricing(){ 
        ServicePaymentType__c cpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'C' limit 1];
        ServicePaymentType__c wpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'W' limit 1];
        
        // Create a Parts Master Entry
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        pm.Name = 'FL1A__TEST_PART';
        pm.dealer__Retail_Price__c = 99.99;
        pm.dealer__Cost__c = 115;
        insert pm;        
                
        dealer__Parts_Inventory__c pi = new dealer__Parts_Inventory__c(
            Name='ToBoChanged',
            dealer__Bin__c='A123',
            dealer__Entry_Date__c=Date.today(),
            dealer__Cost__c=Decimal.valueOf('123.45'),
            dealer__List__c=Decimal.valueOf('224.95'),
            dealer__Part_No__c='A88999',
            dealer__Source__c='Temp',
            dealer__Parts_Master__c = pm.Id,
            dealer__Location__c=dealer.TestClassUtil.createLocation(),
            dealer__On_Hand__c=2,
            dealer__On_Order__c  = 100
        );
        
        insert pi;    
        
        // Service Payment    
        //BLL1d ServicePaymentType__c spt = new ServicePaymentType__c (
        //BLL1d    		Name = 'C',  //Same as Service Estimate Subline, 
        //BLL1d     		Default_Labor_Rate__c = 70);
        //BLL1d insert spt;
        
        //Service Estimate
        dealer__Service_Estimate__c se = new dealer__Service_Estimate__c(
        	dealer__Cosmetic_Notes__c='Repair / Repaint Bumper'
        );
        insert se;
        
        //Service Estimate Line
        dealer__Service_Estimate_Line__c sel = new dealer__Service_Estimate_Line__c(
            		dealer__Service_Estimate__c=se.Id,
                	dealer__Labor_Type__c = wpt.Name);	// BLL1c 'C');
        
        insert sel;

        // Sub Line
        dealer__Service_Estimate_SubLine__c newSubLine = new dealer__Service_Estimate_SubLine__c(
                    dealer__Labor_Rate__c=90,
                    dealer__Line_Type__c='Labor',
            		dealer__Parts_Master__c = pm.id,
            		dealer__Part_Price__c = 0,
                    dealer__Service_Estimate_Line__c=sel.Id);       
        
        Test.startTest();
            
        insert newSubLine;    
        List<dealer__Parts_Master__c> pml = [SELECT dealer__Cost__c FROM dealer__Parts_Master__c where Id=: pm.Id];
        List<dealer__Service_Estimate_SubLine__c> ses = [SELECT dealer__Part_Price__c FROM dealer__Service_Estimate_SubLine__c where Id=: newSubLine.Id];

        Test.stopTest();
        
        System.assertEquals(pml[0].dealer__Cost__c, ses[0].dealer__Part_Price__c);

    }

    
    @isTest private static void testRecomputeSublines(){
        ServicePaymentType__c cpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'C' limit 1];
        ServicePaymentType__c wpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'W' limit 1];
        
        dealer.Utility.getDMSSettings();

        //Location
        dealer__Dealer_Location__c loc = createLocation();
		// BLL4
		update(new User(Id=UserInfo.getUserId(), Division=loc.dealer__Company_Number__c));
		// BLL4 end


        Contact c = new Contact(LastName='Test');
        Account a = new Account(Name='Test Acct');
		// BLL3
        insert a;	
		c.AccountId = a.Id;
		// BLL3
		insert c;
        // BLL3d insert a;

        dealer__Service_Vehicle__c d = new dealer__Service_Vehicle__c(
            dealer__VIN__c='3GNEK12Z15G244588',
            dealer__Veh_Owner_Contact__c = C.ID,
            dealer__Year__c='2014',
            dealer__Make__c='test',
            dealer__Carline__c='test');
        insert d;
        
        dealer__Service_Repair_Order__c SRO = new dealer__Service_Repair_Order__c(
            dealer__Vehicle__c = d.ID, dealer__Customer_Contact__c = c.ID, dealer__Mileage_In__c=10, 
            dealer__Company__c = loc.Id ,dealer__RO_Number__c='10001');
        
        insert SRO;
		// BLL4
		SRO = [select dealer__Vehicle__c, dealer__Customer_Contact__c, dealer__Mileage_In__c, 
            dealer__Company__c, dealer__Company_Number__c, dealer__RO_Number__c
			from dealer__Service_Repair_Order__c 
			where Id=:SRO.Id limit 1];
		// BLL4
        
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        pm.Name = 'Oil Filter';
        pm.dealer__Retail_Price__c = 99.99;
        pm.dealer__Cost__c = 20;
        insert pm;
        
        // create a service estimate
        dealer__Service_Estimate__c est = new dealer__Service_Estimate__c(
        	dealer__Customer__c = a.Id,
        	dealer__Status__c = 'Open',
			// BLL4
			dealer__Company__c = SRO.dealer__Company__c,
			dealer__Company_Number__c = SRO.dealer__Company_Number__c,
			// BLL4
            dealer__Service_Repair_Order__c = SRO.Id
        );
        insert est;
        
        dealer__Service_Estimate_Line__c sel = new dealer__Service_Estimate_Line__c(
			dealer__Service_Estimate__c=est.Id,
			dealer__Labor__c=100,
			dealer__Parts__c=50,
			dealer__Labor_Type__c = wpt.Name // BLL1c 'W'
		);
        insert sel;
                    
       	dealer__Service_Estimate_SubLine__c subLine = new dealer__Service_Estimate_SubLine__c(
       				dealer__Service_Estimate_Line__c   = sel.Id,
           			dealer__Parts_Master__c = pm.Id,
           			dealer__Part_Price__c  = 100,
           			dealer__Part_Quantity__c = 1

       	);
        
        sel.dealer__Labor_Type__c = cpt.Name; //BLL1c 'C';
            
        Test.startTest();
                update sel;

        Test.stopTest();


        
        dealer__Service_Estimate_Line__c sl = [select dealer__Labor_Type__c, dealer__Parts__c from dealer__Service_Estimate_Line__c
                                              where Id=: sel.Id];
        
        system.assertEquals(cpt.Name	/* 'C' */ , sl.dealer__Labor_Type__c);
        
    }
    
    @isTest private static void testSetForcedLaborRate(){
        ServicePaymentType__c cpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'C' limit 1];
        ServicePaymentType__c wpt = [select Id, Name from ServicePaymentType__c where Payment_Type__c = 'W' limit 1];
        
        //Location
        dealer__Dealer_Location__c loc = createLocation();
        
        Account a = new Account(Name='Test Acct');
        insert a;
        
        dealer__Parts_Master__c pm = new dealer__Parts_Master__c();
        pm.Name = 'Oil Filter';
        pm.dealer__Retail_Price__c = 99.99;
        pm.dealer__Cost__c = 20;
        insert pm;
        
        dealer__ServiceLaborRateDefault__c lr = new dealer__ServiceLaborRateDefault__c(dealer__Labor_Rate__c = 100, dealer__Location__c  = Loc.Id);
        insert lr;
        
        //ServicePaymentType__c sp = new ServicePaymentType__c(Name='C', Payment_Type__c='C', Default_Labor_Rate__c = 100);
        //insert sp;
        
        // create a service estimate
        dealer__Service_Estimate__c est = new dealer__Service_Estimate__c(
        	dealer__Customer__c = a.Id,
        	dealer__Status__c = 'Open'
        );
        insert est;
        
        dealer__Service_Estimate_Line__c sel = new dealer__Service_Estimate_Line__c(
			dealer__Service_Estimate__c=est.Id,
			dealer__Labor__c=100,
			dealer__Parts__c=50,
			dealer__Labor_Type__c = cpt.Name	// BLL1c 'C'
		);
        insert sel;
                    
       	dealer__Service_Estimate_SubLine__c subLine = new dealer__Service_Estimate_SubLine__c(
       				dealer__Service_Estimate_Line__c   = sel.Id,
           			dealer__Parts_Master__c = pm.Id,
           			dealer__Part_Price__c  = 100,
           			dealer__Part_Quantity__c = 1,
            		dealer__Line_Type__c = 'Labor'
       	);
        
        Test.startTest();
			insert subLine;
        Test.stopTest();

       	dealer__Service_Estimate_SubLine__c sb = [select dealer__Part_Price__c, dealer__Total_Part_Price__c From dealer__Service_Estimate_SubLine__c
                                                 Where Id =: subLine.Id];
     
        
        //BLL2d Decimal newRetailPrice = PartPriceMatrix.calculate(pm.dealer__Cost__c); 
        //BLL2d system.assertEquals(sb.dealer__Part_Price__c, newRetailPrice);
        
    }
    
      private static dealer__Dealer_Location__c createLocation(){
        
        dealer__Dealer_Location__c objLocation = new dealer__Dealer_Location__c();
        objLocation.Name = 'Test Location';
        objLocation.dealer__City__c = 'Test City';
        objLocation.dealer__Company_Number__c = '101';
        objLocation.dealer__Postal_Code__c = '411028';
        objLocation.dealer__State__c = 'CA';
        objLocation.dealer__Tax_Local_Rate__c = 5.0;
        objLocation.dealer__Tax_Local_Rental_Addition__c = 2.0;
        objLocation.Centralized_Purchasing_On_Off__c = true;
        insert objLocation;
        return objLocation;
    }
 
}