/**
 * LeadTrigger_MW_TEST
 * Tests: LeadTrigger_MW
 */
/**
 * Date        	Programmer 	Description
 * 	2015-08-12  B. Leaman   BLL1 - Test lead ownership change to change open task owner
 *	2018-04-10	B. Leaman	BLL2 - test lead record type upload
 *	2018-12-21	B. Leaman	BLL3 - test failure due to missing subject - use any valid picklist value
 */
@isTest
private class LeadTrigger_MW_TEST {

    @isTest
    private static void StockNumbersFromPardot() {
        TestHelper_MW th = new TestHelper_MW();
        
        //Group g = new Group(Name='TestGroupX', Type='Queue');
        //insert(g);
        Group g = [select Id, Name from Group Where Type='Queue' limit 1];
        
        Test.startTest();
        RecordType rt = th.getRetailLeadRt();
        Lead l = new Lead( RecordTypeId=rt.Id, 
                     FirstName='MyTest', LastName='Lead', 
                     Desired_Vehicles__c='ABCDE',
                     City='Lancaster', State='PA', PostalCode='17601',
                     upload_RecordType__c = 'Commercial',	// BLL2a
                     OwnerId=g.Id
                 );
        insert(l);

        //List<Id> updids = new List<Id>();
        //updids.add(l.Id);

        Lead newlead = [select Id, Name, Desired_Vehicles__c, RecordTypeId	// BLL2c
                        from Lead
                        where Id=:l.Id 
                        limit 1];
		Id rtid1 = newlead.RecordTypeId;	// BLL2a
        newlead.Desired_Vehicles__c = '12345';
        newlead.upload_RecordType__c = 'Retail';	// BLL2a
        upsert(newlead);
        
        // Create a task to trigger response time calcs
		// BLL3
		Schema.DescribeFieldResult dfr = Task.Subject.getDescribe();
		List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
		// BLL3
        Task t = new Task(WhoId = newlead.Id, ActivityDate = Date.today(),
                          Status='Not started',
						  Subject=plvs[0].getLabel(),	// BLL3
                          Description = l.Description);
        insert(t);

        newlead = [select Id, Name, Desired_Vehicles__c, RecordTypeId	// BLL2c
                        from Lead
                        where Id=:l.Id 
                        limit 1];
		Id rtid2 = newlead.RecordTypeId;	// BLL2a
        newlead.Desired_Vehicles__c = 'abcde';
        newlead.City='Louisville'; newlead.State='OH'; newlead.PostalCode='44641';
        upsert(newlead);

        // Try something else
        Lead finallead = [select Id, Name, Desired_Vehicles__c 
                        from Lead
                        where Id=:l.Id 
                        limit 1];
        //System.assertEquals( 'ABCDE; 12345', finallead.Desired_Vehicles__c);
        finallead.Desired_Vehicles__c = 'abcde;';
        upsert(finallead);

        l.OwnerId=UserInfo.getUserId();
        l.Status='Unqualified';
        update(l);

        // BLL1a begin test lead owner change
        User u = th.getTestUser('1');
        newlead.OwnerId = u.Id;
        update(newlead);
        // BLL1a end
        
        Test.stopTest();

        Lead extendedtest = [select Id, Name, Desired_Vehicles__c, Store_Location__c 
                        from Lead
                        where Id=:l.Id 
                        limit 1];
        //System.assertEquals( 'abcde;', extendedtest.Desired_Vehicles__c);
        System.debug(extendedtest.Store_Location__c);


        // check for response times
        Lead msrtimes = [
             select Id, Name, Time_In_Queue__c, Response_Time_BDC__c, BusHrs_Time_In_Queue__c, BusHrs_Response_Time_BDC__c
             from Lead 
             where Id=:l.Id
        ];
        System.debug(msrtimes);

        // BLL1a begin
        // check related task ownership
        Task newt = [select Id, Subject, OwnerId from Task where Id=:t.Id limit 1]; 
        System.assertEquals(u.Id, newt.OwnerId, 'Task owner did not get changed');
        // BLL1a end

		System.assert(rtid1==rtid2, 'Record type was updated via upload_RecordType__c field and should not have been.');	// BLL2a        
    }

}