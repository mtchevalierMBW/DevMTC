/**
 * PurchaseOrderPrint_EXT_TEST
 * Tests: PurchaseOrderPrint_EXT
 * Written by: Bryan Leaman
 * Date: June 15, 2017
 * 
 * Modifications:
 *	2019-09-17	B. Leaman	W-000730 BLL1 - DT 5.x upgrade requirements.
**/
@isTest
public class PurchaseOrderPrint_EXT_TEST {

    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    @testSetup
    static void setupFFA() {
        TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        c2g__codaGeneralLedgerAccount__c g = FFAdata.GLAMap.get('cogs');
        g.VehicleRequired__c = true;
        g.ScheduledAccount__c = true;
        update(g);
    
        System.runAs(FFAdata.TestUser) {
        }
    }
    
    
    static testMethod void testTransaction() {
        FFAdata.refresh(); 
        System.runAs(FFAdata.TestUser) {
            TestHelper_MW th = new TestHelper_MW();

            // Create test data
            dealer__Dealer_Location__c loc = th.getDealerLocation('1');
            dealer__Parts_Master__c pm = th.getPartsMaster('1');
            dealer__Parts_Inventory__c p = th.getPartsInventory('1');
            
            Account v = th.getVendorAccount('1');
            Account person = th.getPersonAccount('1');

            dealer__Service_Vehicle__c car = new dealer__Service_Vehicle__c( 
                Name='TestCar',
                dealer__Year__c='2011',
                dealer__Make__c='Toyota',
                dealer__Carline__c='Prius'
            );
            insert car;     
            
            dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c(
            	dealer__Invoice_Number__c = 'TEST123',
				// BLL1
				dealer__Location__c = FFAdata.DealerLocation.Id,
				dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c
				// BLL1 end
            );
            insert(pi);
            
            dealer__Purchase_Order__c po = new dealer__Purchase_Order__c(
                dealer__Company__c=loc.Id, dealer__Vendor__c=v.Id,
                dealer__Parts_Invoice__c = pi.Id
            );
            insert(po);
            dealer__Purchase_Order_Line__c pol = new dealer__Purchase_Order_Line__c(
                dealer__Purchase_Order__c = po.Id, dealer__Part__c=p.Id,
                dealer__Part_Quantity__c=1, dealer__Part_Quantity_Received__c=1,
                dealer__Parts_Invoice__c=pi.Id, //dealer__Parts_Line__c=pil.Id, 
                dealer__Parts_Master__c=pm.Id, //dealer__Service_Job_Line__c=rol.Id,
                dealer__Amount__c = 1.00
            );
            insert(pol);
            Test.startTest();
            
            PageReference pgRef = Page.PurchaseOrderPDF; 
            Test.setCurrentPage(pgRef); //Set the page for Test Method
            ApexPages.currentPage().getParameters().put('id', po.Id);
            //ApexPages.currentPage().getParameters().put('retURL', '/');
            ApexPages.StandardController sc = new ApexPages.StandardController(po);
            PurchaseOrderPrint_EXT pop = new PurchaseOrderPrint_EXT(sc);
                  
            Test.stopTest();
        }
    
    }
    
}