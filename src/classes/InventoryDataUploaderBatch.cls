/**
* InventoryDataUploaderBatch
*
* MobilityWorks (c) - 2018
*
* A batch class to incrementally update info generated from 
* InventoryDataUploaderController
*
* Tested By: InventoryDataUploaderBatchTest
* Developer: Alexander Miller
* Date 3/6/2018
*
* Modifications
* 2019-10-30	B. Leaman	W-000773 BLL1 - Allow matching by stock# instead of VIN; fix spelling of listOfCoulmHeaders (unmarked);
*							When matching by VIN, skip delivered vehicles;
*/
global with sharing class InventoryDataUploaderBatch implements Database.Batchable<InventoryDataUploaderController.InventoryItem>, Database.Stateful {
    
    global List<InventoryDataUploaderController.InventoryItem> listOfInventory;

    global String successCSV;
    global String errorCSV;
    global String updateFailCSV;

    global String jsonString;

    global String comma = ',';
    global String newLine = '\n';

    global Iterable<InventoryDataUploaderController.InventoryItem> start(Database.BatchableContext BC) 
    {  
        listOfInventory = new List<InventoryDataUploaderController.InventoryItem>();

        System.debug(jsonString);

        JSONParser parser = JSON.createParser(jsonString);
        while (parser.nextToken() != null) 
        {
            if (parser.getCurrentToken() == JSONToken.START_ARRAY) 
            {
                while (parser.nextToken() != null) 
                {
                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                    {
                        InventoryDataUploaderController.InventoryItem inv = (InventoryDataUploaderController.InventoryItem)parser.readValueAs(InventoryDataUploaderController.InventoryItem.class);
                        listOfInventory.add(inv);
                        parser.skipChildren();
                    }
                }
            }
        }

        return listOfInventory;
    }

    global void execute(Database.BatchableContext BC, List<InventoryDataUploaderController.InventoryItem> listTemp) 
    {
        InventoryDataUploaderController.InventoryItem listTempItem = listTemp.get(0);

        if(listTempItem.willUpdate)
        {
            List<dealer__Vehicle_Inventory__c> listToUpdate = new List<dealer__Vehicle_Inventory__c>();
            listToUpdate.add(listTempItem.vehicle);

            Database.SaveResult[] srList = Database.update(listToUpdate, false);

            for (Database.SaveResult sr : srList) 
            {
                if (!sr.isSuccess()) 
                {              
                    for(Database.Error err : sr.getErrors()) 
                    {                 
						// BLL1
                        //updateFailCSV += listTempItem.VIN + comma + 
                        updateFailCSV += listTempItem.KEY + comma + 
						// BLL1 end
                                        listTempItem.inboundTransportRequested + comma + 
                                        listTempItem.acquisitionDate + comma + 
                                        listTempItem.retailReady + comma + 
                                        listTempItem.outboundTransportRequested + comma +
                                        listTempItem.productionComplete + comma +
                                        err.getStatusCode() + comma +
                                        err.getMessage() + comma +
                                        err.getFields() + newLine; 
                    }
                }
            }
        }
    }   
     
    global void finish(Database.BatchableContext BC) 
    {
		// BLL1
		String keycol = InventoryDataUploaderController.columnHeaderSTOCK;
		if (String.isBlank(keycol)) keycol = InventoryDataUploaderController.columnHeaderVIN;
		// BLL1 end
		// BLL1
     	//this.successCSV = InventoryDataUploaderController.columnHeaderVIN + comma + InventoryDataUploaderController.columnHeaderInboundTransportRequested + comma +
     	this.successCSV = keyCol + comma + InventoryDataUploaderController.columnHeaderInboundTransportRequested + comma +
		// BLL1 end
            				InventoryDataUploaderController.columnHeaderAcquisitionDate + comma + InventoryDataUploaderController.columnHeaderRetailReady + comma + 
            				InventoryDataUploaderController.columnHeaderOutboundTransportRequested + comma + InventoryDataUploaderController.columnHeaderProductionComplete + '\n';

		// BLL1
        //this.errorCSV = InventoryDataUploaderController.columnHeaderVIN + comma + InventoryDataUploaderController.columnHeaderInboundTransportRequested + comma +
        this.errorCSV = keyCol + comma + InventoryDataUploaderController.columnHeaderInboundTransportRequested + comma +
		// BLL1 end
            				InventoryDataUploaderController.columnHeaderAcquisitionDate + comma + InventoryDataUploaderController.columnHeaderRetailReady + comma + 
            				InventoryDataUploaderController.columnHeaderOutboundTransportRequested + comma + InventoryDataUploaderController.columnHeaderProductionComplete + ',Error Reason' + '\n';
        
		// BLL1
        //this.updateFailCSV = InventoryDataUploaderController.columnHeaderVIN + comma + InventoryDataUploaderController.columnHeaderInboundTransportRequested + comma +
        this.updateFailCSV = keyCol + comma + InventoryDataUploaderController.columnHeaderInboundTransportRequested + comma +
		// BLL1 end
            				InventoryDataUploaderController.columnHeaderAcquisitionDate + comma + InventoryDataUploaderController.columnHeaderRetailReady + comma + 
            				InventoryDataUploaderController.columnHeaderOutboundTransportRequested + comma + InventoryDataUploaderController.columnHeaderProductionComplete + ',Error Status Code,Error Message, Error Field' + '\n';

        for(InventoryDataUploaderController.InventoryItem tempItem : listOfInventory)
        {
            if(tempItem.willUpdate)
            {
                // Successes from validation page
				// BLL1
                //successCSV += tempItem.VIN + comma + 
                successCSV += tempItem.KEY + comma + 
				// BLL1 end
                                    tempItem.inboundTransportRequested + comma + 
                                    tempItem.acquisitionDate + comma + 
                                    tempItem.retailReady + comma + 
                                    tempItem.outboundTransportRequested + comma + 
                                    tempItem.productionComplete + newLine;
            }
            else
            {   
                // Errors from validation page
				// BLL1
                //errorCSV += tempItem.VIN + comma + 
                errorCSV += tempItem.KEY + comma + 
				// BLL1 end
                                    tempItem.inboundTransportRequested + comma + 
                                    tempItem.acquisitionDate + comma + 
                                    tempItem.retailReady + comma + 
                                    tempItem.outboundTransportRequested + comma + 
                                    tempItem.errorReason.trim() + comma + 
                                    tempItem.productionComplete + newLine;
            }   
        }

        Messaging.reserveSingleEmailCapacity(2);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        Blob b = Blob.valueOf(successCSV);
        Messaging.EmailFileAttachment sucesses = new Messaging.EmailFileAttachment();
        sucesses.setFileName('successful.csv');
        sucesses.setBody(b);

        Blob b1 = Blob.valueOf(errorCSV);
        Messaging.EmailFileAttachment errors = new Messaging.EmailFileAttachment();
        errors.setFileName('error.csv');
        errors.setBody(b1);
 
        Blob b2 = Blob.valueOf(updateFailCSV);
        Messaging.EmailFileAttachment updateFails = new Messaging.EmailFileAttachment();
        updateFails.setFileName('updateFails.csv');
        updateFails.setBody(b2);

        String email = UserInfo.getUserEmail();

        String[] toAddresses = new String[] {email};
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName('MobilityWorks Salesforce Administrators');
        mail.setSubject('Inventory Data Loading Tool Results');
        mail.setPlainTextBody('Attached at the results of the update');
        mail.setFileAttachments(new Messaging.EmailFileAttachment[] {sucesses,errors,updateFails});
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
    }
}