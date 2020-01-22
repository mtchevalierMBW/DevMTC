/**
 * EOM Parts
 *
 * Coverage:
 *	2019-02-28	90%	(192/211)
 *
 * Modifications:
 * 2018-03-07	B. Leaman	BLL1 - Skip manufacturing locations in this report (they all use dim 187).
 * 2019-02-27	B. Leaman	W-000604 BLL2 - include dimensions where inv, wip or gl is null, but not if ALL are null or zero;
 */
public without sharing class PartsEOM {

	/** Parts EOM Public Variables */
	public Map<Id, String> location_names = new Map<Id, String>();
	public Map<Id, String> location_dimmension_names = new Map<Id, String>();
	public List<String> locationNamesList = new List<String>();

	public List<dealer__Parts_Inventory__c> parts_inventory = new List<dealer__Parts_Inventory__c>();
	public Map<String, Decimal> location_physical_value = new Map<String, Decimal>();
    public Map<String, Decimal> location_negative_value = new Map<String, Decimal>();
	public Map<String, Decimal> location_wip_value = new Map<String, Decimal>();
	public Map<String, Decimal> general_ledger_value = new Map<String, Decimal>();
	public List<eomData> end_of_month = new List<eomData>();
    public List<dealer__Purchase_Order__c> missingPurchaseOrderJournals = new List<dealer__Purchase_Order__c>();
	public String eomdata_json;
    public Set<Id> dim1ToInclude = new Set<Id>();
    
    // Eval Page 
    public String locationName {get;set;}
    public List<oobItems> invalidTransactions {get;set;}

	/**
	 * PartsEOM Constructor
	 * @return [description]
	 */
	public PartsEOM() {
		invalidTransactions=new List<oobItems>();
        // If Eval Page and has Var set 
        if(ApexPages.currentPage().getParameters().get('location')!=null) {
            locationName=ApexPages.currentPage().getParameters().get('location');
        }
	}

	/**
	 * [locationNames description]
	 */
	public void locationNames() {
		for(dealer__Dealer_Location__c d : [Select Id, Name, dealer__Company_Number__c, 
												Financial_Force_Dimension_1__r.Name, Financial_Force_Dimension_1__c 
												FROM dealer__Dealer_Location__c
												Where Financial_Force_Dimension_1__c != null
												and ManufacturingLocation__c=false	// BLL1a skip mfg locations
												Order By Financial_Force_Dimension_1__r.Name ASC]) {

			dim1ToInclude.add(d.Financial_Force_Dimension_1__c);
			locationNamesList.add(d.Financial_Force_Dimension_1__r.Name);
			location_names.put(d.Id, d.Financial_Force_Dimension_1__r.Name);
			location_dimmension_names.put(d.Financial_Force_Dimension_1__c, d.Financial_Force_Dimension_1__r.Name);
		}

		System.debug(locationNamesList);
	}

	
	/**
	 * [groupPhysical : Gets ledger values of all the locations]
	 */
	public void groupPhysical() {

		for(AggregateResult ar : [Select dealer__Location__c, 
										SUM(dealer__Physical_Value__c) physicalvalue
										FROM dealer__Parts_Inventory__c
                                  			WHERE dealer__On_Hand__c >=0 
										GROUP BY dealer__Location__c]) {

				String locationId = String.valueOf(ar.get('dealer__Location__c'));
				Decimal locationValue = Decimal.valueOf(String.valueOf(ar.get('physicalvalue')));

				if(location_names.get(locationId)!=null) {
					location_physical_value.put(location_names.get(locationId), locationValue);
				}
		}
	}
    
    /**
     * [groupNegative : Get negative on hand values]
     */
    public void groupNegative() {
		
        for(AggregateResult ar : [Select dealer__Location__c, 
										SUM(dealer__Physical_Value__c) physicalvalue
										FROM dealer__Parts_Inventory__c
                                  			WHERE dealer__On_Hand__c < 0 
										GROUP BY dealer__Location__c]) {

				String locationId = String.valueOf(ar.get('dealer__Location__c'));
				Decimal locationValue = Decimal.valueOf(String.valueOf(ar.get('physicalvalue')));

				if(location_names.get(locationId)!=null) {
					location_negative_value.put(location_names.get(locationId), locationValue);
				}
		}        
    }

	/**
	 * [sumGL description] 
	 * 	
	 **/
	public void sumGL() {

		// Get 1220 Account Id
		Id gl1220 = [SELECT Name, Id, c2g__ReportingCode__c, c2g__ExternalId__c FROM c2g__codaGeneralLedgerAccount__c where c2g__ExternalId__c = '1220' limit 1].Id;
            
		for(AggregateResult ar : [Select c2g__Dimension1__c,
									SUM(c2g__GeneralLedgerAccountValue__c) entryvalue
									FROM c2g__codaTransactionLineItem__c 
                                  	WHERE c2g__GeneralLedgerAccount__c =:gl1220
                                  	AND c2g__Dimension1__c IN:dim1ToInclude
									GROUP BY c2g__Dimension1__c]) {

			String dim1Id 	= 	String.valueOf(ar.get('c2g__Dimension1__c'));
			Decimal tval 	=	Decimal.valueOf(String.valueOf(ar.get('entryvalue')));

			if(location_dimmension_names.get(dim1Id)!=null) {
				general_ledger_value.put(location_dimmension_names.get(dim1Id), tval);
			}

		}
	}

	/**
	 * [groupLocationWIP description]
	 * 		- 11/07/2016 - 	Reopening a repair order retains the Journal reference.  
	 * 						The filter criteria is being changed to remove the 
	 * 						reference to the Journal and made to match the exact
	 * 						filter critera of the Report (WIP - all locations)
	 * 						- WHERE Journal__c = null Deprecated 11/7/2017 JVK
	 */
	public void groupLocationWIP() {
		for(AggregateResult ar : [SELECT dealer__Company__c, 
										SUM(dealer__Parts_Cost__c) cost
										FROM dealer__Service_Repair_Order__c 
										WHERE dealer__Status__c NOT IN('Posted', 'Void')
										GROUP BY dealer__Company__c]) {

			String locationId = String.valueOf(ar.get('dealer__Company__c'));
			Decimal cval  = Decimal.valueOf(String.valueOf(ar.get('cost')));

			if(location_names.get(locationId)!=null) {
				location_wip_value.put(location_names.get(locationId), cval);
			}
		}
	}

	/**
	 * eomData - Wrapper Class
	 * @notets This class creates a data structure for displaying the content in a normalized fasion
	 */
	public class eomData {
		public String store {get;set;}
		public Decimal inventory_value {get;set;}
        public Decimal inventory_negative {get;set;}
		public Decimal wip {get;set;}
		public Decimal general_ledger {get;set;}
		public Decimal total {get;set;}
		public Decimal variance {get;set;}
		public Decimal percent_inventory {get;set;}

		public eomData(String s, Decimal i, Decimal n, Decimal w, Decimal gl) {
            
            // Check for NULL Values
            if(i==null) { i=0; }
            if(n==null) { n=0; }
            if(w==null) { w=0; }
            if(gl==null) { gl=0; }
            
			store=s;
			inventory_value=i.setScale(2);
            inventory_negative=n.setScale(2);
			wip=w.setScale(2);
			general_ledger=gl.setScale(2);
			total=(inventory_value+inventory_negative+wip);
			variance=total.setScale(2) - gl.setScale(2);
			Decimal decimal_percent_inventory=0;
            if(gl>0) { decimal_percent_inventory=(variance/gl); }
			percent_inventory=decimal_percent_inventory.setScale(2);
		}
	}

	/**
	 * geteom 
	 * @return List of eomdata wrapper class.  This data represents month end calculations
	 */
	public List<eomData> geteom(){
		return end_of_month;
	}

	public String geteomdata_json() {
		
		// Set all the location names
		locationNames();

		// Derive Parts Ledger Value
		groupPhysical();
        
        // Derive Negative Parts Ledger Value
		groupNegative();

		// Derive GL Value
		sumGL();

		// Derive WIP
		groupLocationWIP();

		// Generate Balance Sheet Data
		for(String s : locationNamesList) {

			System.debug(s);
			System.debug(location_physical_value.get(s));
			System.debug(location_wip_value.get(s));
			System.debug(general_ledger_value.get(s));

			// BLL2
			//if(location_physical_value.get(s)!=null && location_wip_value.get(s)!=null && general_ledger_value.get(s)!=null) {
			//end_of_month.add(new eomData(
			//						s, 
			//						location_physical_value.get(s), 
            //    					location_negative_value.get(s),
			//						location_wip_value.get(s), 
			//						general_ledger_value.get(s)
			//					)
			//				);
			//}
			Decimal lpv = location_physical_value.get(s);
			Decimal lnv = location_negative_value.get(s);
			Decimal lwv = location_wip_value.get(s);
			Decimal glv = general_ledger_value.get(s);
			if (lpv==null) lpv=0.00;
			if (lnv==null) lnv=0.00;
			if (lwv==null) lwv=0.00;
			if (glv==null) glv=0.00;
			if (lpv!=0 || lnv!=0 || lwv!=0 || glv!=0) {
				end_of_month.add(new eomData( s, lpv, lnv, lwv, glv));
			}
			// BLL2d end
		}

		eomdata_json = JSON.serializePretty(end_of_month);		

		return eomdata_json;
	}
    
    public PageReference backToEOM() {
    	PageReference p = Page.PartsEOMAnalysis;
        p.setRedirect(true);
        return p;
    }
    
    public PageReference evalLocation() {
     	
        // Get Company Location ID from DIM1 Name
		dealer__Dealer_Location__c loc = [Select Id,Financial_Force_Dimension_1__c from dealer__Dealer_Location__c where Financial_Force_Dimension_1__r.Name =: locationName limit 1];
        
        // Get all Posted Repair Orders
		Set<Id> roIds = new Set<Id>();
		List<dealer__Service_Repair_Order__c> roList = [Select Id, Name, dealer__Posted_Date_Time__c, Total_Parts_Cost__c from dealer__Service_Repair_Order__c 
                                                        	where (Journal__c !=null OR dealer__Posted_Date_Time__c !=NULL) AND dealer__Total_Repair_Order_Charges__c > 0 
                                                        	AND dealer__Posted_Date_Time__c = THIS_YEAR ORDER BY dealer__Posted_Date_Time__c DESC];
        
		List< c2g__codaJournalLineItem__c > lineItems = [Select Id, Name, c2g__Value__c, c2g__Journal__r.Repair_Order__c 
                                                         	from c2g__codaJournalLineItem__c 
                                                         	where c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c = '1220' 
                                                         	and c2g__Dimension1__c =: loc.Financial_Force_Dimension_1__c
                                                        	and c2g__Journal__r.c2g__JournalStatus__c  = 'Complete'];
        
        // Create Map of the RO with Parts Total Cost
		Map<Id, dealer__Service_Repair_Order__c> ros = new Map<Id, dealer__Service_Repair_Order__c>();
		Map<Id, Decimal> roValues = new Map<Id, Decimal>();
        for(dealer__Service_Repair_Order__c ro : roList) {
            roValues.put(ro.Id, ro.Total_Parts_Cost__c);
            ros.put(ro.Id, ro);
        }
        
        Map<Id, Decimal> glValues = new Map<Id, Decimal>();
        for(c2g__codaJournalLineItem__c li : lineItems) {
            if(glValues.get(li.c2g__Journal__r.Repair_Order__c)!=null) {
				glValues.put(li.c2g__Journal__r.Repair_Order__c, (glValues.get(li.c2g__Journal__r.Repair_Order__c) + (li.c2g__Value__c*-1)));
            } else {
                glValues.put(li.c2g__Journal__r.Repair_Order__c, (li.c2g__Value__c*-1));
            }
        }
		
        // Iterate RO and chaeck balance
		for(dealer__Service_Repair_Order__c ro : roList) {
            if(glValues.get(ro.Id)!=null && ro.Total_Parts_Cost__c != glValues.get(ro.Id)) {
               invalidTransactions.add(new oobItems(ro, ro.Total_Parts_Cost__c, glValues.get(ro.Id), null, null)); 
            }    
        }
        
        return null;   
    }
    
    /**
     * purchaseOrdersNoGL
     * Fetch all purchase orders that are not open for a location (Parts Purchase Orders) and fetches all journals to see if any are missing journals.
     */
    public PageReference purchaseOrdersNoGL() {
      	dealer__Dealer_Location__c loc = [Select Id,Financial_Force_Dimension_1__c from dealer__Dealer_Location__c where Financial_Force_Dimension_1__r.Name =: locationName limit 1];
        Set<Id> poIds = new Set<Id>();
        Map<Id, dealer__Purchase_Order__c> poMap = new Map<Id, dealer__Purchase_Order__c>();
        for(dealer__Purchase_Order__c po : [SELECT Id, Name, RecordTypeId, dealer__Company__c, dealer__Status__c, dealer__PO_Amount__c, dealer__Accepted_DateTime__c  
                                            	FROM dealer__Purchase_Order__c 
                                            	where dealer__Company__c =: loc.Id 
                                            	and dealer__Status__c != 'Open'
                                           		and RecordType.Name = 'Parts Purchase']) {
        	poIds.add(po.Id);
			poMap.put(po.Id, po);
        }
        
        Map<Id, c2g__codaJournal__c> jrnls = new Map<Id, c2g__codaJournal__c >();
        for(c2g__codaJournal__c j : [Select Id, Name, c2g__JournalStatus__c, Purchase_Order__c from c2g__codaJournal__c where Purchase_Order__c IN:poIds]) {
            jrnls.put(j.Purchase_Order__c, j);
        }
        
        System.debug(poMap.size());
        System.debug(jrnls.size());

        // Look and check each journal for purchase order
		
        for(Id pid : poMap.keySet()) {
            if(jrnls.get(pid)==null) {
              missingPurchaseOrderJournals.add(poMap.get(pid));  
            }
        }
      //   
        
        return null;
    }
    
    public List<dealer__Purchase_Order__c> getmissingPurchaseOrderJournals() {
        return missingPurchaseOrderJournals;
    }
    
    public class oobItems {
        public dealer__Service_Repair_Order__c ro {get;set;}
        public List<c2g__codaJournalLineItem__c> jlines {get;set;}
        public List<dealer__Service_Job__c> sroJoblines {get;set;}
        public Decimal valueOut {get;set;}
        public Decimal valueIn {get;set;}
        public Decimal difference {get;set;}
        
        public oobItems(dealer__Service_Repair_Order__c rorecord, Decimal vo, Decimal vi, List<dealer__Service_Job__c> jobLines, List<c2g__codaJournalLineItem__c> journalLines) {
            
            if(vo==null) {
                vo=0;
            }
            
            if(vi==null) {
                vi=0;
            }
            
            ro=rorecord;
            valueOut=vo;
            valueIn=vi;
            difference=vo-vi;
            
            sroJoblines = jobLines;
            jlines = journalLines;
        }
    }
    
    @RemoteAction
    public static oobItems balanceLines(String roId) {
		// Get Associated Job Lines
		List<dealer__Service_Job__c> jobLines = [Select Id, dealer__Service_Repair_Order__c, dealer__Parts_Total__c , 
                                                 	dealer__Parts_Cost__c, Name, (select Id, Name, dealer__Quantity_Sold__c, dealer__Cost__c from dealer__Parts_Lines__r) 
                                                 	From dealer__Service_Job__c where dealer__Service_Repair_Order__c =:roId];        	
        
        List<c2g__codaJournalLineItem__c> journalLines = [Select Id, c2g__Journal__c, Name, c2g__Value__c, c2g__Journal__r.Repair_Order__c, c2g__Journal__r.Name, c2g__LineDescription__c 
                                                         	from c2g__codaJournalLineItem__c 
                                                         	where c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c = '1220'
                                                         	AND c2g__Journal__r.Repair_Order__c =: roId];
        
   		return new oobItems(null, null, null, jobLines, journalLines);
    } 
    
    /**
     * Any associated journals
     */
    @RemoteAction
    public static List<c2g__codaJournalLineItem__c> anyReferenceJournalLines(Id roId) {
        
        dealer__Service_Repair_Order__c ro = [Select Id, Name, dealer__RO_Number__c from dealer__Service_Repair_Order__c where Id=:roId limit 1];
        
        String searchString = '%'+ro.Name+'%';
        String searchKey = '%'+ro.dealer__RO_Number__c+'%';
        return [Select Id, c2g__Journal__c, Name, c2g__Value__c, c2g__Journal__r.Repair_Order__c, c2g__Journal__r.Name, c2g__LineDescription__c 
						from c2g__codaJournalLineItem__c
						WHERE (	c2g__Journal__r.c2g__JournalDescription__c LIKE:searchString or c2g__Journal__r.c2g__JournalDescription__c  LIKE:searchKey 
                               		or Control__c LIKE :searchString or Control__c LIKE:searchKey
                               		or c2g__Journal__r.c2g__Reference__c LIKE:searchString or c2g__Journal__r.c2g__Reference__c LIKE:searchKey
                         		)
               			AND c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c = '1220'];
    }
    
    /**
     * postCorrectiveJournal
     * - Used to fix out of balance Parts/1220 Repair Orders
     */
	@RemoteAction
    public static Id postCorrectiveJournal(String s) {
        
		String[] sval = s.split(':');
        Decimal diffValue = Decimal.valueOf(sval[1]);
        
        dealer__Service_Repair_Order__c ro = [Select Id, Name, dealer__Company__c, dealer__RO_Number__c from dealer__Service_Repair_Order__c where Id=:sval[0] ];
        dealer__Dealer_Location__c loc = FFAccounting.getDealerLocation(ro.dealer__Company__c);
        
        Map<String, c2g__codaGeneralLedgerAccount__c> gl_accounts = new Map<String, c2g__codaGeneralLedgerAccount__c>();
        Set<String> rc = new Set<String>{'1220','1209'};
        for(c2g__codaGeneralLedgerAccount__c gl : [Select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c IN:rc limit 10]) {
            gl_accounts.put(gl.c2g__ReportingCode__c, gl);
        }        

        c2g__codaJournal__c journalHeader       =   new c2g__codaJournal__c();
        journalHeader.c2g__OwnerCompany__c      =   FFAccounting.getFFCompany(loc.Id);
        journalHeader.c2g__Period__c            =   FFAccounting.getCurrentPeriod(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalCurrency__c   =   FFAccounting.currency(journalHeader.c2g__OwnerCompany__c);
        journalHeader.c2g__JournalDescription__c=   'RO Correction ' + ro.Name; 
        journalHeader.c2g__JournalDate__c       =   Date.today();
        journalHeader.c2g__Reference__c         =   ro.Name;
        journalHeader.Source__c                 =   'SVC';
        journalHeader.Repair_Order__c           =   ro.Id; 
        
        List<c2g__codaJournalLineItem__c> jLines = new List<c2g__codaJournalLineItem__c>();
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=null,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                c2g__LineDescription__c='Correcting Parts Variance',
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1220').Id,
                c2g__Value__c=(diffValue *-1),
                c2g__LineType__c='General Ledger Account',
                Control__c=ro.dealer__RO_Number__c
            )
        );
        
        jLines.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c=null,
                c2g__Dimension1__c=loc.Financial_Force_Dimension_1__c,
                c2g__LineNumber__c=1,
                c2g__LineDescription__c='Correcting Parts Variance',
                c2g__GeneralLedgerAccount__c=(String)gl_accounts.get('1209').Id,
                c2g__Value__c=(diffValue),
                c2g__LineType__c='General Ledger Account',
                Control__c=ro.dealer__RO_Number__c
            )
        );          
        
        Id journalId = FinancialForce_MBW.createJournalApi(journalHeader, jLines);
        
        return journalId;
    }    
}