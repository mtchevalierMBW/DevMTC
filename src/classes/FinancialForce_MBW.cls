/**
 * FinancialForce_MBW
 * Tested by: FinancialForce_MBW_TEST
 * Programmer: Bryan Leaman
 * Date: 2015-12-07
 * Coverage:
 *	2017-10-17	89%	(175/197)
 * 
 Modifications:
 2019-04-17	B. Leaman	W-000575 BLL1 - add RestrictCashPosting__c field to soql query on period.
 */
public without sharing class FinancialForce_MBW {

	// getAllCompanies - return list of all FF companies
	public static List<c2g__codaCompany__c> getAllCompanies() {
		System.debug('getAllCompanies');
		List<c2g__codaCompany__c> companies = new List<c2g__codaCompany__c>();
		for(c2g__codaCompany__c c : [
			select RecordType.Name, Id, Name, OwnerId, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c 
			from c2g__codaCompany__c 
		]) {
			if (c.OwnerId.getSObjectType()!=Schema.User.SObjectType) {
				companies.add(c);
			}
		}
		System.debug(companies);
		return companies;
	}
   
	// getCompanyOwnerIds - return list of queue ids (company owners)
	public static Set<Id> getCompanyOwnerIds() {
		System.debug('getCompanyOwnerIds');
		Set<Id> idset = new Set<Id>();
		for(c2g__codaCompany__c cmp : FinancialForce_MBW.getAllCompanies()) {
			idset.add(cmp.OwnerId);
		}
		return idset;
	}
	
	// getMyAuthorizedCompanies
	public static List<c2g__codaCompany__c> getMyAuthorizedCompanies() {
		return getAuthorizedCompaniesFor(UserInfo.getUserId());
	}
	// getAuthorizedCompaniesFor userid
	public static List<c2g__codaCompany__c> getAuthorizedCompaniesFor(Id uid) {
		List<c2g__codaCompany__c> authCmps = new List<c2g__codaCompany__c>();
		Set<Id> cmpIds = new Set<Id>();
		for(c2g__codaUserCompany__c uc : [
			select Id, c2g__User__c, c2g__Company__c
			from c2g__codaUserCompany__c
			where c2g__User__c=:uid
		]) {
			cmpIds.add(uc.c2g__Company__c);
		}
		return [
			select RecordType.Name, Id, Name, OwnerId, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c 
			from c2g__codaCompany__c
			where Id in :cmpIds 
		];
	}
	
	// getMyCurrentCompanyIds
	public static Set<Id> getMyCurrentCompanyOwnerIds() {
		return FinancialForce_MBW.getCurrentCompanyOwnerIdsFor(UserInfo.getUserId());
	}
	// getCurrentCompanyIdsFor userid
	public static Set<Id> getCurrentCompanyOwnerIdsFor(Id uid) {
		Set<Id> companyowners = FinancialForce_MBW.getCompanyOwnerIds();
		Set<Id> userCmpIds = new Set<Id>();
		for(GroupMember gm : [
			select Id, GroupId from GroupMember 
			where GroupId in :companyowners and UserOrGroupId = :uid
			]) {
			userCmpIds.add(gm.GroupId);
		}
		return userCmpIds;
	}
	
	//getMyCurrentCompanies
	public static List<c2g__codaCompany__c> getMyCurrentCompanies() {
		return FinancialForce_MBW.getCurrentCompaniesFor(UserInfo.getUserId());
	}
	// getCurrentCompaniesFor user
	public static List<c2g__codaCompany__c> getCurrentCompaniesFor(Id uid) {
		Set<Id> cmpOwnIds = FinancialForce_MBW.getCurrentCompanyOwnerIdsFor(uid);
		List<c2g__codaCompany__c> cmps = [
			select RecordType.Name, Id, Name, OwnerId, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c 
			from c2g__codaCompany__c
			where OwnerId in :cmpOwnIds 
		];
		return cmps;
	}

	// selectCompany
	public static boolean selectCompany(Id cmpId) {
		return FinancialForce_MBW.selectCompanyFor(UserInfo.getUserId(), cmpId);
	}
	// selectCompanyFor user cmpid
	public static boolean selectCompanyFor(Id uid, Id cmpId) {
		System.debug('selectCompanyFor user id ' + uid + ', company id ' + cmpId);
		Set<Id> cmpIds = new Set<Id>();
		cmpIds.add(cmpId);
		return selectCompaniesFor(uid, cmpIds);
		//boolean okay = true;
		//Set<Id> cmpIds = FinancialForce_MBW.getCurrentCompanyIdsFor(uid);
		//Set<Id> rmvCmp = new Set<Id>();
		//boolean needToAddCmp = true;
		//for(Id i : cmpIds) {
		//	if (i!=cmpId) {
		//		rmvCmp.add(i);
		//	}
		//	needToAddCmp = needToAddCmp && (i!=cmpId);
		//}
		//try {
		//	if (rmvCmp.size()>0) {
		//		List<GroupMember> gm = [
		//			select Id, GroupId 
		//			from GroupMember 
		//			where GroupId in :rmvCmp and UserOrGroupId=:uid
		//		];
		//		if (gm.size()>0) delete(gm);
		//	}
		//	if (needToAddCmp) {
		//		GroupMember g = new GroupMember(GroupId=cmpId, UserOrGroupId=uid);
		//		insert(g);
		//	}
		//} catch(Exception e) {
		//	okay = false;
		//	System.debug('Unable to selectCompany ' + cmpId + ': ' + e.getMessage());
		//}
		//return okay;
	}

	// getCompanyOwnerMap
	public static Map<Id,Id> getCompanyOwnerMap() {
		List<c2g__codaCompany__c> companies = FinancialForce_MBW.getAllCompanies();
		Map<Id,Id> cmpOwnMap = new Map<Id,Id>();
		for(c2g__codaCompany__c c : companies) {
			cmpOwnMap.put(c.Id, c.OwnerId);
		}
		return cmpOwnMap;
	}
	
	// selectCompany
	public static boolean selectCompanies(Set<Id> cmpIds) {
		return FinancialForce_MBW.selectCompaniesFor(UserInfo.getUserId(), cmpIds);
	}
	// selectCompanyFor user cmpid
	public static boolean selectCompaniesFor(Id uid, Set<Id> cmpIds) {
		System.debug('selectCompanyFor user id ' + uid + ', company id ' + JSON.serialize(cmpIds));
		boolean okay = true;
		List<c2g__codaCompany__c> currCmps = FinancialForce_MBW.getCurrentCompaniesFor(uid);
		Set<Id> currCmpIds = new Set<Id>();
		for(c2g__codaCompany__c c : currCmps) {
			currCmpIds.add(c.Id);
		} 
		
		Set<Id> rmvCmpOwnIds = new Set<Id>();
		Set<Id> addCmpOwnIds = new Set<Id>();
		Map<Id,Id> cmpOwnMap = FinancialForce_MBW.getCompanyOwnerMap();
		for(Id i : cmpIds) {
			if (!currCmpIds.contains(i)) addCmpOwnIds.add(cmpOwnMap.get(i));
		}
		for(Id i : currCmpIds) {
			if (!cmpIds.contains(i)) rmvCmpOwnIds.add(cmpOwnMap.get(i));
		}
		try {
			if (rmvCmpOwnIds.size()>0) {
				List<GroupMember> gm = [
					select Id, GroupId 
					from GroupMember 
					where GroupId in :rmvCmpOwnIds and UserOrGroupId=:uid
				];
				if (gm.size()>0) delete(gm);
			}
			if (addCmpOwnIds.size()>0) {
				List<GroupMember> gms = new List<GroupMember>();
				for(Id i : addCmpOwnIds) {
					gms.add(new GroupMember(GroupId=i, UserOrGroupId=uid));
				}
				insert(gms);
			}
		} catch(Exception e) {
			okay = false;
			System.debug('Unable to selectCompanies ' + JSON.serialize(cmpIds) + ': ' + e.getMessage());
		}
		return okay;
	}

	// GrantUserCompanyAuth
	public static void GrantUserCompanyAuth(Set<Id> uids, Set<Id> cmpids) {
		System.debug('GrantUserCompanyAuth');
		System.debug(uids);
		System.debug(cmpids);
		Set<String> exist = new Set<String>();
		for(c2g__codaUserCompany__c ex : [
			select c2g__User__c, c2g__Company__c 
			from c2g__codaUserCompany__c 
			where c2g__User__c in :uids and c2g__Company__c in :cmpids
		])	{
			exist.add(((String)ex.c2g__User__c) + ':' + ((String) ex.c2g__Company__c));
		}
		List<c2g__codaUserCompany__c> uc = new List<c2g__codaUserCompany__c>();
		for(Id u : uids) {
			for(Id c : cmpids) {
				if (!exist.contains( ((String) u) + ':' + ((String) c) )) {
					uc.add(new c2g__codaUserCompany__c(c2g__User__c=u, c2g__Company__c=c));
				}
			}
		}
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.optAllOrNone = false;   
		if (uc.size()>0) Database.insert(uc, dml);
		//if (uc.size()>0) insert(uc);
		System.debug(uc);
	}

	// getPeriod
	public static c2g__codaPeriod__c getOpenPeriod(c2g__codaCompany__c company, Date txnDate) {
		// Next open period ending after transaction date
		// BLL1 add RestrictCashPosting__c to soql:
		c2g__codaPeriod__c period = [
			select Id, Name, c2g__StartDate__c, c2g__EndDate__c, c2g__Closed__c, RestrictCashPosting__c, c2g__AP__c, c2g__AR__c, c2g__Cash__c 
			from c2g__codaPeriod__c
			where c2g__OwnerCompany__c=:company.Id and c2g__EndDate__c>=:txnDate 
			  and c2g__Closed__c!=true 
			order by c2g__StartDate__c
			limit 1
		];
		return period;
	}

	// createJournalApi
	public static Id createJournalApi(c2g__codaJournal__c journal, List<c2g__codaJournalLineItem__c> jlines) {

		// Build journal for API so multi-company works
		c2g.CODAAPIJournalTypes_12_0.Journal apiJournal = new c2g.CODAAPIJournalTypes_12_0.Journal();
		
		// Company Context - from company field in journal header
		c2g__codaCompany__c company=null;
		if (journal!=null && journal.c2g__OwnerCompany__c!=null) company = [select Id, Name, OwnerId from c2g__codaCompany__c where Id=:journal.c2g__OwnerCompany__c];
		System.debug(company);
		
		// error if not activated
		if (company!=null && company.OwnerId.getSObjectType()!=Schema.Group.SObjectType) {
			System.debug('Error: Company ' + company.Name + ' is not activated.');
			// throw new FFException('Error: Company ' + company.Name + ' is not activated.');
		}
		c2g.CODAAPICommon_10_0.Context ctx = new c2g.CODAAPICommon_10_0.Context();
		ctx.CompanyName = company!=null ? company.Name : null;
		
		// Currency
		apiJournal.JournalCurrency = new c2g.CODAAPICommon.Reference();
		apiJournal.JournalCurrency.Name='USD';

		// Required to be a valid journal (JVK 12-13-2015)
		apiJournal.JournalStatus = c2g.CODAAPIJournalTypes_12_0.enumJournalStatus.InProgress;
		apiJournal.TypeRef = c2g.CODAAPIJournalTypes_12_0.enumType.ManualJournal;

		if (journal.c2g__JournalCurrency__c!=null) {
			c2g__codaAccountingCurrency__c curr = [
				select Id, Name 
				from c2g__codaAccountingCurrency__c 
				where Id=:journal.c2g__JournalCurrency__c
			];
			apiJournal.JournalCurrency.Name=curr.Name; 
		}
		
		// Date & Period
		apiJournal.JournalDate = journal.c2g__JournalDate__c;
		apiJournal.Period = new c2g.CODAAPICommon.Reference();
		c2g__codaPeriod__c period = FinancialForce_MBW.getOpenPeriod(company, journal.c2g__JournalDate__c);
		if (period!=null && period.c2g__StartDate__c > journal.c2g__JournalDate__c) {
			apiJournal.JournalDate = period.c2g__StartDate__c;
		}
		apiJournal.Period.Name = period!=null ? period.Name : null;
		
		// Created by
		if (journal.CreatedById!=null) {
			apiJournal.CreatedById = new c2g.CODAAPICommon.Reference();
			apiJournal.CreatedById.Id = journal.CreatedById;
		}
		
		apiJournal.JournalDescription = journal.c2g__JournalDescription__c;
		apiJournal.Reference = journal.c2g__Reference__c;
		
		
		// Journal lines
		apiJournal.LineItems = new c2g.CODAAPIJournalLineItemTypes_12_0.JournalLineItems();
		apiJournal.LineItems.LineItemList = new List<c2g.CODAAPIJournalLineItemTypes_12_0.JournalLineItem>();
		Map<Decimal,c2g__codaJournalLineItem__c> lineMap = new Map<Decimal,c2g__codaJournalLineItem__c>();
		Decimal lineNo = 0;
		for(c2g__codaJournalLineItem__c line : jlines) {
			lineNo += 1;
			lineMap.put(lineNo, line);
		
			// Create journal line
			c2g.CODAAPIJournalLineItemTypes_12_0.JournalLineItem apiLine = new c2g.CODAAPIJournalLineItemTypes_12_0.JournalLineItem();
			apiLine.LineDescription = line.c2g__LineDescription__c;
			apiLine.Value = line.c2g__Value__c;
		
			// Line type...
			if (line.c2g__LineType__c=='General Ledger Account') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.GeneralLedgerAccount;
			if (line.c2g__LineType__c=='Account - Customer') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.Account_Customer;
			if (line.c2g__LineType__c=='Account - Vendor') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.Account_Vendor;
			if (line.c2g__LineType__c=='Bank Account') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.BankAccount;
			if (line.c2g__LineType__c=='Product - Purchases') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.Product_Purchases;
			if (line.c2g__LineType__c=='Product - Sales') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.Product_Sales;
			if (line.c2g__LineType__c=='Tax Code') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.TaxCode;
			if (line.c2g__LineType__c=='Intercompany') apiLine.LineTypeRef = c2g.CODAAPIJournalLineItemTypes_12_0.enumLineType.Intercompany;
		
			// GL Account
			apiLine.GeneralLedgerAccount = new c2g.CODAAPICommon.Reference();
			apiLine.GeneralLedgerAccount.Id = line.c2g__GeneralLedgerAccount__c;
			
			// Dimensions1-4 (if specified)
			if (line.c2g__Dimension1__c!=null) {
				apiLine.Dimension1 = new c2g.CODAAPICommon.Reference();
				apiLine.Dimension1.Id=line.c2g__Dimension1__c;
			} 
			if (line.c2g__Dimension2__c!=null) {
				apiLine.Dimension2 = new c2g.CODAAPICommon.Reference();
				apiLine.Dimension2.Id=line.c2g__Dimension2__c;
			} 
			if (line.c2g__Dimension3__c!=null) {
				apiLine.Dimension3 = new c2g.CODAAPICommon.Reference();
				apiLine.Dimension3.Id=line.c2g__Dimension3__c;
			} 
			if (line.c2g__Dimension4__c!=null) {
				apiLine.Dimension4 = new c2g.CODAAPICommon.Reference();
				apiLine.Dimension4.Id=line.c2g__Dimension4__c;
			} 
		
			// Customer or Vendor account
			if (line.c2g__Account__c!=null) {
				apiLine.Account = new c2g.CODAAPICommon.Reference();
				apiLine.Account.Id = line.c2g__Account__c;
			}
			
			// Bank account
			if (line.c2g__BankAccount__c!=null) {
				apiLine.BankAccount = new c2g.CODAAPICommon.Reference();
				apiLine.BankAccount.Id = line.c2g__BankAccount__c;
			}
		
			// Destination company
			if (line.c2g__DestinationCompany__c!=null) {
				apiLine.DestinationCompany = new c2g.CODAAPICommon.Reference();
				apiLine.DestinationCompany.Id = line.c2g__DestinationCompany__c;
			}
			
			apiJournal.LineItems.LineItemList.add(apiLine);
		}
		
		
		// Create journal using API
		c2g.CODAAPICommon.Reference jref = c2g.CODAAPIJournal_12_0.CreateJournal(ctx, apiJournal);
		
		if (jref.Id!=null) {
			// Add our custom fields for generated journal 
			DescribeSObjectResult jdsr = journal.getSObjectType().getDescribe();
			Map<String, Schema.SObjectField> jfldmap = jdsr.fields.getMap();
			
			c2g__codaJournal__c j = new c2g__codaJournal__c(Id=jref.Id);
			for(String k : jfldmap.keySet()) {
				String baseField = k.removeEnd('__c');
				// skip managed field values
				if (!baseField.contains('__') ) {  
					Schema.DescribeFieldResult dfr = jfldmap.get(k).getDescribe();
					if (dfr.isUpdateable()) {
						Object fldvalue = journal.get(k);
						if (fldvalue!=null) {
							j.put(k, fldvalue);
						}
					}
				}
			}
			update(j);
			
			// Add our custom fields for the journal lines 
			DescribeSObjectResult jldsr = jlines[0].getSObjectType().getDescribe();
			Map<String, Schema.SObjectField> jlfldmap = jldsr.fields.getMap();
			List<c2g__codaJournalLineItem__c> jls = [
				select Id, c2g__LineNumber__c 
				from c2g__codaJournalLineItem__c 
				where c2g__Journal__c=:j.Id
			];
			for(c2g__codaJournalLineItem__c jl : jls) {
				c2g__codaJournalLineItem__c srcline = lineMap.get(jl.c2g__LineNumber__c);
				if (srcline!=null) {
					for(String k : jlfldmap.keySet()) {
						String baseField = k.removeEnd('__c');
						// skip managed field values
						if (!baseField.contains('__') ) {  
							Schema.DescribeFieldResult dfr = jlfldmap.get(k).getDescribe();
							if (dfr.isUpdateable()) {
								Object fldvalue = srcline.get(k);
								if (fldvalue!=null) {
									jl.put(k, fldvalue);
								}
							}
						}
					}
				}
			}
			update(jls);
		}
			
		system.debug(jref.Id);

		return jref.Id;
	}
		
}