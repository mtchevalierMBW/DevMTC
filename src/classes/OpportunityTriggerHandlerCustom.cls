/**
* TransitWorks (c) - 2018
* 
* OpportunityTriggerHandlerCustom
* 
* CreatedBy: Alexander Miller
* CreatedDate: 9-21-2018
* Tested By: OpportunityTriggerHandlerCustomTest
* Work Item: W-000361
*
* Primary trigger handler for the custom TransitWorks Opportunity Object
*
* Alexander Miller - AMILLER1 - W-000449 - Update to copy the Account reference to the custom Opp
*/
public class OpportunityTriggerHandlerCustom {
    
    /** currentPofileName - Profile name of the user invoking this class */
    public String currentPofileName;
    
    /** profileId -  Profile id of the user invoking this class */
    public Id profileId;
    
    /** sysAdmin - Text check on the System Admin profile for special privilidges */
    public String sysAdmin = 'System Administrator';

    /** opportunityCreatedStageName - initial value for Opportunities */
    public String opportunityCreatedStageName = 'Pending';

    /** opportunityTransitWorksRecordTypeName - TransitWorks record type name for standard Opportunities */
    public String opportunityTransitWorksRecordTypeName = 'TransitWorksOpps';

    public static List<SlopOppObject> listOfMarriages;

    public OpportunityTriggerHandlerCustom()
    {
        // 1. Set the current user's profile name
        User u = CurrentUserSingleton.getInstance();
        currentPofileName = u.Profile.Name;
    }

    /**
    * checkStatusLegalStatusChange
    *
    * Parent method which helps reduce the number of SOQLs 
    * needed to complete the logic
    */
    public void checkStatusLegalStatusChange(List<Opportunity__c> newList, Map<Id, Opportunity__c> oldMap )
    {
        List<rstk__sohdr__c> listOfSalesOrders = getListOfTransitSalesOrders(newList);

        System.debug(listOfSalesOrders);
        
        transitOppCannotBeWonWithoutSalesOrderUpdate(newList, oldMap, listOfSalesOrders);
        //transitOppCannotBeLostWithOpenSalesOrders(newList, listOfSalesOrders);
    }
    

    /**
    * transitOppCannotBeWonWithoutSalesOrderUpdate
    *
    * Function which flags all opportunity updates
    * if said opportunity does not have a sales Order and is trying
    * to be marked as Stage = Won
    */
    public void transitOppCannotBeWonWithoutSalesOrderUpdate(List<Opportunity__c> newList, Map<Id, Opportunity__c> oldMap, List<rstk__sohdr__c> listOfSalesOrders){
        
        // get all of the related Sales Orders
        Map<Id, rstk__sohdr__c> mapOfOppsToSalesOrders = new Map<Id, rstk__sohdr__c>();

        // load all sales orders by making the key ID the opportunity        
        for(rstk__sohdr__c tempSalesOrder : listOfSalesOrders)
        {
            mapOfOppsToSalesOrders.put(tempSalesOrder.Opportunity_custom__c, tempSalesOrder);
        }
        
        System.debug(mapOfOppsToSalesOrders);

        // check all of the Opportunities and see if they're not listed
        for(Opportunity__c tempOpp : newList)
        {
            if(tempOpp.Status__c == 'Won' && oldMap != null && oldMap.get(tempOpp.Id).Status__c != 'Won' && mapOfOppsToSalesOrders.get(tempOpp.Id) == null)
            {
                // show error on user's screen
                tempOpp.addError(Label.OppTransitStageError); 
            }
        }
        
        System.debug(newList);
    }

    /**
    * transitOppCannotBeLostWithOpenSalesOrders
    *
    * Function which flags all opportunity updates
    * if said opportunity does has at least one Sales Order marked as closed
    * and opportunity trying to be marked as Stage = Lost
    */
    /*
    public void transitOppCannotBeLostWithOpenSalesOrders(List<Opportunity__c> newList, List<rstk__sohdr__c> listOfSalesOrders){
        
        // check all of the Opportunities and see if they're not listed
        for(Opportunity__c tempOpp : newList)
        {
            if(tempOpp.Status__c == 'Lost')
            {
                Boolean showError = false;
                for(rstk__sohdr__c tempSalesOrder : listOfSalesOrders)
                {
                    if(tempSalesOrder.rstk__sohdr_closed__c == false || tempSalesOrder.rstk__sohdr_cancelled__c == false)
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
    */

    /**
    * getListOfTransitSalesOrders
    *
    * Helper function to get Sales Orders with their closed and cancelled checkbox
    * along with Opportunity information
    *
    * @param List<Opportunity__c> - list containing all opportunities possibly tied to Sales Orders
    *
    * @return List<rstk__sohdr__c> - list of Sales Orders found to be Transit Works and related to opps from param
    */
    public List<rstk__sohdr__c> getListOfTransitSalesOrders(List<Opportunity__c> listOfOpps){
        return ([SELECT Id, 
                rstk__sohdr_closed__c, 
                rstk__sohdr_cancelled__c, 
                rstk__sohdr_opportunity__c,
                Opportunity_custom__c
                FROM rstk__sohdr__c 
                WHERE Opportunity_custom__c IN :listOfOpps ]);
    }
    
    public void updateOpportunityIdTextField(List<Opportunity__c> newList)
    {
        List<Opportunity__c> listOfOpps = new List<Opportunity__c>();
        
        for(Opportunity__c tempOpp : newList)
        {
            if(tempOpp.Opportunity_Id__c == null || String.isEmpty(tempOpp.Opportunity_Id__c))
            {
                tempOpp.Opportunity_Id__c = tempOpp.Opportunity__c;
            }
        }
    }

    //AMILLER1
    public void updateAccountReference(List<Opportunity__c> newList)
    {        
        for(Opportunity__c tempOpp : newList)
        {
            if(tempOpp.Account_Id__c != null && tempOpp.Account_Id__c != '' && tempOpp.Account__c == null)
            {
                tempOpp.Account__c = tempOpp.Account_Id__c;
            }
        }
    }
    // AMILLER1

     /**
     * createOpportunityForNewSlops
     *
     * function which takes the list of Custom Opportunities and will create an Opportunity with the initial mappings
     *  
     * @param newList - List<Opportunity__c> trigger.newnewMap of everything being fired
     */
    public void createOpportunityForNewSlops(List<Opportunity__c> newList)
    {
        List<Opportunity> listOfOpps = new List<Opportunity>();

        listOfMarriages = new List<SlopOppObject>();

        for(Opportunity__c tempSlop : newList)
        {
            if(tempSlop.Opportunity__c == null)
            {
                Opportunity tempOpp = createOppforSLOP(tempSlop);

                SlopOppObject tempObj = new SlopOppObject();
                tempObj.setOpp(tempOpp);
                tempObj.setSlop(tempSlop);
                listOfMarriages.add(tempObj);

                listOfOpps.add(tempOpp);
            }
        }
        
        System.debug(listOfMarriages);
        System.debug(listOfOpps);

        insert listOfOpps;

        System.debug(listOfMarriages);
        System.debug(listOfOpps);

        for(SlopOppObject tempMarriage : listOfMarriages)
        {
            tempMarriage.getSlop().Opportunity__c = tempMarriage.getOpp().Id;
        }
    }

    /**
    * syncOpportunityAfterSlopCreation
    *  
    * Function which takes the newly made Custom Opportunities 
    * and assigns their new IDs to existing Opportunities from 
    * createOpportunityForNewSlops()
    *
    * @param 
    */
    public void syncOpportunityAfterSlopCreation(Map<Id, Opportunity__c> newMap)
    {
        List<Opportunity> listOfOppsToUpdate = new List<Opportunity>();

        for(Opportunity__c tempSlop : newMap.values())
        {
            System.debug(tempSlop.Opportunity__c);
            System.debug(tempSlop.Id);
            listOfOppsToUpdate.add(new Opportunity(Id = tempSlop.Opportunity__c, Opportunity__c = tempSlop.Id));
        }

        update listOfOppsToUpdate;
    }

    /**
    * syncChangedFields
    *
    * Function which takes the modified fields and commits them to standard Opportunities
    */
    public void syncChangedFields(Map<Id, Opportunity__c> newMap, Map<Id, Opportunity__c> oldMap)
    {
        List<Opportunity> listOfOpps = new List<Opportunity>();

        for(Opportunity__c tempOpp : newMap.values())
        {
            listOfOpps.add(getModifiedSlopFields(tempOpp, newMap, oldMap));
        }

        update listOfOpps;
    }

    /**
    * createOppforSLOP
    *    
    * Function which takes the current SLOP and assigns it an Opportunity
    *
    * @param tempSlop - dealer__Sales_Up__c individual Custom Opportunity to be synced with Salesforce standard Opportunities
    *
    * @return tempOpp - Opportunity mapped to the Custom Opportunty in the function parameter
    */
    public Opportunity createOppforSLOP(Opportunity__c tempSLOP)
    {
        Opportunity tempOpp = new Opportunity();
        
        tempOpp.Name = tempSLOP.Name != null ? tempSLOP.Name : null;                                                                                    // Name
        tempOpp.AccountId = tempSLOP.Account_Id__c != null ? tempSLOP.Account_Id__c : null;                                                             // Account 
        tempOpp.OwnerId = getDefaultOpportunityOwner();                                                                                                 // Owner
        tempOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(opportunityTransitWorksRecordTypeName).getRecordTypeId();  // Record Type
        tempOpp.CloseDate = tempSLOP.Close_Date__c != null ? tempSLOP.Close_Date__c : System.Today();                                                   // Decision Date (Close Date)
        tempOpp.StageName = tempSlop.Status__c != null ? tempSlop.Status__c : opportunityCreatedStageName;                                              // Status
        tempOpp.Sales_Channel__c = tempSlop.Sales_Channel__c;                                                                                           // Sales Channel
        
        System.debug(tempOpp);
        
        return tempOpp;
    }

    /**
    * getModifiedSlopFields
    *
    * Function which cycles through everything outside the blacklist 
    * of fields for groups for a single record
    * 
    * @param tempSlop - Opportunity__c containing all the newest values 
    * @param oldMap - Map<Id, Opportunity__c> map of the old values in the trigger context
    * @param newMap - Map<Id, Opportunity__c> map of the new values in the trigger context
    * 
    * @return tempOpp - Opportunity containing all of the modifications being monitored in the Solution Opportunity Sync process
    */
    public Opportunity getModifiedSlopFields(Opportunity__c tempSlop, Map<Id, Opportunity__c> newMap, Map<Id, Opportunity__c> oldMap )
    {
        // 1. Set the Opportunity to be the one found on the Solution Opportunity
        Opportunity tempOpp = new Opportunity();
        tempOpp.Id = tempSlop.Opportunity__c;

        System.debug(tempSlop);

        System.debug(oldMap.get(tempSlop.Id));

        // Decision Date / Close Date
        if(tempSlop.Close_Date__c != null && oldMap.get(tempSlop.Id) != null &&  tempSlop.Close_Date__c != oldMap.get(tempSlop.Id).Close_Date__c)
        { 
            tempOpp.CloseDate = tempSlop.Close_Date__c;
        }
        
        // Status / StageName
        if(tempSlop.Status__c != null && tempSlop.Status__c != oldMap.get(tempSlop.Id).Status__c)
        { 
            tempOpp.StageName = tempSlop.Status__c;
        } 

        // Account / Customer
        if(tempSlop.Customer_Master__c != null && tempSlop.Customer_Master__c != oldMap.get(tempSlop.Id).Customer_Master__c)
        { 
            tempOpp.AccountId = tempSlop.Account_Id__c;
        } 
        
        System.debug(tempSlop);
        System.debug(tempOpp);
        
        return tempOpp;
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

    /**
    * SlopOppObject
    *
    * Since the standard HashMap functionality couldn't
    * hold Map<Opportinity, dealer__Sales_Up__c> combo after
    * insert, this sub-class object is meant to hold the 
    * marriage of both records during insertion periods
    */
    public class SlopOppObject
    {
        public Opportunity Opp;

        public Opportunity__c Slop;

        public SlopOppObject(){}

        public void setSlop(Opportunity__c temp)
        {
            this.Slop = temp;
        }

        public void setOpp(Opportunity temp)
        {
            this.opp = temp;
        }

        public Opportunity__c getSlop()
        {
            return this.Slop;
        }

        public Opportunity getOpp()
        {
            return this.Opp;
        }
    }
}