// PardotWebFormData_MW_EXT_TEST
// Tests: PardotWebFormData_MW_EXT
@isTest
private class PardotWebFormData_MW_EXT_TEST {
    @isTest
    private static void UseControllerExtension() {


        dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='DTM';
        ddl.dealer__Service_Director__c =Userinfo.getuserid();
        insert ddl;        

       Profile prof = [select id from profile where name='system Administrator'];
       User usr = new User(alias = 'bob', email='bob@example.com',
                  emailencodingkey='UTF-8', lastname='wolcot',
                  timezonesidkey='America/Los_Angeles',
                  languagelocalekey='en_US',
                  localesidkey='en_US', profileid = prof.Id,
                  username='bob@example.com.9Nique',
                  Division='DTM');
                  insert usr;
                  
        System.runAs(usr){ 

            TestHelper_MW th = new TestHelper_MW();
            RecordType rt = th.getRetailLeadRt();
            Lead l=null;
            dealer__Vehicle_Inventory__c vi = th.getVehicleInventory('1');
            String twoStock = vi.dealer__Stock_Number__c + ';1001B';
            //dealer__Vehicle_Inventory__c vi = [select Id, dealer__Stock_Number__c from dealer__Vehicle_Inventory__c limit 1];
            l = new Lead(RecordTypeId = rt.Id, FirstName='Test', LastName='Lead',  
                             phone='(555) 555-1212', Desired_Vehicles__c = twoStock );
            insert(l);
            ApexPages.StandardController leadController = new ApexPages.StandardController(l);
    	    PardotWebFormData_MW_EXT lead_ext = new PardotWebFormData_MW_EXT(leadController);
            String s = lead_ext.Vehicles[0].stocknbr + lead_ext.Vehicles[0].name + lead_ext.Vehicles[0].inventorylink + lead_ext.Vehicles[0].websitelink;
        }
    } 
}