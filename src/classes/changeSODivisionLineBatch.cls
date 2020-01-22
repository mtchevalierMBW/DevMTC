/**
* changeSODivisionLineBatch
*
* MobilityWorks (c) - 2018
*
* Batch class which takes all of the lines
* generated from changeSalesOrderDivisionController
* and inserts each one to avoid SF limits 
*
* Tested By:
* Developer: Alexander Miller
* Date 1/18/2018
*
* 5-14-2018 Alexander Miller (AMILLER) - update to help keep error messages when they do occur
*/
global class changeSODivisionLineBatch implements Database.Batchable<rstk__soapi__c>, Database.Stateful
{
    // stateful global variable that will survive execution contexts
    global List<rstk__soapi__c> listOfSoLinesToInsert;
    global List<rstk__soline__c> listOfOriginalLines;
    global Map<Decimal, List<rstk__soconfig__c>> listOfSoConfigToInsert;
    global Id oldSalesOrderId;
    global Id newSalesOrderId;
    global String newSalesOrderName;
    global Map<Id, rstk__soprod__c> mapOfLinesToProducts;
    global Map<Decimal, List<rstk__sortoper__c>> mapofLinesToLabOps;
    global Id loggedInUser;

    global String errors;

    public changeSODivisionLineBatch(){}  

    public void setData(List<rstk__soapi__c> tempData, List<rstk__soline__c> tempOldLines, Map<Decimal, List<rstk__soconfig__c>> tempConfig, Id oldSO, Id newSO, Map<Decimal, List<rstk__sortoper__c>> tempLaborMap, Id thisUser, String newName)
    {
        listOfSoLinesToInsert = tempData;
        listOfOriginalLines = tempOldLines;
        listOfSoConfigToInsert = tempConfig;
        oldSalesOrderId = oldSO;
        newSalesOrderId = newSO;
        mapofLinesToLabOps = tempLaborMap;
        loggedInUser = thisUser;
        newSalesOrderName = newName;
    } 
    
    global Iterable<rstk__soapi__c> start(Database.BatchableContext BC)
    {  
        return listOfSoLinesToInsert;
    }

    global void execute(Database.BatchableContext BC, List<rstk__soapi__c> listTemp)
    {
        Database.SaveResult[] srList = Database.insert(listTemp, false);

        // Iterate through each returned result
        for (Database.SaveResult sr : srList) 
        {
            if (!sr.isSuccess()) 
            { 
                for(Database.Error err : sr.getErrors()) 
                {    
                    errors += '<br/> INSERT SOAPI: status code: ' + err.getStatusCode() + ' : Field: ' + err.getFields() + ' : Message ' + err.getMessage(); 
                }
            }
        }

        rstk__soline__c tempLine = [SELECT Id, 
                                        CreatedDate,
                                        Origin_Sales_Order_Line__c 
                                    FROM rstk__soline__c
                                    WHERE CreatedById = :loggedInUser
                                    ORDER BY CreatedDate DESC LIMIT 1];
        
        tempLine.Origin_Sales_Order_Line__c = listOfOriginalLines.get(0).Id;
        //update tempLine;

        List<rstk__soline__c> listToUpdate = new List<rstk__soline__c>();
        listToUpdate.add(tempLine);

        Database.SaveResult[] srList2 = Database.update(listToUpdate, false);

        // Iterate through each returned result
        for (Database.SaveResult sr : srList2) 
        {
            if (!sr.isSuccess()) 
            { 
                for(Database.Error err : sr.getErrors()) 
                {    
                    errors += '<br/> UPDATE SOLINE: status code: ' + err.getStatusCode() + ' : Field: ' + err.getFields() + ' : Message ' + err.getMessage(); 
                }
            }
        }

        listOfOriginalLines.remove(0);
    }   
     
    global void finish(Database.BatchableContext BC) 
    {    
        // AMILLER - added if statement
        if(errors == null)
        {
            errors = '';
        }

        Map<Id,rstk__soline__c> listOfNewSOLines = new Map<Id, rstk__soline__c>([SELECT Id,
                                                    rstk__soline_line__c,
                                                	rstk__soline_prod__c
                                                FROM rstk__soline__c 
                                                WHERE rstk__soline_sohdr__c = :newSalesOrderId]);
        
        List<Id> listOfConfigIds = new List<Id>();

        for(Decimal tempConfigKey : listOfSoConfigToInsert.KeySet())
        {    
            for(rstk__soconfig__c tempConfigItem : listOfSoConfigToInsert.get(tempConfigKey))
            {
                for(rstk__soline__c tempLine : listOfNewSOLines.values())
                {
                    if(tempLine.rstk__soline_line__c == tempConfigKey)
                    {
                        tempConfigItem.rstk__soconfig_soline__c = tempLine.Id;
                    }
                }
            }  
            
            // insert all of so config so work order will work
            //insert listOfSoConfigToInsert.get(tempConfigKey); 
            System.debug(listOfSoConfigToInsert.get(tempConfigKey).get(0));     
            Database.SaveResult[] srList = Database.insert(listOfSoConfigToInsert.get(tempConfigKey), false);

            // Iterate through each returned result
            for (Database.SaveResult sr : srList) 
            {
                if (!sr.isSuccess()) 
                {          
                    for(Database.Error err : sr.getErrors()) 
                    {                   
                        System.debug('Status Code: ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Message: ' + err.getMessage()+ ': ' + err.getMessage());
                        System.debug('Field: ' + err.getFields());
                        System.debug('-----------------------------');

                        errors += '<br/> status code: ' + err.getStatusCode() + ' : Field: ' + err.getFields() + ' : Message ' + err.getMessage();  
                    }
                }
            }   

            for(rstk__soconfig__c tempItem : listOfSoConfigToInsert.get(tempConfigKey))
            {
                listOfConfigIds.add(tempItem.Id);
            }
        }

        for(Decimal tempLaborKey : mapofLinesToLabOps.KeySet())
        {    
            for(rstk__sortoper__c tempLabor : mapofLinesToLabOps.get(tempLaborKey))
            {
                for(rstk__soline__c tempLine : listOfNewSOLines.values())
                {
                    if(tempLine.rstk__soline_line__c == tempLaborKey)
                    {
                        tempLabor.rstk__sortoper_soline__c = tempLine.Id;
                    }
                }
            }  
               
            Database.SaveResult[] srList = Database.insert(mapofLinesToLabOps.get(tempLaborKey), false);

            // Iterate through each returned result
            for (Database.SaveResult sr : srList) 
            {
                if (!sr.isSuccess()) 
                {          
                    for(Database.Error err : sr.getErrors()) 
                    {                   
                        System.debug('Status Code: ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Message: ' + err.getMessage()+ ': ' + err.getMessage());
                        System.debug('Field: ' + err.getFields());
                        System.debug('-----------------------------');

                        errors += '<br/> status code: ' + err.getStatusCode() + ' : Field: ' + err.getFields() + ' : Message ' + err.getMessage();  
                    }
                }
            }   
        }
        
        System.debug('Finished');

        if(!String.isEmpty(errors))
        {
            errors += '<br/>';

            for(Decimal tempConfigKey : listOfSoConfigToInsert.KeySet())
            {    
                for(rstk__soconfig__c tempConfigItem : listOfSoConfigToInsert.get(tempConfigKey))
                {
                    errors += '<br/> SOCONFIG: ' + tempConfigItem;  
                }
            }

            errors += '<br/>';

            for(Decimal tempLaborKey : mapofLinesToLabOps.KeySet())
            {    
                for(rstk__sortoper__c tempLabor : mapofLinesToLabOps.get(tempLaborKey))
                {
                    errors += '<br/> SOLABOR: ' + tempLabor; 
                } 
            }

            Messaging.reserveSingleEmailCapacity(2);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {'alex.miller@mobilityworks.com'};
            mail.setToAddresses(toAddresses);
            mail.setReplyTo('alex.miller@mobilityworks.com');
            mail.setSenderDisplayName('TransitWorks Salesforce Support'); 
            mail.setSubject('Division Change errors : ' + newSalesOrderId);
            mail.setHtmlBody(errors);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }

        User tempUser = [SELECT Id, Email FROM User WHERE Id = :loggedInUser LIMIT 1]; 

        Messaging.reserveSingleEmailCapacity(2);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {tempUser.email};
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('alex.miller@mobilityworks.com');
        mail.setSenderDisplayName('TransitWorks Salesforce Support');
        mail.setSubject('Transfer Complete For New Order : ' + newSalesOrderName);
        mail.setHtmlBody('Transfer Complete For New Order : ' + newSalesOrderName);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 

        
    }
    // make sure SOCONFIGs of the same name are modified to make them unique? Deletion lets the order firm
    // Example: Fasteners
}