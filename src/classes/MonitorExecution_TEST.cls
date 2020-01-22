/**
 * MonitorExecution_TEST
 * Tests: MonitorExecution
 * Programmer: Bryan Leaman
 * Date: 2015-10-27
 * 
 *	2016-01-12	B. Leaman	BLL1 Create a group to test with.
 */
@isTest
private class MonitorExecution_TEST {

	//@testSetup static void methodName() {
    //	// Create a group
    //	Group g = new Group(Name='MONITOR_EXECUTION_Test_Group_1', Type='Regular');
    //	insert(g);
    //	try {
    //		GroupMember m = new GroupMember(GroupId=g.Id, userOrGroupId=UserInfo.getUserId());
    //		insert(m);
    //	} catch(Exception e) {}
	//}
	
    static testMethod void unitTest1 () {

		Group g = null;
		try {
			g = [select Id, Name from Group where Type='Regular' limit 1];
		} catch(Exception e) {}

    	MonitorExecution__c mesetting = new MonitorExecution__c(Name='Testing', Enabled__c=true, AdminName__c='Bryan Leaman', NotificationType__c='Email' );
		mesetting.GroupEmail__c = (g!=null) ? g.Name : null;
    	insert(mesetting);
    	
    	Test.startTest();
        MonitorExecution monitor = new MonitorExecution('Testing');
        monitor.log('Test entry');
        User admin = monitor.getAdmin();
        String s = monitor.getSubject();
        String t = monitor.getLogText();
        String u = monitor.getUserAndOrg();
        monitor.createLogTask();
        monitor.notifyAdmin();
        Test.stopTest();
    }

}