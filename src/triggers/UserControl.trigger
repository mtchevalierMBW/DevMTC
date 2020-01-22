/**
    UserControl
    Tested by: UserControl_TC
    
    Coverage:
    2018-04-04	77% (24/31)
	2019-02-08	100%	(39/39)
	2019-12-19	95%	(43/45)
    
    2016-11-15  B. Leaman   BLL1 - Automatically switch user role if the role starts with a division
                            and the division is being changed (a store person switching stores).
	2019-02-08	B. Leaman	W-000588 BLL2 - also automatically move regional managers to new region when
							they select a store in a different region. Note, may need to go up 2 levels
							when there is a multi-store role between the store and the region.	
							Also move update to future method since lightning is preventing the role id update.
    2019-12-06  J. Pritt    JRP1 - Autofill dealer.dealership_location__c  Already filling MBW Version                             
	2019-12-19	B. Leaman	W-000805 BLL3 - Don't require division if user doesn't have a DealerTeam license type (Dealerteam_License_Type__c)
 */
trigger UserControl on User (before insert, before update) {

	// BLL3
	Set<String> Divisions = new Set<String>();
	for(User u : Trigger.new) if (!String.isBlank(u.Division)) Divisions.add(u.Division);
	// BLL3 end

    // Get a Map of the Dealership Locations
    // BLL3
	LocationsSingleton ls = LocationsSingleton.getInstance();
	ls.addLocationAbbrevs(Divisions);
	//List<dealer__Dealer_Location__c> locations = [Select Id, Name, dealer__Company_Number__c, dealer__Service_Director__c from dealer__Dealer_Location__c];
    //Map<String, String> locationMap = new Map<String, String>();
    //Map<String, String> locationSVD = new Map<String, String>();
    //for(dealer__Dealer_Location__c l : locations) {
    //    locationMap.put(l.dealer__Company_Number__c, l.Name);
    //    if(l.dealer__Service_Director__c!=null) locationSVD.put(l.dealer__Company_Number__c, l.dealer__Service_Director__c);
    //}
	// BLL3 end

    for(User u : trigger.new) {

        // BLL2 - tichten up code for coverage
		//if(u.Division==null||u.Division=='') {
        //    u.addError('User Division Must be Set to a valid DealerLocation Company Number');
        //    return;
        //}
		// BLL3
		//if(String.isBlank(u.Division)) u.addError('User Division must be Set to a valid DealerLocation Company Number');
		if (!String.isBlank(u.Dealerteam_License_Type__c) && u.Dealerteam_License_Type__c!='None') {
			if(String.isBlank(u.Division)) u.addError('DealerTeam User\'s Division must be Set to a valid Dealer Location Company Number');
		}
		String StoreName = null;
		dealer__Dealer_Location__c loc;
		if (!String.isBlank(u.Division)) loc = ls.getLocationByAbbrev(u.Division);
		StoreName = loc!=null ? loc.Name : null;
		u.Dealership_Location__c = StoreName;
		// JRP1
        u.dealer__Dealership_Location__c = StoreName;	
		// JRP1 end
		//} else {
		//	u.Dealership_Location__c = null;
		//	u.dealer__Dealership_Location__c = null;
		//}
		// BLL3 end
		// BLL2 end
        
		// BLL3
        //if(locationMap.containsKey(u.Division)) {
        //    // We have a valid Key, save User Division
        //    u.Dealership_Location__c = String.valueOf(locationMap.get(u.Division));
        //    //if(locationSVD.get(u.Division)!=null) {
        //    //    u.service_manager__c = String.valueOf(locationSVD.get(u.Division));
        //    //}
        //}
		// BLL3 end

    }

    // BLL1a - When a store user changes stores, reflect the change in their role hierarchy too unless
    // they're not assigned to a store-related role to begin with or the new location
    // doesn't match their role or the newly constructed role name doesn't exist.
    MW_TriggerControls__c UserDivisionRoleChg = MW_TriggerControls__c.getInstance('UserDivisionRoleChg');
	// BLL2 - separate control to turn off regional role switch, but it's subservient to UserDivisionRoleChg
	MW_TriggerControls__c UserRegionRoleChg = MW_TriggerControls__c.getInstance('UserRegionRoleChg');
	Map<Id,User> updUsers = new Map<Id,User>();
	// BLL2 end
    if (UserDivisionRoleChg==null || UserDivisionRoleChg.Enabled__c) {
        boolean divChange = false;
        for(User u : Trigger.new) {
            User oldu = (Trigger.oldMap!=null) ? Trigger.oldMap.get(u.Id) : null;
            if (oldu!=null && oldu.Division!=u.Division) divChange = true;
        }
        System.debug('divChange='+String.valueOf(divChange));

        Map<String,UserRole> roleNameMap = new Map<String,UserRole>();
		// BLL2 (switching over to developer name and pulling in parentroleid!)
        //Map<Id,UserRole> roleMap = new Map<Id,UserRole>([select Id, Name from UserRole]);
        //for(UserRole r : roleMap.values()) roleNameMap.put(r.Name,r);
		Map<Id,UserRole> roleMap = new Map<Id,UserRole>([select Id, Name, DeveloperName, ParentRoleId from UserRole]);
		for(UserRole r : roleMap.values()) roleNameMap.put(r.DeveloperName,r);
		// BLL2

        for(User u : Trigger.New) {
            User oldu = (Trigger.oldMap!=null) ? Trigger.oldMap.get(u.Id) : null;
			// BLL2 original logic: assign new role based on swapping store abbrev in role name
			System.debug(u);
			System.debug(oldu);
            if (oldu!=null && divChange==true) {
                UserRole oldrole = roleMap.get(oldu.UserRoleId);
                System.debug(oldrole);
                //if (oldrole!=null && oldrole.Name.startsWith(oldu.Division)) {
                    String newrolename;
					// BLL2
                    //if (oldrole!=null) newrolename = u.Division + oldrole.Name.removeStart(oldu.Division);
                    if (oldrole!=null && !String.isBlank(oldu.Division)) newrolename = u.Division + oldrole.DeveloperName.removeStart(oldu.Division);
					// BLL2 end
                    System.debug(newrolename);
                    Id newroleid = roleNameMap.containsKey(newrolename) ? roleNameMap.get(newrolename).Id : null;
                    System.debug(newroleid);
                    //if (oldrole!=null && oldrole.Name.startsWith(oldu.Division) && newroleid!=null) u.UserRoleId = newroleid;
                    if (oldrole!=null && !String.isBlank(oldu.Division) && oldrole.DeveloperName.startsWith(oldu.Division) && newroleid!=null) 
						updUsers.put(u.Id, new User(Id=u.Id, UserRoleId = newroleid));
                //}

				// BLL2 assign new regional role if new store role's parent role differs from the old one and user is in the old store's parent role
				if (UserRegionRoleChg==null || UserRegionRoleChg.Enabled__c) {
					UserRole oldstorerole = roleNameMap.get(oldu.Division + '_Store');
					UserRole newstorerole = roleNameMap.get(u.Division + '_Store');
					// Get parent role...
					if (oldstorerole!=null) oldstorerole = roleMap.get(oldstorerole.ParentRoleId);
					if (newstorerole!=null) newstorerole = roleMap.get(newstorerole.ParentRoleId);
					// Go up an extra level to get to a region?
					if (oldstorerole!=null && !oldstorerole.DeveloperName.contains('Region')) oldstorerole = roleMap.get(oldstorerole.ParentRoleId);
					if (newstorerole!=null && !newstorerole.DeveloperName.contains('Region')) newstorerole = roleMap.get(newstorerole.ParentRoleId);
					// Get the role Ids
					Id oldrgnid = oldstorerole!=null ? oldstorerole.Id : null;
					Id newrgnid = newstorerole!=null ? newstorerole.Id : null;
					if (oldrgnid!=null && newrgnid!=null && oldrgnid!=newrgnid && u.UserRoleId==oldrgnid) 
						updUsers.put(u.Id, new User(Id=u.Id, UserRoleId = newrgnid));
				}
				// BLL2

            }
        }

		// BLL2
		if (updUsers.size()>0) Utility.updateSObjectsFuture(JSON.serialize(updUsers.values()));
		// BLL2 end

    }
    // BLL1a end

}