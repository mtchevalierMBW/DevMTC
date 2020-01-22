/**
 * AvalaraSalesTaxValidator
 * Tested by: AvalaraSalesTaxValidator_TEST
 * Date: 2019-08-01
 * Programmer: Bryan Leaman
 * Project: #
 * Update proposal F&I overall status info when credit application statuses are updated.
 *
 * Coverage:
 *	2019-08-01	100%	(50/50)
 *
 * Modifications: 
 *
**/
public with sharing class AvalaraSalesTaxValidator {

	
	@AuraEnabled
	public static List<LocationTaxResult> CalculateTaxesForLocations(
		List<String> companyAbbrevs,
		Decimal amount,
		String taxCode,
		Date taxDate,
		Boolean testCompany
	){
 
		System.debug(companyAbbrevs);
		System.debug(taxcode);
		System.debug(taxdate);
		System.debug(testCompany);

		List<LocationTaxResult> resultsByLocation = new List<LocationTaxResult>();

		AvaTax_MBW tax = new AvaTax_MBW();
		tax.forceTestEndpoint = testCompany;
		TaxSvc.TaxSvcSoap soapClient = tax.getAvataxClient();

		AvaTax__c avatax_settings = AvaTax__c.getOrgDefaults();
		String CompanyCode = testCompany ? avatax_settings.Test_CompanyCode__c : avatax_settings.CompanyCode__c;

		for(dealer__Dealer_Location__c l : [
		    select Id, Name, dealer__Company_Number__c, 
				dealer__Street__c, dealer__City__c, dealer__State__c, dealer__Postal_Code__c
		    from dealer__Dealer_Location__c 
		    where dealer__Company_Number__c in :companyAbbrevs
			order by dealer__State__c
		]) {
		
		    TaxSvc.GetTaxRequest gettaxReq = new TaxSvc.GetTaxRequest();
		    gettaxReq.DocCode = 'Test';
		    gettaxReq.DocType = 'SalesOrder';
		    gettaxReq.CompanyCode = CompanyCode;
		    gettaxReq.CustomerCode = 'TESTCUSTOMER';
		    gettaxReq.DetailLevel = 'Tax';
		    getTaxReq.DocDate = taxdate;
		    gettaxReq.Commit_x=false;

		    gettaxReq.Addresses = new TaxSvc.ArrayOfBaseAddress();
		    gettaxReq.Addresses.BaseAddress = new List<TaxSvc.BaseAddress>();
		    TaxSvc.BaseAddress addr1 = new TaxSvc.BaseAddress();
		    addr1.AddressCode = 'Store';
		    addr1.Line1 = l.dealer__Street__c;
		    addr1.City = l.dealer__City__c;
		    addr1.Region = l.dealer__State__c;
		    addr1.PostalCode = l.dealer__Postal_Code__c;
		    gettaxReq.Addresses.BaseAddress.add(addr1);
		    //TaxSvc.BaseAddress addr2 = new TaxSvc.BaseAddress();
		    //addr2.AddressCode = 'Customer';
		    //addr2.Line1 = 'street';
		    //addr2.City = 'city';
		    //addr2.Region = 'state';
		    //addr2.PostalCode = 'zip';
		    //gettaxReq.Addresses.BaseAddress.add(addr2);
		    gettaxReq.OriginCode = 'Store';
		    gettaxReq.DestinationCode = 'Store';

		    gettaxReq.Lines = new TaxSvc.ArrayOfLine();
		    gettaxReq.Lines.Line = new List<TaxSvc.Line>();

		    TaxSvc.Line taxLine = new TaxSvc.Line();
		    taxLine.TaxCode = taxcode;
		    taxLine.No = '1';
		    taxLine.ItemCode = 'Test';
		    taxLine.Description = 'Test';
		    taxLine.Amount = amount;
		    gettaxReq.Lines.Line.add(taxLine);

		    tax.gettaxReq = gettaxReq;
		    if (!Test.isRunningTest()) tax.calculateTax();

		    System.debug(tax.gettaxRslt);
		    Avatax_MBW.TaxResults resultSmry = tax.summarizeTaxResults();
			System.debug(resultSmry);
			resultsByLocation.add(new LocationTaxResult(l, resultSmry.TotalAmt, resultSmry.TaxableAmt, resultSmry.Tax));
		}

		System.debug(resultsByLocation);
		return resultsByLocation;
	}

	public class LocationTaxResult {
		@AuraEnabled public dealer__Dealer_Location__c location;
		@AuraEnabled public Decimal Amount;
		@AuraEnabled public Decimal TaxableAmount;
		@AuraEnabled public Decimal TaxAmount;
		@AuraEnabled public Decimal EffectiveRate;
		public LocationTaxResult(dealer__Dealer_Location__c loc, Decimal amt, Decimal taxable, Decimal tax) {
			location = loc;
			Amount = amt;
			TaxableAmount = taxable;
			TaxAmount = tax;
			EffectiveRate = null;
			if (TaxableAmount!=null && TaxableAmount!=0 && TaxAmount!=null) EffectiveRate = TaxAmount*100 / TaxableAmount;
		}
	}

}