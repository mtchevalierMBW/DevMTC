/**
CentralizedPartsStoreInventory
Tested by: CentralizedParts_TC

Test coverage:
2018-11-23	95%	(19/20)

Modifications:
2018-11-23	B. Leaman	W-000492	BLL1 - show min/max/re-order points for locations

**/
public with sharing class CentralizedPartsStoreInventory {
	public dealer__Stock_Order__c order {get; set;}
	public  List<PartOrderWrapper> partOrderWrappers {get; set;}


	public CentralizedPartsStoreInventory(ApexPages.StandardController controller) {
		String orderId = ApexPages.currentPage().getParameters().get('id');
		order = [SELECT Id, Name, (SELECT Id, Name, dealer__Parts_Inventory__c, dealer__Parts_Inventory__r.Name, dealer__Parts_Master__c FROM dealer__Parts_Orders__r ORDER BY Name) FROM dealer__Stock_Order__c WHERE Id = :orderId];

		List<String> partMasterIds = new List<String>();
		for(dealer__Parts_Order__c partOrder : order.dealer__Parts_Orders__r) {
			partMasterIds.add(partOrder.dealer__Parts_Master__c);
		}

		// BLL1
		//Map<Id, dealer__Parts_Master__c> partMastersMap = new Map<Id, dealer__Parts_Master__c>([SELECT Id, Name, 
		//	(SELECT Name, Id, dealer__On_Hand__c, dealer__Location__r.Name FROM dealer__Parts_Inventories__r WHERE dealer__On_Hand__c > 0 AND dealer__Location__c != null) 
		//	FROM dealer__Parts_Master__c WHERE Id IN :partMasterIds]);
		Map<Id, dealer__Parts_Master__c> partMastersMap = new Map<Id, dealer__Parts_Master__c>([
			SELECT Id, Name, 
				( SELECT Name, Id, dealer__On_Hand__c, dealer__Location__r.Name,
				  dealer__Min__c, dealer__Max__c, dealer__Re_Order_Point__c 
				  FROM dealer__Parts_Inventories__r WHERE dealer__On_Hand__c > 0 AND dealer__Location__c != null) 
			FROM dealer__Parts_Master__c 
			WHERE Id IN :partMasterIds
		]);
		// BLL1 end

		partOrderWrappers = new List<PartOrderWrapper>();
		for(dealer__Parts_Order__c partOrder : order.dealer__Parts_Orders__r) {
			dealer__Parts_Master__c partMaster = partMastersMap.get(partOrder.dealer__Parts_Master__c);
			if(partMaster != null && partMaster.dealer__Parts_Inventories__r.size() > 0) {
				partOrderWrappers.add(new PartOrderWrapper(partOrder, partMastersMap.get(partOrder.dealer__Parts_Master__c)));
			}
		}

	}

	public class PartOrderWrapper {
		public dealer__Parts_Order__c partOrder {get; set;}
		public dealer__Parts_Master__c partMaster {get; set;}

		public PartOrderWrapper(dealer__Parts_Order__c partOrder, dealer__Parts_Master__c partMaster) {
			this.partOrder = partOrder;
			this.partMaster = partMaster;
		}
	}
}