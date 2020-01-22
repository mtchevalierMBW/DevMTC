@isTest
private class TestSalesUp {
	static testmethod void testNewSalesUp() {

       RecordType person = [select Id, Name from RecordType 
                where SObjectType='Account' and isPersonType=true limit 1];

		Account a = new Account(FirstName = 'Jarrett', LastName='Kuljis', RecordTypeId=person.Id);
		insert a;

		a = [Select Id, PersonContactId from Account where Id=:a.Id];
		
		PageReference pageRef = Page.SalesUpNewPersonsAccount;
        Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('_lkid', a.PersonContactId);

		dealer__Sales_Up__c sup = new dealer__Sales_Up__c();
		sup.Solution_Type__c = 'Chassis/Conversion';
		ApexPages.StandardController sc = new ApexPages.StandardController(sup);

		SalesUpMBW s = new SalesUpMBW(sc);
        insert(sup); // BLL add
        
	}

	static testmethod void testNeedsAssesment() {
		
		Account a = new Account(FirstName = 'Jarrett', LastName='Kuljis');
		insert a;

		dealer__Sales_Up__c sup = new dealer__Sales_Up__c();
		sup.dealer__Customer_Account__c = a.Id;
		ApexPages.StandardController sc = new ApexPages.StandardController(sup);

		NeedsAnalysisAccount s = new NeedsAnalysisAccount(sc);

		s.performNewNeedsAssesment();
		s.saveNeedsAssesment();
	}

    // Test with a business account, not a persons account - BLL
	static testmethod void testNewSalesUp2() {

       RecordType business = [select Id, Name from RecordType 
                where SObjectType='Account' and Name like 'Business%' limit 1];

		Account a = new Account(RecordTypeId=business.Id, Name='testNewSalesUp2', BillingState='OH', BillingPostalCode='44641');
		insert a;
		Contact c = new Contact(AccountId=a.Id, FirstName='testNew', LastName='SalesUp2');
		insert c;
        dealer__Sales_Up__c sup2 = new dealer__Sales_Up__c(dealer__Buyer_Contact__c=c.Id, dealer__Customer_Account__c=a.Id);
        insert(sup2);
 
	}

}