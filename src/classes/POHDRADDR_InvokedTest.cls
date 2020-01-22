/**
* MobilityWorks (c) - 2017
*
* Programmer: Alexander Miller
* Created 1/1/2018 
*
* Modified By         Alias       Work Item       Date       Reason
* -----------------------------------------------------------------
* Alexander Miller    AMM1        IR-0050863     3/15/2019   Update to handle test class failure due to RS v19.6.2
*/
@isTest(SeeAllData = true)
public class POHDRADDR_InvokedTest {

    public static testMethod void testQuery()
    {
        Test.StartTest();

        List<Id> listOfIds = new List<Id>();
        List<rstk__pohdr__c> query = ([SELECT Id FROM rstk__pohdr__c LIMIT 1]);
        listOfIds.add(query.get(0).Id);
        POHDRADDR_Invoked.refreshQuery(listOfIds);
        
        Test.StopTest();
    }

    public static testMethod void testCombineStreetAddresses()
    {
        Test.StartTest();
        
        String result1 = POHDRADDR_Invoked.combineStreetAddresses('','','');
        String result2 = POHDRADDR_Invoked.combineStreetAddresses('123 Fake Street','','');
        String result3 = POHDRADDR_Invoked.combineStreetAddresses('123 Fake Street','FakeVill','');
        String result4 = POHDRADDR_Invoked.combineStreetAddresses('123 Fake Street','FakeVill','FakeState');

        System.assertEquals('', result1);
        System.assertEquals('123 Fake Street', result2);
        System.assertEquals('123 Fake Street, FakeVill', result3);
        System.assertEquals('123 Fake Street, FakeVill, FakeState', result4); 

        Test.StopTest();
    }

    public static testMethod void testInvocableMethod()
    {
        Test.StartTest();
        
        // AMM2
        // List<Id> listOfIds = new List<Id>();
        
        // // Get POs that can be worked on
        // List<rstk__pohdr__c> query = ([SELECT Id, Sales_Order_Header__c FROM rstk__pohdr__c WHERE rstk__pohdr_ordsts__c IN ('2-Firmed', '3-Approvals Processing', '4-Approved', '5-Vendor Notified') LIMIT 2]);
        // listOfIds.add(query.get(0).Id);
        // listOfIds.add(query.get(1).Id);

        // // Get Sales Orders with one Override and one normal
        // List<rstk__sohdr__c> listOfNormalShip = ([SELECT Id FROM rstk__sohdr__c WHERE rstk__sohdr_shiptoaddr__c != null LIMIT 1]);
        // List<rstk__sohdr__c> listOfOverrideShip = ([SELECT Id FROM rstk__sohdr__c WHERE rstk__sohdr_oshiptoaddr__c != null LIMIT 1]);

        // // set them to auto override
        // query.get(0).Auto_Override_Ship_To_Address__c = true;
        // query.get(1).Auto_Override_Ship_To_Address__c = true;

        // // set the sales orders
        // query.get(0).Sales_Order_Header__c = listOfNormalShip.get(0).Id;
        // query.get(1).Sales_Order_Header__c = listOfOverrideShip.get(0).Id;

        // update query;

        // POHDRADDR_Invoked.invocablePurchaseOrderAddressUpdate(listOfIds);

        List<Id> listOfIds = new List<Id>();
        
        // Get POs that can be worked on
        List<rstk__pohdr__c> query = new List<rstk__pohdr__c>();

        query.add([SELECT Id, 
            Sales_Order_Header__c, 
            CreatedDate 
        FROM rstk__pohdr__c 
        WHERE rstk__pohdr_ordsts__c IN ('2-Firmed', '3-Approvals Processing', '4-Approved', '5-Vendor Notified') AND 
            Sales_Order_Header__c != null AND
            Sales_Order_Header__r.rstk__sohdr_shiptoaddr__c != null AND 
            Auto_Override_Ship_To_Address__c = true
        ORDER BY CreatedDate DESC
        LIMIT 1]);

        query.add([SELECT Id, 
            Sales_Order_Header__c, 
            CreatedDate 
        FROM rstk__pohdr__c 
        WHERE rstk__pohdr_ordsts__c IN ('2-Firmed', '3-Approvals Processing', '4-Approved', '5-Vendor Notified') AND 
            Sales_Order_Header__c != null AND
            Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__c != null AND 
            Auto_Override_Ship_To_Address__c = true
        ORDER BY CreatedDate DESC
        LIMIT 1]);

        for(rstk__pohdr__c tempPo : query)
        {
            listOfIds.add(tempPo.Id);
        }

        POHDRADDR_Invoked.invocablePurchaseOrderAddressUpdate(listOfIds);

        // AMM2

        Test.StopTest();
    }
}