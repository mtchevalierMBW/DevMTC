/**
 * PartLabelPrint_TEST
 * Tests: PartLabelPrint_CTLR
 *
 * Modifications:
 *	2019-09-18	B. Leaman	W-000730 BLL1 - DT 5.x update requirements on parts invoice rcds
 */
@isTest
private class PartLabelPrint_TEST {

	// BLL1
	@TestSetup
	static void setupData(){
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	}
	// BLL1 end

    @isTest
    static void BasicPrintTest() {
        TestHelper_MW th = new TestHelper_MW();
        
        PartLabelPrint_CTLR plp = new PartLabelPrint_CTLR();
        dealer__Parts_Master__c pm = th.getPartsMaster('1');
        plp.labelsFromPartsMaster(pm.Id);
        System.assert(plp.LabelInfos.size()>0, 'No labels for part ' + pm.Id);
        plp.print();
        plp.back();
        
        //List<dealer__Purchase_Order_Line__c> polines = [
        //        select Id, Name, dealer__Purchase_Order__c 
        //        from dealer__Purchase_Order_Line__c
        //        where dealer__Parts_Line__c!=null
        //        order by CreatedDate desc
        //];
        //if (polines.size()>0) {
        //    plp.labelsFromPurchaseOrderLine(polines[0].Id);
        //    System.assert(plp.LabelInfos.size()>0, 'No labels for part ' + pm.Id);
        //    plp.labelsFromPurchaseOrder(polines[0].dealer__Purchase_Order__c);
        //    System.assert(plp.LabelInfos.size()>0, 'No labels for part ' + pm.Id);
        //}
        
    }

    @isTest
    static void ExtendedPrintTest() {
        //PartLabelPrint_CTLR plp = new PartLabelPrint_CTLR();

        // Create test data
        //dealer__Parts_Inventory__c p = [select Id, Name, dealer__Parts_Master__c from dealer__Parts_Inventory__c limit 1];
        //p.dealer__On_Hand__c=1;
        //update(p);
        //dealer__Parts_Master__c pm = [select Id, Name, dealer__Manufacturer__c from dealer__Parts_Master__c where id=:p.dealer__Parts_Master__c limit 1];
        //dealer__Dealer_Location__c loc = [select Id, Name from dealer__Dealer_Location__c limit 1];
        
        //RecordType vrt = [select Id, Name from RecordType where SObjectType='Account' and Name like 'Vendor%' limit 1];
        //Account v = new Account(
        //   RecordTypeId=vrt.Id, 
        //   Name='TestVendor', BillingState='OH', BillingPostalCode='44641'
        //);
        //insert(v);
        
        TestHelper_MW th = new TestHelper_MW();
        
        User u = th.getTestUser('1');
        System.runAs(u) {

            PartLabelPrint_CTLR plp = new PartLabelPrint_CTLR();
    
            // Create test data
            dealer__Dealer_Location__c loc = th.getDealerLocation('1');
            dealer__Parts_Master__c pm = th.getPartsMaster('1');
            dealer__Parts_Inventory__c p = th.getPartsInventory('1');
            
            //RecordType vrt = [select Id, Name from RecordType where SObjectType='Account' and Name like 'Vendor%' limit 1];
            Account v = th.getVendorAccount('1');
            Account person = th.getPersonAccount('1');

            dealer__Service_Vehicle__c car = new dealer__Service_Vehicle__c( 
                Name='TestCar',
                dealer__Year__c='2011',
                dealer__Make__c='Toyota',
                dealer__Carline__c='Prius'
            );
            insert car;     
        
          /*  dealer__Service_Repair_Order__c ro = new dealer__Service_Repair_Order__c(
                Name='MyTestRO',
                dealer__Vehicle__c = car.Id, 
                dealer__Mileage_in__c = 123, 
                dealer__RO_Number__c = 'RO#654321',
                dealer__Customer_Contact__c=person.PersonContactId
            );
            insert(ro);
            dealer__Service_Job__c rol = new dealer__Service_Job__c(
              // dealer__Service_Repair_Order__c=ro.Id
            );
            insert(rol);*/
            
            dealer__Parts_Invoice__c pi = new dealer__Parts_Invoice__c(
            	dealer__Invoice_Number__c = 'TEST123',
				// BLL1
				dealer__Location__c = loc.Id,
				dealer__Company_Number__c = loc.dealer__Company_Number__c
				// BLL1 end
            );
            insert(pi);
           /* dealer__Parts_Invoice_Line__c pil = new dealer__Parts_Invoice_Line__c(
               dealer__Parts_Invoice__c=pi.Id,   dealer__Part__c=p.Id,
               dealer__Part_Number__c=p.Name, dealer__Quantity_Sold__c=1
            );
            insert(pil);*/
            
            //rol.dealer__Parts_Line__c = pil.Id;
           // update(rol);
            
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
            
            // delete everything (for testing in Execute Anonymous Apex)
            //delete(pol);
            //delete(po);
            
            //delete(pil);
            //delete(pi);
            
            //delete(rol);
            //delete(ro);
            //delete(v);        
    
            // Done with test data
            
            Test.startTest();
    
            plp.labelsFromPurchaseOrder(po.Id);
            
            Test.stopTest();
        }
        
    }
}