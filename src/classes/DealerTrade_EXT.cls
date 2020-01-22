/**
 * DealerTrade_EXT
 * Tested by: VehicleTransfer_TEST
 *
 *	Modification log:
 *	2018-08-09	B. Leaman	BLL1 - fix page reference re-direction for lightning
 */

public with sharing class DealerTrade_EXT {
    private ApexPages.StandardController stdController;
    public dealer__Dealer_Trade__c dealertrade;
    public String retURL = null;
    
    public DealerTrade_EXT(ApexPages.StandardController ctlr) {
		List<String> fields = new List<String>();
		//fields.add('Desired_Vehicles__c');
		if(!Test.isRunningTest() && fields.size()>0) ctlr.addFields(fields);

		stdController = ctlr;
		dealertrade = (dealer__Dealer_Trade__c) stdController.getRecord();

		Map<String,String> parms = ApexPages.currentPage().getParameters();
 		for(String k : parms.keySet()) {
 			System.debug('Parameter ' + k + '=' + parms.get(k));
 			if (k=='vehId') {
 				Id lkid = parms.get(k);
				if (lkid.getSObjectType()==Schema.dealer__Vehicle_Inventory__c.SObjectType)	dealertrade.dealer__Stock_No__c = parms.get(k);
 			}
 			if (k=='retURL') retURL = parms.get(k);
 		}
		if (retURL==null) retURL = ApexPages.currentPage().getHeaders().get('Referer');
	
		if (dealertrade.Id==null) {
			dealertrade.dealer__Salesperson__c = UserInfo.getUserId();
			if (dealertrade.dealer__Store_Location__c==null) {
				User u = CurrentUserSingleton.getInstance();
				List<dealer__Dealer_Location__c> usrloc = [select Id from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division];
				if (usrloc!=null && usrloc.size()>0) {
					dealertrade.dealer__Store_Location__c = usrloc[0].Id;
				}
			}
			if (dealertrade.dealer__Stock_No__c!=null && dealertrade.dealer__Outbound_Location__c==null) {
				List<dealer__Vehicle_Inventory__c> vehs = [select Id, Name, dealer__Store_Location__c from dealer__Vehicle_Inventory__c where Id=:dealertrade.dealer__Stock_No__c];
				if (vehs!=null && vehs.size()>0) {
					dealertrade.dealer__Outbound_Location__c = vehs[0].dealer__Store_Location__c;
				}
			}
			// Once dealer account reference is in production...
			// if (dealertrade.dealer__Dealer__c==null && dealertrade.dealer__Store_Location__c!=null) {
			// 	List<dealer__Dealer_Location__c> locs = [select Id, Name, dealer__Location_Account__c from dealer__Dealer_Location__c where Id=:dealertrade.dealer__Store_Location__c];
			// 	if (locs!=null && locs.size()>0) dealertrade.dealer__Dealer__c = locs[0].dealer__Location_Account__c;
			// }
		}

	}
	
	
	public PageReference save() {
		try {
			upsert(dealertrade);
		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return null;
		}
		// for lightning, construct link as /o/dealer__Dealer_Trade__c/{id}/view (edit?)
		//BLL1d return new PageReference('/' + dealertrade.Id + '/e?retURL=/'+dealertrade.Id);
		// BLL1a
		ApexPages.StandardController ctl = new ApexPages.StandardController(dealertrade);
		PageReference p = ctl.view();
		//if (UserInfo.getUIThemeDisplayed()<='Theme3') p = ctl.edit();
		p.getParameters().put('retURL', ctl.view().getURL());	
		//p.setRedirect(true);
		return p;
	}
	
	public PageReference cancel() {
		PageReference p;
		dealer__Vehicle_Inventory__c vi; 
		if (dealertrade!=null && dealertrade.dealer__Stock_No__c!=null) vi = new dealer__Vehicle_Inventory__c(Id=dealertrade.dealer__Stock_No__c); 
		//if (!String.isBlank(retURL)) p = new PageReference(retURL);
		if (vi!=null) p = (new ApexPages.StandardController(vi)).view(); 
		else p = new PageReference('/');
		//p.setRedirect(true);
		return p;
	}
	
}