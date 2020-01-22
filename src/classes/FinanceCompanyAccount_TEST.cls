/**
 * FinanceCompanyAccount_TEST
 * Test: FinanceCompanyAccount trigger
 * 
 * 
 */
@isTest
private class FinanceCompanyAccount_TEST {

    static testMethod void FinanceCompanyCreatesAccount() {
        dealer__Finance_Company__c fc = new dealer__Finance_Company__c(
           Name = 'Test Finance Company',
           dealer__Bank_Address__c = '101 Drive Blvd',
           dealer__Bank_City__c = 'Akron',
           dealer__Bank_State__c = 'OH',
           dealer__Bank_Zip__c = '44601'
        );
        Test.startTest();
        insert(fc);
        fc.Name = fc.Name + ' updated';
        update(fc);
        Test.stopTest();
        dealer__Finance_Company__c fcafter = [select Id, Name, FinanceAccount__c from dealer__Finance_Company__c where Id=:fc.Id limit 1];
        System.assert(fcafter.Id!=null,'New finance company does not reference an account');
        Account fcacct = [select Name, Id from Account where Id=:fcafter.FinanceAccount__c limit 1];
    }
}