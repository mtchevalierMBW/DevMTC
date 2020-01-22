/**
 * ServiceEstimateTaxes_EXT
 * Tested by: ServiceEstimateTaxes_EXT_TEST
 * Date: February 2, 2018
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 * 2018-02-02	94% (49/52)
 */

global with sharing class ServiceEstimateTaxes_EXT {
    private ApexPages.StandardController stdController;
    public dealer__Service_Estimate__c obj;
    public dealer__Service_Estimate__c sco;
	public AvaTax_MBW.TaxResults taxresult {get; private set;}
	public List<String> Jurisdictions {get; private set;}
	public List<String> JurisdictionTypes {get; private set;}
	public List<Decimal> TaxableAmounts {get; private set;}
	public List<Decimal> TaxPcts {get; private set;}
	public List<Decimal> TaxAmts {get; private set;}
	public Decimal TotalTax {get; private set;}
	private AvaTax_MBW tax;
	public String hash {get;private set;}
	public boolean debug {get; private set;}
	    
    public ServiceEstimateTaxes_EXT(ApexPages.StandardController ctlr) {
		List<String> fldList = new List<String>();
		Map<String, Schema.SObjectField> fieldMap =  Schema.dealer__Service_Estimate__c.SObjectType.getDescribe().fields.getMap();
		for(string f : fieldMap.keySet())
			if (fieldMap.get(f).getDescribe().isAccessible()) fldList.add(f);
		String allfields = String.join(fldList, ',');

		//List<String> fields = new List<String>();
		//fields.add('TaxCalcDT__c');
		//fields.add('TaxHash__c');
		//fields.add('TaxResults_JSON__c');
		//fields.add('dealer__Estimate_Total__c');
		//if(!Test.isRunningTest()) ctlr.addFields(fields);

		sco = (dealer__Service_Estimate__c) ctlr.getRecord();
		String soql = 'select ' + allfields + ' from dealer__Service_Estimate__c where Id=\'' + sco.Id + '\' limit 1 ';    
		obj = Database.query(soql);
		stdController = ctlr;
		if (obj!=null && obj.Id!=null) tax = AvaTax_MBW.getInstanceServiceEstimateId(obj.Id);
		if (tax!=null) hash = tax.getHash();
		debug = ApexPages.currentPage().getParameters().containsKey('debug');

		Jurisdictions = new List<String>();
		JurisdictionTypes = new List<String>();
		TaxableAmounts = new List<Decimal>();
		TaxPcts = new List<Decimal>();
		TaxAmts = new List<Decimal>();
		TotalTax = 0.00;

		if (!String.isBlank(obj.TaxResults_JSON__c)) {
			try {
				taxresult = (AvaTax_MBW.TaxResults) JSON.deserialize(obj.TaxResults_JSON__c, AvaTax_MBW.TaxResults.class);
				for( AvaTax_MBW.TaxResultJuris j : taxresult.byJurisdiction) {
					Jurisdictions.add(j.Jurisdiction);
					JurisdictionTypes.add(j.JurisdictionType);
					TaxableAmounts.add(j.TaxableAmt);
					TaxPcts.add(j.TaxRate * 100);
					TaxAmts.add(j.Tax);
					TotalTax += j.Tax;
				}
			} catch(Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
					'Internal error with tax results. Please recalculate taxes.'));
			}
		}
	}
	
	public boolean getNeedToCalculateTaxes() {
		boolean rtn = false;
		rtn = (obj.dealer__Estimate_Total__c!=null && obj.dealer__Estimate_Total__c!=0)
			&& tax!=null 
			&& (obj.TaxHash__c==null || obj.TaxHash__c!=tax.getHash());
		return rtn;
	}
	
	@RemoteAction
	global static void CalculateTaxes(String objidstr) {
		Id objId = (Id) objidstr;
		AvaTax_MBW tax = AvaTax_MBW.getInstanceServiceEstimateId(objid);
		tax.calculateTax();
		tax.saveEstimateTaxDetail();	
	}
	
}