/**
 * AccountBalance
 * Tested by: AccountBalance_TEST
 * Date: 2019-01-31
 * Programmer: Bryan Leaman
 * Project: W-000574
 *
 * Coverage:
 *	2019-02-01	88%	(22/25)
 *
 * Modifications:
 *
**/
public with sharing class AccountBalance {

	// AuthorizedToTransactionLines
	//------------------------------
	@AuraEnabled
	public static boolean AuthorizedToTransactionLines(){
		return Schema.SObjectType.c2g__codaTransactionLineItem__c.isAccessible();
	}

	@AuraEnabled
	public static string ReportURL(){
		c2g__AccountSettings__c ffaAS = c2g__AccountSettings__c.getInstance();
		return '/lightning/r/Report' + ffaAS.c2g__AccountBalanceReportURL__c + '/view';
	}

	// AccountBalancesByCompany
	//----------------------------
	@AuraEnabled
	public static List<AccountBalance.BalanceByCompany> AccountBalancesByCompany(Id accountId){
		List<AggregateResult> arlist = [
			select c2g__OwnerCompany__c companyid, c2g__OwnerCompany__r.Name companyname, sum(c2g__AccountOutstandingValue__c) balance
			from c2g__codaTransactionLineItem__c
			where c2g__Account__c=:accountId and c2g__AccountOutstandingValue__c!=0.00
			  and c2g__LineType__c = 'Account' and c2g__MatchingStatus__c != 'Matched'
			group by c2g__OwnerCompany__c, c2g__OwnerCompany__r.Name
			order by c2g__OwnerCompany__r.Name
		];
		Decimal grandTotal = 0.00;
		List<AccountBalance.BalanceByCompany> bbcs = new List<AccountBalance.BalanceByCompany>();
		for(AggregateResult ar : arlist) {
			Decimal amount = (Decimal) ar.get('balance');
			bbcs.add(new AccountBalance.BalanceByCompany((Id) ar.get('companyid'), 	(String) ar.get('companyname'), (String) ar.get('companyname'), amount ));
			grandTotal += amount;
		}
		if (bbcs.size()>0) bbcs.add(new AccountBalance.BalanceByCompany(null, 'Total', ' ', grandTotal));
		return bbcs;
	}

	// BalanceByCompany
	//=============================
	public class BalanceByCompany {
		@AuraEnabled public Id CompanyId {get;set;}
		@AuraEnabled public String CompanyName {get;set;}
		@AuraEnabled public String CompanySearch {get;set;}
		@AuraEnabled public Decimal Balance {get;set;}
		public BalanceByCompany(Id cid, String cname, String csearch, Decimal amount) {
			CompanyId = cid;
			CompanyName = cname;
			CompanySearch = csearch;
			Balance = amount;
		}
	}
}