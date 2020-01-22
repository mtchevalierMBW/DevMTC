/**
 * SolutionOppFollowUpTasks_TEST
 * Tests: SolutionOppFollowUpTasks
 * Date: 2019-04-01
 * Programmer: Bryan Leaman
 * Project: #W-000528
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *	2019-09-18	B. Leaman	W-000730 BLL1 - new requirements in DT 5.x
 *
 */
 @isTest
 private class SolutionOppFollowUpTasks_TEST {

	//private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	private static void setupTestData() {
		// BLL1
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
		// BLL1
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getPersonAccount('1');
		dealer__Dealer_Location__c loc = th.getDealerLocation('1');

		dealer__Sales_Up__c sup = new dealer__Sales_Up__c(
			Legacy_ID__c = 'TEST_LEGACY_1',
			dealer__Buyer_Contact__c = a.PersonContactId,
			dealer__Lead_Status__c = 'Pending',
			OwnerId = UserInfo.getUserId()
		);
		insert(sup);

		dealer__Sales_Appointment__c sap = new dealer__Sales_Appointment__c(
			Legacy_Opportunity__c = sup.Legacy_ID__c,
			dealer__Customer__c = a.PersonContactId,
			dealer__Date__c = Date.today(),
			dealer__Time__c = '10:00 AM',
			dealer__DateTime__c = Datetime.now(),
			dealer__Confirmed__c = true,
			dealer__Appointment_Result__c = 'Show',
			dealer__Appointment_Type__c = 'First Visit',
		    dealer__Assigned_To__c = UserInfo.getUserId()
		);
		insert(sap);
	}


	static testMethod void unitTest() {
		TestHelper_MW th = new TestHelper_MW();
		Test.startTest();

		dealer__Sales_Up__c sup = [
			select Id, Name, dealer__Latest_Appointment_Date_Time__c, Follow_Up_Stage__c, 
				dealer__Customer_Account__c, dealer__Salesperson_1__c, dealer__Buyer_Contact__c,
				OwnerId, Company__c
			from dealer__Sales_Up__c
			limit 1
		];
		dealer__Sales_Up__c oldsup = sup.clone();
		sup.dealer__Latest_Appointment_Date_Time__c.addSeconds(2);
		sup.Follow_Up_Stage__c = '1';
		SolutionOppFollowUpTasks.resetFollowupStageIfChanged(
			new List<dealer__Sales_Up__c>{sup}, new Map<Id,dealer__Sales_Up__c>{oldsup.Id=>oldsup}
		);
		update(sup);

		SolutionOppFollowUpTasks ba = new SolutionOppFollowUpTasks('1', false, true);
		Database.executeBatch(ba);

		//List<Task> ts = [select Id from Task limit 1];
		//for(Task t : ts) t.Close_Task__c = true;
		//update(ts);

		SolutionOppFollowUpTasks sofut = new SolutionOppFollowUpTasks(null, false, true);

		List<dealer__Sales_Up__c> objlist = new List<dealer__Sales_Up__c>();
		objlist.add(sup);
		sofut.MapStoreGMs(objlist);

		sup.Follow_Up_Stage__c = '1';
		sup.dealer__Latest_Appointment_Date_Time__c = DateTime.now().addDays(-1);
		sofut.execute(null, objlist);
		sup.Follow_Up_Stage__c = '2';
		sup.dealer__Latest_Appointment_Date_Time__c = DateTime.now().addDays(-2);
		sofut.execute(null, objlist);
		sup.Follow_Up_Stage__c = '3';
		sup.dealer__Latest_Appointment_Date_Time__c = DateTime.now().addDays(-6);
		sofut.execute(null, objlist);
		sup.Follow_Up_Stage__c = '4';
		sup.dealer__Latest_Appointment_Date_Time__c = DateTime.now().addDays(-13);
		sofut.execute(null, objlist);
		sup.Follow_Up_Stage__c = '5';
		sup.dealer__Latest_Appointment_Date_Time__c = DateTime.now().addDays(-29);
		sofut.execute(null, objlist);

/*		sup.Follow_Up_Stage__c='1';
		Task t1 = sofut.generateTask(sup);
		sup.Follow_Up_Stage__c='2';
		Task t2 = sofut.generateTask(sup);
		sup.Follow_Up_Stage__c='3';
		Task t3 = sofut.generateTask(sup);
		sup.Follow_Up_Stage__c='4';
		Task t4 = sofut.generateTask(sup);
		sup.Follow_Up_Stage__c='5';
		Task t5 = sofut.generateTask(sup);
*/
		Test.stopTest();
	}
	
	
	static testMethod void TestCRON() {
		Test.startTest();
		List<String> jobIds = SolutionOppFollowUpTasks.scheduleMe();
		String firstJobId = jobIds[0];

		// Get the information from the CronTrigger API object
		CronTrigger ct = [
			SELECT Id, CronExpression, TimesTriggered, NextFireTime
			FROM CronTrigger 
			WHERE id = :firstJobId
		];

		// Verify the expressions are the same
		System.assertEquals(SolutionOppFollowUpTasks.CRON_LIST[0], ct.CronExpression);

		// Verify the job has not run
		System.assertEquals(0, ct.TimesTriggered);

		Test.stopTest();
	}
	
 }