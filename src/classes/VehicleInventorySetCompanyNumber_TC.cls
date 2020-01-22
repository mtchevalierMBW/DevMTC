@isTest
private class VehicleInventorySetCompanyNumber_TC{
    static testmethod Void Myunittest(){

        dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='DT1';
        ddl.dealer__Service_Director__c =UserInfo.getUserId();
        ddl.Name='Test';
        ddl.Region__c='Test';
        ddl.dealer__Physical_Location__Longitude__s = -77.1;
        ddl.dealer__Physical_Location__Latitude__s = 38.8;
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

            dealer__Vehicle_Inventory__c  dvi = new  dealer__Vehicle_Inventory__c();
            dvi.dealer__VIN__c ='Test';  
            //dvi.dealer__Company_Number__c ='';
            dvi.dealer__Make__c='Test';
            dvi.dealer__Model__c='Test';
            dvi.dealer__Stock_Number__c='123';
            dvi.dealer__Year__c='2013';
            insert dvi;


            dvi.dealer__Company_Number__c ='';
            update dvi;

        // Test coverage for Inventory Brochure print
      /*  ApexPages.StandardController sc = new ApexPages.StandardController(dvi);
        ApexPages.currentPage().getParameters().put('id', dvi.Id);
        ApexPages.currentPage().getParameters().put('printedprice', '50000');
        ApexPages.currentPage().getParameters().put('imageseq1', '2');
        ApexPages.currentPage().getParameters().put('imageseq2', '2');
        ApexPages.currentPage().getParameters().put('imageseq3', '2');
        ApexPages.currentPage().getParameters().put('price', '50000');

        VehicleInventory_Brochure print = new VehicleInventory_Brochure(sc);
        print.returnToRecord(); */

        }
    }
}