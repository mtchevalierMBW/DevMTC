/**
* TransitWorks (c) - 2018
*
* TWPOAutoClose
* 
* Created By: Alexander Miller
* Tested By: TWPOAutoCloseTest
* Description: 
* 	When all lines of the PO are status 8, the PO should auto-close itself
*/
public class TWPOAutoClose {

    @InvocableMethod(label='closePOs' description='Function which kicks off the SYDATA PO Closure process')
    public static void closePOs(List<ID> ids) {
        
        System.debug(ids);
        
        List<rstk__sydata__c> listOfSyData = new List<rstk__sydata__c>();

        for(Id tempId : ids)
        {
           	rstk__sydata__c tempSyData = new rstk__sydata__c();
        	tempSyData.rstk__sydata_txntype__c = 'PO Close'; 
            tempSyData.rstk__sydata_pohdr__c = tempId;
            
            listOfSyData.add(tempSyData);
        }
        
        insert listOfSyData;
    }
}