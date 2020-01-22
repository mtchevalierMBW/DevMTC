/****************************************************************************************
Name            : ffaUtilities
Author          : CLD
Created Date    : 1/14/16
Description     : Contains various methods for FFA Utilities
*****************************************************************************************/

global class ffaUtilities {

	/******************************************************************************/
    /** Method to return a list of the current companies
    /******************************************************************************/
    public static List<c2g__codaCompany__c> getCurrentCompanies()
    {
    	List<c2g__codaCompany__c> allCompanies = [Select id, ownerid, name from c2g__codaCompany__c];
    	Id currentUserId = UserInfo.getUserId();
    	List<c2g__codaCompany__c> myCompanies = new List<c2g__codaCompany__c>();
    	Set<Id> currentUserGroupIds = new Set<Id>();
    	for(GroupMember gm :[SELECT Id, GroupId FROM GroupMember WHERE UseroRGroupId = :currentUserId]) 
    	{
    		currentUserGroupIds.add(gm.GroupId);
    	}
    	for(c2g__codaCompany__c company : allCompanies)
    	{
    		if(currentUserGroupIds.contains(company.ownerid))
    		{
    			myCompanies.add(company);
    		}
    	}
    	return myCompanies;
    }

    /******************************************************************************/
    /** Method to post Journals                                                  **/
    /******************************************************************************/
    public static List<c2g__codaJournal__c> postJournals(List<Id> journalIds)
    {
    	Set<String> companyString = new Set<String>();
        String COMPANY_NAME = '';
    	List<c2g__codaJournal__c> journalList = [SELECT Id, c2g__OwnerCompany__r.Name
    		FROM c2g__codaJournal__c
    		WHERE Id in :journalIds];
    	if(!journalList.isEmpty())
    	{
    		for(c2g__codaJournal__c j : journalList)
	    	{
	    		companyString.add(j.c2g__OwnerCompany__r.Name);
                COMPANY_NAME = j.c2g__OwnerCompany__r.Name;
	    	}
	    	System.assert(companyString.size() <= 1, 'ERROR: You can only post journals for one company at a time');

			c2g.CODAAPICommon_10_0.Context company = new c2g.CODAAPICommon_10_0.Context(); 
	        company.CompanyName = COMPANY_NAME;
	        company.Token = null;

	        List<c2g.CODAAPICommon.Reference> postList = new List<c2g.CODAAPICommon.Reference>();
	        for(c2g__codaJournal__c j : journalList)
	        {
	        	c2g.CODAAPICommon.Reference journalRef = new c2g.CODAAPICommon.Reference();
	        	journalRef.id = j.id;
	        	postList.add(journalRef);
	        }

	        c2g.CODAAPIJournal_12_0.BulkPostJournal(company, postList);	
    	}
        return journalList;
    }

}