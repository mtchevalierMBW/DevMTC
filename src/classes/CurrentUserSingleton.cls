/**
 * CurrentUserSingleton
 * Tested by: CurrentUserSingleton_TEST
 * Date: Jul 27, 2016
 * Programmer: Bryan Leaman
 *
 *	2016-08-16	B. Leaman	BLL1a - add profile id and name (for DealProcessTrigger preventing deletion of deals).
 */
public with sharing class CurrentUserSingleton {

	private static User u;
	
	public static User getInstance() {
		if (u==null) {
			u = [
				select Id, Name, Email, Division, ProfileId, Profile.Name // BLL1c
				from User 
				where Id=:UserInfo.getUserId() 
				limit 1
			];
		}
		return u;
	}
	
}