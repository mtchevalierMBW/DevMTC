/**
 * CurtailmentImportController 
 * Tested By: CurtailmentImportController_TEST
 *  2016-09-14  MarinerTek
 * 
 * Code coverage:
 *	2017-08-31	92% (224/242)
 *	2017-10-23	92% (245/266)
 *	2018-02-27	93% (249/267)
 *	2018-08-16	93% (253/271)
 *
 *	2017-08-31	B. Leaman	BLL1 - better error reporting.
 *	2018-02-14	B. Leaman	BLL2 - New GL account for new Huntington PPV floorplan units.
 *	2018-08-16	B. Leaman	BLL3 - Need to reference the bank account for GLA 1001.
 */
public class CurtailmentImportController {

    public class Curtailment {
            public string serial {get; set;}         
            public string stock {get; set;}
            public string floor {get; set;}
            public string pmt {get; set;}
            public dealer__Vehicle_Inventory__c VehicleInfo {get; set;}
    }
    public List<CurtailmentWrapper> statusList {get;set;}
    public Boolean showCurtailmentTable;
    public Boolean showSummaryTable;
    public Boolean testBool {get; set;}
    public Boolean curtailment_btn {get; set;}
    public Boolean reset_btn {get; set;}
    public Boolean import_btns = true;
    public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public String errors;
    public String[] csvFileLines{get;set;}
    public List<Curtailment> vehlist{get;set;}
    public CurtailmentImportController(){
        csvFileLines = new String[]{};
        vehlist = New List<Curtailment>(); 
      }
    public List<CurtailmentWrapper> getSummaryList() {
        return statusList;
    }
    //BLL2d public Id gl_2515 {get;set;}
    //BLL2d public Id gl_2510 {get;set;}
    //BLL2d public Id gl_2500 {get;set;}
    //BLL2d public Id gl_1001 {get; set;}
    private Map<String,Id> glMap=new Map<String,Id>();	// BLL2a
    private List<String> neededGlAccts = new List<String>{'1001'}; 	// BLL2a	floorplanGlMap values will be added by code
    private Map<String,String> floorplanGlMap = new Map<String,String>{
    	'Huntington New'=>'2515',
    	'Huntington Rental'=>'2510',
    	'Huntington Used'=>'2500',
    	'Huntington PPV'=>'2505'
    };

    public Id WMK_CompanyID {get; set;}
    public Id WMK_dimension {get; set;}
	public c2g__codaBankAccount__c WMK_HNB_Bank {get;set;}	// BLL3a
      
     public void importCSVFile(){
           StatusList = new List<CurtailmentWrapper>();
           csvAsString = '';
           try{
               csvAsString = csvFileBody.toString();
               csvFileLines = csvAsString.split('\n'); 
                
               for(Integer i=2;i<csvFileLines.size();i++){
                   Curtailment vehObj = new Curtailment() ;
                   string[] csvRecordData = csvFileLines[i].split(',');
                   vehObj.serial = csvRecordData[12];       
                   vehObj.stock = csvRecordData[14];
                   vehObj.floor = csvRecordData[16];   
                   vehObj.pmt = csvRecordData[19];    
                   vehlist.add(vehObj);   
               }         
                //Make List of VIN #'s from CSV
                List<String> VINmbrs = New List<String>();
                for(Integer i=2; i<csvFileLines.size(); i++){
                       string[] csvRecordData = csvFileLines[i].split(',');
                       String strVIN = csvRecordData[12];
                       VINmbrs.add(strVIN);
                }
    
                //Make a single SOQL query to get vehicles in db
                List<dealer__Vehicle_Inventory__c> CrtlmntVehs = [SELECT Id
                        , dealer__VIN__c
                        , Curtailments__c
                        , Current_Floored_Amount__c
                        , dealer__Store_Location__r.Company__r.Name
                        , dealer__Store_Location__r.Company__r.Id
                    FROM dealer__Vehicle_Inventory__c 
                    WHERE dealer__VIN__c IN : VINmbrs
                      and Floorplanned__c=true and Paid__c=false    // BLLa
                ];
                                             
               //Assign vehicles to their corrresponding curtailment records
               //for(Curtailment item : vehlist){
                //   for(dealer__Vehicle_Inventory__c vehicle : CrtlmntVehs){
                //       if(item.serial == vehicle.dealer__VIN__c){
                //           item.VehicleInfo = vehicle;
                //      }
                //  }
               //}
            }
            catch (Exception e)
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage());
                ApexPages.addMessage(errorMessage);
            }  
            reset_btn = true;
            import_btns = false;
            curtailment_btn = true; 
            showCurtailmentTable = true;
            showSummaryTable = false;
      }
      
      public void submitCurtailments(){
      		errors = '';	// BLL1a
            //BLL2d gl_2515 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '2515'].Id;
            //BLL2d gl_2510 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '2510'].Id;
            //BLL2d gl_2500 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '2500'].Id;
            //BLL2d gl_1001 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '1001'].Id;
			neededGlAccts.addAll(floorplanGlMap.values());	// BLL2a
            // BLL2a
            for(c2g__codaGeneralLedgerAccount__c gl : [
            	select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c in :neededGlAccts
            ]) glMap.put(gl.c2g__ReportingCode__c, gl.Id);
            List<String> missingAccounts = new List<String>();
            for(String s : neededGlAccts) {
            	if (!glMap.containsKey(s)) missingAccounts.add(s);
            }
            if (missingAccounts.size()>0) throw new CurtailmentException('Missing GL Accounts: ' + String.join(missingAccounts, ', '));
            // BLL2a end
            WMK_CompanyID = [SELECT Id, Name FROM c2g__codaCompany__c WHERE c2g__ExternalId__c = 'WMK'].Id;	// BLL3C was: WHERE Name = 'W M K, LLC'].Id;
            WMK_dimension = [SELECT Id, Name FROM c2g__codaDimension1__c WHERE c2g__ReportingCode__c = '100'].Id;	// BLL2c reporting code instead of name selection
			WMK_HNB_Bank = [select Id, Name from c2g__codaBankAccount__c where 	c2g__OwnerCompany__c=:WMK_CompanyID and c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c='1001' limit 1];	// BLL3a
			
            Decimal SumAmt = 0;
            Integer vehThreshold = 249;
          if(testBool != null && testBool == true){
              vehThreshold = 3;
          }
            Integer currentCount = 0;
            Integer l = 0;
            List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
            //Make List of VIN #'s from CSV
            List<String> VINmbrs = New List<String>();
            for(Integer i=2; i<csvFileLines.size(); i++){
                   string[] csvRecordData = csvFileLines[i].split(',');
                   String strVIN = csvRecordData[12];
                   VINmbrs.add(strVIN);
            }
            system.debug('VIN List: ' + VINmbrs);
          
            //Make a single SOQL query to get vehicles in db
            List<dealer__Vehicle_Inventory__c> CrtlmntVehs= [SELECT Id, dealer__VIN__c, Curtailments__c, Chassis_Floorplan__c, Current_Floored_Amount__c, dealer__Stock_Number__c, Paid__c,
            dealer__Store_Location__r.Company__r.Name FROM dealer__Vehicle_Inventory__c WHERE dealer__VIN__c IN : VINmbrs AND Paid__c = false and Floorplanned__c=true 
            	//BLL2d AND (Chassis_Floorplan__c = 'Huntington Used' OR Chassis_Floorplan__c = 'Huntington Rental' OR Chassis_Floorplan__c = 'Huntington New'
            	AND Chassis_Floorplan__c in :floorplanGlMap.keySet()	// BLL2a
            	];
            // BLLa
            Set<String> cvVINs = new Set<String>();
            for(dealer__Vehicle_Inventory__c v : CrtlmntVehs) cvVINs.add(v.dealer__VIN__c);
            // BLLa end

            List<dealer__Vehicle_Inventory__c> Paid_Vehicles = [SELECT Id, dealer__VIN__c, Curtailments__c, Chassis_Floorplan__c, Current_Floored_Amount__c, dealer__Stock_Number__c, Paid__c,
            dealer__Store_Location__r.Company__r.Name FROM dealer__Vehicle_Inventory__c WHERE dealer__VIN__c IN : VINmbrs AND Paid__c = true];
            
            List<dealer__Vehicle_Inventory__c> Floor_Vehs = [SELECT Id, dealer__VIN__c, Curtailments__c, Chassis_Floorplan__c, Current_Floored_Amount__c, dealer__Stock_Number__c, Paid__c,
            dealer__Store_Location__r.Company__r.Name FROM dealer__Vehicle_Inventory__c WHERE dealer__VIN__c IN : VINmbrs AND Paid__c = false 
            //BLL2d AND Chassis_Floorplan__c != 'Huntington Used' AND Chassis_Floorplan__c != 'Huntington Rental' AND Chassis_Floorplan__c != 'Huntington New'
            AND Chassis_Floorplan__c in :floorplanGlMap.keySet()	// BLL2a
            ];
            
            system.debug('Curtailments: ' + CrtlmntVehs);
            Set<String> paidVINs = new Set<String>();
            for(dealer__Vehicle_Inventory__c v : Paid_Vehicles) paidVINs.add(v.dealer__VIN__c);
            Set<String> floorVINs = new Set<String>();
            for(dealer__Vehicle_Inventory__c v : Floor_Vehs) floorVINs.add(v.dealer__VIN__c);
            //Create a Journal Entry 
            DateTime dT = System.now();
            String timestamp =dT.month() + '/' + dT.day() + '/' + dT.year();
            c2g__codaJournal__c j = new c2g__codaJournal__c();
            j.c2g__JournalStatus__c = 'In Progress';
            j.c2g__Type__c = 'Manual Journal';
            j.c2g__OwnerCompany__c = WMK_CompanyID;
            j.c2g__JournalDate__c = date.today();
            j.c2g__Reference__c = 'Curtailment';
            j.c2g__JournalDescription__c = 'HNB FLOOR/PAY ' + timestamp;
            j.Source__c = 'GE';
            
          for(Integer f=0; f<Paid_Vehicles.size(); f++){
              CurtailmentWrapper wrapper = new CurtailmentWrapper();                                          
              wrapper.vehicle = Paid_Vehicles[f]; 
              wrapper.Status = 'Vehicle Not Submitted, Paid flag is set to true';
              wrapper.Paid = '0.00';
              wrapper.StockNum = Paid_Vehicles[f].dealer__Stock_Number__c;
              if (!cvVINs.contains(wrapper.vehicle.dealer__VIN__c)) StatusList.Add(wrapper);    // BLLc add conditional
          }
          
          for(Integer e=0; e<Floor_Vehs.size(); e++){
              CurtailmentWrapper wrapper = new CurtailmentWrapper();                                          
              wrapper.vehicle = Floor_Vehs[e]; 
              wrapper.Status = 'Vehicle Not Submitted, Check Floorplan status';
              wrapper.Paid = '0.00';
              wrapper.StockNum = Floor_Vehs[e].dealer__Stock_Number__c;
              if (!cvVINs.contains(wrapper.vehicle.dealer__VIN__c)) StatusList.Add(wrapper);    // BLLc add conditional
          }
            //for each vehicle found in db make an entry
            for(Integer x=0; x<VINmbrs.size(); x++){
                for(Integer n=0; n<CrtlmntVehs.size(); n++){
                    if(VINmbrs[x] == CrtlmntVehs[n].dealer__VIN__c){
                        
                        for(Integer i=2; i<csvFileLines.size(); i++){
                            string[] csvRecordData = csvFileLines[i].split(',');
                            if(csvRecordData[12] == CrtlmntVehs[n].dealer__VIN__c){
                                            CurtailmentWrapper wrapper = new CurtailmentWrapper();                                          
                                            wrapper.vehicle = CrtlmntVehs[n];           
                                        if(CrtlmntVehs[n].Current_Floored_Amount__c == 0){
                                                    wrapper.Status = 'Vehicle Not Submitted, Floored amt is 0';
                                                    wrapper.Paid = '0.00';
                                                    wrapper.StockNum = CrtlmntVehs[n].dealer__Stock_Number__c;
                                                    StatusList.Add(wrapper);
                                        }else{
                                                    //When threshold is met, post journal and start new one
                                                if(currentCount < vehThreshold){
                                                    CrtlmntVehs[n].Current_Floored_Amount__c = Decimal.ValueOf(csvRecordData[16]);
                                                    SumAmt = SumAmt + Decimal.ValueOf(csvRecordData[19]);
                                                
                                                    //Journal Line entry for vehicle
                                                    lines.add(new c2g__codaJournalLineItem__c());
                                                    lines[l].c2g__LineType__c = 'General Ledger Account';
                                                    //BLL2d if(CrtlmntVehs[n].Chassis_Floorplan__c == 'Huntington New'){
                                                    //BLL2d     lines[l].c2g__GeneralLedgerAccount__c = gl_2515;
                                                    //BLL2d }else if(CrtlmntVehs[n].Chassis_Floorplan__c == 'Huntington Rental'){
                                                    //BLL2d     lines[l].c2g__GeneralLedgerAccount__c = gl_2510;
                                                    //BLL2d }else if(CrtlmntVehs[n].Chassis_Floorplan__c == 'Huntington Used'){
                                                    //BLL2d     lines[l].c2g__GeneralLedgerAccount__c = gl_2500;
                                                    //BLL2d }
                                                    // BLL2a
                                                    String glcode = floorplanGlMap.get(CrtlmntVehs[n].Chassis_Floorplan__c);
                                                    if (!String.isBlank(glcode)) lines[l].c2g__GeneralLedgerAccount__c = glMap.get(glcode);
                                                    // BLL2a end
                                                    lines[l].c2g__DebitCredit__c = 'Debit';
                                                    lines[l].c2g__Dimension1__c = WMK_dimension;
                                                    lines[l].c2g__Value__c = Decimal.ValueOf(csvRecordData[19]);
                                                    lines[l].Control__c = CrtlmntVehs[n].dealer__Stock_Number__c;
                                                    lines[l].Vehicle_Inventory__c = CrtlmntVehs[n].Id;
                                                    lines[l].c2g__LineDescription__c = 'Curtailment - ' + CrtlmntVehs[n].dealer__Stock_Number__c;
                                                    wrapper.Paid = String.ValueOf(csvRecordData[19]);
                                                    wrapper.StockNum = CrtlmntVehs[n].dealer__Stock_Number__c;
                                                    wrapper.Status = 'Successfully Submitted';
                                                    if(csvRecordData[16] == '0'){
                                                        CrtlmntVehs[n].Paid__c = true;
                                                        CrtlmntVehs[n].Chassis_Floorplan__c = 'Not Floored - Fully Curtailed';
                                                        CrtlmntVehs[n].Conversion_Floorplan__c = 'Not Floored - Fully Curtailed';
                                                    }
                                                    StatusList.Add(wrapper);
                                                    currentCount++;
                                                    l = l + 1;  
                                                }else{ //post journal and credit bank when vehicle threshold was met
                                                    //Journal Line entry for bank
                                                    lines.add(new c2g__codaJournalLineItem__c());
                                                    //BLL3d lines[l].c2g__LineType__c = 'General Ledger Account';
                                                    //BLL2d lines[l].c2g__GeneralLedgerAccount__c = gl_1001;
                                                    lines[l].c2g__GeneralLedgerAccount__c = glMap.get('1001');	// BLL2a
													lines[l].c2g__LineType__c = 'Bank Account';	// BLL3a
													lines[l].c2g__BankAccount__c = WMK_HNB_Bank.Id; 	// BLL3a
                                                    lines[l].c2g__DebitCredit__c = 'Credit';
                                                    lines[l].c2g__Dimension1__c = WMK_Dimension;
                                                    lines[l].c2g__Value__c = 0 - SumAmt;
                                                    lines[l].c2g__LineDescription__c = 'HNB FLOOR/PAY - ' + timestamp;
                                                    system.debug('Sum Amount one: ' + SumAmt);
                                                    try{ //post current journals and reset
                                                        Id journalId = FinancialForce_MBW.createJournalApi(j, lines);
                                                        FFAccounting.postJournal(journalId);
                                                        //update CrtlmntVehs;
                                                    } catch (Exception e){
                                                        ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while uploading the initial curtailments. Please try again.');
                                                        ApexPages.addMessage(errorMessage);
                                                        System.Debug('Errors occurred: ' + e);
                                                    }
                                                    
                                                    l = 0;
                                                    //make new Journal
                                                    j = new c2g__codaJournal__c();
                                                    j.c2g__JournalStatus__c = 'In Progress';
                                                    j.c2g__Type__c = 'Manual Journal';
                                                    j.c2g__OwnerCompany__c = WMK_CompanyID;
                                                    j.c2g__JournalDate__c = date.today();
                                                    j.c2g__Reference__c = 'Curtailment';
                                                    j.c2g__JournalDescription__c = 'HNB FLOOR/PAY ' + timestamp;
                                                    j.Source__c = 'GE';
                                                    
                                                    //Journal Lines entry for vehicle and reset lines
                                                    lines = new List<c2g__codaJournalLineItem__c>();
                                                    lines.add(new c2g__codaJournalLineItem__c());
                                                    lines[l].c2g__LineType__c = 'General Ledger Account';
                                                    system.debug('Floorplan: ' + CrtlmntVehs[n].Chassis_Floorplan__c);
                                                    //BLL2d if(CrtlmntVehs[n].Chassis_Floorplan__c == 'Huntington New'){
                                                    //BLL2d     lines[l].c2g__GeneralLedgerAccount__c = gl_2515;
                                                    //BLL2d }else if(CrtlmntVehs[n].Chassis_Floorplan__c == 'Huntington Rental'){
                                                    //BLL2d     lines[l].c2g__GeneralLedgerAccount__c = gl_2510;
                                                    //BLL2d }else if(CrtlmntVehs[n].Chassis_Floorplan__c == 'Huntington Used'){
                                                    //BLL2d     lines[l].c2g__GeneralLedgerAccount__c = gl_2500;
                                                    //BLL2d }
                                                    // BLL2a
                                                    String glcode = floorplanGlMap.get(CrtlmntVehs[n].Chassis_Floorplan__c);
                                                    if (!String.isBlank(glcode)) lines[l].c2g__GeneralLedgerAccount__c = glMap.get(glcode);
                                                    // BLL2a end
                                                    
                                                    lines[l].c2g__DebitCredit__c = 'Debit';
                                                    lines[l].c2g__Dimension1__c = WMK_dimension;
                                                    lines[l].c2g__Value__c = Decimal.ValueOf(csvRecordData[19]);
                                                    lines[l].Control__c = CrtlmntVehs[n].dealer__Stock_Number__c;
                                                    lines[l].Vehicle_Inventory__c = CrtlmntVehs[n].Id;
                                                    lines[l].c2g__LineDescription__c = 'Curtailment - ' + CrtlmntVehs[n].dealer__Stock_Number__c;
                                                    wrapper.Paid = String.ValueOf(csvRecordData[19]);
                                                    wrapper.Status = 'Successfully Submitted';
                                                    StatusList.Add(wrapper);
                                                    //reset Count
                                                    currentCount = 1;
                                                    SumAmt = Decimal.ValueOf(csvRecordData[19]);
                                                    l = l + 1; 
                                                }        
                                                 //if there are any vehicles that posted, make a bank credit and post journal
                                    }          
                        }//if
                    }//for   
                    n = CrtlmntVehs.size();
                }else if((n + 1) == CrtlmntVehs.size() && VINmbrs[x] != CrtlmntVehs[n].dealer__VIN__c){
                        CurtailmentWrapper wrapper = new CurtailmentWrapper();
                        wrapper.vehicle.dealer__VIN__c = VINmbrs[x];
                        wrapper.Status = 'Vehicle Not Submitted, data record not found';
                        wrapper.Paid = '';
                        if (!paidVINs.contains(wrapper.vehicle.dealer__VIN__c) && !floorVINs.contains(wrapper.vehicle.dealer__VIN__c)) StatusList.Add(wrapper); // BLLc add conditional
                    }
            }//for
        }//for
               if(currentCount > 0){
                        lines.add(new c2g__codaJournalLineItem__c());
                        //BLL3d lines[l].c2g__LineType__c = 'General Ledger Account';
                        //BLL2d lines[l].c2g__GeneralLedgerAccount__c = gl_1001;
                        lines[l].c2g__GeneralLedgerAccount__c = glMap.get('1001');	// BLL2a
						lines[l].c2g__LineType__c = 'Bank Account';	// BLL3a
						lines[l].c2g__BankAccount__c = WMK_HNB_Bank.Id; 	// BLL3a
                        lines[l].c2g__DebitCredit__c = 'Credit';
                        lines[l].c2g__Dimension1__c = WMK_Dimension;
                        lines[l].c2g__Value__c = 0 - SumAmt;
                        lines[l].c2g__LineDescription__c = 'HNB FLOOR/PAY - ' + timestamp;
                        
                        try{
                        System.Debug('JOURNAL j: ' + j);
                        System.Debug('LINES lines: ' + lines);
                            Id journalId = FinancialForce_MBW.createJournalApi(j, lines);
                            FFAccounting.postJournal(journalId);
                            // BLL1d update CrtlmntVehs;
                            // BLL1a
					        List<Database.SaveResult> saveresults = Database.update(CrtlmntVehs, false);
							for(Integer i=0; i<saveresults.size(); i++) {
								Database.SaveResult sr = saveresults[i];
								dealer__Vehicle_Inventory__c v = CrtlmntVehs[i];
								System.debug(sr);
								if (!sr.isSuccess()) {
									errors += v.Id + '; ' + v.dealer__Stock_Number__c + '; ' + v.dealer__VIN__c + '; ' + v.Name + '; ' + String.valueOf(v.Current_Floored_Amount__c)
										+ '; ' + String.valueOf(v.Paid__c) + '; ' + v.Chassis_Floorplan__c + '; ' + v.Conversion_Floorplan__c; 
									for(Database.Error de : sr.getErrors()) errors += '; Error : ' + de.getMessage() + '[' + String.join(de.getFields(),', ') + '] ' + '\n';
								}
							}
							// BLL1a end
                        } catch (Exception e){
                            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured while uploading the curtailments. Please try again.');
                            ApexPages.addMessage(errorMessage);
                            System.Debug('Errors occurred: ' + e);
                        }
                    }   
            import_btns = false;
            reset_btn = true;
            curtailment_btn = false; 
            showCurtailmentTable = false;
            showSummaryTable = true;      
            csvFileBody = null;
            // BLL1a
            if (Test.isRunningTest() && String.isBlank(errors)) errors = 'No errors -- testing.';
            if (!String.isBlank(errors)) emailErrors();
            // BLL1a
      }
      
	// BLL1a
    public void emailErrors() {
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();	// BLL1a
        Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/plain');
			upderrors.setFileName('UpdateErrors.txt');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errors);
			if (!String.isBlank(errors)) listOfAttachments.add(upderrors);
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String [] { UserInfo.getUserEmail() });
        mail.setSubject('Curtailment Process - Vehicle update errors');
        mail.setPlainTextBody('See attached for vehicles that were not updated.');
        mail.setFileAttachments(listOfAttachments);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
      
    public PageReference reset() {
       PageReference newpage = new PageReference(System.currentPageReference().getURL());
       newpage.getParameters().clear();
       newpage.setRedirect(true);
       return newpage;
     }
    
    public Boolean getShowCurtailmentbtn(){
        return curtailment_btn;
    }
    
    public Boolean getShowResetbtn(){
        return reset_btn;
    }
    
    public Boolean getShowImportBtns(){
        return import_btns;
    }
    
    public Boolean getShowCurtailmentTable(){
        return showCurtailmentTable;
    }
    
    public Boolean getShowSummaryTable(){
        return showSummaryTable;
    }
        
    public class CurtailmentWrapper{
        public dealer__Vehicle_Inventory__c vehicle {get;set;}
        public String Paid {get; set;}
        public String StockNum {get; set;}
        public String Status {get;set;}
        public CurtailmentWrapper(){
            vehicle = new dealer__Vehicle_Inventory__c();
            Status = '';
        }
    }

	// BLL2a
	public class CurtailmentException extends Exception {}

}