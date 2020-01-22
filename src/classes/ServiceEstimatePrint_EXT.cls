/**
 * ServiceEstimatePrint_EXT
 * Tested by: ServiceEstimatePrint_EXT_TEST
 * Date: 2019-04-05
 * Programmer: Bryan Leaman
 * Project: W-000645
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *
 * Modifications: 
 *
**/
public with sharing class ServiceEstimatePrint_EXT {
 
	private ApexPages.StandardController stdcontroller;
	public dealer__Service_Estimate__c se;
	public String PrintDateTimeLocal {get;set;}

	// ServiceEstimatePrint_EXT
	//---------------------------------------
	public ServiceEstimatePrint_EXT (ApexPages.StandardController controller) {
		stdcontroller = controller;
		se = (dealer__Service_Estimate__c) stdController.getRecord();
        //TimeZone tz = UserInfo.getTimeZone();
        PrintDateTimeLocal = DateTime.now().format('MM/dd/yyyy h:mm a');
	}

}