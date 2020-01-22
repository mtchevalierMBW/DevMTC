/**
 * ServiceRO_Print_TC
 * Tests: ServiceRO_Print
 * 
 * 2016-01-28	B. Leaman	BLL1 - Test getting default labor rate.
 * 2016-10-03	B. Leaman	BLL2 - Update to get misc charges the new way
 * 2019-01-25	B. Leaman	W-000567 BLL3 - provide order urgency when required. (new validation rule)
 * 2019-07-29	B. Leaman	W-000473 BLL4 - increase code coverage.
 *	2019-09-17	B. Leaman 	W-000730 BLL5- Fix failing tests with DT 5.x upgrade.
 */ 
@isTest
private class ServiceRO_Print_TC{
	
	// BLL4
	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
	
	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();

		contact con = new contact();
		con.Phone = '8888888';
		con.LastName = 'Test';
		insert con;

		//Account a = new Account();
		//a.LastName ='Test';
		//a.AccountSource ='Dealer';
		//insert a;
		TestHelper_MW th = new TestHelper_MW();
		Account a = th.getBusinessAccount('1');

		// Create Document
		//Document d = new Document();
		//d.Body = Blob.valueOf('InvoiceLogo');
		//d.FolderId = UserInfo.getUserId();
		//d.Name = 'InvoiceLogo';
		//d.DeveloperName = 'InvoiceLogo';
		//Database.insert(d,false);

		dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
		ddl.Name ='Test';
		ddl.dealer__City__c ='Test';
		ddl.dealer__Postal_Code__c='301352';
		ddl.dealer__State__c='Te';
		ddl.dealer__Company_Number__c='12365';
		ddl.dealer__Service_Director__c=userinfo.getuserid();
		ddl.dealer__Street__c ='Test';
		ddl.dealer__Main_Phone__c ='Test';
		ddl.dealer__Website__c ='www.Test.com';
		insert ddl;

		//dealer.TestClassUtil tc = new dealer.TestClassUtil();
		//tc.insertDMSSettings();

		dealer__Service_Repair_Order__c dsr = new dealer__Service_Repair_Order__c();
		dsr.Name='Test';
		dsr.dealer__Customer__c =a.id;
		dsr.dealer__Mileage_In__c =12;
		dsr.dealer__RO_Number__c='80';
		dsr.dealer__Company__c = ddl.Id;
		insert dsr;

		ServicePaymentType__c spt = new ServicePaymentType__c();
		spt.Name ='Test';
		spt.Description__c ='Test';
		insert spt;

		dealer__Service_Job__c dsj = new dealer__Service_Job__c();
		dsj.dealer__Cause__c ='Test';
		dsj.dealer__Labor_Charges__c =12;
		dsj.dealer__Service_Repair_Order__c =dsr.id;
		dsj.dealer__Labor_Type__c='c';
		dsj.dealer__Labor_Rate__c='Test';
		dsj.dealer__Misc_Charges__c=11;
		dsj.dealer__Concern__c='test';
		dsj.dealer__CustomerConcern__c='test';
		dsj.dealer__Correction__c='test';
		dsj.dealer__Op_Code__c='71232';
		//dsj.dealer__Line_Total__c=12;
		dsj.dealer__Parts_Total__c=7;
		dsj.dealer__Service_Type__c='MR';
		dsj.dealer__Line_Number__c=1;
		//dsj.dealer__Operation_Code_Description__c='Test';
		dsj.dealer__Stat__c='Te';
		dsj.dealer__Technician__c=userinfo.getuserid();
		dsj.dealer__Book_Time__c=11;
		dsj.Payment_Method__c=spt.id;
		dsj.dealer__Line_Number__c=1;                    
		insert dsj;

		dealer__Parts_Invoice__c dpi = new dealer__Parts_Invoice__c();
		dpi.dealer__Customer_Contact__c =con.id;
		dpi.dealer__Counterman__c=userinfo.getuserid();
		dpi.dealer__Invoice_Number__c ='1';
		// BLL5
		dpi.dealer__Location__c = FFAdata.DealerLocation.Id;
		dpi.dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c;
		// BLL5 end
		insert dpi;

		dealer__Parts_Invoice_Line__c dpl = new dealer__Parts_Invoice_Line__c();
		dpl.dealer__Parts_Invoice__c= dpi.id;
		dpl.Name ='test';
		dpl.dealer__Core__c  =12;
		dpl.dealer__Cost__c=12;
		dpl.dealer__Price__c=12;
		dpl.dealer__Part_Number__c='12';
		dpl.dealer__Quantity_Sold__c=12;
		dpl.dealer__Quantity_Ordered__c =12;
		dpl.dealer__Job_Line__c= dsj.id;
		//dpl.dealer__Service_Job_Line_Number__c=12;
		//dpl.dealer__Extended_Price__c=12;
		dpl.dealer__Part_Description__c='test';
		dpl.dealer__Total_Price__c=12;
		//dpl.dealer__Service_Line_Payment_Method__c='test';
		dpl.dealer__Pay_Type__c='c';
		//dpl.dealer__Service_Job_Line_Number__c=12; 
		dpl.dealer__Service_Repair_Order__c=dsr.id;    
		dpl.dealer__Order_Type__c = 'Ground';	// BLL3a              
		insert dpl;

		ServiceMiscCharges__c smc = new ServiceMiscCharges__c();
		smc.Type__c = 'Freight';
		smc.Service_Job_Line__c  =dsj.id;
		smc.Amount__c =11;
		insert smc;

	}
	// BLL4 end

	Static testmethod Void Myunittest(){
		// BLL4
		// dealer__Service_Repair_Order__c dsr = [select Id from dealer__Service_Repair_Order__c limit 1];	// BLL4a
		Map<String, Schema.SObjectField> sromap = Schema.SObjectType.dealer__Service_Repair_Order__c.fields.getMap();
		List<String> fieldlist = new List<String>();
		for(string f : sromap.keySet()) if (sroMap.get(f).getDescribe().isAccessible()) fieldlist.add(f);
		String fields = String.join(fieldlist, ',');
		String soql = 'select ' + fields + ' from dealer__Service_Repair_Order__c limit 1';
		dealer__Service_Repair_Order__c dsr = Database.query(soql);
		// BLL4 end

		Test.setCurrentPage(Page.ServiceRepairOrderCustomerCopy);	// BLL4a
		ApexPages.StandardController sc = new ApexPages.StandardController(dsr);
		ApexPages.currentPage().getParameters().put('id', dsr.id);

		ServiceRO_Print sp = new ServiceRO_Print(new ApexPages.StandardController(dsr));
		//BLL2d sp.total_hazmat =12;
		//BLL2d sp.total_shop =12;
		//BLL2d sp.total_freight =13;
		//BLL2d sp.total_hazmat_w=11;
		//BLL2d sp.total_freight_w =1;
		sp.getInvoiceLogo();
		sp.getServiceJobList();
		sp.getServicePartsList(); 
		sp.getMiscList(); 
		sp.getLinesList(); 
		//BLL3d sp.total_hazmat = 10;
		//BLL2d Decimal total_hazmat=sp.total_hazmat;
		//BLL2d Decimal total_shop=sp.total_shop;
		//BLL2d Decimal total_freight=sp.total_freight;
		//BLL2d Decimal total_hazmat_w=sp.total_hazmat_w;
		//BLL2d Decimal total_shop_w=sp.total_shop_w;
		//BLL2d Decimal total_freight_w=sp.total_freight_w;
		// BLL2a
		List<ServiceRO_Print.MiscChargeSummary> cmc = sp.CustMiscCharges;
		List<ServiceRO_Print.MiscChargeSummary> imc = sp.IntMiscCharges;
		List<ServiceRO_Print.MiscChargeSummary> wmc = sp.WarrMiscCharges;
		List<ServiceRO_Print.MiscChargeSummary> amc = sp.AllMiscCharges;
		// BLL2a end
		string printDateTime = sp.printDateTime;
		Decimal dftRate = sp.getDefaultLaborRate(); // BLL1a
		// BLL4
		Decimal td = sp.total_deposit;
		Decimal ts = sp.total_sublet;
		Decimal tsw = sp.total_sublet_w;
		Decimal tsc = sp.total_sublet_cust;
		// BLL4 end
	}
}