/**
* MobilityWorks (c) - 2017
*
* ConfigurationSessionTriggerHandler
* 
* Tested by: ConfigurationSessionTriggerHandlerTest
* Programmer: Alexander Miller
* Date: 2018-1-8
*
* Primary handler class for the Configuration Session trigger
*
* Alexander Miller - 8/31/2018 - AMILLER1 - W-000361 - Update to handle prevention of clones when the session is deactivated
*/
public class ConfigurationSessionTriggerHandler{

    public List<rstk__confsess__c> newList = new List<rstk__confsess__c>();
    public List<rstk__confsess__c> oldList = new List<rstk__confsess__c>();
    public Map<Id, rstk__confsess__c> newMap = new Map<Id, rstk__confsess__c>();
    public Map<Id, rstk__confsess__c> oldMap = new Map<Id, rstk__confsess__c>();

    public Map<Id, rstk__confsess__c> ConfigMapUpdate = new Map<Id, rstk__confsess__c>();

    private static boolean run = true;

    // AMILLER1
    public String cloneDeactivatedError = 'This session is deactivated. Please make a new one.';

    public ConfigurationSessionTriggerHandler(){}

    public ConfigurationSessionTriggerHandler(rstk__confsess__c[] newArray, rstk__confsess__c[] oldArray, Map<Id, rstk__confsess__c> newHashMap, Map<Id, rstk__confsess__c> oldHashMap){
        newList = newArray;
        oldList = oldArray;
        newMap = newHashMap;
        oldMap = oldHashMap;
    }

    /**
    * updateMaps
    *
    * Function which takes all the global maps and updates them at once.
    */
    public void updateMaps()
    {
        update ConfigMapUpdate.values();
    }

    /**
    * runOnce
    *
    * a function which helps prevent recursive DML calls
    */
    public boolean runOnce(){
        
        if(run)
        {
            run = false;
            return true;
        }
        else
        {
            return run;
        }
    }

    /**
    * markLatestSalesOrder
    *
    * Function which scans the system for the first 
    * Sales Order Line and matches up the Sales Order
    * Header and then pastes it into the Configuration
    */
    public void markLatestSalesOrder()
    {
        Set<rstk__confsess__c> listOfConfigToUpdate = new Set<rstk__confsess__c>();

        List<rstk__soline__c> listOfSalesLine = ([SELECT Id, 
                                                    rstk__soline_sohdr__c,
                                                    rstk__soline_sohdr__r.Name,
                                                    rstk__soline_confsess__c,
                                                    CreatedDate 
                                                FROM rstk__soline__c 
                                                WHERE rstk__soline_confsess__c IN :newMap.keySet()
                                                ORDER BY CreatedDate ASC]);

        // Sort the list into maps containing the latest Sales Order Line 
        Map<Id, rstk__soline__c> mapOfLines = new Map<Id, rstk__soline__c>();
        for(rstk__soline__c tempLine : listOfSalesLine)
        {
            // if it doesn't exist, place it
            if(mapOfLines.get(tempLine.Id) == null)
            {
                mapOfLines.put(tempLine.Id, tempLine);
            }
            // if the current record in the loop is newer, replace the map item
            else if(mapOfLines.get(tempLine.Id) != null && tempLine.CreatedDate > mapOfLines.get(tempLine.Id).CreatedDate)
            {   
                mapOfLines.put(tempLine.Id, tempLine);
            }
        }

        // Assign Configuration Sessions the latest Sales Order Headers
        for(rstk__soline__c tempSoLine : mapOfLines.values())
        {
           if(ConfigMapUpdate.get(tempSoLine.rstk__soline_confsess__c) != null)
           {
               ConfigMapUpdate.get(tempSoLine.rstk__soline_confsess__c).rstk__confsess_sohdr__c = tempSoLine.rstk__soline_sohdr__c;
               ConfigMapUpdate.get(tempSoLine.rstk__soline_confsess__c).Sales_Order_Text__c = tempSoLine.rstk__soline_sohdr__r.Name;
           }
           else
           {
               ConfigMapUpdate.put(tempSoLine.rstk__soline_confsess__c, new rstk__confsess__c(Id=tempSoLine.rstk__soline_confsess__c, rstk__confsess_sohdr__c = tempSoLine.rstk__soline_sohdr__c, Sales_Order_Text__c = tempSoLine.rstk__soline_sohdr__r.Name));
           }
        }  
    }

    /**
    * pasteClone
    *
    * Function which takes all the configuration sessions
    * and checks if they were made through the cloning
    * process. If it was, then get the origin 
    * Id and pasted it into the Configuration Session
    * to show the chain
    */
    public void pasteClone()
    {
        for(rstk__confsess__c tempConfig : newList)
        {
            if(tempConfig.isClone())
            {
                if(ConfigMapUpdate.get(tempConfig.Id) != null)
                {
                    ConfigMapUpdate.get(tempConfig.Id).Configuration_Session_Cloned__c = tempConfig.getCloneSourceId();
                }
                else
                {
                    ConfigMapUpdate.put(tempConfig.Id, new rstk__confsess__c(Id=tempConfig.Id, Configuration_Session_Cloned__c=tempConfig.getCloneSourceId()));
                }
            }
        }
    }

    // AMILLER1
    /**
    * preventCloneOnDeactivatedSessions
    *
    * Function which looks at the session being cloned and prevents it
    * if its already deactivated
    *
    * @param listOfSessions - list of configuration sessions being processed in the trigger creation process
    */
    /*
    public void preventCloneOnDeactivatedSessions(List<rstk__confsess__c> listOfSessions)
    {
        for(rstk__confsess__c tempSession : listOfSessions)
        {
            if(tempSession.isClone() && tempSession.Deactivated__c)
            {
                tempSession.addError(cloneDeactivatedError);
            }
        }
    }
    */
    // AMILLER1

    // AMILLER2
    /**
    * copyCustomOpportunityLink
    *
    * Function which copies the custom TransitWorks Opportunity link to the Config Session
    *
    * @param listOfSessions - list of configuration sessions being processed in the trigger creation process
    */
    public void copyCustomOpportunityLink(List<rstk__confsess__c> listOfSessions)
    {   
        List<rstk__confsess__c> listOfConfigSessions = ([SELECT Id,
                                                             rstk__confsess_opportunity__c,
                                                             rstk__confsess_opportunity__r.Opportunity__c
                                                        FROM rstk__confsess__c
                                                        WHERE Id IN :listOfSessions]);

        for(rstk__confsess__c tempConfig : listOfConfigSessions)
        {
            if(tempConfig.rstk__confsess_opportunity__c != null && 
                tempConfig.rstk__confsess_opportunity__r.Opportunity__c != null)
            {
                tempConfig.Opportunity__c = tempConfig.rstk__confsess_opportunity__r.Opportunity__c;
            }
        }

        update listOfConfigSessions;
    }
    // AMILLER2 
}