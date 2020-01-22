/**
 * DevSandbox_PopulateData
 * Tested by: DevSandbox_PopulateData_TEST
 * Date: Jul 24, 2017
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 * 2017-09-28	83% (194/235)
 * 2018-04-30	83% (204/244)
 * 
 * Run it now:
Database.executeBatch(new DevSandbox_PopulateData('devSandboxSampleData', true),1);
Database.executeBatch(new DevSandbox_PopulateData('devSandboxSampleData', true, 2, 2),1);
 *
 * Verify usability of zip resource (ensure all csv files are valid when read as strings):
 *-------------------------------------
	DevSandbox_PopulateData c = new DevSandbox_PopulateData('devSandboxSampleData',false);
	for(DevSandbox_PopulateData.DataStep s : c.remainingSteps) {
		try {
			String fileData = c.FileDataFromZipResource(c.zipresource, s.CsvName);
			System.debug(s.CsvName + ' [OK]');
		} catch(Exception e) {
			System.debug(s.CsvName + ' [ERROR] ' + e.getMessage());
		}
	}
 *-------------------------------------
 */
global class DevSandbox_PopulateData implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
  
	//global final String query;
	global boolean doUpdate;
    global String errors;
    global String results;
    global String zipresource;
    global String jsonpayload;
    global DataStep thisStep;
    global Integer fromStepNbr;
    global Integer toStepNbr;
    global List<DataStep> remainingSteps;
    global Map<String,Id> idMap;	// Used to map old Ids to new Ids so data references work! 
	global Map<String, Schema.SObjectType> gd;
	
	// DevSandbox_PopulateData constructor - generate query string & initialize
	global DevSandbox_PopulateData(String zipfile, boolean doUpd) {
		this(zipfile, doUpd, null, null);
	}
	
	global DevSandbox_PopulateData(String zipfile, boolean doUpd, Integer fromStep, Integer toStep) {
		Organization org = [select Id, isSandbox from Organization limit 1];
		doUpdate = doUpd;
		zipresource = zipfile;
		jsonpayload = FileDataFromZipResource(zipresource, 'script.json');
		//System.debug(jsonpayload);

		remainingSteps = new List<DataStep>();
		List<DataStep> allsteps;
		allSteps = (List<DataStep>) JSON.deserialize(jsonpayload, List<DataStep>.class);
		System.debug(allSteps.size());
		if (allSteps==null) allSteps = new List<DataStep>();
		//if (remainingSteps.size()>0) {
		//	thisStep = remainingSteps.remove(0);
		//	System.debug(thisStep);
		//	System.debug(remainingSteps);
		//}
		fromStepNbr = fromStep;
		toStepNbr = toStep;
		if (fromStepNbr==null) fromStepNbr = 1;
		if (toStepNbr==null) toStepNbr = allSteps.size();
		for(Integer i=fromStepNbr; i<=toStepNbr; ++i) remainingSteps.add(allSteps[i-1]);
		System.debug(remainingSteps.size());

		// dummy soql to just return a record
		//String soql = 'select Id, Name from User ';
		//if (!org.isSandbox && !Test.isRunningTest()) soql += ' and Id=null '; 
		//soql += 'limit ' + String.valueOf(allSteps.size());
		if (!org.isSandbox && !Test.isRunningTest()) remainingSteps.clear();
		
		//query = soql;
		errors = '';
		results = '';
		if (idMap==null) idMap = new Map<String,Id>();
		if (gd==null) gd =  Schema.getGlobalDescribe();
	}

	//global DevSandbox_PopulateData(String zipfile, String jsonstr, Map<Id,Id> idsmapped, boolean doUpd) {
	//	doUpdate = doUpd;
	//	jsonpayload = jsonstr;
	//	zipresource = zipfile;
	//	idMap = idsmapped;
	//
	//	remainingSteps = (List<DataStep>) JSON.deserialize(jsonpayload, List<DataStep>.class);
	//	if (remainingSteps.size()>0) {
	//		thisStep = remainingSteps.remove(0);
	//	}
	//
	//	// dummy soql to just return a record
	//	String soql = 'select Id, Name from Organization where isSandbox=true limit 1'; 
	//	query = soql;
	//	errors = '';
	//	results = '';
	//	if (idMap==null) idMap = new Map<String,Id>();
	//	if (gd==null) gd =  Schema.getGlobalDescribe();
	//}

	// start - query the database
	//global Database.QueryLocator start(Database.BatchableContext bc) {
	//	return Database.getQueryLocator(query);
	//}
	// alternate start method for iterable
	global Iterable<sObject> start(Database.BatchableContext bc) {
		List<sObject> objList = new List<sObject>();
		//objList = remainingSteps;
		for(Integer i=0; i<remainingSteps.size(); ++i) objList.add(new Contact());
		System.debug(objList.size());
		return objList;
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {

		System.debug(remainingsteps);
		System.debug(scope);
		for(sObject s : scope) {
	
			if (remainingSteps.size()>0) {
				thisStep = remainingSteps.remove(0);
				System.debug(thisStep);
				System.debug(remainingSteps);
			}

			Map<String,SObject> sobjMap = new Map<String,sObject>();
			
			String uploaddata = '';
			if (thisStep!=null && thisStep.DataSource=='csv') {
				System.debug(zipresource);
				System.debug(thisStep.CsvName);
				uploaddata = FileDataFromZipResource(zipresource, thisStep.CsvName );
				System.debug(uploaddata);
				if (!String.isBlank(uploaddata)) sobjMap = GenerateSObjectMapFromCSV(uploaddata, thisStep, idMap);
			}
			System.debug('Number of records to update: ' + String.valueOf(sobjMap.size()));
			
			// Do inserts/updates!
			if (sobjMap.size()>0)  {
				Database.SaveResult[] saveresults = new List<Database.SaveResult>();
				List<SObject> updObj = sobjMap.values();
				try {
					for(Integer i=0; i<5 && i<updObj.size(); ++i) System.debug(updObj[i]);
				} catch(Exception e) { System.debug(e.getMessage()); }
	
				System.debug(thisStep.Action);
				if (doUpdate && thisStep.Action=='insert') {
					System.debug('Ready to insert records');
					Map<String,Id> newIdMap = new Map<String,Id>();
					//System.debug(sobjMap.keySet());
					saveresults = Database.insert(sobjMap.values(), false);
					//System.debug(sobjMap.get(sobjMap.keySet()[0]));
					//System.debug(sobjMap);
					for(String oldId : sobjMap.keySet()) {
						SObject obj = sobjMap.get(oldId);
						//System.debug(oldId);
						//System.debug(obj);
						//System.debug(thisStep.CrossRefIds);
						if (obj.get('Id')!=null && thisStep.CrossRefIds) newIdMap.put(oldId, (Id) obj.get('Id')); 
					}
					if (thisStep.CrossRefIds) System.debug('idMap follows:');
					else System.debug('ID Map not recorded for this object.');
					System.debug(newIdMap);
					idMap.putAll(newIdMap);
					System.debug(idMap.size());
				}
				
				if (doUpdate && thisStep.Action=='update') {
					System.debug('Ready to update records');
					saveresults = Database.update(updObj, false);
				} 
	
				System.debug(saveresults.size());
				System.debug(updObj.size());
				if (updObj.size()>0) System.debug(updObj[0]);
				System.debug('List of failed updates:');
				//for(Database.SaveResult sr : saveresults) {
				for(Integer i=0; i<updObj.size(); i++) {
					SObject o = updObj[i];
					String msg = o.get('Id') + ',' + o.get('Name') + ': ';
					Database.SaveResult sr = saveresults.size()>i ? saveresults[i] : null;
					if (sr!=null && !sr.isSuccess()) {
						System.debug(o);
						System.debug(sr);
						for(Database.Error de : sr.getErrors()) {
							msg += '[' + String.join(de.getFields(), ', ') + '] ' + de.getMessage() + '\r';
						}
						errors += msg;
					} else {
						results += msg + ' success\n';
					}
				}
				System.debug('List complete.');
			}
	
			// Reset results & error messages if getting too large
			if (results.length() + errors.length() > 10000000) sendEmail();
		
		}

	}
	
	public Map<String,SObject> GenerateSObjectMapFromCSV(String uploaddata, DataStep step, Map<String,Id> idMap) {
		Set<String> byteOrderMarksHex = new Set<String>{'efbbbf', 'feff', 'fffe'}; // utf-8, utf-16 big endian, utf-16 little endian
		System.debug(step);
		Map<String,SObject> oMap = new Map<String,SObject>();
		Schema.SObjectType sot = gd.get(step.APIName);
		if (sot==null) System.debug('Unable to get metadata for "' + step.APIName + '"');
		Schema.DescribeSObjectResult objd = sot!=null ? sot.getDescribe() : null;
		Map<String, Schema.SObjectField> fieldmap = objd!=null ? objd.fields.getMap() : new Map<String,Schema.SObjectField>();
		Map<String, Schema.DescribeFieldResult> fieldDescMap = new Map<String, Schema.DescribeFieldResult>();
		for(String f : fieldmap.keySet()) fieldDescMap.put(f.toLowerCase(), fieldmap.get(f).getDescribe());
		System.debug(fieldDescMap); 

		uploaddata=encodeQuotedNewline(uploaddata);
		System.debug('after encodeQuotedNewline');
		System.debug(uploaddata);
		List<String> csvLines = splitCsvLines(uploaddata);	// regex too complicated for forms obj
		//System.debug(csvLines);
		System.debug(csvlines.size());
		for(String l : csvLines) l = decodeQuotedNewline(l);
		System.debug(csvlines.size());
		
		String csvHdgLine = csvLines.size()>0 ? csvLines.remove(0) : '';
		System.debug(csvHdgLine);
		// strip utf-8 byte order encoding 
		if (byteOrderMarksHex.contains(EncodingUtil.convertToHex(Blob.valueOf(csvHdgLine.substring(0,1))))) {
			System.debug('strip utf-8 byte order encoding character');
			csvHdgLine = csvHdgLine.substring(1);
		}
		System.debug(csvlines.size());
		System.debug(csvHdgLine);
		 
		List<String> csvfldnames = csvHdgLine.split(',');
		List<String> fldnames = new List<String>();
		for(String c : csvfldnames) fldnames.add(c.trim().toLowerCase().replace('"',''));
		System.debug(fldnames);

		Integer lnbr = 0;
		for(String line : csvLines) {
			//System.debug(++lnbr);
			//System.debug(line);
			// replace double-quotes that indicate empty fields with just no value
			while (line.indexOf(',"",')>=0) line = line.replace(',"",', ',,');
			SObject obj = sot.newSObject();
			String oldId = null;

			// Idea TODO: if no quotes on the line, just use "split" -- might be faster
			

			// Split csv line into columns (handle quoted strings with commas!)
			// handle commas in quoted values: field1, "John, Amy Smith", field3
			// ignore quotes inside strings (dbl-quoted):  "This is a ""quoted"" string."
			List<String> coldata = new List<String>();
			boolean inquote = false;
			Integer start = 0;
			Integer i=0;
			for(i=0; i<line.length(); i++) {
				if (line.substring(i, i+1)=='"' && line.length()>i+1 && line.substring(i+1, i+2)=='"') {
					if (inquote) i++;
				} else {
					if (line.substring(i, i+1)=='"') inquote = !inquote;
				}
				if (line.length()>=i+1 && line.substring(i ,i+1)==',' && !inquote) {
					String fldvalue = line.substring(start, i).trim();
					// remove begin/end quotes
					if (fldvalue.startsWith('"') && fldvalue.endsWith('"')) fldvalue = fldvalue.removeStart('"').removeEnd('"');
					fldvalue = fldvalue.replace('""', '"');	// dbl-quotes to single quotes
					coldata.add(fldvalue);
					start = i+1;
				}
			}
			// last column...
			String fldvalue = line.substring(start).trim();
			// remove begin/end quotes
			if (fldvalue.startsWith('"') && fldvalue.endsWith('"')) fldvalue = fldvalue.removeStart('"').removeEnd('"');
			fldvalue = fldvalue.replace('""', '"');	// dbl-quotes to single quotes
			coldata.add(fldvalue);
			
			//System.debug('data columns=' + String.valueOf(coldata.size()));
			Set<String> skipFieldNames = new Set<String>();
			if (step.SkipFields!=null)
				for(String f : step.SkipFields) skipFieldNames.add(f.toLowerCase());

			// TODO: fill SObject from field data & set oldId
			for(Integer c=0; c<coldata.size(); c++) {
				String fldname = fldnames[c];
				Schema.DescribeFieldResult fld = fieldDescMap.get(fldname);
				//System.debug(fldname);
				
				String strvalue = coldata [c];
				//System.debug(fldname + ' <= ' + strvalue);
				//System.debug(fldname.length());
				//System.debug(fldname.equalsIgnoreCase('id'));
				//System.debug(fldname=='id');

				// special handling of record id field:
				if (fldname=='id') {
					//System.debug('oldId='+strvalue);
					oldId = strvalue;
				} // else System.debug(fldname + ' is not "id"');

				try {
					
				if (fldname=='id' && step.Action=='update') {
					System.debug('Map old id=' + oldId + ' to new id=' + idMap.get(oldId));
					obj.put('Id', idMap.get(oldId));
				}

				//if (fld!=null) System.debug(fld.isUpdateable());
				//if (fld!=null) System.debug(skipFieldNames.contains(fldname.toLowerCase()));
				if (!String.isBlank(fldname) && fld!=null && !skipFieldNames.contains(fldname.toLowerCase())) {
					//System.debug(fldname);
					//System.debug(strvalue);
					if ((Step.Action!='update' && fld.isCreateable())
						|| (thisStep.Action=='update' && fld.isUpdateable())) {

						Schema.DisplayType fieldtype = fld.getType();
						//System.debug(fieldtype);
						boolean islookupfield = fieldtype==Schema.DisplayType.REFERENCE;
						//System.debug(islookupfield);
						
						// TODO: if it's a lookup reference field
						if (islookupfield && !String.isBlank(strvalue) 
							&& (strvalue.length()==15 || strvalue.length()==18)
							&& idMap.containsKey(strvalue)) {
							//System.debug(strvalue + ' map to new id ' + idMap.get(strvalue));
							strvalue = idMap.get(strvalue);
						}
	
						// TODO: handle various field types!
						//System.debug(obj);
						if (fldname!='id' && !String.isBlank(strvalue)) {
							//System.debug('Assign ' + fldname + '=' + strvalue);
							if (fieldtype==Schema.DisplayType.STRING) {obj.put(fldname, strvalue); }
							else if (fieldtype==Schema.DisplayType.REFERENCE) {obj.put(fldname, (Id) strvalue); }
							else if (fieldtype==Schema.DisplayType.BOOLEAN) {obj.put(fldname, (strvalue=='1' || strvalue.equalsIgnoreCase('true'))); }
							else if (fieldtype==Schema.DisplayType.CURRENCY) {obj.put(fldname, Decimal.valueOf(strvalue)); }
							else if (fieldtype==Schema.DisplayType.INTEGER) {obj.put(fldname, Integer.valueOf(strvalue)); }
							else if (fieldtype==Schema.DisplayType.DOUBLE) {obj.put(fldname, Double.valueOf(strvalue)); }
							else if (fieldtype==Schema.DisplayType.PERCENT) {obj.put(fldname, Double.valueOf(strvalue)/100); }
							else if (fieldtype==Schema.DisplayType.DATE) {
								boolean setdate = false;
								try {
									obj.put(fldname, Date.parse(strvalue));
									setdate = true;
								} catch(Exception e) { }
								try {
									if (setdate==false) obj.put(fldname, Date.valueOf(strvalue));
									setdate = true;
								} catch(Exception e) { }
							}
							else if (fieldtype==Schema.DisplayType.DATETIME) {obj.put(fldname, DateTime.parse(strvalue)); }
							else if (fieldtype==Schema.DisplayType.MULTIPICKLIST) {obj.put(fldname, strvalue);}
							else if (fieldtype==Schema.DisplayType.PICKLIST) {obj.put(fldname, strvalue);}
							else {obj.put(fldname, strvalue); }	// default to String
						}
						//else System.debug('Skip assignment');
					}

				}
				} catch(Exception e) {
					errors += e.getMessage();
				}
			}
			System.debug(obj);
			System.debug(oldId);
			if (oldId!=null) oMap.put(oldId,obj);
			else if (obj!=null) System.debug('Original record Id missing: ' + obj.get('Name'));
		}
		
		return oMap; 
	}

	public List<String> splitCsvLines(String s) {
		List<String> lines = new List<String>();
		while (s.contains('\n')) {
			String line = s.substringBefore('\n');
			if (!String.isBlank(line)) lines.add(line);
			s = s.substringAfter('\n');
		}
		if (!String.isBlank(s)) lines.add(s);
		return lines;
	}
	
	global String encodeQuotedNewline(String s) {
		String result = '';
		Integer pos = 0;
		Integer q = s.indexOf('"', pos);
		// found open quote...
		while (q>=0) {

			// from last-used close-quote position to current quote position
			result += s.substring(pos, q);

			// find close quote
			if (s.length()>=q+1 && s.substring(q,q+1)=='"') {
				pos = s.indexOf('"', q+1);
				// skip "", which are quotes within a quoted string.
				while(pos>=0 && s.length()>=pos+2 && s.substring(pos,pos+2)=='""') {
					pos = s.indexOf('"', pos+2);
				}
				if (pos<0) pos = s.length();
			} else pos = q+1; 

			//System.debug(q);
			//System.debug(pos);
			if (pos>=q) result += s.substring(q,pos).replace('\n','<<newline>>');
			else result += s.substring(q);

			q = s.indexOf('"', pos+1);	// find next open quote
		}
		System.debug(pos);
		if (pos>=0) result += s.substring(pos);
		return result;
	}
	global String decodeQuotedNewline(String s) {
		return s.replace('<<newline>>','\n');
	}
	
	// finish - send results via email
	global void finish(Database.BatchableContext bc) {
		//// Next step 
		//MW_TriggerControls__c DevPopulateData = MW_TriggerControls__c.getInstance('DevPopulateData');
		//System.debug(DevPopulateData);
		//System.debug(remainingSteps);
		//if ((remainingSteps!=null && remainingSteps.size()>0)
		//	&& (DevPopulateData==null || DevPopulateData.Enabled__c==true)) {
		//	System.debug('Submitting next step...');
		//	Database.executeBatch(new DevSandbox_PopulateData(
		//		zipresource, JSON.serialize(remainingSteps), idMap, doUpdate
		//	));
		//} else System.debug('No more steps or aborting');
		sendEmail();	// to be commented out after testing (probably)
	}


	// sendEmail of the results	
	global void sendEmail() {
		//Organization org = [select Id, Name, isSandbox from Organization limit 1];
		Organization org = OrganizationSingleton.getInstance();
		String csvheader = 'Batch populate data in dev sandbox results:\n';
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Batch update DevSandbox_PopulateData complete - UPDATES');
		String body = 'Batch update DevSandbox_PopulateData has completed.\n\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('results.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + results);
			if (!String.isBlank(results)) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('UpdateErrors.txt');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errors);
			if (!String.isBlank(errors)) listOfAttachments.add(upderrors);
		Messaging.EmailFileAttachment idmapatt = new Messaging.EmailFileAttachment();
			idmapatt.setContentType('text/csv');
			idmapatt.setFileName('idmap.csv');
			idmapatt.setInline(false);
			String idmapcsv = '';
			for(Id fromid : idMap.keySet()) idmapcsv += fromid+','+idMap.get(fromid) + '\n';
			idmapatt.Body = Blob.valueOf('From_Id,To_Id\n'+idmapcsv);
			if (!String.isBlank(idmapcsv)) listOfAttachments.add(idmapatt);

		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (!String.isBlank(results) || !String.isBlank(errors)) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		results = '';
		errors = '';
		
	}

	global String FileDataFromZipResource(String zipresource, String filename) {
		// ZIP archive
		List<StaticResource> resources = [
			select Id, Name, SystemModStamp
			from StaticResource 
			where Name = :zipresource
		];
		StaticResource static_resource = resources.size()>0 ? resources[0] : null;
		String url_file_ref = '/resource/';
		if (static_resource!=null) {
			url_file_ref += String.valueOf(((DateTime)static_resource.get('SystemModStamp')).getTime())
			+ '/' 
			+ static_resource.get('Name')
			+ '/' + filename;
		}
		PageReference file_ref = new PageReference(url_file_ref);
		String fileData = '';
		//System.debug(zipresource);
		//System.debug(filename);
		if (!Test.isRunningTest()) {
			Blob csvblob = file_ref.getContent();
			fileData = csvblob.toString();
		} else {
			if (filename=='script.json') fileData = '['
				+ '{"Name":"Test 1","APIName":"Contact","DataSource":"csv","CsvName":"test1.csv","Action":"insert","CrossRefIds":true},' 
				+ '{"Name":"Test 2","APIName":"Contact","DataSource":"csv","CsvName":"test2.csv","Action":"insert","CrossRefIds":true}' 
				+ ']';
			else if (filename=='test1.csv') fileData = 'Id,FirstName,LastName,Phone\n'
				+ '003c000000sfZ46,"Tester1","Contact1",(330) 555-0001\n'
				+ '003c000000qCr7K,"Tester2","Contact2",(330) 555-0002\n';
			else if (filename=='test2.csv') fileData = 'Id,Name,BillingState,Phone\n'
				+ '001c000001CSvi1,"Company1 name","OH","(440) 555-0001"\n'
				+ '001c000001D2RnA,"Company2, Inc.","PA","(717) 555-0002"\n';
		}
		return fileData;
	}

	public class DataStep {
		public String Name {get;set;}
		public String APIName {get;set;}
		public String DataSource {get;set;}	// 'csv' | 'apex'
		public String Action {get;set;} // 'insert' | 'update' (2nd pass to fill in other Ids) 
		public String CsvName {get;set;}
		public String ApexCode {get;set;}
		public Set<String> SkipFields {get;set;}
		public Integer BatchSize {get;set;} // ignored
		public boolean CrossRefIds {get;set;}
		
		public DataStep() {
		}
		
	}

}