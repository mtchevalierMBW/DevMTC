/**
* MobilityWorks (c) - 2018
*
* SalesUpMBWContactOppHandler 
*
* Created By: Alexander Miller
* Tested By: SalesUpMBWContactOppHandlerTest
* Description:
*
* Class which is not restrictied by license to sync with Salesforce standard Opportunities.
*
* 9/13/2018 - Alexander Miller - AMILLER1 - Update to use fewer resources in trigger updates
* 9/19/2018 - Alexander Miller - AMILLER2 - W-000370 - Update to make all Opportunities owned by IT Department from Custom Setting
* 11/22/2018 - Alexander Miller - AMM3 - IR-0044276 - update to help prevent issues with batches invoking future methods
* 12/11/2018 - Alexander Miller - AMM4 - IR-0045402 - Update to handle null pointer on the Total Proposal Gross
* 2019-07-19	B. Leaman	W-000720 BLL1 - Copy GCLID__c (Google Click ID) into opportunity
*/
public without sharing class SalesUpMBWContactOppHandler {

    public SalesUpMBWContactOppHandler(){}
    
    public static String opportunityCreatedStageName = 'Pending';

    public static String opportunityMobilityWorksRecordType = 'MBWC_OppRecordType';

    public static String salesChannelMBW_Na = 'MBW N/A';

    private static boolean run = true; // AMILLER1

    // AMILLER1
    /**
    * runOnce
    *
    * Function which helps prevent duplicate calls during updates
    */
    public static boolean runOnce()
    {
        if(run)
        {
            run=false;
            return true;
        }
        else
        {
            return run;
        }
    }
    // AMILLER1
    
    /**
     * syncOpportunity
     *
     * function which takes the list of Solution Opportunities and will update an existing Opportunity if any chosen 
     * fields are also modified on the Solution Opportunity
     * 
     * @param newMap - Map<Id, dealer__Sales_Up__c> trigger.newMap of everything being fired
     * @param newMap - Map<Id, dealer__Sales_Up__c> trigger.oldMap of everything being fired
     */
    public static void syncOpportunity(Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap)
    {      
        // 1. Get all the "tracked fields" and see if any of them are modified
        List<dealer__Sales_Up__c> listOfModifiedSLOPs = new List<dealer__Sales_Up__c>();
        List<Id> listOfModifiedSLOPIds = new List<Id>();

        for(Id tempSalesUpId : newMap.keySet())
        {
            // 1A. Opportunity isn't blank and its brand new record
            if(newMap.get(tempSalesUpId).Opportunity__c != null && oldMap == null)
            {
                listOfModifiedSLOPIds.add(tempSalesUpId);
            }
            // 1B. Opportunity isn't blank and its not new and the tracked fields are modified
            else if(newMap.get(tempSalesUpId).Opportunity__c != null && oldMap != null && oldMap.get(tempSalesUpId) != null && isSolutionOpportunityChanged(newMap.get(tempSalesUpId), oldMap.get(tempSalesUpId)))
            {
                listOfModifiedSLOPIds.add(tempSalesUpId);
            }
        }

        // 2. Get the total proposal amounts and see if they are different than the Amount field on the Opportunity
        List<Opportunity> listOfOpportunities = getAllRelatedOpportunities(newMap.values());

        System.debug(listOfOpportunities);

        Map<Id, Decimal> mapOfTotalRollups = getTotalWonProposalAmountBySLOP(newMap.values());

        for(Opportunity tempOpp : listOfOpportunities)
        {
            if(tempOpp.Solution_Opportunity__c != null && tempOpp.Amount != mapOfTotalRollups.get(tempOpp.Solution_Opportunity__c))
            {
                listOfModifiedSLOPIds.add(tempOpp.Solution_Opportunity__c);
            }
        }

        System.debug(listOfModifiedSLOPIds);

        // 3. If any Opportunity field is old, then call the future method with the Ids
        // AMM3
        //if(listOfModifiedSLOPIds.size() > 0)
        if(listOfModifiedSLOPIds.size() > 0 && System.isBatch() == false)
        // AMM3
        if(listOfModifiedSLOPIds.size() > 0)
        {
			System.debug(listOfModifiedSLOPIds);
            syncSolutionOpportunityToOpportunity(listOfModifiedSLOPIds);
        }
    }

    /** 
    * syncSolutionOpportunityToOpportunity
    *
    * Function which syncs the Opportunities found to be different from Solution
    * Opportunities
    *
    * @param solutionOpportunityIdList - list of Ids for Solution Opportunities with changes
    */
    @future(callout = true)
    public static void syncSolutionOpportunityToOpportunity(List<Id> solutionOpportunityIdList)
    {

        List<dealer__Sales_Up__c> listOfSolutionOpportunities = ([SELECT Id,
                                                                        OwnerId,
                                                                        Opportunity__c,
                                                                        Decision_Date__c,
                                                                        BDC_Created__c,
                                                                        dealer__Lead_Status__c,
                                                                        BuyerContact__c,
                                                                        dealer__Lead_Type__c,
                                                                        dealer__Source__c,
                                                                        Solution_Type__c,
																		GCLID__c,	// BLL1
                                                                        dealer__Store_Location__c
                                                                    FROM dealer__Sales_Up__c 
                                                                    WHERE Id IN :solutionOpportunityIdList]);

        System.debug(listOfSolutionOpportunities);

        List<Id> listOfOpportunityIds = new List<Id>();

        for(dealer__Sales_Up__c tempSalesUp : listOfSolutionOpportunities)
        {
            if(tempSalesUp.Opportunity__c != null)
            {
                listOfOpportunityIds.add(tempSalesUp.Opportunity__c);
            }
        }

        System.debug(listOfOpportunityIds);

        Map<Id, Opportunity> mapOfOpportunities = new Map<Id, Opportunity>([SELECT Id,
                                                                                OwnerId,
                                                                                Amount,
                                                                                CloseDate,
                                                                                BDC_Created__c,
                                                                                StageName,
                                                                                Buyer_Contact__c,
                                                                                Lead_Type__c,
                                                                                LeadSource,
                                                                                Solution_Type__c,
																				GCLID__c, 	// BLL1
                                                                                Store_Location__c
                                                                            FROM Opportunity
                                                                            WHERE Id IN :listOfOpportunityIds]);

        System.debug(mapOfOpportunities);

        List<Opportunity> listOfModifiedFieldOpps = new List<Opportunity>();
        List<dealer__Sales_Up__c> listOfModifiedSolutionOpps = new List<dealer__Sales_Up__c>();
        
        for(dealer__Sales_Up__c tempSalesUp : listOfSolutionOpportunities)
        {
            if(tempSalesUp.Opportunity__c != null)
            {
                listOfModifiedFieldOpps.add(getModifiedSlopFields(mapOfOpportunities.get(tempSalesUp.Opportunity__c),tempSalesUp)); // add opp to first param
                listOfModifiedSolutionOpps.add(tempSalesUp);
			}
        }

        System.debug(listOfModifiedFieldOpps);

        System.debug(listOfModifiedSolutionOpps);
        
        // 2. Grab all the rollups of the children proposals
        Map<Id, Decimal> mapOfTotalRollups = getTotalWonProposalAmountBySLOP(listOfModifiedSolutionOpps);
        System.debug(mapOfTotalRollups);
        
        Map<Id, Opportunity> mapOfOpps = new Map<Id, Opportunity>();
        mapOfOpps.putAll(listOfModifiedFieldOpps);
        
        for(dealer__Sales_Up__c tempSlop : listOfModifiedSolutionOpps)
        {
           	if(mapOfOpportunities.get(tempSlop.Opportunity__c).Amount != mapOfTotalRollups.get(tempSlop.Id))
       	    {
   	        	mapOfOpps.get(tempSlop.Opportunity__c).Amount = mapOfTotalRollups.get(tempSlop.Id);   
            }
        }

        System.debug(mapOfOpps.values());
        
        update mapOfOpps.values();
    }

    /**
    * isSolutionOpportunityChanged
    *
    * Function which quickly tells if any tracked field is 
    * modified
    *
    * @param oldSlop - OldMap Solution Opportunity
    * @param newSlop - newMap Solution Opportunity
    *
    * Boolean - True if modified, false if not
    */
    public static Boolean isSolutionOpportunityChanged(dealer__Sales_Up__c oldSlop, dealer__Sales_Up__c newSlop)
    {
        String meaningfulDataOld = oldSlop.Name + ';' + 
                                oldSlop.Decision_Date__c + ';' + 
                                oldSlop.BDC_Created__c + ';' + 
                                oldSlop.dealer__Lead_Status__c + ';' + 
                                oldSlop.BuyerContact__c + ';' + 
                                oldSlop.dealer__Lead_Type__c + ';' + 
                                oldSlop.dealer__Source__c + ';' + 
                                oldSlop.Solution_Type__c + ';'  + 
								oldSlop.GCLID__c + ';' +	// BLL1a
                                oldSlop.dealer__Store_Location__c + ';';
        String meaningfulDataNew = newSlop.Name + ';' + 
                                newSlop.Decision_Date__c + ';' + 
                                newSlop.BDC_Created__c + ';' + 
                                newSlop.dealer__Lead_Status__c + ';' + 
                                newSlop.BuyerContact__c + ';' + 
                                newSlop.dealer__Lead_Type__c + ';' + 
                                newSlop.dealer__Source__c + ';' + 
                                newSlop.Solution_Type__c + ';' + 
								newSlop.GCLID__c + ';' +	// BLL1a
                                newSlop.dealer__Store_Location__c + ';';

        if(meaningfulDataOld == meaningfulDataNew)
        {
            return false;
        }
        else 
        {
            return true;
        }
    }

    /**
    * getAllRelatedOpportunities
    *
    * Function which grabs all Opportunities tied to the 
    * solution opportunities
    *
    * @param listOfSLOPs - list of Solution Opportunities to focus on
    */
    public static List<Opportunity> getAllRelatedOpportunities(List<dealer__Sales_Up__c> listOfSLOPs)
    {
        List<Id> listOfOppIds = new List<Id>();

        for(dealer__Sales_Up__c tempSLOP : listOfSLOPs)
        {
            if(tempSLOP.Opportunity__c != null)
            {
                listOfOppIds.add(tempSLOP.Opportunity__c);
            }
        }

        return ([SELECT Id,
                    Amount,
                    Solution_Opportunity__c 
                FROM Opportunity 
                WHERE Id IN :listOfOppIds]);
    }
    // AMILLER2

    /**
     * createOpportunityForNewSlops
     *
     * function which takes the list of Solution Opportunities and will create an Opportunity with the initial mappings
     *  
     * @param newList - List<dealer__Sales_Up__c> trigger.newnewMap of everything being fired
     */
    public static void createOpportunityForNewSlops(List<dealer__Sales_Up__c> newList)
    {
        List<Opportunity> listOfOpps = new List<Opportunity>();

        List<SlopOppObject> listOfMarriages = new List<SlopOppObject>();

        for(dealer__Sales_Up__c tempSlop : newList)
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

        insert listOfOpps;
        
        for(SlopOppObject tempMarriage : listOfMarriages)
        {
            tempMarriage.getSlop().Opportunity__c = tempMarriage.getOpp().Id;
        }
	}

    /**
    * syncOpportunityAfterSlopCreation
    *  
    * Function which takes the newly made Solution Opportunities 
    * and assigns their new IDs to existing Opportunities from 
    * createOpportunityForNewSlops()
    *
    * @param 
    */
    public static void syncOpportunityAfterSlopCreation(Map<Id, dealer__Sales_Up__c> newMap)
    {
        List<Opportunity> listOfOppsToUpdate = new List<Opportunity>();

        for(dealer__Sales_Up__c tempSlop : newMap.values())
        {
            System.debug(tempSlop);
            
            listOfOppsToUpdate.add(new Opportunity(Id = tempSlop.Opportunity__c, Solution_Opportunity__c = tempSlop.Id));
        }

        update listOfOppsToUpdate;
    }
    
    /**
	* createOppforSLOP
	*	 
	* Function which takes the current SLOP and assigns it an Opportunity
	*
	* @param tempSlop - dealer__Sales_Up__c individual Solution Opportunity to be synced with Salesforce standard Opportunities
	*
	* @return tempOpp - Opportunity mapped to the Solution Opportunty in the function parameter
	*/
    public static Opportunity createOppforSLOP(dealer__Sales_Up__c tempSLOP)
    {
        System.debug(tempSLOP);

        Id defaultOwner = getDefaultOpportunityOwner();

        System.debug(defaultOwner);

    	Opportunity tempOpp = new Opportunity();
        
        tempOpp.Name = tempSLOP.Name != null && String.isEmpty(tempSLOP.Name) == false ? tempSLOP.Name : 'SalesUpMBWContactOppHandler';             // Name
        tempOpp.AccountId = tempSLOP.dealer__Customer_Account__c != null ? tempSLOP.dealer__Customer_Account__c : null; 						    // Account 
        tempOpp.OwnerId = defaultOwner != null ? defaultOwner : tempSLOP.OwnerId;														            // Owner
        tempOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(opportunityMobilityWorksRecordType).getRecordTypeId();	// Record Type
        tempOpp.CloseDate = tempSLOP.Decision_Date__c != null ? tempSLOP.Decision_Date__c : System.Today();											// Decision Date (Close Date)
        tempOpp.BDC_Created__c = tempSLOP.BDC_Created__c;																							// BDC Created
        tempOpp.StageName = tempSlop.dealer__Lead_Status__c != null ? tempSlop.dealer__Lead_Status__c : opportunityCreatedStageName;				// Status
        tempOpp.Buyer_Contact__c = tempSLOP.BuyerContact__c != null ? tempSLOP.BuyerContact__c : null;												// Buyer Contact
        tempOpp.Lead_Type__c = tempSLOP.dealer__Lead_Type__c != null ? tempSLOP.dealer__Lead_Type__c : null;										// Lead Type
        tempOpp.LeadSource = tempSLOP.dealer__Source__c != null ? tempSLOP.dealer__Source__c : null;    											// Source
        tempOpp.Solution_Type__c = tempSLOP.Solution_Type__c != null ? tempSLOP.Solution_Type__c : null;											// Solution Type
        tempOpp.Store_Location__c = tempSLOP.dealer__Store_Location__c != null ? tempSLOP.dealer__Store_Location__c : null;							// Store
        tempOpp.Sales_Channel__c = salesChannelMBW_Na;																								// Sales Channel
		tempOpp.GCLID__c = tempSLOP.GCLID__c;	// BLL1a																						
        
        return tempOpp;
    }
    
    /**
    * getModifiedSlopFields
    *
    * Function which cycles through everything outside the blacklist 
    * of fields for groups for a single record
    * 
    * @param tempSlop - dealer__Sales_Up__c containing all the newest values 
    * @param oldMap - Map<Id, dealer__Sales_Up__c> map of the old values in the trigger context
    * @param newMap - Map<Id, dealer__Sales_Up__c> map of the new values in the trigger context
    * 
    * @return tempOpp - Opportunity containing all of the modifications being monitored in the Solution Opportunity Sync process
    */
    public static Opportunity getModifiedSlopFields(Opportunity tempOppParam, dealer__Sales_Up__c tempSlop )
    {
        // 1. Set the Opportunity to be the one found on the Solution Opportunity
        Opportunity tempOpp = new Opportunity();
        tempOpp.Id = tempSlop.Opportunity__c;

        System.debug(tempSlop);

        // Owner
        Id defaultOwner = getDefaultOpportunityOwner(); 
        if(defaultOwner != null && tempOppParam.OwnerId != defaultOwner)
        {
            tempOpp.OwnerId = defaultOwner;
        }

        // Decision Date / Close Date
        if(tempSlop.Decision_Date__c != null && tempSlop.Decision_Date__c != tempOppParam.CloseDate)
        { 
            tempOpp.CloseDate = tempSlop.Decision_Date__c;
        }
        
        // BDC Created
        if(tempSlop.BDC_Created__c != null && tempSlop.BDC_Created__c != tempOppParam.BDC_Created__c)
        { 
            tempOpp.BDC_Created__c = tempSlop.BDC_Created__c;
        }
        
        // Status / StageName
        if(tempSlop.dealer__Lead_Status__c != null && tempSlop.dealer__Lead_Status__c != tempOppParam.StageName)
        { 
            tempOpp.StageName = tempSlop.dealer__Lead_Status__c;
        }
       
        // Buyer Contact
        if(tempSlop.BuyerContact__c != null && tempSlop.BuyerContact__c != tempOppParam.Buyer_Contact__c)
        { 
            tempOpp.Buyer_Contact__c = tempSlop.BuyerContact__c;
        }
        
        // Lead Type
        if(tempSlop.dealer__Lead_Type__c != null && tempSlop.dealer__Lead_Type__c != tempOppParam.Lead_Type__c)
        { 
            tempOpp.Lead_Type__c = tempSlop.dealer__Lead_Type__c;
        }
        
        // Source / Lead Source
        if(tempSlop.dealer__Source__c != null && tempSlop.dealer__Source__c != tempOppParam.LeadSource)
        { 
            tempOpp.LeadSource = tempSlop.dealer__Source__c;
        }
        
        // Solution Type
        if(tempSlop.Solution_Type__c != null && tempSlop.Solution_Type__c != tempOppParam.Solution_Type__c)
        { 
            tempOpp.Solution_Type__c = tempSlop.Solution_Type__c;
        }
        
		// BLL1
		if(tempSlop.GCLID__c != null && tempSlop.GCLID__c != tempOppParam.GCLID__c) {
			tempOpp.GCLID__c = tempSlop.GCLID__c;
		}
		// BLL1 end

        // Store Location
        if(tempSlop.dealer__Store_Location__c != null && tempSlop.dealer__Store_Location__c != tempOppParam.Store_Location__c)
        { 
            tempOpp.Store_Location__c = tempSlop.dealer__Store_Location__c;
        }
        
        System.debug(tempSlop);
        System.debug(tempOpp);
        
        return tempOpp;
    }
    
    /**
     * getTotalWonProposalAmountBySLOP
     * 
     * Function which gathers all of the total prices of children Porposals related 
     * to the Solution Opportunities found in the function parameter
     * 
     * @param listOfSlops - List<dealer__Sales_Up__c> list of Solution Opportunities fired in this trigger
     * 
     * @return Map<Id, Decimal> - map where the key is the Solution Opportunity found. The value is the total price of all won proposals below it
     */
    public static Map<Id, Decimal> getTotalWonProposalAmountBySLOP(List<dealer__Sales_Up__c> listOfSlops)
    {
        Map<Id, Decimal> returningMap = new Map<Id, Decimal>();
        
        List<dealer__Deal__c> listOfRelatedWonProposals = ([SELECT Id,
                                                            	dealer__Sales_Lead__c,							                        // Solution Opportunity
                                                                Total_Proposal_Gross__c                                                 // Total Proposal Gross (before Commissions)
                                                           FROM dealer__Deal__c
                                                           WHERE dealer__Sales_Lead__c IN :listOfSlops AND		                        // Get all related to the bulkified Solution Opportunity List
                                                           	dealer__Status__c IN ('Won - Delivered', 'Won - Posted')]);					// Won status only
        
        // Bucket the individual amounts by Solution Opportunity Id to be applied to Salesforce Opportunities later
        for(dealer__Deal__c proposal : listOfRelatedWonProposals)
        {
            // AMM4
            if(proposal.Total_Proposal_Gross__c != null)
            {      
            // AMM4      
	        	if(returningMap.get(proposal.dealer__Sales_Lead__c) == null)
	            {
	                returningMap.put(proposal.dealer__Sales_Lead__c, proposal.Total_Proposal_Gross__c);
	            }
	            else
	            {
	                Decimal originalAmount = returningMap.get(proposal.dealer__Sales_Lead__c);
	
	                originalAmount = originalAmount + proposal.Total_Proposal_Gross__c;
	
	                returningMap.put(proposal.dealer__Sales_Lead__c, originalAmount);
	            }
            // AMM4
            }
            // AMM4
        }
        
        System.debug(returningMap);
        
        return returningMap;
    }

    // AMILLER1
    /**
    * isAllowedToRun
    *
    * Function which checks the custom Setting MW Trigger Controls
    * and sees if an Administrator is currently allowing this class to run
    */
    public static Boolean isAllowedToRun()
    {
        MW_TriggerControls__c SyncSolutionOpps = MW_TriggerControls__c.getInstance('SyncSolutionOpps');
        
        System.debug(SyncSolutionOpps);

        if (SyncSolutionOpps ==null || SyncSolutionOpps.Enabled__c) 
        {
            return true;
        }
        else 
        {
           return false;
        }
    }
    // AMILLER1

    // AMILLER2
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

        public dealer__Sales_Up__c Slop;

        public SlopOppObject(){}

        public void setSlop(dealer__Sales_Up__c temp)
        {
            this.Slop = temp;
        }

        public void setOpp(Opportunity temp)
        {
            this.opp = temp;
        }

        public dealer__Sales_Up__c getSlop()
        {
            return this.Slop;
        }

        public Opportunity getOpp()
        {
            return this.Opp;
        }
    }
}