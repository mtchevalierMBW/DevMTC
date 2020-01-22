/**
 * upload_Service_Vehicle_Helper_MW_Test
 * Tests: upload_Service_Vehicle_Helper_MW
 *
 * 2015-09-08	B. Leaman	BLL1 - re-enable check for contact being updated (from person account)
 */
@isTest
class upload_Service_Vehicle_Helper_MW_Test{
  @isTest private static void account_Assignment(){ 
  // Create a test account 
    RecordType pa_rt = [select Id, Name from RecordType where SObjectType='Account' and IsPersonType=true limit 1];
    Account a = new Account(RecordTypeId=pa_rt.Id, 
        FirstName='TestPerson', LastName='Account', 
        dealer__External_ID__c='TESTACCT123');
    insert(a);
    Account pa = [select Id, PersonContactID from Account where Id=:a.Id limit 1];

    // Create service vehicle
    dealer__Service_Vehicle__c sv = new dealer__Service_Vehicle__c(
        upload_Account__c = a.dealer__External_ID__c,
        dealer__Year__c = '2000',
        dealer__Make__c = 'Toyota',
        dealer__Carline__c = 'Sienna'
    );
    insert(sv);

    // Retrieve resulting Service Vehicle record
    dealer__Service_Vehicle__c svafter = [select Id, Name, dealer__Veh_Owner__c, dealer__Veh_Owner_Contact__c
          from dealer__Service_Vehicle__c
          where Id=:sv.Id];

    // Make sure the account was assigned
    System.assertEquals(a.Id, svafter.dealer__Veh_Owner__c,'Did not connect vehicle to owner account');

    // Make sure the contact was assigned
    System.assertEquals(pa.PersonContactID, svafter.dealer__Veh_Owner_Contact__c,'Did not connect vehicle to owner contact');
    
  }
}