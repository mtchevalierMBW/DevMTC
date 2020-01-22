/**
 * SOAckExtension
 * 
 * Created 3/16/2018
 * Programmer: Alexander Miller
 * Tested By: SOAckExtensionTest
 * 
 * A class which allows for Sales Order Header Email Templates
 * for invoicing can gain dynamic data
 */
public class SOAckExtension {
    
    Id orderId {get;set;}
    
    public rstk__sohdr__c orderHeader {get;set;}

    /** Rebates - total discount */
    public Decimal Rebates {get;set;}

    public SOAckExtension() { 
        
        Rebates = 0;
        
        orderId = ApexPages.currentPage().getParameters().get('id');
        
        // load initial data
        List<rstk__soline__c> temp = ([SELECT Id, 
                                	rstk__soline_ext__c
                                FROM rstk__soline__c
                            	WHERE rstk__soline_sohdr__c = :orderId AND
                               		rstk__soline_prod__r.Name LIKE '%Discount%']);
        
        orderHeader = [SELECT Id, rstk__sohdr_ordertotal__c FROM rstk__sohdr__c WHERE Id = :orderId];
        
        for(rstk__soline__c tempList : temp)
        {
        	Rebates += tempList.rstk__soline_ext__c;
        }
    }
}