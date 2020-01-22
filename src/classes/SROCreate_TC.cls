/**
 * SROCreate_TC
 * Tests: SROCreate
 *
 *	2016-04-12	B. Leaman	BLL1 IT#18207 - Add coverage for new methods in SROCreate; increase coverage;
 *	2016-11-23	B. Leaman	BLL2 - tests are failing, likely due to bad user.division -- fix.
 */
@isTest
public class SROCreate_TC{


	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
	}


    Static testmethod Void Myunittest(){
		FFAdata.refresh(); 
		TestHelper_MW th = new TestHelper_MW();	
    //Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
    // User u = new User();
    // u.Alias = 'standt';
    // u.Email='testabc@gmail.com';
    // u.EmailEncodingKey='UTF-8';
    // u.LastName='Testing';
    // u.LanguageLocaleKey='en_US';
    // u.LocaleSidKey='en_US';
    // u.ProfileId = p.Id;
    // u.TimeZoneSidKey='America/Los_Angeles';
    // u.UserName='tes8888@gmail.com';
    // u.Dealership_Location__c ='Test';
    //u.service_manager__c  ='Test';
     //BLLxd u.Division ='12365';
    // u.Division = FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL2a
    // insert u;

    //dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
    //    ddl.Name ='Test';
    //    ddl.dealer__City__c ='Test';
    //    ddl.dealer__Postal_Code__c='301352';
     //   ddl.dealer__State__c='Te';
     //   ddl.dealer__Company_Number__c=u.Division;
     //   ddl.dealer__Service_Director__c =Userinfo.getuserid();
     //   insert ddl;

     //BLL2d  System.runAs(u) {                
		System.runAs(FFAdata.TestUser) {	// BLL2a
         
            //BLL2d dealer.TestClassUtil tc = new dealer.TestClassUtil();
            //BLL2d tc.insertDMSSettings(); 
             
            contact con = new contact();
            con.Phone = '8888888';
            con.LastName = 'Test';
            insert con;

            //Account a = new Account();
            //a.LastName ='Test';
            //a.AccountSource ='Dealer';
            //a.dealer__PersonContactId__c=con.id;
            //insert a;
			Account a = th.getBusinessAccount('1');
			a.dealer__PersonContactId__c=con.id;
			update(a);

            dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c();
            dvi.dealer__VIN__c ='test';
            dvi.dealer__Vehicle_Order_Number__c ='Test';
            dvi.dealer__Make__c='Test';
            dvi.dealer__Model__c='Test';
            dvi.dealer__Stock_Number__c='1';
            dvi.dealer__Year__c='2014';
            insert dvi;

            dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
            dsv.Name='Test';
            dsv.dealer__VIN__c ='2C4RDGBG2FR581207';
            dsv.dealer__Body_Style__c = 'Test';
            //BLL2d dsv.dealer__Company_Number__c='12123';
            dsv.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL2a
            dsv.dealer__Veh_Owner_Contact__c = con.id;
            dsv.dealer__Carline__c ='Test';
            dsv.dealer__Make__c  ='Test';
            dsv.dealer__Year__c  ='2013';
            dsv.dealer__Last_Odometer__c =1;
            dsv.dealer__Sales_Inventory__c =dvi.id;
            insert dsv;
           
            dealer__FixedOperationsSettings__c fos= new dealer__FixedOperationsSettings__c();
            fos.Name='Test';
            // fos.dealer__RepairOrderIndex__c=12.34; // Deprecate, not active
            fos.dealer__Repair_Order_Index__c=12.45;
            insert fos;
            
            dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
            //dsr.Name ='RO#CIN-7068';
            dsr.dealer__Customer__c=a.id;
            dsr.dealer__Mileage_In__c=0;
            dsr.dealer__Service_Advisor__c=UserInfo.getUserid();
            dsr.dealer__Vehicle__c=dsv.id;
            dsr.dealer__Status__c='Open';
            dsr.dealer__Tag__c='1244';
            dsr.dealer__RO_Number__c='abc0013444'; 
            //dsr.dealer__Status__c='Open';
            //dsr.dealer__Create_Date_Time__c=system.today();
           //dsr.dealer__Vehicle_Inventory__c=dvi.id;
            //dsr.dealer__Company__c= ddl.Id;
            //BLL2d dsr.dealer__Company_Number__c = ddl.dealer__Company_Number__c;
            dsr.dealer__Company_Number__c=FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL2a
            
            //dsr.dealer__Service_Advisor__c = UserInfo.getUserId();
            dsr.dealer__RO_Number__c= String.Valueof(fos.dealer__Repair_Order_Index__c);
            insert dsr;
        
                ApexPages.StandardController sc = new ApexPages.StandardController(dsr);
                ApexPages.currentPage().getParameters().put('id', dsr.id);
                ApexPages.currentPage().getParameters().put('x_lkid', a.Id);	// BLL1a
                ApexPages.currentPage().getParameters().put('customer', a.Id);	// BLL1a
                ApexPages.currentPage().getParameters().put('vehicle', dsv.Id);	// BLL1a

                //SROCreate scr= new SROCreate(new ApexPages.StandardController(dsr));
                SROCreate scr= new SROCreate(sc);
                
                scr.save();
                scr.accountSelected();
               // scr.lookupPersonsAccountId(a.id);
               // scr.lookupPersonsAccountId(con.id);
			scr.VehicleInventoryReferences(dvi.Id);	// BLL1a
        }
    }
    
    Static testmethod Void Myunittest2(){
		FFAdata.refresh(); 
		TestHelper_MW th = new TestHelper_MW();	

    //Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
    // User u = new User();
    // u.Alias = 'standt';
    // u.Email='testabc@gmail.com';
    // u.EmailEncodingKey='UTF-8';
    // u.LastName='Testing';
    // u.LanguageLocaleKey='en_US';
    // u.LocaleSidKey='en_US';
    // u.ProfileId = p.Id;
    // u.TimeZoneSidKey='America/Los_Angeles';
    // u.UserName='tes8888@gmail.com';
    // u.Dealership_Location__c ='Test';
    //u.service_manager__c  ='Test';
     //BLLxd u.Division ='12365';
    // u.Division = FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL2a
    // insert u;

    //dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
    //    ddl.Name ='Test';
    //    ddl.dealer__City__c ='Test';
    //    ddl.dealer__Postal_Code__c='301352';
    //    ddl.dealer__State__c='Te';
    //    ddl.dealer__Company_Number__c=u.Division;
    //    ddl.dealer__Service_Director__c =Userinfo.getuserid();
    //    insert ddl;

    //BLL2d System.runas(u) {
		System.runAs(FFAdata.TestUser) {	// BLL2a
            //BLL2d dealer.TestClassUtil tc = new dealer.TestClassUtil();
            //BLL2d tc.insertDMSSettings(); 
             
            contact con = new contact();
            con.Phone = '8888888';
            con.LastName = 'Test';
            insert con;

            //Account a = new Account();
            //a.LastName ='Test';
            //a.AccountSource ='Dealer';
            //a.dealer__PersonContactId__c=con.id;
            //a.isPersonAccount=false;
            //insert a;
			Account a = th.getBusinessAccount('1');
			a.dealer__PersonContactId__c=con.id;
			update(a);

            //dealer__Dealer_Location__c d = [Select Id, Name, dealer__Company_Number__c from dealer__Dealer_Location__c where dealer__Company_Number__c =:u.Division limit 1];

           // System.debug(d);

            dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c();
            dvi.dealer__VIN__c ='test';
            dvi.dealer__Vehicle_Order_Number__c ='Test';
            dvi.dealer__Make__c='Test';
            dvi.dealer__Model__c='Test';
            dvi.dealer__Stock_Number__c='1';
            dvi.dealer__Year__c='2014';
            insert dvi;

            dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
            dsv.Name='Test';
            dsv.dealer__VIN__c ='2C4RDGBG2FR581207';
            dsv.dealer__Body_Style__c = 'Test';
            //BLL2d dsv.dealer__Company_Number__c='12123';
            dsv.dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL2a
            dsv.dealer__Veh_Owner_Contact__c = con.id;
            dsv.dealer__Carline__c ='Test';
            dsv.dealer__Make__c  ='Test';
            dsv.dealer__Year__c  ='2013';
            dsv.dealer__Last_Odometer__c =1;
            dsv.dealer__Sales_Inventory__c =dvi.id;
            insert dsv;
           
            dealer__FixedOperationsSettings__c fos= new dealer__FixedOperationsSettings__c();
            fos.Name='Test';
            // fos.dealer__RepairOrderIndex__c=12.34; // Deprecate 
            fos.dealer__Repair_Order_Index__c=12.45;
            insert fos;
            
           
            
            dealer__Service_Repair_Order__c dsr2 = new dealer__Service_Repair_Order__c();
            //dsr.Name ='RO#CIN-7068';
            dsr2.dealer__Customer__c=a.id;
            dsr2.dealer__Mileage_In__c=0;
             dsr2.dealer__Service_Advisor__c=UserInfo.getUserid();
           // dsr2.dealer__Vehicle__c=dsv.id;
            dsr2.dealer__Status__c='Open';
            dsr2.dealer__Tag__c='1244';
            dsr2.dealer__RO_Number__c='abc0013444'; 
            //dsr.dealer__Status__c='Open';
            //dsr.dealer__Create_Date_Time__c=system.today();
           dsr2.dealer__Vehicle_Inventory__c=dvi.id;
            //dsr.dealer__Company__c= ddl.Id;
            //BLL2d dsr2.dealer__Company_Number__c = ddl.dealer__Company_Number__c;
            dsr2.dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c;	// BLL2a
            //dsr.dealer__Service_Advisor__c = UserInfo.getUserId();
            dsr2.dealer__RO_Number__c= String.Valueof(fos.dealer__Repair_Order_Index__c);
            insert dsr2;

                    ApexPages.StandardController sc2 = new ApexPages.StandardController(dsr2);
                    ApexPages.currentPage().getParameters().put('id', dsr2.id);
                    //SROCreate scr= new SROCreate(new ApexPages.StandardController(dsr));
                    SROCreate scr2= new SROCreate(sc2);
                    
                    scr2.save();
                    scr2.accountSelected();
                    scr2.lookupPersonsAccountId(a.id);
                   // scr.lookupPersonsAccountId(con.id);
        }
        //scr.lookupPersonsAccountId(con.id);
    }
}