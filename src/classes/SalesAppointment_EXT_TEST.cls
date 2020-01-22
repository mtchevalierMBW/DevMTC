/**
* SalesAppointment_EXT_TEST
* Tests: SalesAppointment_EXT
* Date: 2019-01-14
* Programmer: Bryan Leaman
*
*
* Modifications:
*	2019-09-18	B. Leaman	W-000730 BLL1 - New requirements in DT 5.x
*/
@isTest
private class SalesAppointment_EXT_TEST {

	 //private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	 @testSetup
	 static void setupData() {
		 //TestHelper_MW.createBaseFFAData(FFAdata);
		 ////FFAdata.refresh(); 
		 //dealer.TestClassUtil tc = new dealer.TestClassUtil();
		 //tc.insertDMSSettings();
		 // BLL1
		 dealer.TestClassUtil tc = new dealer.TestClassUtil();
		 tc.insertDMSSettings();
		 // BLL1
		 
		 TestHelper_MW th = new TestHelper_MW();
		 Account a = th.getPersonAccount('1');
		 dealer__Sales_Up__c sup = new dealer__Sales_Up__c(
			dealer__Lead_Date__c = Date.Today(),
			dealer__Lead_Status__c = 'Pending',
			dealer__Lead_Type__c = 'List',
			dealer__Source__c = 'Pride',
			Solution_Type__c = 'Rental',
			dealer__Customer_Account__c = a.Id
		 );
		 insert(sup);

		DateTime dt = DateTime.now();
		dealer__Sales_Appointment__c sappt = new dealer__Sales_Appointment__c(
        	dealer__Appointment_Type__c = 'First Visit',
        	dealer__Assigned_To__c = UserInfo.getUserId(),
        	dealer__Customer__c = sup.dealer__Customer_Account__r.PersonContactId,
        	dealer__Sales_Up__c = sup.Id,
        	dealer__DateTime__c = dt,
        	dealer__Date__c = dt.date(),
        	dealer__Time__c = dt.format('hh:mm a')
		);
		insert(sappt);		 
	 }


	 // ctrlExtTest
	 //---------------------------------------
	 static testMethod void ctrlExtTest() {
		//FFAdata.refresh(); 
		//System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();

			Set<String> fields = new Set<String>();
			Map<String,Schema.SObjectField> fm = dealer__Sales_Appointment__c.getSObjectType().getDescribe().fields.getMap();
			for(String f : fm.keySet()) {
				Schema.DescribeFieldResult fd = fm.get(f).getDescribe();
				if(fd.isAccessible() && !fd.isDeprecatedAndHidden()) fields.add(f);
			}

			dealer__Sales_Appointment__c sappt = Database.query('select ' + String.join(new List<String>(fields), ',') 
				+ ' from dealer__Sales_Appointment__c limit 1');

			Test.startTest();

			PageReference pgRef = Page.SalesAppointment_MW; 
			Test.setCurrentPage(pgRef); //Set the page for Test Method
			ApexPages.currentPage().getParameters().put('id', sappt.Id);
			ApexPages.StandardController sc = new ApexPages.StandardController(sappt);
			SalesAppointment_EXT sae = new SalesAppointment_EXT(sc);

			String tzstr = sae.UserTimeZone;
			sae.save();
			sae.cancel();

			Test.stopTest();

		//}
	 }

}