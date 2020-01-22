/**
 *
 *  2016-01-30  B. Leaman restructure & remove a couple items to remain under SOQL limits.
 *  2016-03-07  J. Kuljis - Vehicles require locations or a user with location set on their user record.
 *  2016-12-01  B. Leaman - BLL2 getting errors not finding data set up in setupData routine; remove where clauses
 *                          System.today and Date.today appear to not always work. Maybe system.today is GMT?
 *	2016-12-21	B. Leaman	BLL3 - force record type due to new restrictions on vehicle type & proposal type.
 *	2016-12-29	B. Leaman	BLL4 - Replace custom lookups with managed versions (Deal obj)
 *	2017-02-28	B. Leaman	BLL5 - record type changes for commercial proposals
 */
@isTest
private class CustomInvoice_TC{
    
    @testSetup
    static void setupData() {

        //    // Instantiate the DMS Settings
            dealer.TestClassUtil tc = new dealer.TestClassUtil();
            tc.insertDMSSettings();

            dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
            ddl.Name ='Test';
            ddl.dealer__City__c ='Test';
            ddl.dealer__Postal_Code__c='301352';
            ddl.dealer__State__c='Te';
            ddl.dealer__Company_Number__c='DTM';
            ddl.dealer__Service_Director__c = Userinfo.getuserid();
            //ddl.Primary_Service_Center__c = primaryServiceCenterLocation.Id;
            insert ddl;              

           Profile prof = [select id from profile where name='system Administrator'];
           User usr = new User(alias = 'bob', email='bob@example.com',
                      emailencodingkey='UTF-8', lastname='wolcot',
                      timezonesidkey='America/Los_Angeles',
                      languagelocalekey='en_US',
                      localesidkey='en_US', profileid = prof.Id,
                      username='bob@example.com.not9nique',
                      Division='DTM');
                      insert usr;
                      
            System.runAs(usr){  

                   
                
            // Disable custom MBW triggers:
            insert(new MW_TriggerControls__c(Name='AvataxDeal',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='AvataxRepair',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='AvataxRental',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='ProposalPostTax',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='RentalPostTax',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='RepairPostTax',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='SalesUpUpdateContactInfo',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='Sales_Appt_First_Visit',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='Solution_Opp_Open_Chassis',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='ProtectPostedDeal',Enabled__c=false));
            insert(new MW_TriggerControls__c(Name='DealerLocationLatLng',Enabled__c=false));
            //insert(new MW_TriggerControls__c(Name='',Enabled__c=false));
            // End disable custom MBW triggers 
            
            dealer__FixedOperationsSettings__c  dfst = new dealer__FixedOperationsSettings__c();
            dfst.dealer__Parts_Inventory_Control_Method__c='Test';
            dfst.dealer__Parts_Inventory_Control_Method__c='Test';
            dfst.dealer__Label_Printer__c='Test';
            dfst.dealer__Repair_Order_Index__c=11;
            insert dfst;



            contact con = new contact();
            con.Phone = '8888888';
            con.LastName = 'Test';
            insert con;

            Account a = new Account();
            a.LastName ='Test';
            a.AccountSource ='Dealer';
            a.dealer__Vendor__c =True;
            a.dealer__Active__c='YES';
            a.dtffa__Active__c='YES';
            a.Active__c =True;
            insert a;

            dealer__Service_Vehicle__c  dsv = new dealer__Service_Vehicle__c ();
            dsv.dealer__VIN__c ='5TDYK3DCXBS07585X';
            dsv.Name='Test';
            dsv.dealer__Body_Style__c = 'Test';
            dsv.dealer__Company_Number__c='DTM';
            dsv.dealer__Veh_Owner_Contact__c = con.id;
            dsv.dealer__Carline__c ='Test';
            dsv.dealer__Make__c  ='Test';
            dsv.dealer__Year__c  ='2013';
            insert dsv;

            dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c();
            dsp.dealer__Lead_Date__c=System.Today();
            dsp.dealer__Lead_Status__c='Pending';
            dsp.dealer__Lead_Type__c='List';
            dsp.dealer__Source__c ='Pride';
            dsp.Solution_Type__c ='Rental';
            dsp.dealer__Customer_Account__c =a.id;
            // BLL1d - creates appraisal & service vehicles, running lots of SOQL
            //dsp.dealer__Trade_Appraised_Value__c=12;
            //dsp.dealer__Trade_Body_Type__c='test';
            //dsp.dealer__Trade_Comments__c='Test';
            //dsp.dealer__Trade_Make__c='Test';
            //dsp.dealer__Trade_Mileage__c=12;
            //dsp.dealer__Trade_Model__c ='Test';
            //dsp.dealer__Trade_Trim_Level__c='Test';
            //dsp.dealer__Trade_VIN__c='5TDYK3DCXBS075851';
            //dsp.dealer__Trade_Year__c ='2013';
            insert dsp;

            

            dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c();
            dvi.dealer__Location__c = ddl.Id;
            dvi.dealer__Last_VIN_Decode__c=system.today();
            dvi.dealer__Year__c='2012';
            //dvi.Conversion__c =dpk.id;
            dvi.dealer__Vehicle_Type__c='test';
            dvi.dealer__Vehicle_Size__c='Test'; 
            dvi.dealer__Trim_Level__c='test';
            dvi.dealer__Vehicle_Cost__c=0; 
            dvi.dealer__VIN__c='test';
            dvi.dealer__Stock_Number__c='TEST'; 
            dvi.dealer__Status_Code__c='121'; 
            dvi.dealer__Sale_Date__c=system.Today();
            dvi.dealer__Retail_Price__c=12;  
            dvi.dealer__Reserve_Price__c=12; 
            dvi.dealer__New_Tires__c=12; 
            dvi.dealer__NUO__c='test'; 
            dvi.dealer__Model__c='test';
            dvi.dealer__Model_Code__c='12'; 
            dvi.dealer__Mileage__c=0; 
            dvi.dealer__Memo_Two__c='test';  
            dvi.dealer__Memo_One__c='test';  
            dvi.dealer__Make__c='test';
            dvi.dealer__Location__c='test';
            dvi.dealer__License__c='test';
            dvi.dealer__License_Exp__c=system.today();
            dvi.dealer__Inventory_Date__c=system.today();
            dvi.dealer__In_Stock__c=true;  
            dvi.dealer__Holdback__c=12; 
            //dvi.dealer__Days_in_Stock__c=0; 
            dvi.dealer__Coded_Cost__c=12; 
            dvi.dealer__Body_Type__c='test';
            dvi.dealer__Keyless_Entry_Code__c='test';
            dvi.dealer__Demo_Indicator__c=True; 
            dvi.dealer__Ignition_Key_Code__c='test';
            dvi.dealer__MSRP__c=2;
            dvi.dealer__Pack__c=0;
            dvi.dealer__Exterior_Color__c='test';
            dvi.dealer__Title_Type__c='In-State';
            dvi.dealer__Fuel_Type__c='test';
            dvi.dealer__Work_in_Process__c=2;
            dvi.dealer__Invoice_Price__c=3;
            dvi.dealer__Engine_Description__c='test';
            dvi.dealer__Transmission_Type__c='test';
            dvi.Conversion_Cost__c=0; 
            insert dvi;

            dealer__Parts_Kit__c dpk = new dealer__Parts_Kit__c();
            dpk.Name='Test12';
            dpk.dealer__Description__c ='Testabc';
            dpk.Retail_Price__c =1;
            dpk.Parts_Cost__c=1;
            dpk.CMC_Price__c =0;
            insert dpk;

            ServicePaymentType__c sp = new ServicePaymentType__c();
            sp.Name='IEO';
            insert sp;
            
            ServicePaymentType__c sp1 = new ServicePaymentType__c();
            sp1.Name='IEU';
            insert sp1;
            
            ServicePaymentType__c sp2 = new ServicePaymentType__c();
            sp2.Name='IEN';
            insert sp2;

	        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();	// BLL3a
            dealer__Deal__c dd = new dealer__Deal__c();
            dd.Name = 'Test';
  			//dd.RecordTypeId=RcdTypes.get('Retail Vehicle Sale').getRecordTypeId();	// BLL3a
  			dd.RecordTypeId=RcdTypes.get('Retail').getRecordTypeId();	// BLL5a
  			dd.dealer__Deal_Type__c = 'Chassis/Conversion';	// BLL5a
            dd.dealer__Auto_Insurance_Agent__c='Test';
            dd.dealer__Deal_ID__c ='Test';
            dd.dealer__Sales_Lead__c = dsp.id;
            dd.dealer__Store_Location__c=ddl.id;
            dd.dealer__Vehicle__c=dvi.id;
            dd.dealer__Service_Vehicle__c=dsv.id;	// BLL4c
            //dd.dealer__Store_Location__c = [Select Id, dealer__Company_Number__c from dealer__Dealer_Location__c limit 1].Id;
            dd.dealer__Company_Number__c='DTM';
            //update dd;
            insert dd;

            dealer__After_Market__c dam = new dealer__After_Market__c();
            dam.dealer__Car_Deal__c =dd.id;
            dam.dealer__Company_Number__c='DTM';
            dam.dealer__Cost__c=1;
            dam.dealer__Description__c='Test';
            dam.dealer__Labor_Sale__c=12;
            dam.dealer__List_Price__c=1;
            dam.dealer__Parts_Kit__c=dpk.id;
            dam.dealer__Parts_Sale__c=3; 
            dam.dealer__Sale_Price__c=4; 
            dam.dealer__Vendor__c=a.id; 
            dam.Labor_Hours__c=1;
            dam.Taxable__c=True;
            //dam.Gross__c=1;
            dam.dealer__Sale_Price__c = 2;
            dam.Name='Test';        

            

        }

    }
    
    
    static testmethod void Myunittest(){

  
        dealer__Deal__c dd = [Select Id, Name, dealer__Store_Location__c, dealer__Service_Vehicle__c, dealer__VIN__c, dealer__Mileage__c, dealer__Vehicle__c, dealer__Buyer__c FROM dealer__Deal__c Limit 1];	// BLL4c

        Test.startTest();

            CustomInvoice ci = new CustomInvoice();
            dealer__Service_Repair_Order__c dsr = ci.createROFromDeal(dd);
            ci.createLines(dsr,dd); 
        
        //dd.dealer__Service_Vehicle__c=dsv.id;	// BLL4c
        //update dsv;
        // Temp removal because of too many SOQL queries in production
        //update(dd);
        //ci.createROFromDeal(dd);
        
        Test.stopTest();        

        //dealer__Sales_Up__c dsp = [
        //    select dealer__Lead_Date__c, dealer__Lead_Status__c, dealer__Lead_Type__c, dealer__Source__c, Solution_Type__c,
        //        dealer__Customer_Account__c, dealer__Trade_Appraised_Value__c, dealer__Trade_Body_Type__c, 
        //        dealer__Trade_Comments__c, 
        //        dealer__Trade_Make__c, dealer__Trade_Mileage__c, dealer__Trade_Model__c, dealer__Trade_Trim_Level__c,
        //        dealer__Trade_VIN__c, dealer__Trade_Year__c
        //        from dealer__Sales_Up__c
        //        where  dealer__Lead_Status__c='Pending' and dealer__Lead_Type__c='List'  //BLL2d dealer__Lead_Date__c = :Date.today() and
        //          and dealer__Source__c ='Pride' and Solution_Type__c ='Rental'
        //        limit 1
        //];
                
        //dealer__Dealer_Location__c ddl =  [
        //    select Name, dealer__City__c, dealer__Postal_Code__c, dealer__State__c, dealer__Company_Number__c, dealer__Service_Director__c
        //    from dealer__Dealer_Location__c
        //    where dealer__Company_Number__c='DTM'
        //    limit 1
        //];
              

        //dealer__Vehicle_Inventory__c dvi = [
        //    select dealer__Last_VIN_Decode__c, dealer__Year__c, dealer__Vehicle_Type__c, dealer__Vehicle_Size__c,  
        //        dealer__Trim_Level__c, dealer__Vehicle_Cost__c, dealer__VIN__c, dealer__Stock_Number__c, dealer__Status_Code__c,
        //        dealer__Sale_Date__c, dealer__Retail_Price__c, dealer__Reserve_Price__c, dealer__New_Tires__c, dealer__NUO__c, 
        //        dealer__Model__c, dealer__Model_Code__c, dealer__Mileage__c, dealer__Memo_Two__c, dealer__Memo_One__c,
        //        dealer__Make__c, dealer__Location__c, dealer__License__c, dealer__License_Exp__c, dealer__Inventory_Date__c,
        //        dealer__In_Stock__c, dealer__Holdback__c, dealer__Coded_Cost__c, dealer__Body_Type__c, dealer__Keyless_Entry_Code__c, 
        //        dealer__Demo_Indicator__c, dealer__Ignition_Key_Code__c, dealer__MSRP__c, dealer__Pack__c, dealer__Exterior_Color__c, 
        //        dealer__Title_Type__c, dealer__Fuel_Type__c, dealer__Work_in_Process__c, dealer__Invoice_Price__c, 
        //        dealer__Engine_Description__c, dealer__Transmission_Type__c, Conversion_Cost__c 
        //    from dealer__Vehicle_Inventory__c
        //    where dealer__VIN__c='test' and dealer__Stock_Number__c='TEST' and dealer__Status_Code__c='121' 
        //    limit 1
        //];

        //dealer__Service_Vehicle__c dsv = [
        //    select dealer__VIN__c, Name, dealer__Body_Style__c, dealer__Company_Number__c, dealer__Veh_Owner_Contact__c,
        //        dealer__Carline__c, dealer__Make__c, dealer__Year__c
        //        from dealer__Service_Vehicle__c
        //        //where Name='Test'
        //        limit 1
        //];
                
        //Account a = [
        //    select LastName, AccountSource, dealer__Vendor__c, dealer__Active__c, dtffa__Active__c, Active__c
        //    from Account 
        //    where LastName='Test' and AccountSource='Dealer' and dealer__Vendor__c=true
        //    limit 1
        //];
        
        //dealer__Parts_Kit__c dpk = [
        //    select Name, dealer__Description__c, Retail_Price__c, Parts_Cost__c, CMC_Price__c
        //    from dealer__Parts_Kit__c
        //    where Name='Test12' and dealer__Description__c='Testabc'
        //    limit 1
        //];


        //dam.CreatedDate=system.now();
        //dam.CreatedById=userinfo.getuserid();
        //dam.LastModifiedDate=system.now();
        //dam.LastModifiedById=userinfo.getuserid();
        //BLL1d insert dam;
        
        //dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
        //dsr.dealer__Customer__c =a.id;
        //dsr.dealer__Mileage_In__c =12;
        //dsr.dealer__RO_Number__c ='11';
        //dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        //dsr.dealer__Vehicle__c = dsv.Id;
        //dsr.dealer__Company__c=ddl.id;
        //insert dsr;

        //dealer__Service_Job__c dsj = new dealer__Service_Job__c();
        //dsj.dealer__Cause__c ='Test';
        //dsj.dealer__Labor_Charges__c =12;
        //dsj.dealer__Service_Repair_Order__c =dsr.id; 
        //dsj.dealer__Actual_Time__c=12;
        //dsj.dealer__Book_Time__c=12;
        //dsj.dealer__Cause__c='Test';
        //dsj.dealer__Concern__c='Test';
        //dsj.dealer__Correction__c='Test';
        ////dsj.dealer__Customer_Id__c='Test';
        //dsj.dealer__Estimate__c=12;
        ////dsj.dealer__Gross_Profit__c=12;
        //dsj.dealer__Job_Added_Date__c=system.today();
        ////dsj.dealer__Job_ELR__c=12;
        ////dsj.dealer__Job_Finish__c=system.today();
        //dsj.dealer__Job_Line_Id__c='Test';
        ////dsj.dealer__Job_Start__c=system.today();
        //dsj.dealer__Labor_Charges__c=12;
        //dsj.dealer__Labor_Rate__c='Test';
        //dsj.dealer__Labor_Type__c='Test';
        //dsj.dealer__Line_Number__c=12;
        ////dsj.dealer__Line_Total__c=12;
        //dsj.dealer__Op_Code__c='Test';
        ////dsj.dealer__Operation_Code_Description__c='Test';
        //dsj.dealer__Parent_Record__c='Test';
        //dsj.dealer__Parts_Cost__c=12;
        ////dsj.dealer__Parts_Invoice_Id__c='Test';
        ////dsj.dealer__Parts_Line__c=dpi.id;
        //dsj.dealer__Parts_Total__c=12;
        //dsj.dealer__Service_Type__c='MR';
        ////dsj.dealer__Service_Vehicle_Id__c='Test';
        ////dsj.dealer__Standard_Operation_Code__c=dso.id;
        //dsj.dealer__Stat__c='Test';
        //dsj.dealer__Sublet_Total__c=12;
        //dsj.dealer__Technician_Cost__c=12;
        //dsj.dealer__Technician__c=Userinfo.getuserid();
        //dsj.Payment_Notes__c='Test';
        //dsj.dealer__Add_On__c=True;
        //dsj.dealer__Misc_Charges__c=12;
        //dsj.dealer__Op_Description__c='Test';
        //dsj.dealer__Technician_ID__c='Test';
        //dsj.dealer__CustomerConcern__c='Test';
        ////dsj.dealer__RO_Open_Date_Time__c=system.today();
        //dsj.dealer__Claim__c='Test';
        //dsj.dealer__Paid_By__c=a.id;
        ////dsj.Payment_Method__c=spt.id;
        ////BLL1d dsj.External_ID__c='Test';   
        //insert dsj;  

//  dealer__Service_Repair_Order__c dsr = [
//      select Id, Name, dealer__Customer__c, dealer__Mileage_In__c, dealer__RO_Number__c, dealer__VIN__c,
//          dealer__Vehicle__c, dealer__Company__c
//          from dealer__Service_Repair_Order__c
//          where dealer__RO_Number__c ='11'
//          order by CreatedDate desc
//          limit 1 
//    ];

//  dealer__Deal__c dd = [select Id, Name, dealer__Auto_Insurance_Agent__c, dealer__Deal_ID__c,
//      dealer__Store_Location__c, dealer__Service_Vehicle__c, dealer__Vehicle__c, dealer__Mileage__c	// BLL4c
//      from dealer__Deal__c
//      where dealer__Deal_ID__c = 'Test' and Name='Test'
//      limit 1];
  

    }

}