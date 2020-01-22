/**
 * VehiclePOLines_TC
 * Tests: 
 *
 *	2017-05-04	B. Leaman	BLL1 - Remove custom Dealer_Location_Users__c object.
 *	2018-07-16	B. Leaman	BLL2 - increase coverage.
 */
@isTest
public class VehiclePOLines_TC {


	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupTest() {
		TestHelper_MW th = new TestHelper_MW();
		TestHelper_MW.createBaseFFAData(FFAdata);
		FFAdata.refresh(); 
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();

		// GeneralLedgerAccount 
		c2g__codaGeneralLedgerAccount__c gla = new c2g__codaGeneralLedgerAccount__c(
			Name='1299 - VehicleGL',
			c2g__ReportingCode__c = '1299',
			c2g__Type__c='Balance Sheet'
		);
		insert(gla);
		
		// Vehicle template
		Map<String, Schema.RecordTypeInfo> viRcdTypes = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo TmpltRtInfo = viRcdTypes.get('Vehicle Template');
        insert(new dealer__Vehicle_Inventory__c(
        	RecordTypeId = TmpltRtInfo.getRecordTypeId(),
        	dealer__VIN__c = 'testingxyz',
        	dealer__Stock_Number__c = 'Test#xyz',
        	dealer__Year__c = '2020',
        	dealer__Make__c = 'Toyota',
        	dealer__Model__c = 'tbd',
        	dealer__Purchase_Date__c = Date.today(),
        	Conv_MFG__c = 'BraunAbility'
        ));
	
	}

    static testMethod void poUnitTest(){
        
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        
	        Account a = new Account();
	        a.LastName ='Test';
	        a.AccountSource ='Dealer';
	        a.dealer__Vendor__c=true;
	        insert a;
	        
	        dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c();
	        dvi.dealer__Last_VIN_Decode__c=system.Today();
	        dvi.dealer__Make__c='Test';
	        dvi.dealer__Model__c='Test';
	        dvi.dealer__Stock_Number__c='99XXXX';
	        dvi.dealer__VIN__c='Test';
	        dvi.dealer__Year__c='2013';
	        dvi.dealer__Status_Code__c='Order';
	        insert dvi;
	        
	        List<dealer__Purchase_Order__c> polist = new List<dealer__Purchase_Order__c>();	// BLL2a
	        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c(); 
	        po.dealer__Vendor__c = a.id;
	        //po.dealer__Company__c = [Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'SAN' limit 1].Id;
	        po.dealer__Company__c =FFAdata.DealerLocation.Id;
	        po.dealer__StockNumber__c = '0XXXXXX';
	        po.dealer__Model__c = 'Accord';
	        po.dealer__Make__c = 'HOnda';
	        po.dealer__VIN__c = '12345678';
	        po.dealer__Year__c = '2015';
	        po.dealer__Invoice_Amount__c =100000.00;
	        po.dealer__Invoice_Date__c =System.Today();
	        po.dealer__Invoice_Number__c ='xyz123';
	        po.dealer__Vehicle_Status__c = 'Order';
	        //insert po;
	        // BLL2a
	        polist.add(po);
	        polist.add(new dealer__Purchase_Order__c(
	        	dealer__Vendor__c = a.id,
	        	dealer__Company__c =FFAdata.DealerLocation.Id,
	        	dealer__StockNumber__c = '0YYYYYY',
	        	dealer__Model__c = 'Sienna',
	        	dealer__Make__c = 'Toyota',
	        	dealer__VIN__c = '23456781',
	        	dealer__Year__c = '2016',
	        	dealer__Invoice_Amount__c =100000.00,
	        	dealer__Invoice_Date__c =System.Today(),
	        	dealer__Invoice_Number__c ='xyz1234',
	        	dealer__Vehicle_Status__c = 'Order'
	        ));
	        insert(polist);
	        // BLL2a end
	        
	        dealer__Purchase_Order_Line__c line1 = new dealer__Purchase_Order_Line__c();
	        line1.dealer__Purchase_Order__c = po.Id;
	        line1.dealer__Amount__c = 0;
	        line1.Add_to_Chassis__c = true;
	        line1.Add_to_Conversion__c = false;
	        line1.General_Ledger_Account__c = FFAdata.GLAMap.get('2200t').Id;
	        insert line1;
	        
	        dealer__Purchase_Order_Line__c line2 = new dealer__Purchase_Order_Line__c();
	        line2.dealer__Purchase_Order__c = po.Id;
	        line2.dealer__Amount__c = 0;
	        line2.Add_to_Chassis__c = true;
	        line2.Add_to_Conversion__c = false;
	        line2.General_Ledger_Account__c = FFAdata.GLAMap.get('2200t').Id;
	        insert line2;
	        
	        //line1.PostingTemplate__c = pte.Id;
	        
	       // VehiclePOLines vplx = new VehiclePOLines();
	        
	        // Setup Page
	        PageReference linesPage = Page.VehiclePurchaseOrderLines;
	        linesPage.getParameters().put('id', po.Id);
	        Test.setCurrentPage(linesPage);
	        VehiclePOLines vpl= new VehiclePOLines();
	        
	        User u1 = CurrentUserSingleton.getInstance();
	        vpl.getDivisionInfo(u1);
	        GeneralLedgerAcctMW__c glAcct = [select Id, Name, GeneralLedgerAccountFF__c from GeneralLedgerAcctMW__c limit 1];
	        PostingTemplateEntryRule__c pte = new PostingTemplateEntryRule__c(
	        	Dimension_1__c=FFAdata.Dimension1.Id
	        );
	        // BLL2c
	        VehiclePOLines.lineWrap lw = new VehiclePOLines.lineWrap(
	            'test',2000, glAcct, pte,'test',true,false,0);
	        vpl.lines.add(lw);
	        Id dim1id = lw.dim1;
	        // BLL2c end
	        
	        //vpl.division = ddl.dealer__Company_Number__c;
	        vpl.division = u1.Division;
	        vpl.vehicleInv = dvi;

	        vpl.getAccountInfo( pte );
	        vpl.getAccountInfo(null);	// BLL2a
	        
	        System.debug('The PTE Word to your momma: '+pte);
	        System.debug(vpl.lines);
	        
	        vpl.addLine();
	        vpl.deleteLine();
	        vpl.validateForm();
	        vpl.getBalance();
	        vpl.lines = new List<VehiclePOLines.lineWrap>();
	         vpl.lines.add(new VehiclePOLines.lineWrap(
	            'test',2000, glAcct, pte,'test',true,false,0));
	        System.debug(vpl.lines);
	        vpl.acceptPO();
	        
	        try{
	            //vpl.getFFCompany(cdc.Id);
	            vpl.getFFCompany(FFAdata.CurrentCompany.Id);
	            vpl.acceptPO();
	            vpl.createJournalHeader();              
	        } catch(Exception e){ }
	        
	        vpl.addLine();	// BLL2a - make sure there's an empty line to clean up
	        vpl.indexCount = vpl.lines.size();	// BLL2a
	        vpl.saveLines();       
	        vpl.resetRowCount();   
	        
	        //System.runAs(u){
	        //    vpl.acceptPO();
	        //}
	        
	        vpl.saveLines(); // Done in AcceptPO
	        vpl.createVehicle(); // done in AcceptPO

			// BLLxa
			vpl.vehicleInv = dvi;
			vpl.po.dealer__StockNumber__c = dvi.dealer__Stock_Number__c;
			vpl.getvehicleInv();
			// BLLxa
	        
	        //vpl.getFFCompany(cdc.Id); // done in AcceptPO

			po.dealer__Invoice_Amount__c = vpl.getBalance();	// BLL2a	 
			vpl.savePO();	// BLL2a       
	        vpl.createPayableInvoice();
	        
	        vpl.getCreditDebit(1.01);
	        vpl.getCreditDebit(-1.01);
	        vpl.createJournalHeader();
	        vpl.createPayableInvoice();
	        
	        // BLL2a - Added to increase coverage...
	        List<c2g__codaJournal__c> jh = vpl.JournalHeaders;
        
		}
        
    }


    static testMethod void poUnitTest2(){
        
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
        	TestHelper_MW th = new TestHelper_MW();
        
	        Account a = new Account();
	        a.LastName ='Test';
	        a.AccountSource ='Dealer';
	        a.dealer__Vendor__c=true;
	        insert a;
	        
	        dealer__Vehicle_Inventory__c dvi = new dealer__Vehicle_Inventory__c();
	        dvi.dealer__Last_VIN_Decode__c=system.Today();
	        dvi.dealer__Make__c='Test';
	        dvi.dealer__Model__c='Test';
	        dvi.dealer__Stock_Number__c='99XXXX';
	        dvi.dealer__VIN__c='Test';
	        dvi.dealer__Year__c='2013';
	        dvi.dealer__Status_Code__c='Order';
	        insert dvi;

	        Map<String,Schema.RecordTypeInfo> recordTypeMap = dealer__Vehicle_Inventory__c.sObjectType.getDescribe().getRecordTypeInfosByName();
	        dealer__Vehicle_Inventory__c template = new dealer__Vehicle_Inventory__c(
	        	dealer__Last_VIN_Decode__c=system.Today(),
	        	dealer__make__c='Test',
	        	dealer__model__c='Test',
	        	dealer__stock_number__c='99TEMPLATE',
	        	dealer__vin__c='Testtemplate',
	        	dealer__year__c='2013',
	        	dealer__status_code__c='Order',
	        	RecordTypeId=recordTypeMap.get('Vehicle Template').getRecordTypeId()
	        );
	        insert template;
	        
	        dealer__Purchase_Order__c po = new dealer__Purchase_Order__c(); 
	        po.dealer__Vendor__c = a.id;
	        //po.dealer__Company__c = [Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'SAN' limit 1].Id;
	        po.dealer__Company__c =FFAdata.DealerLocation.Id;
	        po.dealer__StockNumber__c = '0XXXXXX';
	        po.dealer__Model__c = 'Accord';
	        po.dealer__Make__c = 'HOnda';
	        po.dealer__VIN__c = '1FTYE125337';	// BLL2a do not use a 17-digit VIN, vin decoder won't run in test context
	        po.dealer__Year__c = '2015';
	        po.dealer__Invoice_Amount__c =100000.00;
	        po.dealer__Invoice_Date__c =System.Today();
	        po.dealer__Invoice_Number__c ='xyz123';
	        po.dealer__Vehicle_Status__c = 'Order';
	        insert po;
	        
	        // Setup Page
	        PageReference linesPage = Page.VehiclePurchaseOrderLines;
	        linesPage.getParameters().put('id', po.Id);
	        Test.setCurrentPage(linesPage);
	        VehiclePOLines vpl= new VehiclePOLines();
	        vpl.po.Vehicle_Inventory_Template__c = template.Id;
	        vpl.createVehicleFromTemplate();
	        
	        c2g__codaJournalLineItem__c jl = vpl.journalEntry(null, FFAdata.DealerLocation.Id, null, 'GeneralLedgerAccount', 'Debit', 1.00, null);
        
		}
        
    }

}