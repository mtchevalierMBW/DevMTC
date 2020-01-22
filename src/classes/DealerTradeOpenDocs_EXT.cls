/**
 * DealerTradeOpenDocs_EXT
 * Tested by: DealerTradeOpenDocs_EXT_TEST
 *
 */

public with sharing class DealerTradeOpenDocs_EXT {
    private ApexPages.StandardController stdController;
    public dealer__Dealer_Trade__c obj;
    
    public DealerTradeOpenDocs_EXT(ApexPages.StandardController ctlr) {
		List<String> fields = new List<String>();

		//fields.add('dealer__Stock_No__c');
		//if(!Test.isRunningTest()) {             
		//	ctlr.addFields(fields);
		//}   

		obj = (dealer__Dealer_Trade__c) ctlr.getRecord();
		stdController = ctlr;

	}

	public List<OpenDocument> getOpenDocuments() {
		List<OpenDocument> docs = new List<OpenDocument>();
		// Proposals
		for(dealer__Deal__c d : [
				select Id, Name, dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Status__c, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, 
					dealer__Buyer__c, dealer__Buyer__r.Name, Proposed_Delivery_Date__c
				from dealer__Deal__c
				where dealer__Vehicle__c!=null 
				  and dealer__Vehicle__c = :obj.dealer__Stock_No__c
				  and dealer__Status__c not in ('Lost', 'Won - Posted')
			]) {
			OpenDocument opendoc = new OpenDocument();
			opendoc.docRef.CommercialQuote__c = null;
			opendoc.docRef.Deal__c = d.Id;
			opendoc.DocName = d.Name;
			opendoc.docRef.dealer__Company__c = d.dealer__Store_Location__c;
			opendoc.docRef.dealer__Service_Advisor__c = d.dealer__Salesperson_1__c;
			opendoc.docRef.dealer__Customer__c = d.dealer__Buyer__c;
			opendoc.DeliveryDate = d.Proposed_Delivery_Date__c;
			opendoc.Status = d.dealer__Status__c;
			opendoc.StoreLocationName = d.dealer__Store_Location__r.Name;
			opendoc.SalespersonName = d.dealer__Salesperson_1__r.Name;
			opendoc.CustomerName = d.dealer__Buyer__r.Name;
			docs.add(opendoc);
		}
		// Quotes
		for(CommercialQuote__c q : [
				select Id, Name, Location__c, Location__r.Name, Status__c, Salesperson__c, Salesperson__r.Name, 
					Customer__c, Customer__r.Name, Delivery_Date__c
				from CommercialQuote__c
				where VehicleInventory__c!=null 
				  and VehicleInventory__c = :obj.dealer__Stock_No__c
				  and Status__c not in ('Lost', 'Won - Posted', 'Booked', 'Cloned', 'Ordered', 'Received')	// BLLc adj statuses 2017-04-24
			]) {
			OpenDocument opendoc = new OpenDocument();
			opendoc.docRef.CommercialQuote__c = q.Id;
			opendoc.DocName = q.Name;
			opendoc.docRef.Deal__c = null;
			opendoc.docRef.dealer__Company__c = q.Location__c;
			opendoc.docRef.dealer__Service_Advisor__c = q.Salesperson__c;
			opendoc.docRef.dealer__Customer__c = q.Customer__c;
			opendoc.DeliveryDate = q.Delivery_Date__c;
			opendoc.Status = q.Status__c;
			opendoc.StoreLocationName = q.Location__r.Name;
			opendoc.SalespersonName = q.Salesperson__r.Name;
			opendoc.CustomerName = q.Customer__r.Name;
			docs.add(opendoc);
		}
		return docs;
	}
	
	public class OpenDocument {
		public dealer__Service_Repair_Order__c docRef {get;set;}	// Used for reference fields to proposal, quote, salesperson, location
		public String DocName {get;set;}
		public String Status {get;set;}
		public Date DeliveryDate {get;set;}
		public String StoreLocationName {get;set;}
		public String SalespersonName {get;set;}
		public String CustomerName {get;set;}
		public OpenDocument() {
			docRef = new dealer__Service_Repair_Order__c();
			DeliveryDate = null;
			Status = '';
			DocName = '';
			StoreLocationName = '';
			SalespersonName = '';
			CustomerName = '';
		}
	}
	
}