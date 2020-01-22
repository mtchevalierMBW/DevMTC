/**
 * PartsPricing_TEST
 * Tests: PartsMasterPriceControl, PartsInventoryPriceControl
 *
 *	2016-06-30	B. Leaman	BLL1 - additional coverage for marking part Obsolete 
 */
@isTest
private class PartsPricing_TEST {

    static testMethod void partsMarkupPrice() {
        TestHelper_MW th = TestHelper_MW.getInstance();
        dealer__Parts_Master__c pm = th.getPartsMaster('1');
        dealer__Parts_Inventory__c pi = th.getPartsInventory('1');
        
		MW_TriggerControls__c runCopyTrigger = new MW_TriggerControls__c(Name='CopyReportingLedger',Enabled__c=true);
		insert(runCopyTrigger);

        Test.startTest();
        pm.dealer__Cost__c = 4001.00;
        update(pm);
        pi.dealer__Cost__c = 4001.00;
        update(pi);
        Test.stopTest();
        
        dealer__Parts_Master__c pm2 = [select Id, dealer__Cost__c, dealer__Retail_Price__c
             from dealer__Parts_Master__c 
             where id=:pm.Id limit 1];
        dealer__Parts_Inventory__c pi2 = [select Id, dealer__Cost__c, dealer__List__c
             from dealer__Parts_Inventory__c 
             where id=:pi.Id limit 1];
        System.assert(pm2.dealer__Cost__c < pm2.dealer__Retail_Price__c, 'PartsMaster retail price was not marked up');
        System.assert(pi2.dealer__Cost__c < pi2.dealer__List__c, 'PartsInventory retail price was not marked up');

    }
    
    static testMethod void kitItemCostUpdate() {
        TestHelper_MW helper = TestHelper_MW.getInstance();
        dealer__Parts_Master__c partMaster = helper.getPartsMaster('1');
        dealer__Parts_Inventory__c part = helper.getPartsInventory('1');
        
        dealer__Parts_Kit__c kit = new dealer__Parts_Kit__c();
        kit.Name = 'Test Kit';
        kit.dealer__Description__c = 'Test Kit';
        insert kit;
        
        dealer__Parts_Kit_Item__c kitItem = new dealer__Parts_Kit_Item__c();
        kitItem.dealer__Part__c = part.Id;
        kitItem.dealer__Parts_Master__c = partMaster.Id;
        kitItem.dealer__Parts_Kit__c = kit.Id;
        kitItem.dealer__Quantity__c = 1;
        insert kitItem;
        
        partMaster.dealer__Cost__c = 100;
        update partMaster;
        
        dealer__Parts_Master__c updatedPartMaster = [SELECT Id, dealer__Cost__c, dealer__Retail_Price__c FROM dealer__Parts_Master__c WHERE Id = :partMaster.Id];
        dealer__Parts_Kit__c updatedKit = [SELECT Id, dealer__Kit_Cost__c FROM dealer__Parts_Kit__c WHERE Id = :kit.Id];
        dealer__Parts_Kit_Item__c updatedKitItem = [SELECT Id, dealer__Extended_Cost__c, dealer__Quantity__c FROM dealer__Parts_Kit_Item__c WHERE Id = :kitItem.Id];
        
        System.assertEquals(updatedPartMaster.dealer__Cost__c * updatedKitItem.dealer__Quantity__c, updatedKitItem.dealer__Extended_Cost__c);
        System.assertEquals(updatedPartMaster.dealer__Cost__c * updatedKitItem.dealer__Quantity__c, updatedKit.dealer__Kit_Cost__c);
    }
    
   	// BLL1a
    static testMethod void partObsolete() {
        TestHelper_MW th = TestHelper_MW.getInstance();
        dealer__Parts_Master__c pm = th.getPartsMaster('1');
        dealer__Parts_Inventory__c pi = th.getPartsInventory('1');
        
        Test.startTest();
        pm.dealer__Status__c = 'Obsolete';
        update(pm);
        pi.dealer__Status__c = 'Obsolete';
        pi.dealer__On_Hand__c = 0;
        update(pi);
        Test.stopTest();
        
        dealer__Parts_Master__c pm2 = [select Id, dealer__Cost__c, dealer__Retail_Price__c
             from dealer__Parts_Master__c 
             where id=:pm.Id limit 1];
        dealer__Parts_Inventory__c pi2 = [select Id, dealer__Cost__c, dealer__List__c
             from dealer__Parts_Inventory__c 
             where id=:pi.Id limit 1];
        System.assert(pm2.dealer__Cost__c < pm2.dealer__Retail_Price__c, 'PartsMaster retail price was not marked up');
        System.assert(pi2.dealer__Cost__c < pi2.dealer__List__c, 'PartsInventory retail price was not marked up');

    }
    
}