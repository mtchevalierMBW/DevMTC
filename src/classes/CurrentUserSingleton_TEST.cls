/**
 * CurrentUserSingleton_TEST
 * Tests: CurrentUserSingleton
 * Date: Jul 27, 2016
 * Programmer: Bryan Leaman
 *
 */
@isTest
private class CurrentUserSingleton_TEST {

	// unitTest
	//---------------------------------------
	static testMethod void unitTest() {
		User u = CurrentUserSingleton.getInstance();
		User u2 = CurrentUserSingleton.getInstance();
	}

}