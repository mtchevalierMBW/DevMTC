/**
 * VehicleInventoryEmailHandler
 * Tested by: VehicleInventoryEmailHandler_TEST
 * Date: August 23rd, 2017
 * Programmer: Alexander Miller
 * Work: W-000139
 *
 * Process which handles incoming emails from Braun and VMI displaying confirmation messages
 *
 * Once a confirmation is received this class will update the Vehicle Inventory record in the following ways:
 * - Update the Order_Confirmation_Date_Time__c Date field as a time stamp of the email delivery date
 * - Attach all found documents found with the email to the record
 * - In the even of failure at any point in the process, a failure message is sent to vehicle.inventory@mobilityworks.com
 */
global class VehicleInventoryEmailHandler implements Messaging.InboundEmailHandler {

    String errors = '';

    // handleInboundEmail
    //---------------------------------------
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        
        new EmailServiceLog('VehicleInventoryEmailHandler').increment(); 
        
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        String fromAddr = email.fromAddress;
        String results = '';
        String hostname = getHostName(email);
        String vehicleStockNumber = getVehicleInfo(email);
        Id vehicleInventoryId = getVehicleInventoryIdFromStockNumber(vehicleStockNumber);
        Boolean attachmentInsertResult = didInsertAttachments(email, vehicleInventoryId);
        Boolean isConfirmationAlreadyReceived;  

        if(attachmentInsertResult && String.isEmpty(errors)){
            
            isConfirmationAlreadyReceived = isVehicleConfirmationFilledIn(vehicleStockNumber); 
            
            if(isConfirmationAlreadyReceived) {
                // Use case 1: Our Vehicle Inventory Record already received a confirmatino and need to let everyone know
                errors += 'Confirmation was already received and received possible duplicate email';
                result.success = false;
                result.message = 'Hello, \n' + 
                            'Error: Confirmation was already received and received possible duplicate email.\n' + 
                            'Subject line: ' + email.subject + '\n\n'+
                            'Message Body: \n\n' +
                            email.plainTextBody + 
                            'Thanks,\n' +
                            'MobilityWorks Salesforce Administrators';
                sendFailureMessage(fromAddr, email);
                return result;
            } else {
                // Use case 2: the record is cleared to be updated and all the data matches up correctly, update the record and notify Inventory
                updateVehicleIntenvtoryRecord(vehicleInventoryId);
                sendSuccessMessage(fromAddr, email);
                return null;
            }
        } else {
            // Use case 3: there was a failure and all parties need to be notified of the issue
            result.success = false;
            result.message = 'Hello, \n' + 
                            'Error: Email was NOT successfully received.\n' + 
                            'Subject line: ' + email.subject + '\n\n'+
                            'Message Body: \n\n' +
                            email.plainTextBody + 
                            'Thanks,\n' +
                            'MobilityWorks Salesforce Administrators';
            sendFailureMessage(fromAddr, email);
            return result;
        }
    }

    /**
    * isVehicleConfirmationFieldNull
    *
    * a function which lets the process know if the confirmation date already has a value.
    *
    * @param String - the stock number found in the email being evaluated
    * @return true if the date field is NOT null, false otherwise
    */
    public Boolean isVehicleConfirmationFilledIn(String stockNumberParam){
        dealer__Vehicle_Inventory__c tempVehicleInventoryList = ([SELECT Id, Order_Confirmation_Date_Time__c FROM dealer__Vehicle_Inventory__c WHERE dealer__Stock_Number__c = :stockNumberParam LIMIT 1]);
        
        if(tempVehicleInventoryList.Order_Confirmation_Date_Time__c != null){
            return true;
        } else {
            return false;
        }
    }

    /**
    * sendFailureMessage
    *
    * a function which takes the given error messages and sends them to vehicle.inventory@mobilityworks.com
    */
    public void sendFailureMessage(String fromAddressParam, Messaging.InboundEmail emailParam){
        
        Messaging.reserveSingleEmailCapacity(2);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        String[] toAddresses = new String[] {'vehicle.inventory@mobilityworks.com'};
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName('MobilityWorks Salesforce Administrator');
        mail.setSubject('Automated Message: Vehicle Inventory Email Errors');
        mail.setPlainTextBody('Hello,\n' +
        'It appears an email was received which failed to be delivered to our internal system from ' +fromAddressParam + ' with the following error(s): \n'+
        errors + '\n\n' +
        'Subject line: ' + emailParam.subject + '\n\n'+
        'Message Body: \n\n' +
         emailParam.plainTextBody + '\n\n'+ 
        'Thanks,\n' +
        'MobilityWorks Salesforce Adminsitrators');

        // dont send the test message in production
        Organization org = [select Id, Name, isSandbox from Organization limit 1];
        
        if (!org.isSandbox) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    /**
    * sendSuccessMessage
    *
    * a function which notifies vehicle.inventory@mobilityworks.com of successes
    */
    public void sendSuccessMessage(String fromAddressParam, Messaging.InboundEmail emailParam){
        
        Messaging.reserveSingleEmailCapacity(2);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();        
        String[] toAddresses = new String[] {'vehicle.inventory@mobilityworks.com'};
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName('MobilityWorks Salesforce Administrator');
        mail.setSubject('Automated Message: Vehicle Inventory Success');
        mail.setPlainTextBody('Hello,\n' +
        'A Vehicle Inventory was successfully updated from ' +fromAddressParam + ' with the details: \n'+
        errors + '\n\n' +
        'Subject line: ' + emailParam.subject + '\n\n'+
        'Message Body: \n\n' +
         emailParam.plainTextBody + '\n\n'+ 
        'Thanks,\n' +
        'MobilityWorks Salesforce Adminsitrators');

        // dont send the test message in production
        Organization org = [select Id, Name, isSandbox from Organization limit 1];
        
        if (!org.isSandbox) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

    /*
    * getVehicleInventoryIdFromStockNumber
    *
    * function which gets the Id of the Vehicle Inventory record with the same Stock number
    *
    * @param String - the stock number found in the email being evaluated
    * @return Id if the record is found, null otherwise
    */
    public Id getVehicleInventoryIdFromStockNumber(String stockNumberParam){
        try{
            dealer__Vehicle_Inventory__c tempVehicleInventoryList = ([SELECT Id FROM dealer__Vehicle_Inventory__c WHERE dealer__Stock_Number__c = :stockNumberParam LIMIT 1]);
            return tempVehicleInventoryList.Id;
        } catch (Exception e) {
            errors += 'Could not find the Inventory Vehicle matching. The expected stock number was ' + stockNumberParam + ' but is not registered to any record in the system.';
            return null;
        }
        
    }

    /**
    * updateVehicleIntenvtoryRecord
    *
    * a function which updates a given Vehicle Inventory record with a date time stamp. This function assumes StockNumber is not null
    *
    * @param String - the Stock number of a given vehicle
    */  
    public void updateVehicleIntenvtoryRecord(Id recordId){
        dealer__Vehicle_Inventory__c tempVehicleInventoryList = ([SELECT Id, Order_Confirmation_Date_Time__c FROM dealer__Vehicle_Inventory__c WHERE Id = :recordId LIMIT 1]);
        tempVehicleInventoryList.Order_Confirmation_Date_Time__c = System.now(); 
        update tempVehicleInventoryList;
    }

    /**
    * getVehicleInfo
    *
    * a function which gets either the Stock number or the acknowledgement number from the email. This function assumes the email is valid already
    *
    * @param Messaging.Inbound - the Salesforce representation of an email
    * @param String - the email address of the person who is sending the email
    * @return String - either the Stock number found
    */
    public String getVehicleInfo(Messaging.InboundEmail emailParam){
        
        String stringResult;

        if(emailParam.subject.contains('BraunAbility Sales Order Acknowledgement')){

            // scrape body
            String stockNumber = '';
            String[] emailBody = emailParam.plainTextBody.split('\n', 0);
            for(String tempEmailLineString : emailBody)
            {
                if(tempEmailLineString.contains('Customer PO: ')) // Customer PO: HS770923-so-HS770923
                {
                    String[] lineItemStringSplit = tempEmailLineString.split(':', 0); // [Customer PO] [STOCK NUMBER PERMUTATION]
                    System.debug('lineItemStringSplit: '+lineItemStringSplit);
                    
                    // Use case 1: STQ-48457 - HS877252 [get STQ-48457]
                    if(tempEmailLineString.contains('STQ-')){
                        String[] stockNumberTempSplit = lineItemStringSplit[1].split(' - ', 0);
                        stockNumber = stockNumberTempSplit[0]; // STQ-48457
                        
                        System.debug('Use case 1');
                        System.debug('stockNumberTempSplit: ' + stockNumberTempSplit);
                        System.debug('stockNumber: ' + stockNumber);
                    }
                    // Use case 2: HR797108-ST-HR797108
                    else if(tempEmailLineString.contains('-ST-')){
                        String[] stockNumberTempSplit = lineItemStringSplit[1].split('-ST-', 0);
                        stockNumber = stockNumberTempSplit[1]; // HR797108

                        System.debug('Use case 3');
                        System.debug('stockNumberTempSplit: ' + stockNumberTempSplit);
                        System.debug('stockNumber: ' + stockNumber);
                    } 
                    // Use case 3: ST-HS882319
                    else if(tempEmailLineString.contains('ST-')){
                        String[] stockNumberTempSplit = lineItemStringSplit[1].split('ST-', 0);
                        stockNumber = stockNumberTempSplit[1]; // HS882319
                        
                        System.debug('Use case 2');
                        System.debug('stockNumberTempSplit: ' + stockNumberTempSplit);
                        System.debug('stockNumber: ' + stockNumber);
                    }
                    // Use case 4: ER342809-SO-ER342809
                    else if(tempEmailLineString.contains('-SO-')){
                        String[] stockNumberTempSplit = lineItemStringSplit[1].split('-SO-', 0);
                        stockNumber = stockNumberTempSplit[1]; // ER342809

                        System.debug('Use case 4');
                        System.debug('stockNumberTempSplit: ' + stockNumberTempSplit);
                        System.debug('stockNumber: ' + stockNumber);
                    }
                    // Use case 5: SO-HS876157
                    else if(tempEmailLineString.contains('SO-')){
                        String[] stockNumberTempSplit = lineItemStringSplit[1].split('SO-', 0);
                        stockNumber = stockNumberTempSplit[1]; // HS876157

                        System.debug('Use case 5');
                        System.debug('stockNumberTempSplit: ' + stockNumberTempSplit);
                        System.debug('stockNumber: ' + stockNumber);
                    }
                    
                    if(String.isEmpty(stockNumber) == false) // make sure its still there
                    {
                        System.debug('foundBraunStockNumber: ' + stockNumber);
                        stringResult = stockNumber.trim();
                        break;
                    }
                }    
            }
        }
        else if(emailParam.subject.contains('VMI Pricing Confirmation:')){
            String subjectLine = emailParam.subject;
            String[] arr = subjectLine.replaceAll('Pricing','').replaceAll('Confirmation','').replaceAll('VMI #','').replaceAll('VIN #','').split(' '); 
            stringResult = arr[arr.size()-2].trim();
            System.debug('subjectLine: ' + subjectLine);
            System.debug('arr: ' + arr);
            System.debug('stringResult: ' + stringResult);
        }

        return stringResult;
    }

    /**
    * didInsertAttachments
    *
    * a function which takes an email and attaches all of the found attachments to the Vehicle Inventory record. If no attachments are found,
    * the process still marks the email as true.
    *
    * @param Messaging.Inbound - the Salesforce representation of an email
    * @return Boolean - true if the attachment insertion worked, false otherwise
    */
    public Boolean didInsertAttachments(Messaging.InboundEmail emailParam, Id parentIdParam){
        
        Boolean insertionResult = true;

        if(parentIdParam == null)
        {
            insertionResult = false;
            return insertionResult;
        }

        List<Attachment> attachmentList = new List<Attachment>();

        if(emailParam.binaryAttachments != null)
        {
            for (Messaging.Inboundemail.BinaryAttachment bAttachment : emailParam.binaryAttachments) {
              Attachment attachment = new Attachment();
              attachment.Name = bAttachment.fileName;
              attachment.Body = bAttachment.body;
              attachment.ParentId = parentIdParam;
              // only need PDF attachments
              System.debug(bAttachment.fileName);
              if(bAttachment.fileName.endsWithIgnoreCase('.pdf')){
                attachmentList.add(attachment);
              }
            }
        }

        Database.SaveResult[] srList = Database.insert(attachmentList, false);
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess() == false) {

                insertionResult = false;

                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    errors += 'Attachment errors occured: ' + err.getStatusCode() + ': ' + err.getMessage() + '';
                }
            }
        }

        return insertionResult;
    }

    /**
    * getHostName
    *
    * A function to gather where or not the current org running this code is a sandbox or production org.
    *
    * @param Messaging.Inbound - the Salesforce representation of an email
    * @return String - value either containing the prod email suffix or the sandbox one
    */
    public String getHostName(Messaging.InboundEmail emailParam){

        String hostname = '';
        
        Organization org = [select Id, Name, isSandbox from Organization limit 1];
        
        if (org.isSandbox) {
            hostname = 'test.salesforce.com'; 
            try {
                hostname = emailParam.toAddresses[0].substringBeforeLast('.apex.sandbox.salesforce.com').substringAfterLast('.') + '.salesforce.com';
            } catch(Exception e) {
                System.debug(e.getMessage());
            }
        }
        else {
            hostname = 'mbw.my.salesforce.com';
        }

        return hostname;
    }
}