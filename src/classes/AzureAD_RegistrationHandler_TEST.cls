/**
* AzureAD_RegistrationHandler_TEST
* Tests: AzureAD_RegistrationHandler
* Date: 2019-01-23
* Programmer: Bryan Leaman
*
*/
@isTest
private class AzureAD_RegistrationHandler_TEST {

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		AzureAD_RegistrationHandler ad = new AzureAD_RegistrationHandler();
		ad.createUser(null, null);
		ad.updateUser(null, null, null);
	}

}