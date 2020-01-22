/**
 * CashEntryAutoCreateDT
 * Tested by: CashEntryAutoCreateDT_TEST
 * Date: 2019-04-23
 * Programmer: Bryan Leaman
 * Project: W-000575
 *
 * Coverage:
 *	2019-05-02	88% (235/267)
 *	2019-07-09	92%	(322/350)
 *	2019-07-29	90%	(336/372)
 *	2019-08-13	90% (342/378)
 *
 * Modifications: 
 *	2019-06-10	BLL1	W-000575 implementation - handle AMEX like American Express
 *	2019-06-13	BLL2	W-000575 implementation - keep corporate entries in separate cash entries
 *						Also ensure accounts have an Accounts Receivable Control GL# (1100).
 *	2019-07-09	BLL3	W-000575 impl. - better selection of pay methods.
 *	2019-07-12	BLL4	W-000575 impl. - record invoice customer on cash entry lines
 *	2019-07-24	BLL5	W-000724 - ensure accounts do not specify dimension1, or it'll override on the cash entry lines!
 *	2019-07-25	BLL6	W-000725 - separate cash entries by date of the cashiering entry
 *	2019-08-09	BLL7	Allow running 2 locations at a time for new test method.
 *	2019-09-12	BLL8	W-000752 - select open period by date rather than current period!
 *
 * Run it now:
Database.executeBatch(new CashEntryAutoCreateDT(null, true, null, null, null, null), 1);
Database.executeBatch(new CashEntryAutoCreateDT(null, true, 'CreatedDate<2019-05-14T00:00:00Z', null, null, null), 1);

 * Set standard schedule:
CashEntryAutoCreateDT.scheduleMe();

 * Set custom schedule:
System.schedule('CashEntryAutoCreateDT', 'sec min hr day mth wd year', new CashEntryAutoCreateDT(null,true,null,null,null,null));

 */
 global class CashEntryAutoCreateDT implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

	global final String query;
	global boolean doUpdate;
	global String selectCriteria;
	global String recordLimit;
	global Map<String,String> errormap;
	global Map<String,String> resultmap;
	public static final List<String> CRON_LIST = new List<String>{
		'0 0 23 * * ? *' 	// 11 p.m. daily
	};
	global Id currentcompany;
	global List<Id> remainingCompanyIds;
	global c2g__codaGeneralLedgerAccount__c acctRecGL;	// BLL2a

	// BLL3
	global Set<String> paymethods;
	// BLL3 end

	// CashEntryAutoCreateDT constructor - generate query string & initialize
	global CashEntryAutoCreateDT(String rcdlimit, boolean doUpd, String crit, List<Id> companyidlist, Map<String,String> results, Map<String,String> errors) {
		System.debug('CashEntryAutoCreateDT.constructor');
		doUpdate = doUpd;
		selectCriteria = crit;
		System.debug(selectCriteria);
		errormap = new Map<String,String>();
		resultmap = new Map<String,String>();
		recordLimit = rcdlimit;

		// BLL3
		// Alternate payment method names...
		Map<String, dealer__Payment_Methods__c> methodMap = dealer__Payment_Methods__c.getAll();
		paymethods = new Set<String>();
		for(String k : methodMap.keySet()) {
			dealer__Payment_Methods__c pm = methodMap.get(k);
			if (!pm.Name.contains('Charge') && !pm.Name.contains('Receiv')) {
				paymethods.add(pm.Name);
				paymethods.add(pm.dealer__Method__c);
			}
		}
		// BLL3 end

		// starting fresh for all companies or continuing on?
		if (companyidlist==null) {
			remainingCompanyIds = new List<String>();
			String agsoql = 'select dealer__Location__r.Company__c ffcompany, count(Id) cnt '
				+ 'from dealer__Cashering__c '
				+ 'where Create_Cash_Entry__c=true and Cash_Entry_Line_Item__c=null '
				+ '  and dealer__Amount__c!=0 ';
			// BLL3
			if (paymethods!=null && paymethods.size()>0) 
				agsoql += ' and dealer__Payment_Method__c in (\'' 
					+  String.join(new List<String>(paymethods), '\', \'') 
					+ '\')';
			// BLL3 end
			if (!String.isBlank(selectCriteria)) agsoql += ' and ' + selectCriteria + ' ';
			agsoql += 'group by dealer__Location__r.Company__c';
			System.debug(agsoql);
			for(AggregateResult ar : Database.query(agsoql)) {
				System.debug(ar);
				remainingCompanyIds.add((Id) ar.get('ffcompany'));
			}
		} else {
			remainingCompanyIds = new List<Id>(companyidlist);
		}

		System.debug(remainingCompanyIds.size());
		if (remainingCompanyIds.size()>0) currentcompany = remainingCompanyIds.remove(0);
		System.debug(currentcompany);
		System.debug(remainingCompanyIds.size());

		errormap = new Map<String,String>();
		resultmap = new Map<String,String>();
		// continuing from last batch instance ...
		if (errors!=null) errormap = errors;
		if (results!=null) resultmap = results;

	}


	// start method for list of discrete SObjects
	global Iterable<SObject> start(Database.BatchableContext bc) {
		System.debug('CashEntryAutoCreateDT.start');
		List<SObject> objList = new List<SObject>();
		// BLL2
		acctRecGL = [select Id from c2g__codaGeneralLedgerAccount__c where c2g__ExternalId__c='1100' limit 1];
		// BLL2 end
		if (currentcompany!=null) {
			System.debug('selectCompany: ' + currentcompany);
			FinancialForce_MBW.selectCompany(currentcompany);
			System.debug('selectCompany: ' + currentcompany + ' completed');
			String objsoql = 'select dealer__Location__c, count(Id) cnt '
				+ 'from dealer__Cashering__c '
				+ 'where Create_Cash_Entry__c=true and Cash_Entry_Line_Item__c=null '
				+ '  and dealer__Amount__c!=0 '
				+ '  and dealer__Location__r.Company__c=:currentcompany ';
			// BLL3
			if (paymethods!=null && paymethods.size()>0) 
				objsoql += ' and dealer__Payment_Method__c in (\'' 
					+  String.join(new List<String>(paymethods), '\', \'') 
					+ '\')';
			// BLL3 end
			System.debug(selectCriteria);
			if (!String.isBlank(selectCriteria)) objsoql += ' and ' + selectCriteria + ' ';
			objsoql += 'group by dealer__Location__c ';
			System.debug(objsoql);
			objList = Database.query(objsoql);
		}
		System.debug(objList.size());
		for(SObject o : objList) {
			AggregateResult ar = (AggregateResult) o;
			System.debug((String) ar.get('dealer__Location__c') + ' : ' + String.valueOf((Decimal) ar.get('cnt')));
		}
		return objList;
	}


	// execute for a batch of records
	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		System.debug('CashEntryAutoCreateDT.execute');
		System.debug(currentcompany);
		List<AggregateResult> objs = (List<AggregateResult>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

		// For each location -- should only be 1 location per run except from test class
		// BLL7 allow for 2 due to test class requirements of only 1 execute in a test
		for (AggregateResult obj : objs) {
			Id locId = (Id) obj.get('dealer__Location__c');
			Decimal count = (Decimal) obj.get('cnt');
			System.debug(locId);
			System.debug(count);

			// Get location info
			dealer__Dealer_Location__c loc = getLocation(locId);
			System.debug(loc);

			// BLL1
			// Alternate payment method names...
			Map<String, dealer__Payment_Methods__c> methodMap = dealer__Payment_Methods__c.getAll();
			Map<String, String> methodAltName = new Map<String, String>();
			for(String k : methodMap.keySet()) {
				dealer__Payment_Methods__c pm = methodMap.get(k);
				if (pm.Name!=pm.dealer__Method__c && !pm.Name.contains('Charge') && !pm.Name.contains('Receiv')) methodAltName.put(pm.dealer__Method__c, pm.Name);
			}
			// BLL1 end

			// PaymentMethodDefinitions for this location...
			Map<String,PaymentMethodsByLocation__c> locPmtMethodMap = new Map<String,PaymentMethodsByLocation__c>();
			for(PaymentMethodsByLocation__c pm : [
				SELECT Name, Method__c, Location__c, Deposit_Account__c, FF_Payment_Method__c 
				FROM PaymentMethodsByLocation__c
				WHERE Location__c =:loc.dealer__Company_Number__c
			]) {
				locPmtMethodMap.put(pm.Method__c, pm);
				// BLL1
				if (methodAltName.containsKey(pm.Method__c)) locPmtMethodMap.put(methodAltName.get(pm.Method__c), pm);
				// BLL1 end
			}
			System.debug(locPmtmethodMap);

			// Get all dealer__Cashering__c entries for this location that need 
			// their cash entries created (don't already have one)
			String query = 'select Name, dealer__Payment_Method__c, dealer__Amount__c, '
					+ 'Cash_Entry_Line_Item__c, Create_Cash_Entry__c, '
					+ 'dealer__Location__c, dealer__Location__r.Financial_Force_Dimension_1__c,  '
					+ 'dealer__Close_Date__c, dealer__Company_Number__c, Corporate_Entry__c, '	// BLL2c
					+ 'dealer__Customer__c, dealer__Customer__r.c2g__CODAAccountsReceivableControl__c, '	// BLL2c
					+ 'dealer__Deposit__c, dealer__Credit_Card_Authorization_Code__c, '
					+ 'dealer__Deal__c, dealer__Deal__r.Name, dealer__Deal__r.dealer__Store_Location__r.Financial_Force_Dimension_1__c, '
					+ 'dealer__Rental_Agreement__c, dealer__Rental_Agreement__r.Name, dealer__Rental_Agreement__r.Location__r.Financial_Force_Dimension_1__c, '
					+ 'dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name, dealer__Service_Repair_Order__r.dealer__Company__r.Financial_Force_Dimension_1__c, '
					+ 'dealer__Deal__r.dealer__Buyer__c, dealer__Service_Repair_Order__r.dealer__Customer__c, dealer__Rental_Agreement__r.Account__c '	// BLL4
				+ 'from dealer__Cashering__c '
				+ 'where Create_Cash_Entry__c=true and Cash_Entry_Line_Item__c=null '
				+ '  and dealer__Amount__c!=0 '
				+ '  and dealer__Location__c=\'' + loc.Id + '\' ';
			if (!String.isBlank(selectCriteria)) query += ' and ' + selectCriteria + ' ';
			// BLL8 - process in date order to minimize re-querying open period
			query += ' order by dealer__Close_Date__c, Name ';
			// BLL8 end
			if (!String.isBlank(recordLimit)) query += ' LIMIT ' + recordLimit;
			List<dealer__Cashering__c> cashiers = Database.query(query);

        	// Preflight reqs
        	Id ownerCompany =  FFAccounting.getFFCompany(loc.Id);
        	Id currencyId   =  FFAccounting.currency(ownerCompany);
        	//BLL8d Id openPeriod 	=  FFAccounting.getCurrentPeriod(ownerCompany);

			// My current company
			System.debug('[[[ My Current Company check ]]]');
			System.debug(FinancialForce_MBW.getMyCurrentCompanies());
			System.debug(ownerCompany);

			// BLL6 Use close date from cashier record instead of "now"
			//DateTime dt = DateTime.now();
			//Date entrydate = dt.date();
			//String entrydatestr = dt.format('yyyy-MM-dd');
			// BLL6 end
			Map<String, c2g.CODAAPICashEntryTypes_7_0.CashEntry> ceMap = new Map<String, c2g.CODAAPICashEntryTypes_7_0.CashEntry>();
			Map<String, dealer__Cashering__c> cashierMap = new Map<String, dealer__Cashering__c>();

			// BLL2a
			Map<Id,Account> setARCtl = new Map<Id,Account>();
			Map<Id,Account> resetAcct = new Map<Id,Account>();
			// BLL2a end

			// BLL5
			// Update accounts - ensure they have accounts receivable control numbers and NO dimension 1!
			Set<Id> acctIds = new Set<Id>();
			for(dealer__Cashering__c c : cashiers) {
				acctIds.add(c.dealer__Customer__c);
			}
			for(Account a : [select Id, Name, c2g__CODAAccountsReceivableControl__c, c2g__CODADimension1__c from Account where Id in :acctIds]) {
				boolean updacct = false;

				if (a.c2g__CODAAccountsReceivableControl__c==null) {
					a.c2g__CODAAccountsReceivableControl__c = acctRecGL.Id;
					updacct = true;
				}
				if (a.c2g__CODADimension1__c!=null) {
					updacct = true;
				}
				if (updacct) {
					setARCtl.put(a.Id, new Account(
						Id=a.Id,
						c2g__CODAAccountsReceivableControl__c=a.c2g__CODAAccountsReceivableControl__c,
						c2g__CODADimension1__c=null
					));
					//if (a.c2g__CODADimension1__c!=null) resetAcct.put(a.Id, new Account(Id=a.Id, c2g__CODADimension1__c=a.c2g__CODADimension1__c));
				}
			}
			// BLL5 end
			// BLL8
			c2g__codaPeriod__c period = null;
			Id openPeriod = null;
			// BLL8 end

			// For each cashier entry, build a financialforce Cash Entry (by location & FF payment method & date) & Lines
			for(dealer__Cashering__c c : cashiers) {

				// BLL6
				Date entrydate = c.dealer__Close_Date__c;
				if (entrydate==null) entrydate = Date.today();
				DateTime dt = DateTime.newInstance(entrydate, Time.newInstance(0, 0, 0, 0));
				String entrydatestr = dt.format('yyyy-MM-dd');
				// BLL6 end

				// BLL8 - get period for this entry
				if (openPeriod==null || period==null || period.c2g__StartDate__c>entrydate || period.c2g__EndDate__c<entrydate) {
					period = FinancialForce_MBW.getOpenPeriod(new c2g__codaCompany__c(Id=ownerCompany), entrydate);
					openPeriod = period!=null ? period.Id : FFAccounting.getCurrentPeriod(ownerCompany);
				}
				// BLL8 end

				// get the payment method definition for this location
				System.debug(c.dealer__Payment_Method__c);
				PaymentMethodsByLocation__c pmbl = locPmtMethodMap.get(c.dealer__Payment_Method__c);
				System.debug(pmbl);
				// If there is no definition, we don't create cash entries for this kind (aka. Charge to account & Receivables)
				if (pmbl!=null) {
				
					// Once new cash entry per location & payment method & whether it's corporate or not
					String cekey = c.dealer__Company_Number__c + ':' + pmbl.FF_Payment_Method__c
						+ ':' + ((c.dealer__Amount__c>=0) ? 'Receipt' : 'Refund');
					cekey = entrydatestr + ':' + cekey;	// BLL6a
					if (c.Corporate_Entry__c) cekey += ':Corp';	// BLL2a
					System.debug(cekey);
					c2g.CODAAPICashEntryTypes_7_0.CashEntry ce = ceMap.get(cekey);
					if (ce==null) {
						ce = newCashEntry(loc, currencyId, entrydate, openPeriod, (c.dealer__Amount__c<0 ? 'Refund' : 'Receipt'), pmbl, 
							dt.format('yyyyMMdd') + '/' + loc.Financial_Force_Dimension_1__r.c2g__ReportingCode__c 
							+ (c.Corporate_Entry__c?'/COR/':'/') + pmbl.FF_Payment_Method__c);	// BLL2c
						ceMap.put(cekey, ce);
					}
					System.debug(ce);

					// Link to DT Cashiering record by name to be used to reference back
					// to it on the generated cash entry line item after it's created
					cashierMap.put(c.Name, c);
					System.debug(c);

			        /* Generate Line Items */
			        c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItem celine = new c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItem();
			        celine.Account = c2g.CODAAPICommon.getRef(c.dealer__Customer__c, null);
					celine.AccountReference = c.Name;
					// Amounts must be positive numbers, cash entry type of "Receipt" or "Refund" controls +/-
			        celine.CashEntryValue = Math.abs(c.dealer__Amount__c);
			        celine.PaymentValue = Math.abs(c.dealer__Amount__c);
					celine.BankAccountValue = Math.abs(c.dealer__Amount__c);

					String controlnbr='';
					if (!String.isBlank(c.dealer__Rental_Agreement__r.Name)) controlNbr = c.dealer__Rental_Agreement__r.Name;
					if (!String.isBlank(c.dealer__Service_Repair_Order__r.Name)) controlNbr = c.dealer__Service_Repair_Order__r.Name;
					if (!String.isBlank(c.dealer__Deal__r.Name)) controlNbr = c.dealer__Deal__r.Name;
					celine.LineDescription = controlnbr + ' '
						+ (!String.isBlank(c.dealer__Credit_Card_Authorization_Code__c) ? c.dealer__Credit_Card_Authorization_Code__c : '') 
						+ (c.dealer__Amount__c<0 ? ' Refund' : '')
						+ (c.dealer__Deposit__c ? ' (Deposit)' : '');

					// Dimension of document, not current user
					if (c.dealer__Deal__c!=null) celine.AccountDimension1 = c2g.CODAAPICommon.getRef(c.dealer__Deal__r.dealer__Store_Location__r.Financial_Force_Dimension_1__c, null);
					if (c.dealer__Rental_Agreement__c!=null) celine.AccountDimension1 = c2g.CODAAPICommon.getRef(c.dealer__Rental_Agreement__r.Location__r.Financial_Force_Dimension_1__c, null);
					if (c.dealer__Service_Repair_Order__c!=null) celine.AccountDimension1 = c2g.CODAAPICommon.getRef(c.dealer__Service_Repair_Order__r.dealer__Company__r.Financial_Force_Dimension_1__c, null);
					// default to current user dimension
					if (celine.AccountDimension1==null) celine.AccountDimension1 = c2g.CODAAPICommon.getRef(c.dealer__Location__r.Financial_Force_Dimension_1__c, null);

					ce.LineItems.LineItemList.add(celine);
					ce.value += celine.CashEntryValue;

					// Store the cash entry back in the map (not sure this is even necessary)
					//ceMap.put(cekey, ce);

				}

			}

			// Find existing entries to append to & create map by composite key
			// BLL6d String locref = dt.format('yyyyMMdd') + '/' + loc.Financial_Force_Dimension_1__r.c2g__ReportingCode__c + '%' ;	// BLL2c
			String locref = + '%/' + loc.Financial_Force_Dimension_1__r.c2g__ReportingCode__c + '/%' ;
			Map<string,c2g__codaCashEntry__c> existingCEsMap = new Map<string,c2g__codaCashEntry__c>();
				  // AND c2g__ChargesGLADimension1__c=:loc.Financial_Force_Dimension_1__c
			String existingsoql = 'SELECT Id, Name, c2g__ChargesGLADimension1__c, c2g__Type__c, c2g__PaymentMethod__c, c2g__Reference__c, c2g__Date__c '	// BLL2c
				+ 'FROM c2g__codaCashEntry__c '
				+ 'WHERE c2g__Status__c =\'In Progress\' '
				+ '  AND c2g__OwnerCompany__c = \'' + ownerCompany + '\' '
				//BLL6d + '  AND c2g__Date__c = ' + entrydatestr + ' 
				+ '  AND c2g__Reference__c like \'' + locref + '\' '
				+ '  AND Automated_Entry__c = true ';
			System.debug(existingsoql);
			for(c2g__codaCashEntry__c entry : Database.query(existingsoql)) {
				String cekey = loc.dealer__Company_Number__c + ':' + entry.c2g__PaymentMethod__c
					+ ':' + entry.c2g__Type__c;
				// BLL6a
				String cedatestr = DateTime.newInstance(entry.c2g__Date__c, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
				cekey = cedatestr + ':' + cekey;	
				// BLL6a end
				if (entry.c2g__Reference__c.contains('/COR/')) cekey += ':Corp';	// BLL2a
				existingCEsMap.put(cekey, entry);
				System.debug(cekey);
				System.debug(entry);
			}
			System.debug('[[[ existing cash entries ]]]');
			System.debug(existingCEsMap);

			// BLL2 - ensure all accounts have AR control GL#
			try {
				if (setARCtl.size()>0) Database.update(setARCtl.values(), false);
			} catch(Exception e) {}
			// BLL2 end

			// Create cash entries
			//Map<String,c2g.CODAAPICommon.Reference> ceRefMap = new Map<String,c2g.CODAAPICommon.Reference>();
			c2g.CODAAPICommon_7_0.Context ct7 = new c2g.CODAAPICommon_7_0.Context(); 
			ct7.CompanyName = loc.Company__r.Name;

			// create the cash entries!
			Set<Id> ceIds = new Set<Id>();
			for(String cekey : ceMap.keySet()) {

				c2g.CODAAPICashEntryTypes_7_0.CashEntry ce = ceMap.get(cekey);

				// Set Id to existing entry to append
				c2g__codaCashEntry__c existingEntry = existingCEsMap.get(cekey);
				if (existingEntry!=null) {
					ce.Id = existingEntry.Id;
					System.debug(cekey);
					System.debug('Appending to existing cash entry ' + existingEntry.Name);
				}

				c2g.CODAAPICommon.Reference ref;
				try {
					if (doUpdate) {
						ref = c2g.CODAAPICashEntry_7_0.CreateCashEntry(ct7, ce);
						c2g__codaCashEntry__c cashentry = [
							select Id, Name, c2g__Status__c, c2g__Date__c, c2g__OwnerCompany__r.Name, 
								c2g__Period__r.Name, c2g__PaymentMethod__c, c2g__Reference__c, c2g__Type__c, c2g__Value__c
							from c2g__codaCashEntry__c 
							where Id=:ref.Id 
							limit 1
						];
						resultmap.put(ref.Id, String.join(new List<String>{
							//cashentry.Id, 
							cashentry.Name,
							String.valueOf(cashentry.c2g__Date__c), 
							cashentry.c2g__Type__c,
							cashentry.c2g__PaymentMethod__c, 
							String.valueOf(cashentry.c2g__Value__c),
							'"' + cashentry.c2g__OwnerCompany__r.Name + '"',
							cashentry.c2g__Period__r.Name, 
							cashentry.c2g__Reference__c, 
							cashentry.c2g__Status__c, 
							'Created'
						},','));
					} else {
						resultmap.put(cekey, String.join(new List<String>{
							cekey, 
							'"' + 'null' + '"',
							(ce.TypeRef==c2g.CODAAPICashEntryTypes_7_0.enumType.Refund ? 'Refund':'Receipt'),
							ce.PaymentMethod,
							String.valueOf(ce.Value),
							'"' + ct7.CompanyName + '"',
							'"' + 'null' + '"',
							ce.Reference, 
							'In Progress', 
							'Test only'
						},','));
					}
				} catch(Exception e) {
					for(c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItem l : ce.LineItems.LineItemList) {
						dealer__Cashering__c dtc = cashierMap.get(l.AccountReference);
						String docname = '';
						if (!String.isBlank(dtc.dealer__Rental_Agreement__r.Name)) docname = dtc.dealer__Rental_Agreement__r.Name;
						if (!String.isBlank(dtc.dealer__Service_Repair_Order__r.Name)) docname = dtc.dealer__Service_Repair_Order__r.Name;
						if (!String.isBlank(dtc.dealer__Deal__r.Name)) docname = dtc.dealer__Deal__r.Name;
						errormap.put(loc.Name + ' : ' + loc.Company__r.Name, String.join(new List<String>{
							docname,
							String.valueOf(ce.DateValue), 
							l.AccountReference,
							ce.PaymentMethod, 
							'"' + ct7.CompanyName + '"',
							ce.Reference, 
							'error',
							'"' + e.getMessage() + '"'
						},','));
					}
				}
				//if (ce.LineItems.LineItemList.size()>0) ceRefMap.put(cekey, ref);
				if (ref!=null && ref.Id!=null) ceIds.add(ref.id);

			}

			// cross-reference cash entry lines and DealerTeam Cashiering and add control# to cash entry lines
			// (control number is a custom field and not supported by the CreateCashEntry api)
			List<c2g__codaCashEntry__c> updces = new List<c2g__codaCashEntry__c>();
			List<c2g__codaCashEntryLineItem__c> updcelines = new List<c2g__codaCashEntryLineItem__c>();
			List<dealer__Cashering__c> updcashiers = new List<dealer__Cashering__c>();

			// udpate cash entries to set auto-match cash flag
			for(Id cid : ceIds) {
				updces.add(new c2g__codaCashEntry__c(
					Id=cid, AutoMatchCash__c=true, Automated_Entry__c=true
				));
			}

			List<String> storeReportData = new List<String>();	// for email to sales admins

			// Update cashier entries and cash entry line items to reference each other
			for(c2g__codaCashEntryLineItem__c cel : [
				select Id, Name, c2g__AccountReference__c, c2g__NetValue__c, c2g__LineDescription__c, 
					c2g__CashEntry__c, 
					c2g__CashEntry__r.Name, c2g__CashEntry__r.c2g__Type__c, c2g__CashEntry__r.c2g__Reference__c, c2g__CashEntry__r.c2g__Date__c, 
					c2g__LineNumber__c, Control__c, 
					c2g__Account__r.Name, c2g__AccountDimension1__r.Name 
				from c2g__codaCashEntryLineItem__c 
				where c2g__CashEntry__c in :ceIds
				order by c2g__CashEntry__c, c2g__LineNumber__c
				]) {

				// Store control number (dealerteam document number) and link to DealerTeam cashier record on the cash entry line item
				String controlNbr = '';

				// Get the associated DealerTeam cashier record
				dealer__Cashering__c dtc = cashierMap.get(cel.c2g__AccountReference__c);
				System.debug('Account reference: ' + cel.c2g__AccountReference__c);
				System.debug(JSON.serialize(dtc));
				if (dtc!=null) {
					// Get the associated dealerTeam cashier record
					updcashiers.add(new dealer__Cashering__c(Id=dtc.Id, Cash_Entry_Line_Item__c = cel.Id, Cash_Entry__c = cel.c2g__CashEntry__c));

					//if (!String.isBlank(dtc.dealer__MobilityDeal__r.Name)) controlNbr = dtc.dealer__MobilityDeal__r.Name;
					if (!String.isBlank(dtc.dealer__Rental_Agreement__r.Name)) controlNbr = dtc.dealer__Rental_Agreement__r.Name;
					if (!String.isBlank(dtc.dealer__Service_Repair_Order__r.Name)) controlNbr = dtc.dealer__Service_Repair_Order__r.Name;
					if (!String.isBlank(dtc.dealer__Deal__r.Name)) controlNbr = dtc.dealer__Deal__r.Name;
					// BLL4
					Id customerid = null;
					if (dtc.dealer__Deal__c!=null) customerid = dtc.dealer__Deal__r.dealer__Buyer__c;
					if (dtc.dealer__Service_Repair_Order__c!=null) customerid = dtc.dealer__Service_Repair_Order__r.dealer__Customer__c;
					if (dtc.dealer__Rental_Agreement__c!=null) customerid = dtc.dealer__Rental_Agreement__r.Account__c;
					System.debug(customerid);
					//if (!String.isBlank(controlNbr)) updcelines.add(new c2g__codaCashEntryLineItem__c(Id=cel.Id, Cashier__c=dtc.Id, Control__c=controlNbr));
					if (!String.isBlank(controlNbr)) updcelines.add(new c2g__codaCashEntryLineItem__c(Id=cel.Id, Cashier__c=dtc.Id, Control__c=controlNbr, CustomerName__c=customerid));
					// BLL4 end
					if (!String.isBlank(controlNbr)) {
						cel.Control__c = controlNbr;
						cel.CustomerName__c = customerid;
					}
				}

				// Email data to send to stores
				storeReportData.add(String.join(new List<String>{
					cel.c2g__CashEntry__r.Name, 
					'"'+String.valueOf(cel.c2g__CashEntry__r.c2g__Date__c)+'"', 
					cel.c2g__CashEntry__r.c2g__Reference__c, 
					String.valueOf(cel.c2g__LineNumber__c), 
					cel.Name,
					cel.c2g__AccountReference__c,
					'"' + cel.Control__c + '"', 
					'"' + cel.c2g__Account__r.Name + '"',
					'"' + cel.c2g__AccountDimension1__r.Name + '"',
					cel.c2g__CashEntry__r.c2g__Type__c,
					cel.c2g__LineDescription__c,
					String.valueOf(cel.c2g__NetValue__c)
				}, ','));

			}

			System.debug('[[[ Update References ]]]');
			System.debug(updces);
			System.debug(updcelines);
			System.debug(updcashiers);

			// Update the cross-reference links!
			update(updces);
			update(updcelines);
			update(updcashiers);

			// BLL2 - ensure all updated accounts have AR control removed (not needed per Michele S)
			if (resetAcct.size()>0) Database.update(resetAcct.values(), false); 
			// BLL2 end

			emailStoreContacts(loc, storeReportData);

			// Reset results & error messages if getting too large
			if (Limits.getLimitHeapSize() - Limits.getHeapSize() < 1000000){  // if less that 1 meg left
				sendEmail();
			}
		}
	}
	
	
	// newCashEntry
	//--------------------------------------------------
	private c2g.CODAAPICashEntryTypes_7_0.CashEntry newCashEntry(
		dealer__Dealer_Location__c loc, Id currencyId, Date entrydate, Id openPeriod,
		String type, PaymentMethodsByLocation__c pm, String reference) {
		System.debug('CashEntryAutoCreateDT.newCashEntry');

		String depositAccount= pm.Deposit_Account__c;
		String ffPaymentMethod = pm.FF_Payment_Method__c;
	
	    c2g__codaBankAccount__c bankAccount;
	    List<c2g__codaBankAccount__c> banks = [
				SELECT Id 
				FROM c2g__codaBankAccount__c 
				WHERE c2g__ReportingCode__c = :depositAccount
		];
		if (banks.size()>0) bankAccount = banks[0];
	    System.assert(bankAccount!=null && bankAccount.Id!=null, 
			'Bank account must be supplied to create Cash Entry');


		c2g.CODAAPICashEntryTypes_7_0.CashEntry ce = new c2g.CODAAPICashEntryTypes_7_0.CashEntry();
		ce.DateValue = entrydate;
	    ce.BankAccountCurrency = 'USD'; 
		ce.BankAccount = c2g.CODAAPICommon.getRef(bankAccount.Id, null);
		ce.CashEntryCurrency = c2g.CODAAPICommon.getRef(currencyId, null);
		ce.PaymentMethod = ffPaymentMethod;
		ce.Period = c2g.CODAAPICommon.getRef(openPeriod, null);
		ce.Status = c2g.CODAAPICashEntryTypes_7_0.enumStatus.InProgress;
		ce.TypeRef = type=='Refund' ? c2g.CODAAPICashEntryTypes_7_0.enumType.Refund : c2g.CODAAPICashEntryTypes_7_0.enumType.Receipt;
		ce.Value = 0;
		ce.Reference = reference;
		ce.Description = reference + ' ' + type;
		// ce.ChargesGLADimension1 = c2g.CODAAPICommon.getRef(loc.Financial_Force_Dimension_1__c, null);

	    ce.LineItems = new c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItems();
		ce.LineItems.LineItemList = new List<c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItem>();

		return ce;
	}


	// getLocation
	//--------------------------------------------
    private dealer__Dealer_Location__c getLocation(Id locationId) {
		System.debug('CashEntryAutoCreateDT.getLocation');
        return [
			SELECT Id, Name, dealer__Company_Number__c, 
				Financial_Force_Dimension_1__c, Financial_Force_Dimension_1__r.c2g__ReportingCode__c,
				Company__c, Company__r.Name, 
				Sales_Admin__c,Sales_Admin__r.Email, Commercial_Sales_Admin__c, Commercial_Sales_Admin__r.Email
			FROM dealer__Dealer_Location__c 
			WHERE Id=:locationId
		];
    }


	// finish - do next company until there are none left, then send results via email
	//-------------------------------------------------
	global void finish(Database.BatchableContext bc) {
		System.debug('CashEntryAutoCreateDT.finish');
		System.debug(remainingCompanyIds);
		if (remainingCompanyIds.size()>0) {
			System.debug('Next company: ' + remainingCompanyIds[0]);
			CashEntryAutoCreateDT b = new CashEntryAutoCreateDT(recordLimit, doUpdate, selectCriteria, remainingCompanyIds, resultmap, errormap);
			Database.executeBatch(b, 1);
		} else {
			System.debug('No more companies');
			sendEmail();
		}
	}


	// sendEmail of the results
	//-----------------------------------
	global void sendEmail() {
		System.debug('CashEntryAutoCreateDT.sendEmail');
		//Organization org = [select Id, Name, isSandbox from Organization limit 1];
		Organization org = OrganizationSingleton.getInstance();
		String csvheader = 'Cash entry, Date, Type, Payment method, Value, Company, Period, Reference, Status, Message\n';
		String errheader = 'Document, Date, Line Reference, Pay method, Company, Reference, Status, Message\n';
		String todaystr = DateTime.now().format('yyyy-MM-dd');
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//List<String> recipients = new List<String>{ UserInfo.getUserEmail() };
		List<String> recipients = new List<String>(Utility.getGroupMbrUserEmails('CashEntryAutoCreateDT'));
		if (org.isSandbox) recipients = new List<String>{UserInfo.getUserEmail()};
		if (recipients.size()==0) recipients.add(UserInfo.getUserEmail());

		//if (!org.isSandbox) recipients.add('another.email@mobilityworks.com');
		mail.setToAddresses(recipients); 
		mail.setSubject('Cash Entry creation complete - UPDATES');
		String body = 'Cash Entry creation has completed.\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n';
		mail.setPlainTextBody(body);

		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('CashEntries ' + todaystr + '.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + String.join(resultmap.values(),'\n'));
			if (resultmap.size()>0) listOfAttachments.add(resultcsv);
		Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
			upderrors.setContentType('text/csv');
			upderrors.setFileName('CashEntryErrors ' + todaystr + '.csv');
			upderrors.setInline(false);
			upderrors.Body = Blob.valueOf(errheader + String.join(errormap.values(), '\n'));
			if (errormap.size()>0) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (resultmap.size()>0 || errormap.size()>0) Messaging.sendEmail(emailMsgs);
		
		// Reset to clear HEAP
		resultmap = new Map<String,String>();
		errormap = new Map<String,String>();
		
	}


	// emailStoreContacts
	//-----------------------------------
	public void emailStoreContacts(dealer__Dealer_Location__c loc, List<String> storeReportData) {
		System.debug('CashEntryAutoCreateDT.emailStoreContacts');
		//Organization org = [select Id, Name, isSandbox from Organization limit 1];
		Organization org = OrganizationSingleton.getInstance();
		String csvheader = 'Cash entry, Date, Reference, Line nbr, Line, Cashier Name, Document, Account, Dimension1, Type, Payment Notes, Amount\n';
		String todaystr = DateTime.now().format('yyyy-MM-dd');
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> recipients = new List<String>();
		if (loc.Sales_Admin__c!=null) 
			recipients.add(loc.Sales_Admin__r.Email);
		if (loc.Commercial_Sales_Admin__c!=null && loc.Commercial_Sales_Admin__c!=loc.Sales_Admin__c)
			recipients.add(loc.Commercial_Sales_Admin__r.Email);
		if (org.isSandbox) recipients = new List<String>{UserInfo.getUserEmail()};
		if (recipients.size()==0) recipients.add(UserInfo.getUserEmail());

		mail.setToAddresses(recipients); 
		mail.setSubject('Cash Entries for ' + loc.Name);
		String body = 'Cash Entry creation has completed.\n';
		if (!doUpdate) body += 'Test only! NOT Updated!\n';
		mail.setPlainTextBody(body);

		Messaging.EmailFileAttachment resultcsv = new Messaging.EmailFileAttachment();
			resultcsv.setContentType('text/csv');
			resultcsv.setFileName('CashLines-' + loc.Name + ' ' + todaystr + '.csv');
			resultcsv.setInline(false);
			resultcsv.Body = Blob.valueOf(csvheader + String.join(storeReportData,'\n'));
			if (storeReportData.size()>0) listOfAttachments.add(resultcsv);
		mail.setFileAttachments(listOfAttachments);
		if (storeReportData.size()>0) emailMsgs.add(mail);

		// Only send if records were selected for processing...
		if (emailMsgs.size()>0) Messaging.sendEmail(emailMsgs);
	}


	// Schedulable context
	global void execute(SchedulableContext ctx) {
		System.debug('CashEntryAutoCreateDT.execute (schedule)');
		String maxrcds = Test.isRunningTest() ? '1' : null;
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c
			where ScheduledJobId__c=:ctx.getTriggerId()
		];
		BatchSchedule__c bs = bss.size()>0 ? bss[0] : new BatchSchedule__c(Parameters__c='', Active__c=true);
		//List<Object> runparams = new List<Object>();
		//	// default run params (no dynamic params specified)
		//	List<Object> runparams = new List<Object>();
		//	ScheduleParameters sp = new ScheduleParameters(global_parm1, global_parm2, ...);
		//	runparams.add(sp);
		//if (!String.isBlank(bs.Parameters__c)) runparams = (List<Object>) JSON.deserializeUntyped(bs.Parameters__c);
		//else runparams.add(new Map<String,Object>());	// default to 1 empty map to run once with default params!
		//for(Object o : runparams) {
		//	Map<String,Object> params = (Map<String,Object>) o; 
		//	String parm = (String) params.get('parm');
			if (bs==null || bs.Active__c) {
				CashEntryAutoCreateDT b = new CashEntryAutoCreateDT(null, true, null, null, null, null);
				Database.executeBatch(b, 1);
			}
		//}
	}

	// scheduleMe self-scheduler
	public static List<String> scheduleMe() {
		System.debug('CashEntryAutoCreateDT.scheduleMe');
		String thisClassName = CashEntryAutoCreateDT.class.getName();
		// from schedule custom settings
		List<BatchSchedule__c> bss = [
			select Name, ClassName__c, CronSchedule__c, Parameters__c, ScheduledJobId__c, Active__c, BatchSize__c
			from BatchSchedule__c 
			where ClassName__c=:thisClassName
		];
		
		// First remove existing scheduled jobs from the existing schedule custom settings... 
		for(BatchSchedule__c bs : bss) {
			try {
				if (!String.isBlank(bs.ScheduledJobId__c)) System.abortJob((Id) bs.ScheduledJobId__c);
			} catch(Exception e) {System.debug(e);}
		}

		// set default schedule if none found
		Integer i = 0;
		if (bss.size()==0) {
			for(String cron : CashEntryAutoCreateDT.CRON_LIST) {
				//String params = '';
				//for(Integer j=0; j<CRON_NAMESPACE.size(); ++j) {
				//	if (!String.isBlank(params)) params += ',';
				//	params += '{' 
				//		+ '"Limit":"' + parmvalue + '"' 
				//		+ '}'; 
				//}
				String devname = thisClassName.left(37) + '_' + String.valueOf(i+1);
				bss.add(new BatchSchedule__c(
					Name = devname,
					ClassName__c = thisClassName,
					CronSchedule__c = cron,
					//Parameters__c = '['
					//	+ params 
					//	+ ']',
					BatchSize__c = 1,
					Active__c=true
				));
				++i;
			}
		}
		
		// Now (re-)schedule the jobs that are in the BatchSchedule list for this class
		List<String> jobIds = new List<String>();
		CashEntryAutoCreateDT m = new CashEntryAutoCreateDT(null, true, null, null, null, null);
		for(BatchSchedule__c bs : bss) {
			System.debug(bs.CronSchedule__c);
			String jobname = bs.Name;
			if (Test.isRunningTest()) jobname += '_TEST';
			if (bs.Active__c) {
				Id jobId = System.schedule(jobname, bs.CronSchedule__c, m);
				bs.ScheduledJobId__c = jobId;
				jobIds.add(jobId);
			}
		}
		upsert(bss);
		return jobIds;
	}

}