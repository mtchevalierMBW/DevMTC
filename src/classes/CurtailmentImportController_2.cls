/**
 * CurtailmentImportController_2
 * Tested By: CurtailmentImportController_TEST
 *  2017-05-03  MarinerTek
 * 
 * Flooring updates, not curtailments
 *
 * Code coverage:
 * 	2017-08-31	79% (161/202)
 *	2017-10-23	77% (170/219)
 *	2018-08-16	78% (173/219)
 *	2019-10-10	88%	(174/196)
 * 
 *	2017-10-20	B. Leaman 	BLL1 IR-0016942 - add flooring date, update chassis floor date and conversion floor date
 *							when specified. Leave alone if no value in upload. Rename "END" to "ORG" (original floored amt).
 *	2018-10-01	B. Leaman	BLL2 IR-0041179 - skip empty csv rows. An empty row causes vehicle selection where VIN like '%' (all records)
 *							which is over 50K records and hits a salesforce limit on queries.
 *	2019-10-01	B. Leaman	W-000762 BLL3 - Skip missing VIN/SERIAL# rows entirely! It's matching an empty value to EVERY SINGLE VEHICLE!
 *							Also, once the vehicle is resolved, use the salesforce ID for it rather than the VIN search in the batch process!
 */
global class CurtailmentImportController_2 {
	
    global class Curtailment {
            public string serial {get; set;}     
			public string vehId {get;set;} 
        	public string db_serial {get; set;}
            public string stock {get; set;}
            public string floor {get; set;}
        	public string floored_bool {get; set;}
            public string pmt {get; set;}
        	public string org_pmt {get; set;}
        	public string description {get; set;}
        	public string location {get; set;}
            public string orig_floored_amt {get; set;}
            public string curr_floored_amt {get; set;}
            public string new_floored_amt {get; set;}
        	public string color {get; set;}
        	public string message {get; set;}
            public dealer__Vehicle_Inventory__c VehicleInfo {get; set;}
            public string date_floored {get;set;}	// BLL1a
    }
    //global Map<String, Decimal> VIN_AMT_Values { get; set; }
    global Map<String, String> VIN_AMT_Values { get; set; }
    public String floorplan {get;set;}
    public Boolean showUploadTable;
    public Boolean showCurtailmentTable;
    public Boolean showSummaryTable;
    public Boolean testBool {get; set;}
    public Boolean curtailment_btn {get; set;}
    public Boolean reset_btn {get; set;}
    public Boolean import_btns = true;
    public Blob csvFileBody{get;set;}
    public Integer vehicleSubmitCount {get; set;}
    public string csvAsString{get;set;}
    public String[] csvFileLines{get;set;}
    // BLL3
	//public List<Curtailment> vehlist{get;set;}
	public Map<String, Curtailment> vehFlooringMap{get;set;}
	// BLL3 end
    public CurtailmentImportController_2(){
        csvFileLines = new String[]{};
        // BLL3
		//vehlist = New List<Curtailment>(); 
		vehFlooringMap = new Map<String,Curtailment>();
		// BLL3 end
      }
      
     public void importCSVFile(){
         vehicleSubmitCount = 0;
         if(testBool == true){
             floorplan = 'Test';
         }
         else if( ApexPages.currentPage().getParameters().get('floorplan') != null) {
             floorplan = String.valueOf( ApexPages.currentPage().getParameters().get('floorplan') ); 
         }else{
             ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'You must select a template before uploading the Flooring CSV.');
             ApexPages.addMessage(errorMessage);
             return;
         }
         String[] VINlist = new String[]{};
         if (csvFileBody==null) {
             ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'You must select a csv file to upload before previewing the flooring update.'));
         	return;
         }
         csvAsString = csvFileBody.toString();
         csvFileLines = csvAsString.split('\n'); 
         
         
         System.debug('Floor plan ' + floorplan);
         Curtailment_CSV_Templates__c currentTemplate = [
         	SELECT Floorplan__c, VIN_Column__c, Amount_Column__c, Original_Amount__c, Date_Floored_Column__c	// BLL1c 
         	FROM Curtailment_CSV_Templates__c 
         	WHERE Name = :floorplan LIMIT 1
         ];
         
           csvAsString = '';
           try{

               //Match csv Column Header to Template
               boolean VIN_colMatch = false;
               integer VINcol = 0;
               boolean AMT_colMatch = false;
               integer AMTcol = 0;
               boolean ORG_colMatch = false;
               integer ORGcol = 0;
               boolean DATE_colMatch = String.isBlank(currentTemplate.Date_Floored_Column__c);	// BLL1a
               integer DATEcol = -1;	// BLL1a
               
               string[] csvColumnData = csvFileLines[0].split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');
               System.debug('CSV Col ' + csvColumnData);	// BLL1c

               for(Integer i=0; i<csvColumnData.size();i++){ 
               		System.debug(csvColumnData[i]);	// BLL1a
                   if(csvColumnData[i].trim() == currentTemplate.VIN_Column__c.trim()){
                       VIN_colMatch = true;
                       VINcol = i;
                       system.debug('VIN column: '+csvColumnData[i]);
                   }
                   if(csvColumnData[i].trim() == currentTemplate.Amount_Column__c.trim()){
                       AMT_colMatch = true;
                       AMTcol = i;
                       system.debug('AMT column: '+csvColumnData[i]);
                   }
                   if(csvColumnData[i].trim() == currentTemplate.Original_Amount__c.trim()){
                       ORG_colMatch = true;
                       ORGcol = i;
                       system.debug('Orig AMT column: '+csvColumnData[i]);
                   }
                   // BLL1a
                   if (currentTemplate.Date_Floored_Column__c!=null && csvColumnData[i].trim() == currentTemplate.Date_Floored_Column__c.trim()) {
                   		DATE_colMatch = true;
                   		DATEcol = i;
						system.debug('Date Floored column: '+csvColumnData[i]);
                   }
                   // BLL1a end
               }
               
               if(VIN_colMatch == false) ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Template Column did not match on VIN column of uploaded csv. Review csv Column Headers and try again.'));
			   if (AMT_colMatch == false) ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Template Column did not match on Amount column of uploaded csv. Review csv Column Headers and try again.'));
			   if (ORG_colMatch == false) ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Template Column did not match on Original Amount column of uploaded csv. Review csv Column Headers and try again.'));
               // BLL1a
               if (DATE_colMatch == false) ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Could not find Floored Date column (' + currentTemplate.Date_Floored_Column__c.trim() + ') in upload'));
               // BLL1a
			   if (ApexPages.hasMessages(ApexPages.Severity.ERROR)) return;

				for(Integer i=1;i<csvFileLines.size();i++){
					// BLL2a skip empty rows
					System.debug(csvFileLines[i]);
					if (!String.isBlank(csvFileLines[i].replace(',','').trim())) {
                   		// BLL1d Curtailment vehObj = new Curtailment() ;
                   		string[] csvRecordData = csvFileLines[i].split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');
                    	if(csvRecordData[VINcol].contains('')){ csvRecordData[VINcol] = csvRecordData[VINcol].replaceAll(' ', ''); }
                    	string str = '%' + csvRecordData[VINcol];
                    	System.debug(String.valueOf(i) + ' : "' + str + '"');	// BLL3c
                    	if (!String.isBlank(csvRecordData[VINcol])) VINlist.add(str.trim());	// BLL2c don't add if blank
					}
                }               
               
			   	// BLL3 add "and Chassis_Floorplan__c=:currentTemplate.Floorplan__c"
               	List<dealer__Vehicle_Inventory__c> VehiclesList = [
					SELECT Id, dealer__VIN__c, Name, Curtailments__c, dealer__Location__c, Chassis_Floorplan__c,
							Floorplanned__c, Current_Floored_Amount__c, dealer__Stock_Number__c, Paid__c,Original_Floored_Amount__c 
					FROM dealer__Vehicle_Inventory__c 
					WHERE dealer__VIN__c LIKE :VINlist
				];
				//and Chassis_Floorplan__c=:currentTemplate.Floorplan__c	
				system.debug(VINlist);
               	system.debug(VehiclesList);
				// BLL3
				Map<String, List<dealer__Vehicle_Inventory__c>> vinMap = new Map<String, List<dealer__Vehicle_Inventory__c>>();
				for(dealer__Vehicle_Inventory__c v : VehiclesList) {
					List<dealer__Vehicle_Inventory__c> vlist = vinMap.get(v.dealer__VIN__c);
					if (vlist==null) vlist = new List<dealer__Vehicle_Inventory__c>();
					vlist.add(v);
					vinMap.put(v.dealer__VIN__c, vlist);
				}
				// BLL3
               
               //VIN_AMT_Values = new Map<String, Decimal>();
               VIN_AMT_Values = new Map<String, String>();
               
               for(Integer i=1;i<csvFileLines.size();i++){
               	
					// BLL2a
               		if (!String.isBlank(csvFileLines[i].replace(',','').trim())) {
               	
                   		Curtailment vehObj = new Curtailment() ;
                   		string[] csvRecordData = csvFileLines[i].split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)');
                   		if(csvRecordData[VINcol].contains('')){ csvRecordData[VINcol] = csvRecordData[VINcol].replaceAll(' ', ''); }
                   		vehObj.serial = csvRecordData[VINcol]; 
						// BLL3
						if (vehObj.serial!=null) vehObj.serial = vehObj.serial.trim();
						// BLL3
                   		string xstr = csvRecordData[AMTcol].trim();
                   		string ystr = csvRecordData[ORGcol].trim();
                   		String dstr = DATEcol>=0 ? csvRecordData[DATEcol].trim() : '';	// BLL1a
                   
                   		if(csvRecordData[AMTcol].contains('"'))xstr = csvRecordData[AMTcol].replaceAll('"', '');
                   		csvRecordData[AMTcol] = xstr.trim();
                   		//vehObj.pmt = csvRecordData[AMTcol];
                   
                   		if(csvRecordData[AMTcol].contains('$'))xstr = csvRecordData[AMTcol].replace('$', '');
                   		csvRecordData[AMTcol] = xstr.trim();
                   
                   		if(!csvRecordData[AMTcol].contains('.')) xstr = csvRecordData[AMTcol].trim() + '.00';
                   		csvRecordData[AMTcol] = xstr.trim();
                   
                   		if(csvRecordData[AMTcol].contains(',')) xstr = csvRecordData[AMTcol].replace(',', '');
                   		csvRecordData[AMTcol] = xstr.trim();
                   		vehObj.pmt = csvRecordData[AMTcol];
                   
                   		ystr = csvRecordData[ORGcol].replaceAll('"', '');
                   		csvRecordData[ORGcol] = ystr.trim();
                   		//vehObj.org_pmt = csvRecordData[ORGcol];
                   
                   		if(csvRecordData[ORGcol].contains('$')) ystr = csvRecordData[ORGcol].replace('$', '');
                   		csvRecordData[ORGcol] = ystr.trim();
                   
                   		if(!csvRecordData[ORGcol].contains('.')) ystr = csvRecordData[ORGcol].trim() + '.00';
                   		csvRecordData[ORGcol] = ystr.trim();
                   
                   		if(csvRecordData[ORGcol].contains(',')) ystr = csvRecordData[ORGcol].replace(',', '');
                   		csvRecordData[ORGcol] = ystr.trim();

						vehObj.org_pmt = csvRecordData[ORGcol];
						vehObj.date_floored = dstr;	// BLL1a
                   		vehObj.color = 'black';
                   
                   		Boolean wasFound = false;
                   		Integer count = 0;

						// BLL3a
						if (!String.isBlank(vehObj.serial) && vehObj.serial.length()>=6) {
						// BLL3 end

                   			//for (dealer__Vehicle_Inventory__c vcl : VehiclesList) {
							//   if(vcl.dealer__VIN__c.endswith(vehObj.serial)){ 
							//	   count++; 
							//	}
							//}
							for(String vin : vinMap.keySet()) {
								if (vin.endswith(vehObj.serial)) {
									count += vinMap.get(vin).size();
								}
							}
							// BLL3
							//if (count==0) {
							//	vehObj.description = 'Error: VIN/Serial# not found in inventory for floorplan ' + currentTemplate.Floorplan__c + '.';
							//	vehObj.color = 'red';
                        	//	//BLL3
							//	//vehlist.add(vehObj);
							//	if (!vehFlooringMap.containsKey(vehObj.serial)) {
							//		vehFlooringMap.put(vehObj.serial, vehObj);
							//	} else {
							//		vehObj.description = 'Error: Duplicate VIN/Serial# in import file.';
							//		vehFlooringMap.put(vehObj.serial+' [dup]', vehObj);
							//	}
							//	// BLL3 end
							//}
                   			//for (dealer__Vehicle_Inventory__c vcl : VehiclesList) {
							for(String vin : vinMap.keySet()) {
								//if(vcl.dealer__VIN__c.contains(csvRecordData[VINcol].trim())){
								if(vin.endsWith(vehObj.serial)) {
									List<dealer__Vehicle_Inventory__c> vlist = vinMap.get(vin);
									dealer__Vehicle_Inventory__c vcl = vlist[0];
									Integer j=1;
									while (vcl.Chassis_Floorplan__c!=currentTemplate.Floorplan__c
										&& vlist.size()>j) {
										vcl = vlist[j];
									}
								// BLL3 end
                        	   		vehObj.db_serial = vcl.dealer__VIN__c;
                        	   		vehObj.stock = vcl.dealer__Stock_Number__c;
                        	   		vehObj.floor = vcl.Chassis_Floorplan__c;
                        	   		vehObj.floored_bool = String.valueOf(vcl.Floorplanned__c);
                        	   		vehObj.message = vcl.Name;
                        	   		// BLL3
									//if(count > 1){
                        	       	//	//Multi Expression
									// BLL3 end
                        	       	if (vcl.Floorplanned__c == true && vcl.Chassis_Floorplan__c == currentTemplate.Floorplan__c) {
                        	           		try {
                        	               		//Decimal mapAmt = Decimal.valueOf(csvRecordData[AMTcol].trim());
                        	               		Decimal mapAmt = Decimal.valueOf(csvRecordData[AMTcol].trim());
                        	               		Decimal emapAmt = Decimal.valueOf(csvRecordData[ORGcol].trim());
                        	               		//VIN_AMT_Values.put(vehObj.serial, mapAmt);
                        	               		string str = csvRecordData[ORGcol].trim() + ',' + csvRecordData[AMTcol].trim();
                        	               		if (DATEcol>=0) str += ',' + csvRecordData[DATEcol].trim();	// BLL1a
                        	               		System.debug(vehObj.serial + ' : ' + str);	// BLL1a
                        	               		// BLL3
												//VIN_AMT_Values.put(vehObj.serial, str);
												vehObj.vehId = vcl.Id;	
												VIN_AMT_Values.put(vehObj.vehId, str);
												wasFound = true;
												// BLL3 end
                        	               		vehObj.description = 'Successfully mapped VIN: Ready to process.';
                        	               		vehObj.color = 'green';
                        	           		} catch(Exception ex)	{
                        	               		vehObj.description = 'Error: Conversion to Decimal value failed.';
                        	               		vehObj.color = 'red';
                        	           		}
                        	       		// BLL3
										//} else if(vcl.Chassis_Floorplan__c != currentTemplate.Floorplan__c) {
                        	           	//	vehObj.description = 'Warning: CSV VIN matched on more than one record. (This records Chassis Floorplan does not match template selected.)';
                        	           	//	vehObj.color = 'gold';
                        	       		//} else if(vcl.Floorplanned__c == false) {
                        	           	//	vehObj.description = 'Warning: CSV VIN matched on more than one record. (This records Floorplanned flag is set to false.)';
                        	           	//	vehObj.color = 'gold';
                        	       		//}
                        	       		//vehlist.add(vehObj);
                        	       		////refresh for next vehicle
                        	       		//vehObj = new Curtailment();
                        	       		//vehObj.serial = csvRecordData[VINcol]; 
                        	       		//vehObj.pmt = csvRecordData[AMTcol];
										// BLL3 end
                        	   		} else {
                        	       		//Standard Expression
                        	       		if (vcl.Floorplanned__c == false) {
                        	       			vehObj.description = 'Error: Vehicle Record is not set to Floored.';
                        	       			vehObj.color = 'red';
                        	       		} else if(vcl.Chassis_Floorplan__c != currentTemplate.Floorplan__c) {
                        	           		vehObj.description = 'Error: Vehicle Record does not match the template floorplan.';
                        	           		vehObj.color = 'red';
									    }
									// BLL3
                        	       	//	} else {
                        	        //   		try {
                        	        //       		Decimal mapAmt = Decimal.valueOf(csvRecordData[AMTcol].trim());
                        	        //       		Decimal emapAmt = Decimal.valueOf(csvRecordData[ORGcol].trim());
                        	        //       		string str = csvRecordData[ORGcol].trim() + ',' + csvRecordData[AMTcol].trim();
                        	        //       		if (DATEcol>=0) str += ',' + csvRecordData[DATEcol].trim();	// BLL1a
                        	        //       		System.debug(str);	// BLL1a
                        	        //       		// BLL3
									//			//VIN_AMT_Values.put(vehObj.serial, str);
									//			vehObj.vehId = vcl.Id;	
									//			VIN_AMT_Values.put(vehObj.vehId, str);
									//			// BLL3 end
                        	        //       		vehObj.description = 'Successfully mapped VIN: Ready to process.';
                        	        //       		vehObj.color = 'green';
                        	        //       		vehicleSubmitCount++;
                        	        //   		} catch(Exception ex) {
                        	        //       		vehObj.description = 'Error: Conversion to Decimal value failed.';
                        	        //       		vehObj.color = 'red';
                        	        //   		}
                        	       	//	}
									// BLL3 end
                        	   		}
	
                        	   		// BLL3
									//wasFound = true;
									// BLL3
                       			}
                   			}
						// BLL3a
						}
						// BLL3 end
                   
                   		//prevent multis from added twice
                   		// BLL3
						//if(count < 2){
						// BLL3 end
                       		if(wasFound == false && count>0){
								vehObj.description = 'Error: VIN/Serial# did not match any floored vehicles.';
                        		vehObj.color = 'red';
							} else if (wasFound == false) {
								vehObj.description = 'Error: VIN/Serial# did not match any vehicles with floorplan ' + currentTemplate.Floorplan__c + '.';
                        		vehObj.color = 'red';
							}	// BLL3a
                   			//BLL3
							//vehlist.add(vehObj);
							String key = vehObj.vehId!=null ? vehObj.vehId : vehObj.serial;
							if (!vehFlooringMap.containsKey(key)) {
								vehFlooringMap.put(key, vehObj);
								if (vehObj.color=='green') vehicleSubmitCount++;
							} else {
								vehObj.description = 'Error: Duplicate VIN/Serial# in import file.';
	                       		vehObj.color = 'red';
								vehFlooringMap.put(key+' [dup]', vehObj);
							}
							// BLL3 end
                		// BLL3
						//}
						// BLL3 end
               		}	// BLL2a   
               }         

            }
            catch (Exception e)
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage());
                ApexPages.addMessage(errorMessage);
            }  
            reset_btn = true;
            import_btns = false;
            curtailment_btn = true; 
         	showUploadTable = false;
            showCurtailmentTable = true;
            showSummaryTable = false;
      }
      
      public void submitCurtailments(){
		  System.debug(VIN_AMT_Values);
          Curtailment_BatchProcess cbatch = new Curtailment_BatchProcess(VIN_AMT_Values);
		  Database.executeBatch(cbatch);
          
          
          
            import_btns = false;
            reset_btn = true;
            curtailment_btn = false; 
            showCurtailmentTable = false;
            showSummaryTable = true;      
            csvFileBody = null;

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
    
    public Boolean getShowUploadTable(){
        return showUploadTable;
    }
    
    public Integer getvehicleSubmitCount(){
        return vehicleSubmitCount;
    }
    
    public Boolean getShowCurtailmentTable(){
        return showCurtailmentTable;
    }
    
    public List<Curtailment_CSV_Templates__c> getOptions() {
        List<Curtailment_CSV_Templates__c> options = Curtailment_CSV_Templates__c.getall().values();
        
        return options;
    }

	// BLL3
	public List<Curtailment> getVehList() {
		return vehFlooringMap==null ? null : vehFlooringMap.values();
	}
	// BLL3 end

}