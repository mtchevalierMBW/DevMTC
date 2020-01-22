/**
 * DealClone_MBW
 * Tested by: DealClone_MBW_TEST
 *
 *	2017-10-03	B. Leaman	BLL1 - wipe out referece to RO for clones
 *
 */

public with sharing class DealClone_MBW {
    private ApexPages.StandardController stdController;
    public dealer__Deal__c deal {get;private set;}
    public String cloneType {get;set;}
	public List<dealer__Vehicle_Inventory__c> cloneVINs {get;set;}
	public Integer cloneVINidx;
	public boolean cloneOrder {get;set;}
    
    public DealClone_MBW(ApexPages.StandardController ctlr) {
		List<String> fields = new List<String>();
		fields.add('RecordType.Name');
		if(!Test.isRunningTest()) {             
			ctlr.addFields(fields);
		}   

		deal = (dealer__Deal__c) ctlr.getRecord();
		stdController = ctlr;
	    
	    cloneType = deal.Chassis_QTY__c!=null && deal.Chassis_QTY__c>1 ? 'Unit' : 'Full';
	    cloneVINs = new List<dealer__Vehicle_Inventory__c>();
	    cloneOrder = cloneType=='Full';
	    newVIN();

	}
	
	public PageReference returnToProposal() {
		return new PageReference('/'+deal.Id);
	}
	
	// deleteCloneVIN accepts a post parameter 'cloneVINidx' with the list index of the entry to remove
	public void deleteCloneVIN() {
		String idxStr = ApexPages.currentPage().getParameters().get('cloneVINidx');
		try {
			cloneVINidx = String.isBlank(idxStr) ? -1 : Integer.valueOf(idxStr);
		} catch(Exception e) {}
		System.debug(cloneVINidx);
		try {
			cloneVINs.remove(cloneVINidx);
		} catch(Exception e) {}
		renumberVINs();
	}
	
	public void newVIN() {
	    cloneVINS.add(new dealer__Vehicle_Inventory__c(Name='', dealer__VIN__c='',dealer__Stock_Number__c=''));
	    renumberVINs();
	}
	

	public void renumberVINs() {
		for(Integer i = 0; i<cloneVINs.size(); ++i) {
			cloneVINs[i].dealer__vRank__c = i;
		}
	}

	
	// refreshByStockNbr
	public void refreshByStockNbr() {
		List<String> stocknbrs = new List<String>();
		for(dealer__Vehicle_Inventory__c v : cloneVINs) {
			if (!String.isBlank(v.dealer__Stock_Number__c)) stocknbrs.add(v.dealer__Stock_Number__c);
		}
		List<dealer__Vehicle_Inventory__c> vehinv = [
			select Id, Name, dealer__VIN__c, dealer__Stock_Number__c
			from dealer__Vehicle_Inventory__c
			where dealer__Stock_Number__c in :stocknbrs
		];
		Map<String,dealer__Vehicle_Inventory__c> vehmap = new Map<String,dealer__Vehicle_Inventory__c>();
		for(dealer__Vehicle_Inventory__c v : vehinv) vehmap.put(v.dealer__Stock_Number__c.toUpperCase(), v);

		// Now assign 
		for(dealer__Vehicle_Inventory__c v : cloneVINs) {
			if (!String.isBlank(v.dealer__Stock_Number__c)) {
				dealer__Vehicle_Inventory__c stockveh = vehmap.get(v.dealer__Stock_Number__c.toUpperCase());
				v.Id = stockveh.Id;
				v.dealer__VIN__c = stockveh.dealer__VIN__c;
				v.Name = stockveh.Name;
				v.dealer__Stock_Number__c = stockveh.dealer__Stock_Number__c;
			}
		}
	}


	// refreshByVIN
	public void refreshByVIN() {
		List<String> vins = new List<String>();
		for(dealer__Vehicle_Inventory__c v : cloneVINs) {
			if (!String.isBlank(v.dealer__VIN__c)) vins.add(v.dealer__VIN__c);
		}
		List<dealer__Vehicle_Inventory__c> vehinv = [
			select Id, Name, dealer__VIN__c, dealer__Stock_Number__c
			from dealer__Vehicle_Inventory__c
			where dealer__VIN__c in :vins and dealer__Status_Code__c!='Delivered'
			order by CreatedDate
		];
		Map<String,dealer__Vehicle_Inventory__c> vehmap = new Map<String,dealer__Vehicle_Inventory__c>();
		for(dealer__Vehicle_Inventory__c v : vehinv) vehmap.put(v.dealer__VIN__c.toUpperCase(), v);

		// Now assign - order by created date means the most RECENT match will replace any prior matches by VIN
		for(dealer__Vehicle_Inventory__c v : cloneVINs) {
			if (!String.isBlank(v.dealer__VIN__c)) {
				dealer__Vehicle_Inventory__c stockveh = vehmap.get(v.dealer__VIN__c.toUpperCase());
				if (stockveh!=null) {
					v.Id = stockveh.Id;
					v.dealer__VIN__c = stockveh.dealer__VIN__c;
					v.Name = stockveh.Name;
					v.dealer__Stock_Number__c = stockveh.dealer__Stock_Number__c;
				}
			}
		}
	}


	// changedCloneType
	public void changedCloneType() {
	    cloneOrder = cloneType=='Full';
		if (cloneType=='Full') {
			dealer__Vehicle_Inventory__c v = cloneVINs.size()>0 ? cloneVINs[0] : new dealer__Vehicle_Inventory__c();
			cloneVINs.clear();
			cloneVINs.add(v);
		}
	}
	

	// getAccessibleFieldsForSObjectAsString
	public String getAccessibleFieldsForSObjectAsString(Schema.DescribeSObjectResult dso) {
		// Accessible fields for an SObject (Schema.DescribeSObjectResult, Schema.DescribeFieldResult)
		Map<String, Schema.SObjectField> sobjFieldMap =  dso.fields.getMap();
		List<String> sobjFieldList = new List<String>();
		for(String f : sobjFieldMap.keySet()) {
			if (sobjFieldMap.get(f).getDescribe().isAccessible()) sobjFieldList.add(f);
		}
		String sobjFields = String.join(sobjFieldList, ',');
		System.debug(sobjFields);
		return sobjFields;		
	}


	// cloneProposal 
	public PageReference cloneProposal() {
		Id dealId = deal.Id;
		String dealFields = getAccessibleFieldsForSObjectAsString(Schema.dealer__Deal__c.SObjectType.getDescribe());
		dealer__Deal__c clonedeal = Database.query('select ' + dealFields + ' from dealer__Deal__c where Id=:dealId');
		List<dealer__Deal__c> newdeals = new List<dealer__Deal__c>();
		Integer nbrOfClones = cloneType=='Full' ? 1 : cloneVINs.size();
		for(Integer i=0; i<nbrOfClones; ++i) {
			dealer__Deal__c newdeal = clonedeal.clone(false, false, false, false);
			newdeal.dealer__Deal_ID__c = null;
			// Set specific items to change
			newdeal.Chassis_QTY__c = cloneType=='Unit' ? 1 : newdeal.Chassis_QTY__c;
			if (cloneType=='Full') newdeal.dealer__Status__c = 'Pending';	// Reset unless doing delivery units
			newdeal.dealer__DeliveryRepairOrder__c=null;	// BLL1a - remove reference to RO?
			if (newdeal.Cloned_Proposal__c==null && cloneType=='Unit') newdeal.Cloned_Proposal__c = dealId;
			if (cloneVINs.size()<=i) {
				newdeal.dealer__VIN__c = cloneVINs[i].dealer__VIN__c;
				newdeal.dealer__Stock_Number__c = cloneVINs[i].dealer__Stock_Number__c;
				newdeal.dealer__Vehicle__c = cloneVINs[i].Id;
			}
			newdeals.add(newdeal);
		}
		// Assign proposal numbers
		//RetailDefaults__c = retailDefaults = RetailDefaults__c.getOrgDefaults();
		// read with lock:
		RetailDefaults__c retailDefaults = [select Id, ProposalNumber__c from RetailDefaults__c where SetupOwnerId=:UserInfo.getOrganizationId() FOR UPDATE];
        Integer nextDealNbr = Integer.valueOf(retailDefaults.ProposalNumber__c);
		retailDefaults.ProposalNumber__c += newdeals.size();
		update(retailDefaults);
		for(dealer__Deal__c d : newdeals) {
			d.dealer__Deal_ID__c = String.valueOf(nextDealNbr++);
			d.Name = d.dealer__Deal_ID__c;
			if (deal.RecordType.Name=='Commercial') d.Name = 'Q' + d.dealer__Deal_ID__c; 
		}
		insert(newdeals);
		
		// Now clone equipment 
		String amFields = getAccessibleFieldsForSObjectAsString(Schema.dealer__After_Market__c.SObjectType.getDescribe());
		List<dealer__After_Market__c> ams = Database.query('select ' + amFields + ' from dealer__After_Market__c where dealer__Car_Deal__c=\'' + dealId + '\' ');
		List<dealer__After_Market__c> newAfterMarket = new List<dealer__After_Market__c>();
		for(dealer__Deal__c d : newdeals) {
			for(dealer__After_Market__c am : ams) {
				dealer__After_Market__c cloneAM = am.clone(false, false, false, false);
				cloneAM.dealer__Car_Deal__c = d.Id;
				newAfterMarket.add(cloneAM);
			}
		}
		insert(newAfterMarket);

		// Now clone ESC
		String scFields = getAccessibleFieldsForSObjectAsString(Schema.dealer__Service_Contract__c.SObjectType.getDescribe());
		List<dealer__Service_Contract__c> scs = Database.query('select ' + scFields + ' from dealer__Service_Contract__c where dealer__Car_Deal__c=\'' + dealId + '\' ');
		List<dealer__Service_Contract__c> newESC = new List<dealer__Service_Contract__c>();
		for(dealer__Deal__c d : newdeals) {
			for(dealer__Service_Contract__c esc : scs) {
				dealer__Service_Contract__c cloneESC = esc.clone(false, false, false, false);
				cloneESC.dealer__Car_Deal__c = d.Id;
				newESC.add(cloneESC);
			}
		}
		insert(newESC);
	
		// Clone build order? (commercial quote) -- only one deal at a time for this kind of clone
		if (cloneType=='Full' && cloneOrder==true && deal.Commercial_Quote__c!=null) {
			Id cqId = deal.Commercial_Quote__c;
			String cqFields = getAccessibleFieldsForSObjectAsString(Schema.CommercialQuote__c.SObjectType.getDescribe());
			CommercialQuote__c cq = Database.query('select ' + cqFields + ' from CommercialQuote__c where Id=\'' + cqId + '\' '); 
			CommercialQuote__c newcq = cq.clone(false, false, false, false);
			newcq.Proposal__c = newdeals.size()>0 ? newdeals[0].Id : null;
			insert(newcq); 

			// lines
			String cqlFields = getAccessibleFieldsForSObjectAsString(Schema.CommercialQuoteLine__c.SObjectType.getDescribe());
			List<CommercialQuoteLine__c> cqls = Database.query('select ' + cqlFields + ' from CommercialQuoteLine__c where Id=\'' + cqId + '\' '); 
			List<CommercialQuoteLine__c> newcqls = new List<CommercialQuoteLine__c>();
			for(CommercialQuoteLine__c cql : cqls) {
				CommercialQuoteLine__c newcql = cql.clone(false, false, false, false);
				newcql.Commercial_Quote__c = newcq.Id;
				newcqls.add(newcql);
			}
			insert(newcqls);

			// update proposal to link to new quote
			if (newdeals.size()>0) update(new dealer__Deal__c(Id=newdeals[0].Id, Commercial_Quote__c=newcq.Id));
		}
		
		// reduce qty by number of units delivered (but don't go below 1)
		if (cloneType=='Unit') {
			deal.Chassis_QTY__c = (deal.Chassis_QTY__c<=newdeals.size()) ? 1 : deal.Chassis_QTY__c-newdeals.size();
			update(new dealer__Deal__c(id=deal.Id, Chassis_QTY__c=deal.Chassis_QTY__c));
		}
		
		PageReference rtnTo = null;
		if (newdeals.size()>0) rtnTo = new PageReference('/' + newdeals[0].Id);
		
		return rtnTo;
	}
	
	
}