/**
 * Curtailment Process for other Banks
 * Curtailment_BatchProcess
 * Tested by: CurtailmentImportController_TEST
 * Author: MarinerTek
 * Created: 5/11/2017
 *
 * Flooring updates, not curtailments.
 *
 * Code coverage:
 *	2017-08-31	86% (69/80) 
 *	2017-10-23	85%	(85/100)
 *	2019-10-04	86% (69/80)
 * 
 *	Date		Developer	Description
 *	----------	----------	-------------------------------------------------------------------
 *	2017-06-20	B. Leaman	BLL1 - Don't update Paid__c, fix location name in result csv.
 *	2017-08-31	B. Leaman	BLL2 - report any errors updating vehicle inventory, don't update
 *							original floored amount if NOT null per Deeanna Egli -- so we should
 *							now keep the first original floored amount locked in.
 *	2017-10-20	B. Leaman	BLL3 IR-0016942 - allow floored date to be uploaded by this process too.
 *	2019-10-01	B. Leaman	W-000762 BLL4 - Use salesforce ID from interactive audit rather than searching by VIN again!
 */

global class Curtailment_BatchProcess implements Database.Batchable<sObject>, Database.Stateful {
    
    global final String cBatchQuery;
    global List<String> vehicles;
    //global Map<String, Decimal> vehMap;
    global Map<String, String> vehMap;
    global String emailCSV;
    global String errors;	// BLL2a
    global String[] filters;
	global Set<String> vehIdSet;

    global Curtailment_BatchProcess(Map<String,String> vehList){

        vehMap = vehList;
        System.debug(vehMap);	// BLL2a
        vehicles = new List<String>();
        filters = new String[]{};
    	//BLL4 
		//for (String VIN : vehList.keySet()){
        //    vehicles.add(VIN);
        //    String str = '%' + VIN;
        //    filters.add(str.trim());
        //}
		vehIdSet = vehMap!=null ? vehMap.keySet() : new Set<String>();
		// BLL4

		// BLL4
        //emailCSV = '';
		emailCSV = 'Veh Id,CSV VIN,Stock#,Description,Location,Floorplan,Floored,Old Chassis Floored Date, Old Conv Floored Date,Old Original Amt, Old Current Floored Amt,Floorplan Date,Original Floored,Current Floored,Message\n';
		// BLL4 end
        errors = '';	// BLL2a
        cBatchQuery = 'SELECT Id, dealer__VIN__c, Name, Curtailments__c, Chassis_Floorplan__c, '
        		+ 'dealer__Store_Location__c, dealer__Store_Location__r.Name, '	// BLL1a 
        		+ 'Floorplanned__c, Current_Floored_Amount__c, ' 
        		+ 'Original_Floored_Amount__c, dealer__Stock_Number__c, Paid__c, '
        		+ 'Chassis_Floored_Date__c, Conv_Floored_Date__c '	// BLL3a 
        	+ 'FROM dealer__Vehicle_Inventory__c ' 
			+ 'WHERE Id in :vehIdSet ';	// BLL4a
        	// BLL4d + 'WHERE dealer__VIN__c LIKE :filters';
    }
    
    //start batch
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(cBatchQuery);
    }
    
    //Execute
    global void execute(Database.BatchableContext bc, List<sObject> scope){
    	List<dealer__Vehicle_Inventory__c> vehicleList = (List<dealer__Vehicle_Inventory__c>) scope;
		        
        // BLL4
		//emailCSV += 'CSV VIN,Stock#,Description,Location,Floorplan,Floored,Floorplan Date,Original Floored,Current Floored,New Floored,Message\n';	// BLL3a
		// BLL4 end
		// BLL4
        //for(String VIN : vehMap.keySet()){
		// BLL4
            Boolean wasFound = false;
            String ErrorMsg = '';
			integer count = 0;
			// BLL4
            //for(dealer__Vehicle_Inventory__c vcl : vehicleList){ if(vcl.dealer__VIN__c.contains(VIN)){ count++; }}
            for(dealer__Vehicle_Inventory__c vcl : vehicleList){
				System.debug(vcl);
            //    if(vcl.dealer__VIN__c.contains(VIN)){
            //        		string[] split = vehMap.get(VIN).split(',');
				String updateStr = vehMap.get(vcl.Id);
				if (!String.isBlank(updateStr)) {
						string[] split = updateStr.split(',');
			// BLL4 end
                    		System.debug(split);	// BLL2a
							// BLL4
							String oldChassisFlooredDate = String.valueOf(vcl.Chassis_Floored_Date__c);
							String oldConvFlooredDate = String.valueOf(vcl.Conv_Floored_Date__c);
							String oldOrigFlooredAmt = String.valueOf(vcl.Original_Floored_Amount__c);
							String oldCurrFlooredAmt = String.valueOf(vcl.Current_Floored_Amount__c);
							// BLL4 end
                    		// BLL1a
							String locationName = vcl.dealer__Store_Location__r.Name;
							if (locationName==null) locationName = '';
							locationName = locationName.replaceAll(',', ' ');
							// BLL1a end                    		
                            // BLL4 
							//if(count > 1){
                            //    //Multi Expression
                            //    if(vcl.Floorplanned__c == true){
                            //         if (vcl.Original_Floored_Amount__c==null) vcl.Original_Floored_Amount__c = Decimal.ValueOf(split[0]);	// BLL2c
                            //         vcl.Current_Floored_Amount__c = Decimal.ValueOf(split[1]);
                            //         // BLL3a
                            //         if (split.size()>=3 && !String.isBlank(split[2])) {
                            //         	Date floor_date = null;
                            //         	try { floor_date = Date.parse(split[2]);
                            //         		System.debug('Parsed date: ' + floor_date);
                            //         	} catch(Exception e) {System.debug(e.getMessage());}
                            //         	try { floor_date = Date.valueOf(split[2]);
                            //         		System.debug('Date value: ' + floor_date);
                            //         	} catch(Exception e) {System.debug(e.getMessage());}
                            //         	if (floor_date!=null) vcl.Chassis_Floored_Date__c = floor_date;
                            //         	if (floor_date!=null) vcl.Conv_Floored_Date__c = floor_date;
                            //         }
                            //         // BLL3a end
                            //         //vcl.Paid__c = true;
                            //         //vcl.Paid__c = vcl.Current_Floored_Amount__c==0;
                            //         ErrorMsg += 'Record was submitted for update. (Duplicate)';
                            //         emailCSV += vcl.dealer__VIN__c+','+vcl.dealer__Stock_Number__c+','+vcl.Name+','+locationName+','+vcl.Chassis_Floorplan__c+',,'
                            //         	+ (vcl.Chassis_Floored_Date__c!=null ? vcl.Chassis_Floored_Date__c.format() : '') + ','+vcl.Original_Floored_Amount__c+',';	// BLL3c
                            //         emailCSV += vcl.Current_Floored_Amount__c+',,'+ ErrorMsg + '\n';
                            //    }else{
                            //         ErrorMsg += 'Record was NOT submitted for update. (Duplicate: Floorplanned = false)';
                            //         emailCSV += vcl.dealer__VIN__c+','+vcl.dealer__Stock_Number__c+','+vcl.Name+','+locationName+','+vcl.Chassis_Floorplan__c+',,'
                            //         	+ (vcl.Chassis_Floored_Date__c!=null ? vcl.Chassis_Floored_Date__c.format() : '') + ','+vcl.Original_Floored_Amount__c+',';	// BLL3c
                            //         emailCSV += vcl.Current_Floored_Amount__c+',,'+ ErrorMsg + '\n';
                            //    }
                            //    ErrorMsg = '';
                            //} else{
							// BLL4 end
                               //Standard Expression
                               if(vcl.Floorplanned__c == false){
                               		ErrorMsg += 'Record was NOT updated: [Floorplanned = false]';
									// BLL4
                                    //emailCSV += vcl.dealer__VIN__c+','+vcl.dealer__Stock_Number__c+','+vcl.Name+','+locationName+','+vcl.Chassis_Floorplan__c+',,'
									emailCSV += vcl.Id + ',' + vcl.dealer__VIN__c + ',' + vcl.dealer__Stock_Number__c + ',' + vcl.Name + ',' + locationName+',' + vcl.Chassis_Floorplan__c + ',,'
										+ oldChassisFlooredDate + ',' + oldConvFlooredDate + ',' + oldOrigFlooredAmt + ',' + oldCurrFlooredAmt + ','
									// BLL4 end
                                    	+ (vcl.Chassis_Floored_Date__c!=null ? vcl.Chassis_Floored_Date__c.format() : '') + ','+vcl.Original_Floored_Amount__c+',';	// BLL3c
                                    emailCSV += vcl.Current_Floored_Amount__c+','+ ErrorMsg + '\n';
                               }else{
                                    if (vcl.Original_Floored_Amount__c==null || vcl.Original_Floored_Amount__c==0) vcl.Original_Floored_Amount__c = Decimal.ValueOf(split[0]);
                                    vcl.Current_Floored_Amount__c = Decimal.ValueOf(split[1]);
                                    //vcl.Paid__c = true;
                                    //vcl.Paid__c = vcl.Current_Floored_Amount__c==0;
                                    // BLL3a
                                    if (split.size()>=3 && !String.isBlank(split[2])) {
                                    	Date floor_date = null;
                                    	try { floor_date = Date.parse(split[2]);
                                    		System.debug('Parsed date: ' + floor_date);
                                    	} catch(Exception e) {System.debug(e.getMessage());}
                                    	try { floor_date = Date.valueOf(split[2]);
                                    		System.debug('Date value: ' + floor_date);
                                    	} catch(Exception e) {System.debug(e.getMessage());}
                                    	if (floor_date!=null) vcl.Chassis_Floored_Date__c = floor_date;
                                    	if (floor_date!=null) vcl.Conv_Floored_Date__c = floor_date;
                                    }
                                    // BLL3a end
                                    ErrorMsg += 'Record was updated.';
                                    emailCSV += vcl.Id + ',' + vcl.dealer__VIN__c + ',' + vcl.dealer__Stock_Number__c + ',' + vcl.Name + ',' + locationName+',' + vcl.Chassis_Floorplan__c + ',true,'
									// BLL4
										+ oldChassisFlooredDate + ',' + oldConvFlooredDate + ',' + oldOrigFlooredAmt + ',' + oldCurrFlooredAmt + ','
									// BLL4 end
                                    	+ (vcl.Chassis_Floored_Date__c!=null ? vcl.Chassis_Floored_Date__c.format() : '') + ','+vcl.Original_Floored_Amount__c+',';	// BLL3c
                                    emailCSV += vcl.Current_Floored_Amount__c+','+ ErrorMsg + '\n';
                               }
                            // BLL4
							//}
							// BLL4 end
                           
                           wasFound = true;
                       }                
            // BLL4
			//}
			// BLL4 end
             if(wasFound == false){
                    ErrorMsg += 'Record was not updated: Unsuccessfully Matched';
                    // BLL4
					//emailCSV += VIN + ',,,,,,,,';
					emailCSV += vcl.Id + ',,,,,,,,,,,';
					// BLL4 end
                    emailCSV += ','+ ErrorMsg + '\n';
                }
                ErrorMsg = '';
            
        }
        
		// BLL2d
        //try{
        //    update vehicleList;
        //}catch(Exception ex){
        //    
        //}
		// BLL2a - report on individual failures on vehicle update
        List<Database.SaveResult> saveresults = Database.update(vehicleList, false);
		for(Integer i=0; i<saveresults.size(); i++) {
			Database.SaveResult sr = saveresults[i];
			dealer__Vehicle_Inventory__c v = vehicleList[i];
			System.debug(v);
			System.debug(sr);
			if (!sr.isSuccess()) {
				errors += v.Id + '; ' + v.dealer__Stock_Number__c + '; ' + v.dealer__VIN__c + '; ' + v.Name + '; ' + String.valueOf(v.Current_Floored_Amount__c);
				for(Database.Error de : sr.getErrors()) errors += '; Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ' + '\n';
			}
		}
		// BLL2a end

    }
    
    //end batch
    global void finish(Database.BatchableContext bc){
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();	// BLL2a
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(emailCSV);
        //  BLL4
		//string csvname= 'CurtailmentReport.csv';
		string csvname = 'FlooringImportResults.csv';
		// BLL4 end
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        if (!String.isBlank(emailCSV)) listOfAttachments.add(csvAttc);	// BLL2a, BLL4c add condition
        
		// BLL2a
        Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('UpdateErrors.txt');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errors);
			if (!String.isBlank(errors)) listOfAttachments.add(upderrors);
		// BLL2a
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String [] { UserInfo.getUserEmail() });
        //if (UserInfo.getUserEmail().contains('marinertek.com')) mail.setToAddresses(new String[] { 'sam@marinertek.com' });
        // BLL4
		//mail.setSubject('Curtailment Processed Results');
        //mail.setPlainTextBody('Attached is the Curtailment Results.');
		mail.setSubject('Flooring Import Results');
        mail.setPlainTextBody('Attached are the Flooring Import Results.');
		// BLL4 end
        //BLL2d mail.setFileAttachments(new Messaging.EmailFileAttachment[] { csvAttc });
        mail.setFileAttachments(listOfAttachments);	// BLL2a
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        
    }
    
}