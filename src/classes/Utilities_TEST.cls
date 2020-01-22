/**
 *
 * Utilities_TEST
 * Tests: FormattingUtility, Utility
 *
 *  2016-11-03  B. Leaman   BLL1 add ExceptionMessages tests
 *  2018-05-21  B. Leaman   BLL2 - test new routine: getUserIdsDelegatedFor & MemberOfGroupHierarchy rtn
 *	2019-02-11	B. Leaman	BLL3 - test new generic future sobject update routine.
 *	2019-03-11	B. Leaman	BLL4 - test new generic SObject creation from json string.
 *	2019-12-12	B. Leaman	W-000788 BLL6 - ability to delete SObjects in the future too.
 */
@isTest
private class Utilities_TEST {

    @testSetup static void setupFFA() {
        Group g1 = new Group(Name='TestGroup1',DeveloperName='TestGroup1');
        Group g2 = new Group(Name='TestGroup2',DeveloperName='TestGroup2');
        insert(new List<Group>{g1,g2});
        GroupMember gm1 = new GroupMember(GroupId=g1.Id,userOrGroupId=g2.Id);
        GroupMember gm2 = new GroupMember(GroupId=g2.Id,userOrGroupId=UserInfo.getUserId());
        insert(new List<GroupMember>{gm1,gm2});
    }

    static testmethod void testUserGroupEmail() {
        Utility.getGroupMbrUserEmails('TestGroup1');
        Map<Id,Group> gmap = Utility.MemberOfGroupHierarchy(UserInfo.getUserId());	// BLL2a
        boolean inTestGroup1 = false;
        boolean inTestGroup2 = false;
        for(Group g : gmap.values()) {
        	if (g.Name=='TestGroup1') inTestGroup1 = true;
        	if (g.Name=='TestGroup2') inTestGroup2 = true;
        }
        System.assert(inTestGroup2, 'User was not found to be in test group 2 (direct member)');
        System.assert(inTestGroup1, 'User was not found to be in test group 1 (indirect via TestGroup2)');
    }

    static testmethod void PhoneFormatTests() {
        System.assertEquals('(123) 555-1212', FormattingUtility.formatPhoneNbr('123.555.1212'),
             '10-digit USA phone number was not properly formatted');
        System.assertEquals('(123) 555-1212', FormattingUtility.formatPhoneNbr('1-123-555-1212'),
             'Long distance USA phone number was not properly formatted');
        System.assertEquals('+01 110-1234562', FormattingUtility.formatPhoneNbr('+01 110-1234562'),
             'Non-USA phone number format was altered');
        System.assertEquals('(123) 555-1212', Utility.formatPhoneNbr('123.555.1212'),
             '10-digit USA phone number was not properly formatted');
        System.assertEquals('(123) 555-1212', Utility.formatPhoneNbr('1-123-555-1212'),
             'Long distance USA phone number was not properly formatted');
        System.assertEquals('+01 110-1234562', Utility.formatPhoneNbr('+01 110-1234562'),
             'Non-USA phone number format was altered');
    }


    static testmethod void ExceptionMessages() {
        try {
            throw new TestException('This is an error message');    // generate an exception
        } catch(Exception e) {
            String s = Utility.friendlyErrorMessage(e);
            System.assert(!String.isBlank(s), 'Did not get a friendly error message from the exception');
        }
    }


    static testmethod void CustomPermissions() {
        boolean hasCP = Utility.hasCustomPermission('Dummy_nonexistent_test_permission');
    }


    static testmethod void ApprovalTest() {
        Map<Id,Group> usergroupmap = Utility.MemberOfGroups(userInfo.getUserId());
        Set<Id> delegates = Utility.getUserIdsDelegateFor(new Set<Id>{UserInfo.getUserId()});   // BLL2a
        Utility.WaitingOnMyApproval(userInfo.getUserId(), new Set<String>{});
        Utility.ProcessApprovalStep(userInfo.getUserId(), 'approve', new Set<String>{}, 'comment');
    }
    
	// BLL3
	static testmethod void testFutureUpdate() {
		Test.startTest();
		User u = new User(Id=UserInfo.getUserId(), Division='TST');
		Utility.updateSObjectFuture(JSON.serialize(u));
		List<User> us = new List<User>();
		us.add(new User(Id=UserInfo.getUserId(), Division='TS2'));
		Utility.updateSObjectsFuture(JSON.serialize(us));
		Test.stopTest();
	}
	// BLL3 end

	// BLL4
	static testmethod void createSobjectFromJSON(){
	  
		Test.startTest();
		dealer__Sales_Appointment__c sa = (dealer__Sales_Appointment__c) Utility.jsonStringToSObject(
			'{"Name":"Test Account","Date_Marked_BDC__c":"2019-03-01","dealer__DateTime__c":"2019-03-01T10:00:00.000Z","dealer__Notes__c":"Test note","MarketingScore__c":15}',
			 dealer__Sales_Appointment__c.SObjectType);
		Test.stopTest();
		//System.assert(sa.Name=='Test Account', 'Did not get the name property of the sobject from json string');
		System.assert(sa.dealer__Notes__c=='Test note', 'Did not get the note property of the sobject from json string');

	}
	// BLL4 end


	// BLL6
	static testmethod void testFutureDelete() {
		TestHelper_MW th = TestHelper_MW.getInstance();
		Account a = th.getBusinessAccount('1');
		List<Contact> contacts = new List<Contact>();
		contacts.add(new Contact(AccountId=a.Id, FirstName='Test1', LastName='Tester'));
		contacts.add(new Contact(AccountId=a.Id, FirstName='Test2', LastName='Tester'));
		insert(contacts);
		
		Test.startTest();
		Utility.deleteSObjectsFuture(JSON.serialize(contacts));
		Utility.deleteSObjectFuture(JSON.serialize(a));
		Test.stopTest();
	}
	// BLL6 end

    class TestException extends Exception {}

}