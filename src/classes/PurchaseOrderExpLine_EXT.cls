/**
PurchaseOrderExpLine_EXT
Tested by: PurchaseOrderExpLine_EXT_TEST
Written by: Bryan Leaman
Date:	December 4, 2018
Project: W-000520

Coverage:
	2018-12-11	89%	(33/37)

Modifications:

sample json of inContextOfRef:
{
	"type":"standard__recordPage",
	"attributes":{
		"objectApiName":"dealer__Purchase_Order__c",
		"recordId":"a24Z0000002oVxXIAU",
		"actionName":"view"
	},
	"state":{}
}
**/
public with sharing class PurchaseOrderExpLine_EXT {
    private ApexPages.StandardController stdController;
    public dealer__Purchase_Order_Line__c obj;

    public PurchaseOrderExpLine_EXT(ApexPages.StandardController ctlr) {
		obj = (dealer__Purchase_Order_Line__c) ctlr.getRecord();
		stdController = ctlr;
		if (ApexPages.CurrentPage().getParameters()!=null) {
			Map<String,String> pmap = ApexPages.CurrentPage().getParameters();
			for(String p : pmap.keySet()) {
				if (p=='poId') obj.dealer__Purchase_Order__c = pmap.get(p);
				if (p.endsWith('_lkid')) {
					String parmPoId = pmap.get(p);
					if (parmPoId==dealer__Purchase_Order__c.SObjectType.getDescribe().getKeyPrefix()) {
						obj.dealer__Purchase_Order__c = parmPoId;
					}
				}
				if (p=='inContextOfRef') {
					String b64 = pmap.get(p).substring(2);
					String jsonstr = EncodingUtil.base64Decode(b64).toString();
					Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(jsonstr);
					if (m.containsKey('attributes')) {
						Map<String,Object> att = (Map<String,Object>) m.get('attributes');
						String objectApiName = (String) att.get('objectApiName');
						String recordId = (String) att.get('recordId');
						if (objectApiName=='dealer__Purchase_Order__c' && recordId!=null) {
							obj.dealer__Purchase_Order__c = (Id) recordId;
						}
					}
				}
			}
		}

    }

	public ApexPages.PageReference save() {

		if (obj.GeneralLedgerAcct__c!=null && obj.General_Ledger_Account__c==null) {
			List<GeneralLedgerAcctMW__c> glas = [select Id, GeneralLedgerAccountFF__c from GeneralLedgerAcctMW__c where Id=:obj.GeneralLedgerAcct__c];
			if (glas.size()>0) obj.General_Ledger_Account__c = glas[0].GeneralLedgerAccountFF__c;
		}

		try {
			upsert(obj);
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return null;
		}
		ApexPages.StandardController poctl = new ApexPages.StandardController(new dealer__Purchase_Order__c(Id=obj.dealer__Purchase_Order__c));
        PageReference nextpage = poctl.view(); 
        return nextpage;
	}

	public ApexPages.PageReference cancel() {
		ApexPages.StandardController poctl = new ApexPages.StandardController(new dealer__Purchase_Order__c(Id=obj.dealer__Purchase_Order__c));
        PageReference nextpage = poctl.view(); 
        return nextpage;
	}

}