/**
 * CashierProcess
 * Tested by: CashierProcess_TEST
 * Date: 2019-04-24
 * Programmer: Bryan Leaman
 * Project: W-000575
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *	2019-04-30	94% (155/164)
 *
 * Modifications: 
 *	2019-05-30	W-000575 followup BLL1 - handle NWAN warranty charges & allow payment entry.
 *	2019-06-13	W-000575 impl - BLL2 - keep corporate entries separate from store cash entries.
 *	2019-06-19	W-000575 impl - BLL3 - reinistate re-worked NWAN to allow cashiering (but not other warranty!)
 *	2019-07-09	W-000585 impl - BLL4 - protect RO cashiering (pre-posting) from deletion (validation rule prevents changes)
 *	2019-07-15	W-000575 impl - BLL5 - Other vendors also pay like NWAN; create a flag on the vendor for this action.
 *
**/
public with sharing class CashierProcess {

	public static boolean sumDealCashier = true;
	public static boolean sumRentalCashier = true;
	public static boolean sumServiceCashier = true;

	@AuraEnabled
	public static DocumentFinancials documentInfo(Id documentId) {
		return new DocumentFinancials(documentId);
	}

	@AuraEnabled
	public static dealer__Dealer_Location__c userLocation() {
		User u = CurrentUserSingleton.getInstance();
		System.debug(u);
		LocationsSingleton ls = LocationsSingleton.getInstance();
		ls.addLocationAbbrevs(new List<String>{u.Division});
		dealer__Dealer_Location__c loc = ls.getLocationByAbbrev(u.Division);
		System.debug(loc);
		return new dealer__Dealer_Location__c(
			Id=loc.Id, 
			Name=loc.Name,
			dealer__Company_Number__c=loc.dealer__Company_Number__c,
			Manual_Cash_Entry__c=loc.Manual_Cash_Entry__c
		);
	}

	// BLL2
	@AuraEnabled
	public static Object settings(){
		//return Schema.SObjectType.dealer__Cashering__c.fields.Corporate_Entry__c.isUpdateable();
		List<String> objprops = new List<String>();
		objprops.add('"corporateentry":' + String.valueOf(Schema.SObjectType.dealer__Cashering__c.fields.Corporate_Entry__c.isUpdateable()));
		objprops.add('"showcorporateentry":' + String.valueOf(Schema.SObjectType.dealer__Cashering__c.fields.Corporate_Entry__c.isUpdateable()));
		dealer__Dealer_Location__c loc = CashierProcess.userLocation();
		objprops.add('"location":' + JSON.serialize(loc));
		System.debug(objprops);
		return JSON.deserializeUntyped('{' + String.join(objprops, ',') + '}');
	}
	// BLL2 end

	@AuraEnabled
	public static void deleteCashier(Id cashierId) {
		delete(new dealer__Cashering__c(Id=cashierId));
	}
	
	public class DocumentFinancials {
		@AuraEnabled public SObject RecordData;
		@AuraEnabled public Account Client;
		//@AuraEnabled public List<Account> PayorAccounts;
		@AuraEnabled public List<CashierProcess.PayorAccount> Payors;
		@AuraEnabled public List<dealer__Cashering__c> Cashiering;
		@AuraEnabled public List<CashierProcess.CashierSummary> CashieringSummary;
		@AuraEnabled public Decimal TotalChargedToAccount;
		@AuraEnabled public Decimal TotalCollected;
		@AuraEnabled public Decimal TotalOwed;
		@AuraEnabled public Decimal TotalDue;

		private Map<Id,CashierProcess.PayorAccount> payormap;
		private Map<Id,Account> accountmap;

		private Map<String,String> docClientFieldNameMap = new Map<String,String>{
			'dealer__Deal__c' => 'dealer__Buyer__c',
			'dealer__Rental_Agreements__c' => 'Account__c',
			'dealer__Service_Repair_Order__c' => 'dealer__Customer__c'
		};
		private Map<String, Set<String>> ignoreAccountFieldsMap = new Map<String, Set<String>>{
			// 'dealer__Service_Repair_Order__c' => new Set<String>{'dealer__warranty_account__c'}
		};
		
		public DocumentFinancials(Id documentId) {
			// Load cashiering first so we can add all referenced accounts in next step
			loadCashieringRecords(documentId);		
			loadDocumentDataAndPayors(documentId);
			// Summarize charges and payments
			summarizeCashiering(documentId);
		}

		// loadDocumentDataAndPayors
		// get all document data and list of all accounts referenced on the document
		public void loadDocumentDataAndPayors(Id documentId) {
			Schema.SObjectType objType = documentId.getSObjectType();
			Schema.DescribeSObjectResult dsr = objType.getDescribe();
			Map<String,Schema.SObjectField> fieldMap = dsr.fields.getMap();
			Set<String> ignorefields = ignoreAccountFieldsMap.get(dsr.getName());
			if (ignorefields==null) ignorefields = new Set<String>();
			System.debug(ignorefields);

			if (Cashiering==null) Cashiering = new List<dealer__Cashering__c>();

			// list of all fields and all account lookup fields
			Set<String> fieldnames = new Set<String>();
			Set<String> accountFields = new Set<String>();
			for(Schema.SObjectField f : fieldMap.values()) {
				Schema.DescribeFieldResult dfr = f.getDescribe();
			    if (dfr.isAccessible() && !ignorefields.contains(dfr.getName().toLowerCase())) {
					fieldnames.add(dfr.getName());
					Schema.DisplayType fldType = dfr.getType();
					if (fldType==Schema.DisplayType.Reference) {
						if (dfr.getReferenceTo()[0]==Schema.Account.SObjectType) accountFields.add(dfr.getName());
					}
				}
			}

			// drill-down for proposals
			if (objType==Schema.dealer__Deal__c.SObjectType) {
				accountFields.add('dealer__finance_institution_account__r.financeaccount__c');
				fieldnames.add('dealer__finance_institution_account__r.financeaccount__c');
			}

			// build SOQL and get all data for this document
			String soql = 'select ' + String.join(new List<String>(fieldnames), ',') 
				+ ' from ' + dsr.getName() 
				+ ' where Id=\'' + documentId + '\' ';
			List<SObject> objs = new List<SObject>();
			objs = Database.query(soql);
			RecordData = (objs.size()>0) ? objs[0] : null;

			// build set of all account Ids referenced in the document
			Set<Id> accountIds = new Set<Id>();
			for(String f : accountFields) {
				System.debug(f);
				Id acctid = null;
//				if (RecordData!=null) {
//					if (!f.contains('__r.')) acctid = (Id) RecordData.get(f);
//					else {
						List<String> fieldparts = f.split('\\.');
						System.debug(fieldparts);
						SObject o = RecordData;
		    			for(Integer i = 0; i<fieldparts.size()-1; ++i) {
							String fn = fieldparts[i];
							System.debug(fieldparts[i]);
    						o = o!=null ? o.getSObject(fn) : null;	
    					}
						System.debug(fieldparts[fieldparts.size()-1]);
						acctid = o!=null ? (Id) o.get(fieldparts[fieldparts.size()-1]) : null;
//					}
//				}
				if (acctid!=null) accountIds.add(acctid);
			}

			// add any accounts listed in cashiering records
			for(dealer__Cashering__c c : Cashiering) {
				accountIds.add(c.dealer__Customer__c);
			}

			// Get all accounts
 			payormap = new Map<Id,CashierProcess.PayorAccount>();
			//BLL3d accountmap = new Map<Id,Account>([select Id, Name from Account where Id in :accountIds]);
			//accountmap = new Map<Id,Account>([select Id, Name, ClientID__c from Account where Id in :accountIds]);	// BLL3
			accountmap = new Map<Id,Account>([select Id, Name, WarrantyAsReceivable__c, ClientID__c from Account where Id in :accountIds]);	// BLL5
			for(Account a : accountmap.values()) payormap.put(a.Id, new CashierProcess.PayorAccount(a,0));

			// Set which one is the client account
			Client = accountMap.get((Id) RecordData.get((String) docClientFieldNameMap.get(dsr.getName())));

		}
 
		// loadCashieringRecords
		// load up all related cashiering records
		private void loadCashieringRecords(Id documentId) {
			Schema.SObjectType objType = documentId.getSObjectType();
			Schema.DescribeSObjectResult docdsr = objType.getDescribe();

			Schema.DescribeSObjectResult cashdsr = Schema.dealer__Cashering__c.SObjectType.getDescribe();
			Map<String,Schema.SObjectField> cashFieldMap = cashdsr.fields.getMap();

			// get list of cashiering fields referencing the current object
			Set<String> docRefFields = new Set<String>();
			for(Schema.SObjectField f : cashFieldMap.values()) {
				Schema.DescribeFieldResult dfr = f.getDescribe();
			    if (dfr.isAccessible()) {
					//fieldnames.add(dfr.getName());
					Schema.DisplayType fldType = dfr.getType();
					if (fldType==Schema.DisplayType.Reference) {
						//System.debug(dfr.getReferenceTo()[0]);
						if (dfr.getReferenceTo()[0]==docdsr.getSObjectType()) docRefFields.add(dfr.getName());
					}
				}
			}

			// build soql for all records referencing this object Id
			String soql = 'select Id, Name, dealer__Customer__c, dealer__Customer__r.Name, dealer__Location__c, dealer__Location__r.Name, '
				+ 'dealer__Amount__c, dealer__Deposit__c, dealer__Payment_Method__c, dealer__Credit_Card_Authorization_Code__c, '
				+ 'Cash_Entry__c, Cash_Entry__r.Name, Cash_Entry_Line_Item__c, Cash_Entry_Line_Item__r.Name, '
				+ 'dealer__Close_Date__c, CreatedDate, CreatedById, CreatedBy.Name, LastModifiedDate, LastModifiedById, LastModifiedBy.Name, '
				+ 'Cashiered_while_Posted__c '
				+ 'from dealer__Cashering__c '
				+ 'where (';
			String junction = '';
			for(String fn : new List<String>(docRefFields)) {
				soql += junction + ' ' + fn + '=\'' + documentId + '\' ';
				junction = ' or ';
			}
			soql += ') ';
			soql += ' Order by CreatedDate desc ';
			System.debug(soql);
			Cashiering = Database.query(soql);

		}

		// convert nulls to zero
		public Decimal nullToZero(Decimal dec) {
			return dec==null ? 0 : dec;
		}

		// summarize the cashiering details by payor
		public void summarizeCashiering(Id documentId) {
			Map<Id, CashierSummary> summary = new Map<Id, CashierSummary>();

			// build account map by Id
			//Map<Id,Account> accountmap = new Map<Id, Account>();
			//for(Account a : payormap.values()) accountmap.put(a.Id, a);
			Id clientId;

			// by document, set charges (if possible)
			// Rental - client or 3rd party or other payor
			if (RecordData.getSObjectType()==Schema.dealer__Rental_Agreements__c.SObjectType) {
				clientId = (Id) RecordData.get('Account__c');
				CashierSummary ccs = summary.get(clientId);
				if (ccs==null) ccs = new CashierSummary((Account) accountmap.get(clientid), 0, 0, 0, 0);				
				Decimal customerpay = nullToZero((Decimal) RecordData.get('dealer__Customer_Pay_Amount__c'));
				if (customerpay!=0) {
					ccs.AmountOwed += customerpay;
					summary.put(clientid, ccs);
					System.debug(ccs);
				}

				Id payorid = (Id) RecordData.get('Account__c');
				if (RecordData.get('ThirdPartyPayor__c')!=null) payorid = (Id) RecordData.get('ThirdPartyPayor__c');
				if (RecordData.get('Other_payor__c')!=null) payorid = (Id) RecordData.get('Other_payor__c');
				System.debug(payorid);
				//CashierSummary cs = summary.get(clientId);
				CashierSummary cs = summary.get(payorid);
				if (cs==null) cs = new CashierSummary((Account) accountmap.get(payorid), 0, 0, 0, 0);
				//cs.AmountOwed += nullToZero((Decimal) RecordData.get('Total_charges__c'));
				cs.AmountOwed += nullToZero((Decimal) RecordData.get('Payor_Pay_Amount__c'));
				summary.put(payorid, cs);
				System.debug(cs);
			}
			// Repair order - client or others charged
			if (RecordData.getSObjectType()==Schema.dealer__Service_Repair_Order__c.SObjectType) {
				clientId = (Id) RecordData.get('dealer__Customer__c');
				// BLL3
				// special case for NWAN and warranty charges 
				// generate "owed" amount for NWAN as NWAN warranty charges less deductible amt
				if (RecordData.get('dealer__Warranty_Account__c')!=null) {
					//BLL5dAccount nwan = accountmap.get((Id) RecordData.get('dealer__Warranty_Account__c'));
					//BLL5dif (nwan!=null && nwan.ClientID__c=='NWANIN') {
					Account vndr = accountmap.get((Id) RecordData.get('dealer__Warranty_Account__c'));
					if (vndr!=null && vndr.WarrantyAsReceivable__c) {
						Decimal warrDeductible = 0;
						Decimal warrCharges = 0;
						if (RecordData.get('dealer__Warranty_Deductible__c')!=null) 
							warrDeductible = nullToZero((Decimal) RecordData.get('dealer__Warranty_Deductible__c'));
						if (RecordData.get('dealer__Warranty_Charges__c')!=null) 
							warrCharges = nullToZero((Decimal) RecordData.get('dealer__Warranty_Charges__c'));
						CashierSummary warrcs = summary.get(vndr.Id);
						if (warrcs==null) warrcs = new CashierSummary(vndr, 0, 0, 0, 0);
						if (RecordData.get('dealer__Warranty_Deductible__c')!=null) 
							warrDeductible = nullToZero((Decimal) RecordData.get('dealer__Warranty_Deductible__c'));
						if (RecordData.get('dealer__Warranty_Charges__c')!=null) 
							warrCharges = nullToZero((Decimal) RecordData.get('dealer__Warranty_Charges__c'));
						warrcs.Charged = warrCharges>warrDeductible ? warrCharges-warrDeductible : 0.00;
						warrcs.AmountOwed = warrcs.Charged;
						summary.put(vndr.Id, warrcs);
					}
				}
				// BLL3 end
			}
			// Deal - client, grant, payors, finance
			if (RecordData.getSObjectType()==Schema.dealer__Deal__c.SObjectType) {
				clientId = (Id) RecordData.get('dealer__Buyer__c');
				Decimal clientAmt = nullToZero((Decimal) RecordData.get('dealer__Deposit__c'));
				clientAmt += nullToZero((Decimal) RecordData.get('dealer__Down_Pymt__c'));
				clientAmt += nullToZero((Decimal) RecordData.get('TotalDueUponDelivery__c'));
				// releasing dealer
				Id reldealerid = (Id) RecordData.get('ReleasingDealer__c');
				if (reldealerid!=null) {
					clientAmt -= nullToZero((Decimal) RecordData.get('TotalDueUponDelivery__c'));
					System.debug(clientAmt);
					Decimal releasingDealerAmt = nullToZero((Decimal) RecordData.get('TotalDueUponDelivery__c'));
					releasingDealerAmt -= nullToZero((Decimal) RecordData.get('Chassis_Cost__c'));
					// sales tax is included in the fees total
					//releasingDealerAmt -= nullToZero((Decimal) RecordData.get('dealer__Sales_Tax__c'));
					releasingDealerAmt -= nullToZero((Decimal) RecordData.get('dealer__Total_Fees__c'));
					releasingDealerAmt += nullToZero((Decimal) RecordData.get('Government_Price_Concession__c'));
					releasingDealerAmt += nullToZero((Decimal) RecordData.get('dealer__Rebate__c'));
					releasingDealerAmt += nullToZero((Decimal) RecordData.get('Rebate_2__c'));
					releasingDealerAmt += nullToZero((Decimal) RecordData.get('Rebate_3__c'));
					System.debug(releasingDealerAmt);
					CashierSummary csrd = summary.get(reldealerid);
					if (csrd==null) csrd = new CashierSummary((Account) accountmap.get(reldealerid), 0, 0, 0, 0);
					csrd.AmountOwed += releasingDealerAmt;
					if (csrd.AmountOwed!=0) summary.put(reldealerid, csrd);
				}
				CashierSummary ccs = summary.get(clientId);
				if (ccs==null) ccs = new CashierSummary((Account) accountmap.get(clientId), 0, 0, 0, 0);
				ccs.AmountOwed += clientAmt;
				if (ccs.AmountOwed!=0) summary.put(clientId, ccs);
				if (RecordData.get('dtmob__Auto_Grant_Payor__c')!=null) {
					Id payorid = (Id) RecordData.get('dtmob__Auto_Grant_Payor__c');
					CashierSummary cs = summary.get(payorid);
					if (cs==null) cs = new CashierSummary((Account) accountmap.get(payorid), 0, 0, 0, 0);
					cs.AmountOwed += nullToZero((Decimal) RecordData.get('AutoGrant__c'));
					if (cs.AmountOwed!=0) summary.put(payorid, cs);
				}
				if (RecordData.get('Third_Party_Pay_1__c')!=null) {
					Id payorid = (Id) RecordData.get('Third_Party_Pay_1__c');
					CashierSummary cs = summary.get(payorid);
					if (cs==null) cs = new CashierSummary((Account) accountmap.get(payorid), 0, 0, 0, 0);
					cs.AmountOwed += nullToZero((Decimal) RecordData.get('dealer__Deferred_Down_1__c'));
					if (cs.AmountOwed!=0) summary.put(payorid, cs);
				}
				if (RecordData.get('Third_Party_Pay_2__c')!=null) {
					Id payorid = (Id) RecordData.get('Third_Party_Pay_2__c');
					CashierSummary cs = summary.get(payorid);
					if (cs==null) cs = new CashierSummary((Account) accountmap.get(payorid), 0, 0, 0, 0);
					cs.AmountOwed += nullToZero((Decimal) RecordData.get('dealer__Deferred_Down_2__c'));
					if (cs.AmountOwed!=0) summary.put(payorid, cs);
				}
				if (RecordData.get('Third_Party_Pay_3__c')!=null) {
					Id payorid = (Id) RecordData.get('Third_Party_Pay_3__c');
					CashierSummary cs = summary.get(payorid);
					if (cs==null) cs = new CashierSummary((Account) accountmap.get(payorid), 0, 0, 0, 0);
					cs.AmountOwed += nullToZero((Decimal) RecordData.get('dealer__Deferred_Down_3__c'));
					if (cs.AmountOwed!=0) summary.put(payorid, cs);
				}

				String fundingoption = (String) RecordData.get('Funding_Option__c');
				if (fundingoption=='Financed') {
					SObject financeinst = RecordData.getSObject('dealer__Finance_Institution_Account__r');
					String contracttype = (String) RecordData.get('Contract_Type__c');
					Decimal monthlypmt = nullToZero((Decimal) RecordData.get('Contract_Monthly_Payment__c'));
					Decimal loancost = nullToZero((Decimal) RecordData.get('LoanAcquisitionCost__c'));
					Decimal financefee = nullToZero((Decimal) RecordData.get('LeaseAcquisitionFee__c'));
					Decimal gapreimbursement = nullToZero((Decimal) RecordData.get('FinanceCompanyReimbursement__c'));
					Id financeAcct = null;
					if (financeinst!=null) financeAcct = (Id) financeinst.get('FinanceAccount__c');

					if (financeAcct!=null) {
						Id payorid = financeAcct;
						CashierSummary cs = summary.get(payorid);
						if (cs==null) cs = new CashierSummary((Account) accountmap.get(payorid), 0, 0, 0, 0);
						cs.AmountOwed += nullToZero((Decimal) RecordData.get('Contract_Amount_Financed__c'));
						if (contracttype=='Lease' && monthlypmt!=0) cs.AmountOwed -= monthlypmt;
						if (loancost!=0) cs.AmountOwed -= loancost;
						if (financefee!=0) cs.AmountOwed -= financefee;
						if (gapreimbursement!=0) cs.AmountOwed += gapreimbursement;
						if (cs.AmountOwed!=0) summary.put(payorid, cs);
					}
				}
			}

			// summarize cashiering by account
			Decimal chgClient = 0;
			Decimal colClient = 0;
			TotalChargedToAccount = 0;
			TotalCollected = 0;
			TotalOwed = 0;
			TotalDue = 0;
			for(dealer__Cashering__c c : Cashiering) {
				CashierSummary cs = summary.get(c.dealer__Customer__c);
				if (cs==null) cs = new CashierSummary((Account) accountmap.get(c.dealer__Customer__c), 0, 0, 0, 0);
				if (c.dealer__Payment_Method__c.contains('Charge') || c.dealer__Payment_Method__c.contains('Receivable')) {
					cs.Charged += c.dealer__Amount__c;
					TotalChargedToAccount += c.dealer__Amount__c;
					if (c.dealer__Customer__c==clientId) chgClient += c.dealer__Amount__c;
				} else {
					cs.Collected += c.dealer__Amount__c;
					TotalCollected += c.dealer__Amount__c;
					if (c.dealer__Customer__c==clientId) colClient += c.dealer__Amount__c;
				}
				//if (cs.AmountOwed<cs.Charged) cs.AmountOwed = cs.Charged;
				if (RecordData.getSObjectType()==Schema.dealer__Service_Repair_Order__c.SObjectType
				  && !c.Cashiered_while_Posted__c) cs.AmountOwed += c.dealer__Amount__c;
				else if (cs.AmountOwed<cs.Charged) cs.AmountOwed = cs.Charged;
				summary.put(c.dealer__Customer__c, cs);
			}

			// Repair orders - assume client owes until fully cashiered
			// NOT NEEDED: this component isn't used UNTIL the RO is fully cashiered
			//if (RecordData.getSObjectType()==Schema.dealer__Service_Repair_Order__c.SObjectType) {
	        	//Decimal amount = 0;
				//MW_TriggerControls__c RODeductibleAddToTotal = MW_TriggerControls__c.getInstance('RODeductibleAddToTotal');
				//boolean AddDeductibleToAmtDue = (RODeductibleAddToTotal==null || RODeductibleAddToTotal.Enabled__c);
        		//if(RecordData.get('CustomerInvoiceTotal__c')!=null) {
            	//	amount += nullToZero((Decimal) RecordData.get('CustomerInvoiceTotal__c'));
        		//}
				//Decimal warrDeductible = 0;
				//Decimal warrCharges = 0;
				//if (RecordData.get('dealer__Warranty_Deductible__c')!=null) 
				//	warrDeductible = nullToZero((Decimal) RecordData.get('dealer__Warranty_Deductible__c'));
				//if (RecordData.get('dealer__Warranty_Charges__c')!=null) 
				//	warrCharges = nullToZero((Decimal) RecordData.get('dealer__Warranty_Charges__c'));
				//if (AddDeductibleToAmtDue) amount += Math.min(warrDeductible, warrCharges);
				//amount = amount.setScale(2);
				//Decimal unallocated = amount - (TotalChargedToAccount + TotalCollected);
				//for(CashierSummary cs : summary.values()) {
				//	if (cs.Payor.Id==clientId) {
				//		cs.AmountOwed = amount;
				//		cs.Charged = chgClient;
				//		cs.Collected = colClient;
				//		cs.AmountDue = amount - TotalChargedToAccount - TotalCollected;
				//		//if (cs.AmountDue<0) cs.AmountDue = 0;
				//	}
				//}
				// BLL1
				// handle NWAN charges ...
				//if (RecordData.get('dealer__Warranty_Account__c')!=null) {
				//	Account nwan = accountmap.get((Id) RecordData.get('dealer__Warranty_Account__c'));
				//	if (nwan!=null && nwan.ClientID__c=='NWANIN') {
				//		CashierSummary nwancs = summary.get(nwan.Id);
				//		if (nwancs==null) nwancs = new CashierSummary(nwan, 0, 0, 0, 0);
				//		if (RecordData.get('dealer__Warranty_Deductible__c')!=null) 
				//			warrDeductible = nullToZero((Decimal) RecordData.get('dealer__Warranty_Deductible__c'));
				//		if (RecordData.get('dealer__Warranty_Charges__c')!=null) 
				//			warrCharges = nullToZero((Decimal) RecordData.get('dealer__Warranty_Charges__c'));
				//		nwancs.Charged = warrCharges>warrDeductible ? warrCharges-warrDeductible : 0.00;
				//		nwancs.AmountOwed = nwancs.Charged;
				//		CashierSummary.put(nwan.Id, nwancs);
				//	}
				//}
				// BLL1
			//}

			// Calc amount due & total charged to account
			TotalChargedToAccount = 0;
			for(CashierSummary cs : summary.values()) {
				cs.AmountDue = cs.AmountOwed - cs.Collected;
				TotalOwed += cs.AmountOwed;
				TotalDue += cs.AmountDue;
				TotalChargedToAccount += cs.Charged;
				CashierProcess.PayorAccount pa = (cs!=null && cs.Payor!=null && cs.Payor.Id!=null) ? payormap.get(cs.Payor.Id) : null;
				if (pa!=null) pa.AmountDue = cs.AmountDue;
				if (pa!=null) payormap.put(cs.Payor.Id, pa);
			}
			Payors = payormap.values();
			CashieringSummary = summary.values();
		}

	}

	public class PayorAccount {
		@AuraEnabled public Account Payor {get;set;}
		@AuraEnabled public Decimal AmountDue {get;set;}
		public PayorAccount(Account a, Decimal due) {
			Payor = a;
			AmountDue = due;
		}
	}

	// Cashier Summary for a payor
	public class CashierSummary {
		@AuraEnabled public Account Payor {get;set;}
		@AuraEnabled public Decimal Charged {get;set;}
		@AuraEnabled public Decimal Collected {get;set;}
		@AuraEnabled public Decimal AmountOwed {get;set;}
		@AuraEnabled public Decimal AmountDue {get;set;}
		public CashierSummary(Account a, Decimal chg, Decimal col, Decimal owe, Decimal due) {
			Payor = a;
			Charged = chg;
			Collected = col;
			AmountOwed = owe;
			AmountDue = due;
		}
	}

	// BLL2
	// set company number
	public static void SetCompanyNumber(List<dealer__Cashering__c> newlist) {
		LocationsSingleton ls = LocationsSingleton.getInstance();
		List<Id> locIds = new List<Id>();
		for(dealer__Cashering__c c : newlist) if (c.dealer__Location__c!=null) locIds.add(c.dealer__Location__c);
		ls.addLocationIds(locIds);
		for(dealer__Cashering__c c : newlist) {
			dealer__Dealer_Location__c loc = ls.getLocationById(c.dealer__Location__c);
			if (loc!=null) c.dealer__Company_Number__c = loc.dealer__Company_Number__c;
		}
	}
	// BLL2 end

	// Protect cashier records
	//---------------------------------------
	public static void ProtectCashierRecords(
		List<dealer__Cashering__c> newlist, 
		List<dealer__Cashering__c> oldlist, Map<Id, dealer__Cashering__c> oldMap, 
		boolean isInsert, boolean isUpdate, boolean isDelete, boolean isBefore, boolean isAfter) {

		Set<String> allowedFieldUpdates = new Set<String>{
			'lastmodifieddate', 'lastmodifiedbyid', 'ownerid', 
			'dealer__close_date__c','dealer__credit_card_authorization_code__c',
			'dealer__deposit__c', 'dealer__payment_receipt_details__c', 
			'cashier_while_posted__c', 
			'cash_entry__c', 'cash_entry_line_item__c' 	// need to allow setting this value!
		};

		MW_TriggerControls__c CashierUpdatePrevention = MW_TriggerControls__c.getInstance('CashierUpdatePrevention');
		MW_TriggerControls__c CashierDeletePrevention = MW_TriggerControls__c.getInstance('CashierDeletePrevention');
		MW_TriggerControls__c CashierFFLink = MW_TriggerControls__c.getInstance('CashierFFLink');
		MW_TriggerControls__c CashierFFLock = MW_TriggerControls__c.getInstance('CashierFFLock');

		boolean PreventAllDeletes = CashierDeletePrevention==null || CashierDeletePrevention.Enabled__c;
		boolean PreventAllUpdates = CashierUpdatePrevention==null || CashierUpdatePrevention.Enabled__c;
		boolean PreventLinkedRcdUpdDlt = CashierFFLink==null || CashierFFLink.Enabled__c;
		boolean PreventLockedRcdUpdDlt = CashierFFLock==null || CashierFFLock.Enabled__c;


		// FF linked Cash Entry Line Items
		Set<Id> celIds = new Set<Id>();
		Set<Id> roIds = new Set<Id>();	// BLL4a

		if (!isInsert) {
			for(dealer__Cashering__c c : oldlist) {
				if (c.Cash_Entry_Line_Item__c!=null) {
					celIds.add(c.Cash_Entry_Line_Item__c);
				}
				if (c.dealer__Service_Repair_Order__c!=null) roIds.add(c.dealer__Service_Repair_Order__c);	// BLL4a
			}
		}
		if (!isDelete) {
			for(dealer__Cashering__c c : newlist) {
				if (c.Cash_Entry_Line_Item__c!=null) {
					celIds.add(c.Cash_Entry_Line_Item__c);
				}
			}
		}

		Map<Id, c2g__codaCashEntryLineItem__c> celMap = new Map<Id, c2g__codaCashEntrylineItem__c>();
		if (celIds.size()>0) celMap = new Map<Id, c2g__codaCashEntryLineItem__c>([
			select Id, Name, c2g__CashEntry__c, c2g__CashEntry__r.c2g__Status__c
			from c2g__codaCashEntryLineItem__c
			where Id in :celIds
		]);

		// BLL4a
		Map<Id, dealer__Service_Repair_Order__c> roMap = new Map<Id, dealer__Service_Repair_Order__c>();
		if (roIds.size()>0) roMap = new Map<Id, dealer__Service_Repair_Order__c>([
			select Id, dealer__Status__c 
			from dealer__Service_Repair_Order__c
			where Id in :roIds
		]);
		// BLL4 end

		// Prevent deletion
		if (isBefore && isDelete) {
			for(dealer__Cashering__c rcd : oldlist) {
				c2g__codaCashEntryLineItem__c cel = celMap.get(rcd.Cash_Entry_Line_Item__c);
				// BLL4
				// cannot delete RO cashiering records entered prior to posting
				if (rcd.dealer__Service_Repair_Order__c!=null && rcd.Cashiered_while_Posted__c==false) {
					dealer__Service_Repair_Order__c ro = roMap.get(rcd.dealer__Service_Repair_Order__c);
					if (ro==null || ro.dealer__Status__c=='Posted') rcd.addError('You may not delete cashier entries on a Repair Order that has been posted. Reverse the entry and make a new one.');
				}
				// BLL4 end
				if (PreventAllDeletes || (PreventLinkedRcdUpdDlt && rcd.Cash_Entry_Line_Item__c!=null)) {
					rcd.addError('You cannot delete cashier entries' + (rcd.Cash_Entry_Line_Item__c!=null ? ' once sent to FinancialForce' : ''));
				} else if (cel!=null && cel.c2g__CashEntry__c!=null && cel.c2g__CashEntry__r.c2g__Status__c=='Completed') {
					if (PreventLockedRcdUpdDlt) rcd.addError('You cannot delete cashier entries that have already been posted in FinancialForce');
				}
			}
		}

		// Prevent updates
		if (isBefore && isUpdate) {
			for(dealer__Cashering__c rcd : newlist) {
				dealer__Cashering__c oldrcd = oldMap!=null ? oldMap.get(rcd.Id) : null;
				c2g__codaCashEntryLineItem__c cel1 = celMap.get(oldrcd.Cash_Entry_Line_Item__c);
				c2g__codaCashEntryLineItem__c cel2 = celMap.get(rcd.Cash_Entry_Line_Item__c);
				if (!SObjectChangedFields.OnlyAllowedFieldsChanged(rcd, oldrcd, allowedFieldUpdates)) {
					if (PreventAllUpdates || (PreventLinkedRcdUpdDlt && oldrcd!=null && oldrcd.Cash_Entry_Line_Item__c!=null)) {
						rcd.addError('You cannot update cashier entries' + (rcd.Cash_Entry_Line_Item__c!=null ? ' once sent to FinancialForce' : ''));
					} else if ((cel1!=null && cel1.c2g__CashEntry__c!=null && cel1.c2g__CashEntry__r.c2g__Status__c=='Completed')
							|| (cel2!=null && cel2.c2g__CashEntry__c!=null && cel2.c2g__CashEntry__r.c2g__Status__c=='Completed')) { 
						if (PreventLockedRcdUpdDlt) rcd.addError('You cannot update cashier entries that have already been posted in FinancialForce');
					}
				}
			}
		}

	}


	// UpdateDocumentTotals
	//----------------------------------------
	public static void UpdateDocumentTotals(List<dealer__Cashering__c> newlist, Map<Id,dealer__Cashering__c> oldmap,
		boolean isInsert, boolean isUpdate, boolean isDelete) {
		System.debug('UpdateDocumentTotals');
		Map<Id, dealer__Deal__c> deals = new Map<Id, dealer__Deal__c>();
		Map<Id, dealer__Service_Repair_Order__c> services = new Map<Id, dealer__Service_Repair_Order__c>();
		Map<Id, dealer__Rental_Agreements__c> rentals = new Map<Id, dealer__Rental_Agreements__c>();

		// on insert, always update document totals
		if (isInsert) {
			for(dealer__Cashering__c c : newlist) {
				if (c.dealer__Deal__c!=null) deals.put(c.dealer__Deal__c, new dealer__Deal__c(Id=c.dealer__Deal__c));
				if (c.dealer__Rental_Agreement__c!=null) rentals.put(c.dealer__Rental_Agreement__c, new dealer__Rental_Agreements__c(Id=c.dealer__Rental_Agreement__c));
				if (c.dealer__Service_Repair_Order__c!=null) services.put(c.dealer__Service_Repair_Order__c, new dealer__Service_Repair_Order__c(Id=c.dealer__Service_Repair_Order__c));
			}
		}
		// on delete, always update document totals
		if (isDelete) {
			for(dealer__Cashering__c c : oldmap.values()) {
				if (c.dealer__Deal__c!=null) deals.put(c.dealer__Deal__c, new dealer__Deal__c(Id=c.dealer__Deal__c));
				if (c.dealer__Rental_Agreement__c!=null) rentals.put(c.dealer__Rental_Agreement__c, new dealer__Rental_Agreements__c(Id=c.dealer__Rental_Agreement__c));
				if (c.dealer__Service_Repair_Order__c!=null) services.put(c.dealer__Service_Repair_Order__c, new dealer__Service_Repair_Order__c(Id=c.dealer__Service_Repair_Order__c));
			}
		}
		// only recalc totals if amount or pay method changed
		if (isUpdate) {
			for(dealer__Cashering__c c : newlist) {
				dealer__Cashering__c old = oldmap.get(c.Id);
				boolean pmtchanged = c.dealer__Amount__c!=old.dealer__Amount__c || c.dealer__Payment_Method__c!=old.dealer__Payment_Method__c;
				if (pmtchanged && c.dealer__Deal__c!=null) deals.put(c.dealer__Deal__c, new dealer__Deal__c(Id=c.dealer__Deal__c));
				if (pmtchanged && c.dealer__Rental_Agreement__c!=null) rentals.put(c.dealer__Rental_Agreement__c, new dealer__Rental_Agreements__c(Id=c.dealer__Rental_Agreement__c));
				if (pmtchanged && c.dealer__Service_Repair_Order__c!=null) services.put(c.dealer__Service_Repair_Order__c, new dealer__Service_Repair_Order__c(Id=c.dealer__Service_Repair_Order__c));
			}
		}

		System.debug(deals.size());
		System.debug(rentals.size());
		System.debug(services.size());
		//if (deals.size()>0) update(deals.values());
		// Proposals are locked due to their approval process
		if (deals.size()>0) Utility.updateSObjectsFuture(JSON.serialize(deals.values()));
		if (rentals.size()>0) update(rentals.values());
		if (services.size()>0) update(services.values());
	}

	// Update Total Collected fields on documents
	//==============================================

	// dealTotalCollected
	public static void dealTotalCollected(List<dealer__Deal__c> newlist) {
		System.debug('dealTotalCollected');
		if (!sumDealCashier) return;
		sumDealCashier = false;
		// Map proposal to cashiering total (not on receivables)
		Map<Id,Decimal> dealPaidMap = new Map<Id,Decimal>();
		Set<Id> dealIds = new Set<Id>();
		for(dealer__Deal__c deal : newlist) dealIds.add(deal.Id);
		for(AggregateResult ar : [
			select dealer__Deal__c, sum(dealer__Amount__c) paid 
			from dealer__Cashering__c 
			where dealer__Deal__c!=null and dealer__Deal__c in :dealIds
			  and (NOT dealer__Payment_Method__c like 'Charge%') and (NOT dealer__Payment_Method__c like '%Receivable%')
			group by dealer__Deal__c 
		]) {
			System.debug(ar);
			dealPaidMap.put((Id) ar.get('dealer__Deal__c'), (Decimal) ar.get('paid'));
		}
		// set total field on proposal
		for(dealer__Deal__c deal : newlist) deal.Total_Collected__c = dealPaidMap.get(deal.Id);
	}

	// serviceTotalCollected
	public static void serviceTotalCollected(List<dealer__Service_Repair_Order__c> newlist) {
		System.debug('serviceTotalCollected');
		if (!sumServiceCashier) return;
		sumServiceCashier = false;
		// Map RO to cashiering total (not on receivables)
		Map<Id,Decimal> roPaidMap = new Map<Id,Decimal>();
		Set<Id> roIds = new Set<Id>();
		for(dealer__Service_Repair_Order__c ro : newlist) roIds.add(ro.Id);
		for(AggregateResult ar : [
			select dealer__Service_Repair_Order__c, sum(dealer__Amount__c) paid 
			from dealer__Cashering__c 
			where dealer__Service_Repair_Order__c!=null and dealer__Service_Repair_Order__c in :roIds
			  and (NOT dealer__Payment_Method__c like 'Charge%') and (NOT dealer__Payment_Method__c like '%Receivable%')
			group by dealer__Service_Repair_Order__c
		]) {
			System.debug(ar);
			roPaidMap.put((Id) ar.get('dealer__Service_Repair_Order__c'), (Decimal) ar.get('paid'));
		}
		// set total field on the service repair order
		for(dealer__Service_Repair_Order__c ro : newlist) ro.Total_Collected__c = roPaidMap.get(ro.Id);
	}

	// rentalTotalCollected
	public static void rentalTotalCollected(List<dealer__Rental_Agreements__c> newlist) {
		System.debug('rentalTotalCollected');
		if (!sumRentalCashier) return;
		sumRentalCashier = false;
		// Map rental to cashiering total (not on receivables)
		Map<Id,Decimal> rentalPaidMap = new Map<Id,Decimal>();
		Set<Id> rentalIds = new Set<Id>();
		for(dealer__Rental_Agreements__c rental : newlist) rentalIds.add(rental.Id);
		for(AggregateResult ar : [
			select dealer__Rental_Agreement__c, sum(dealer__Amount__c) paid 
			from dealer__Cashering__c 
			where dealer__Rental_Agreement__c!=null and dealer__Rental_Agreement__c in :rentalIds
			  and (NOT dealer__Payment_Method__c like 'Charge%') and (NOT dealer__Payment_Method__c like '%Receivable%')
			group by dealer__Rental_Agreement__c 
		]) {
			System.debug(ar);
			rentalPaidMap.put((Id) ar.get('dealer__Rental_Agreement__c'), (Decimal) ar.get('paid'));
		}
		// set total field on rental
		for(dealer__Rental_Agreements__c rental : newlist) rental.Total_Collected__c = rentalPaidMap.get(rental.Id);
	}


	// Restrict cash entries at the stores...
	//==========================================

	// RestrictManualCashEntries
	//-----------------------------------
	public static void RestrictManualCashEntries(List<c2g__codaCashEntry__c> newlist) {
		boolean cashEntryAllowed = Utility.hasCustomPermission('CashEntryAllowed');
		System.debug(cashEntryAllowed);
		MW_TriggerControls__c mce = MW_TriggerControls__c.getInstance('RestrictManualCashEntries');
		User u = CurrentUserSingleton.getInstance();
		LocationsSingleton ls = LocationsSingleton.getInstance();
		ls.addLocationAbbrevs(new Set<String>{u.Division});
		ls.retrieveLocations();
		dealer__Dealer_Location__c loc = ls.getLocationByAbbrev(u.Division);

		for(c2g__codaCashEntry__c ce : newlist) {
			System.debug(loc);
			if (loc!=null) System.debug(loc.Manual_Cash_Entry__c);
			if (!cashEntryAllowed && loc!=null && !loc.Manual_Cash_Entry__c) {
				if (mce!=null && mce.Enabled__c) ce.addError('Your store uses automatic cash entries. You may not create or update them manually');
			}
		}
	}

	// RestrictManualCashEntryLines
	//-----------------------------------
	public static void RestrictManualCashEntryLines(List<c2g__codaCashEntryLineItem__c> newlist) {
		boolean cashEntryAllowed = Utility.hasCustomPermission('CashEntryAllowed');
		MW_TriggerControls__c mce = MW_TriggerControls__c.getInstance('RestrictManualCashEntries');
		User u = CurrentUserSingleton.getInstance();
		LocationsSingleton ls = LocationsSingleton.getInstance();
		ls.addLocationAbbrevs(new Set<String>{u.Division});
		ls.retrieveLocations();
		dealer__Dealer_Location__c loc = ls.getLocationByAbbrev(u.Division);

		for(c2g__codaCashEntryLineItem__c cel : newlist) {
			System.debug(loc);
			if (loc!=null) System.debug(loc.Manual_Cash_Entry__c);
			if (!cashEntryAllowed && loc!=null && !loc.Manual_Cash_Entry__c) {
				if (mce!=null && mce.Enabled__c) cel.addError('Your store uses automatic cash entries. You may not create or update them manually');
			}
		}
	}

}