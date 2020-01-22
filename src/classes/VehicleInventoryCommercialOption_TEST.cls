/**
 * VehicleInventoryCommercialOption_TEST
 * Tests: VehicleInventoryCommercialOption_TEST
 * Programmer: Bryan Leaman
 * Date: Feb 11, 2016
 * 
 */
@isTest
private class VehicleInventoryCommercialOption_TEST {

    // setupVICO
    @testSetup static void setupVICO() {


        dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='DT1';
        ddl.dealer__Service_Director__c =UserInfo.getUserId();
        ddl.Name='Test';
        ddl.Region__c='Test';
        insert ddl;     

       Profile prof = [select id from profile where name='system Administrator'];
       User usr = new User(alias = 'usr', email='us.name@vmail.com',
                  emailencodingkey='UTF-8', lastname='lstname',
                  timezonesidkey='America/Los_Angeles',
                  languagelocalekey='en_US',
                  localesidkey='en_US', profileid = prof.Id,
                  username='testuser128@test.mobilityworks.com',
                  Division='DT1');
                  insert usr;
                  
        System.runAs(usr){

        String CQOptionRecordType='Chassis Options';
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Commercial_Quote_Options__c.getRecordTypeInfosByName();
        
        // create a commercial quote option
        Commercial_Quote_Options__c cqopt = new Commercial_Quote_Options__c(
            RecordTypeId=RcdTypes.get(CQOptionRecordType).getRecordTypeId(), 
            Name='TestOption', Active__c=true, 
            Vehicle_Manufacturer__c='Ford', Wheelbase__c='Regular', 
            Description__c='Test option description',
            Cost__c=100.00, Freight__c=0.00, Selling_Price__c=140.00,
            Internal_Note__c='No note'
        );
        insert(cqopt);
        
        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', Division__c='Commercial', 
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='Z1234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);

        // Create a vehicle commercial option
        VehicleInventory_CommercialOption__c obj = new VehicleInventory_CommercialOption__c(
            VehicleInventory__c=veh.Id, CommercialQuoteOption__c=cqopt.Id, Quantity__c=1,
            OptionType__c=CQOptionRecordType,  
            Cost__c=cqopt.Cost__c, SellingPrice__c=cqopt.Selling_Price__c,
            Notes__c=cqopt.Internal_Note__c
        );
        insert(obj);

        }
    }

    // ExtensionUnitTest
    static testMethod void ExtensionUnitTest() {

        User u = [Select Id from User where username = 'testuser128@test.mobilityworks.com' limit 1];
        System.runAs(u) {
        
        dealer__Vehicle_Inventory__c obj = [
            select Id, Name, ChassisMfg__c, Wheelbase__c, dealer__Status_Code__c,
                dealer__Store_Location__c, dealer__VIN__c, New_Used_Other__c, Conv_MFG__c, 
                Conversion_Model__c, dealer__Stock_Number__c
            from dealer__Vehicle_Inventory__c
            limit 1
        ];
        VehicleInventory_CommercialOption__c vico = [
            select VehicleInventory__c, CommercialQuoteOption__c, Quantity__c,
            OptionType__c, Cost__c, SellingPrice__c, Notes__c
            from VehicleInventory_CommercialOption__c
            limit 1
        ];
        Commercial_Quote_Options__c cqo = [
            select Id, Name, Active__c, Vehicle_Manufacturer__c, Wheelbase__c, 
                Description__c, Cost__c, Freight__c, Selling_Price__c,
                Internal_Note__c
            from Commercial_Quote_Options__c
            limit 1
        ];
        
		Test.setCurrentPage(Page.Vehicle_CommercialOption); //Set the page for Test Method
        ApexPages.StandardController ctlr = new ApexPages.StandardController(obj);
        VehicleInventoryCommercialOption_EXT ext = new VehicleInventoryCommercialOption_EXT(ctlr); 

        // Get parent Id (vehicle)
        Map<String,String> parms = new Map<String,String>();
        ext.getVehicleOptions();
        
        // Get commercial quote options
        ext.optionType = 'Chassis Options';
        ext.chassisMfg = 'Ford';
        ext.wheelbase = null;
        ext.keywords = null;
        List<VehicleInventoryCommercialOption_EXT.CommercialOptionWrapper> opts1 = ext.getCommercialOptions();
        ext.keywords = 'Test';
        List<VehicleInventoryCommercialOption_EXT.CommercialOptionWrapper> opts2 = ext.getCommercialOptions();
        VehicleInventory_CommercialOption__c vico2 = ext.newVehicleCommercialOption(cqo.Id);
        
        ext.updateVehicleChassisOption(vico);
        ext.removeNonChassisOptions();
        ext.removeChassis();
        // BLL1a additional coverage
        ext.noAction();
        ext.optionToAdd = cqo.Id;
        ext.addOption();
        ext.optionToRmv = cqo.Id;
        ext.rmvOption();
        ext.unitNumber = obj.dealer__Stock_Number__c;
        ext.getCommercialQuotes();
        ext.quoteToUse = null; 
        ext.addQuoteOptions();
        // BLL1a end
        
        ext.editQuantities();
        ext.saveChanges();
        ext.cancelChanges();
        

        }
    }

}