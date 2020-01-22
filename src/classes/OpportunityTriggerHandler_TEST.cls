/**
* OpportunityTriggerHandler_TEST
* 
* Programmer: Alexander Miller
* Date: 2017-09-14
*
*	2018-02-06	B. Leaman 	BLL1 - skip opportunities that violate new validation rules.
*	2018-04-30	B. Leaman	BLL2 - new required field on opportunity: Sales_Channel__c
*/
@isTest(SeeAllData=True)
public class OpportunityTriggerHandler_TEST{

    public static testMethod void testTransitOppCannotBeLostWithOpenSalesOrders()
    {
        List<Opportunity> listOfOpps = [SELECT Id, Sales_Channel__c, RecordType.Name FROM Opportunity 
        	WHERE Account.RecordType.Name = 'TransitWorks'
        	  and ((LeadSource!='Trade Show' and LeadSource!='Marketing Campaign') or CampaignId!=null)
        	  and Sales_Channel__c!=null	// BLL2a
        	LIMIT 10];
        update listOfOpps;
    }
}