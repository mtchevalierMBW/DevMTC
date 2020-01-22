/**
* OpportunityTriggerHandler
* 
* Tested by: OpportunityTriggerHandler_TEST
* Programmer: Alexander Miller
* Date: 2017-09-14
*
* Primary handler class for the opportunity trigger
*
* 9-13-2018 - Alexander Miller - AMILLER1 - Update to remove Profile name query
* 9-19-2018 - Alexander Miller - AMILLER2 - Update to handle MobilityWorks Opportunities
* 9-21-2018 - Alexander Miller - AMILLER3 - W-000370 - Update to assign OpportunityContactRole so pardot will sync correctly. Commented out and moved to nightly batch
*/
public without sharing class OpportunityTriggerHandler{

    public List<Opportunity> newList = new List<Opportunity>();
    public List<Opportunity> oldList = new List<Opportunity>();
    public String currentPofileName;
    public Id profileId;
    public String sysAdmin = 'System Administrator';
    public String accountTransitRecordType = 'TransitWorksOpps';
    public String mobilityWorksOppRecordType = 'MBWC_OppRecordType';
    public Set<String> oppWonStatuses = new Set<String>();
    public Set<String> oppLostStatuses = new Set<String>();
    
    public OpportunityTriggerHandler(){}

    public OpportunityTriggerHandler(Opportunity[] newArray, Opportunity[] oldArray){
        newList = newArray;
        oldList = oldArray;
        profileId = userinfo.getProfileId();
        //AMILLER1
        User u = CurrentUserSingleton.getInstance();
        currentPofileName = u.Profile.Name;
        //currentPofileName = [SELECT Id, Name FROM Profile WHERE Id = :profileId].Name;
        // AMILLER1
        oppWonStatuses.add('Won');
        oppWonStatuses.add('06 - Closed Won');
		oppLostStatuses.add('Lost');
		oppLostStatuses.add('07 - Closed Lost');
    } 

    public void onBeforeUpdate(){
        // TODO uncomment when go-live happens
        //transitOppCannotBeLostWithOpenSalesOrders();
        //transitOppCannotBeWonWithoutSalesOrderUpdate();
    }

    // AMILLER2
    /**
    * mbwBeforeUpdateDefaultOwner
    *
    * Function which ensures the owner field is always set 
    * to the value found in the MBW Custom setting
    */
    public void mbwBeforeUpdateDefaultOwner(List<Opportunity> listOfOpps)
    {
        Id defaultId = getDefaultOpportunityOwner();
        Id mbwOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(mobilityWorksOppRecordType).getRecordTypeId();
        
        System.debug(mbwOppRecordTypeId);
        System.debug(defaultId);

        for(Opportunity tempOpp : listofOpps)
        {
            if(tempOpp.RecordTypeId == mbwOppRecordTypeId && defaultId != null && !String.isEmpty(String.valueOf(defaultId)) && tempOpp.ownerId != defaultId)
            {
                tempOpp.ownerId = defaultId;
            }
            System.debug(tempOpp);
        }
    }

    /**
    * getDefaultOpportunityOwner
    *
    * Function which looks at the custom setting in the org
    * to know which Id should be the default Opportunity Owner
    */
    public static Id getDefaultOpportunityOwner()
    {
        MobilityForceSettings__c oppOwner = MobilityForceSettings__c.getInstance();
        
        System.debug(oppOwner);

        return oppOwner.Standard_Opportunity_Owner__c;
    }
    // AMILLER2

    // AMILLER3
    /**
    * createOpportunityContactRoles
    *
    * Function which looks at the Opportunity information and 
    * creates an OpportunityContactRole so that 
    * Pardot makes the full connection
    *
    * @param 
    */
    // public void createOpportunityContactRoles(List<Opportunity> listOfOpps)
    // {
    //     List<OpportunityContactRole> listOfOppContactRoles = new List<OpportunityContactRole>();
        
    //     Id mbwOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(mobilityWorksOppRecordType).getRecordTypeId();

    //     List<Id> listOfAccountIds = new List<Id>();

    //     for(Opportunity tempOpp : listOfOpps)
    //     {
    //         listOfAccountIds.add(tempOpp.AccountId);
    //     }

    //     List<Contact> listOfContacts = ([SELECT Id, 
    //                                         AccountId,
    //                                         OwnerId
    //                                     FROM Contact 
    //                                     WHERE AccountId IN :listOfAccountIds AND 
    //                                           Contact_Status__c = 'Active']);

    //     for(Opportunity tempOpp : listOfOpps)
    //     {
    //         if(tempOpp.RecordTypeId == mbwOppRecordTypeId && tempOpp.AccountId != null)
    //         {
    //             for(Contact tempCon : listOfContacts)
    //             {
    //                 System.debug(tempCon);

    //                 if(tempCon.AccountId == tempOpp.AccountId)
    //                 {
    //                     OpportunityContactRole tempRole = new OpportunityContactRole();

    //                     tempRole.ContactId = tempCon.Id;
    //                     tempRole.OpportunityId = tempOpp.Id;
    //                     tempRole.Role = 'Decision Maker';

    //                     listOfOppContactRoles.add(tempRole);
    //                 }
    //             }   
    //         }
    //     }

    //     insert listOfOppContactRoles;
    // }
    // AMILLER3

    /**
    * transitOppCannotBeWonWithoutSalesOrderUpdate
    *
    * Function which flags all opportunity updates
    * if said opportunity does not have a sales Order and is trying
    * to be marked as Stage = Won
    */
    public void transitOppCannotBeWonWithoutSalesOrderUpdate(){
        
        // get all of the related Sales Orders
        Map<Id, rstk__sohdr__c> mapOfOppsToSalesOrders = new Map<Id, rstk__sohdr__c>();
        List<rstk__sohdr__c> listOfSalesOrders = getListOfTransitSalesOrders(newList);

        // load all sales orders by making the key ID the opportunity        
        for(rstk__sohdr__c tempSalesOrder : listOfSalesOrders)
        {
            mapOfOppsToSalesOrders.put(tempSalesOrder.rstk__sohdr_opportunity__c, tempSalesOrder);
        }

        // check all of the Opportunities and see if they're not listed
        for(Opportunity tempOpp : newList)
        {
            if(oppWonStatuses.contains(tempOpp.StageName) && 
                mapOfOppsToSalesOrders.get(tempOpp.Id) == null)
            {
                // show error on user's screen
                if(currentPofileName != sysAdmin){
                    tempOpp.addError(Label.OppTransitStageError); 
                }
            }
        }
    }

    /**
    * transitOppCannotBeLostWithOpenSalesOrders
    *
    * Function which flags all opportunity updates
    * if said opportunity does has at least one Sales Order marked as closed
    * and opportunity trying to be marked as Stage = Lost
    */
    public void transitOppCannotBeLostWithOpenSalesOrders(){
        
        // get all of the related Sales Orders
        List<rstk__sohdr__c> listOfSalesOrders = getListOfTransitSalesOrders(newList);

        // check all of the Opportunities and see if they're not listed
        for(Opportunity tempOpp : newList)
        {
            if(oppLostStatuses.contains(tempOpp.StageName))
            {
                Boolean showError = false;
                for(rstk__sohdr__c tempSalesOrder : listOfSalesOrders)
                {
                    if(tempSalesOrder.rstk__sohdr_closed__c == false)
                    {
                        showError = true;
                        break;
                    }
                }
                // show error on user's screen
                if(showError && currentPofileName != sysAdmin){
                    tempOpp.addError(Label.OppTransitChildSalesOrderOpenError); 
                } 
            }
        }
    }

    /**
    * getListOfTransitSalesOrders
    *
    * Helper function to get Sales Orders with their closed and cancelled checkbox
    * along with Opportunity information
    *
    * @param List<Opportunity> - list containing all opportunities possibly tied to Sales Orders
    *
    * @return List<rstk__sohdr__c> - list of Sales Orders found to be Transit Works and related to opps from param
    */
    public List<rstk__sohdr__c> getListOfTransitSalesOrders(List<Opportunity> listOfOpps){
        return ([SELECT Id, 
                rstk__sohdr_closed__c, 
                rstk__sohdr_cancelled__c, 
                rstk__sohdr_opportunity__c 
                FROM rstk__sohdr__c 
                WHERE rstk__sohdr_opportunity__c IN :listOfOpps AND 
                rstk__sohdr_opportunity__r.Account.RecordType.Name = :accountTransitRecordType ]);
    }
}