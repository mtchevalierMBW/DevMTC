/** 
 * ManagementDashboard_TC
 * Tests: ManagementDashboard
 *
 *	2016-03-31	B. Leaman	BLL1 adjustments to work better with no data; increase coverage;
 *	2017-08-24	B. Leaman	BLL2 - no need for getreadresponse method - just use getter.
 *	2017-09-29	B. Leaman	BLL7 - adjustments to controller for heap size.   
 */
@isTest
public  class ManagementDashboard_TC{

	// BLL1a
	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);

			 Account a = new Account();
			        a.LastName ='Test';
			        a.AccountSource ='Dealer';
			        a.Phone ='Test';
			        a.dealer__Active__c='YES';
			        a.dtffa__Active__c='YES';
			        a.Active__c =True;
//			        insert a;
            Account b = new Account();
			        b.LastName ='TestName';
			        b.AccountSource ='Dealer';
			        b.Phone ='Test';
			        b.dealer__Active__c='YES';
			        b.dtffa__Active__c='YES';
			        b.Active__c =True;
//			        insert b;
			insert(new List<Account>{a, b});
			
			        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c();
			        dsp.dealer__Lead_Date__c=System.Today();
			        dsp.dealer__Lead_Status__c='Pending';
			        dsp.dealer__Lead_Type__c='List';
			        dsp.dealer__Source__c ='Pride';
			        dsp.Solution_Type__c ='Rental';
			        dsp.dealer__Customer_Account__c =a.id;
            		dsp.dealer__First_Store_Visit_Date__c = Datetime.now();
			        insert dsp;	
			        
		        dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
			        ddl.Name ='Oakland';
			        ddl.dealer__City__c ='Oakland';
			        ddl.dealer__Postal_Code__c='94606';
			        ddl.dealer__State__c='CA';
			        ddl.dealer__Company_Number__c='OAK';
			        ddl.dealer__Service_Director__c =Userinfo.getuserid();
			        insert ddl;
            
            Map<String, Schema.RecordTypeInfo> DealRcdTypes = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName();
            Schema.RecordTypeInfo commRt = DealRcdTypes.get('Commercial');
            Schema.RecordTypeInfo retailRt = DealRcdTypes.get('Retail');
            
                dealer__Deal__c dd = new dealer__Deal__c();
                        dd.Name = 'Test';
                        dd.dealer__Auto_Insurance_Agent__c='Test';
                        dd.dealer__Deal_ID__c ='Test';
                        dd.dealer__Sales_Lead__c = dsp.id;
                        dd.dealer__Status__c ='Won - GM Approval';
                        dd.dealer__Deal_Date__c =System.Today();
                        dd.Proposed_Delivery_Date__c =System.Today();
                        dd.dealer__Store_Location__r = ddl;
            			dd.RecordTypeId = retailRt.getRecordTypeId();
//                        insert dd;
             dealer__Deal__c dd1 = new dealer__Deal__c();
                        dd1.Name = 'Test1';
                        dd1.dealer__Auto_Insurance_Agent__c='Test1';
                        dd1.dealer__Deal_ID__c ='Test1';
                        dd1.dealer__Sales_Lead__c = dsp.id;
                        dd1.dealer__Status__c ='Won - GM Approval';
                        dd1.dealer__Deal_Date__c =Date.valueOf('2016-01-01 12:00:00');
                        dd1.Proposed_Delivery_Date__c =Date.valueOf('2016-01-01 12:00:00');
                        dd1.dealer__Store_Location__r = ddl;
            			dd1.RecordTypeId = retailRt.getRecordTypeId();
//                        insert dd1;
             dealer__Deal__c dd2 = new dealer__Deal__c();
                        dd2.Name = 'Test2';
                        dd2.dealer__Auto_Insurance_Agent__c='Test2';
                        dd2.dealer__Deal_ID__c ='Test2';
                        dd2.dealer__Sales_Lead__c = dsp.id;
                        dd2.dealer__Status__c ='Won - GM Approval';
                        dd2.dealer__Deal_Date__c =Date.valueOf('2016-01-01 12:00:00');
                        dd2.Proposed_Delivery_Date__c =Date.valueOf('2016-01-01 12:00:00');
                        dd2.dealer__Store_Location__r = ddl;
            			dd2.RecordTypeId = retailRt.getRecordTypeId();
//                        insert dd2;
             dealer__Deal__c dd3 = new dealer__Deal__c();
                        dd3.Name = 'Test3';
                        dd3.dealer__Auto_Insurance_Agent__c='Test3';
                        dd3.dealer__Deal_ID__c ='Test3';
                        dd3.dealer__Sales_Lead__c = dsp.id;
                        dd3.dealer__Status__c ='Pending';
                        dd3.dealer__Deal_Date__c =Date.valueOf('2016-11-01 12:00:00');
                        dd3.Proposed_Delivery_Date__c =Date.valueOf('2016-11-01 12:00:00');
                        dd3.dealer__Store_Location__r = ddl;
            			dd3.RecordTypeId = retailRt.getRecordTypeId();
//                        insert dd3;
            dealer__Deal__c dd4 = new dealer__Deal__c();
                        dd4.Name = 'Test4';
                        dd4.dealer__Auto_Insurance_Agent__c='Test4';
                        dd4.dealer__Deal_ID__c ='Test4';
                        dd4.dealer__Sales_Lead__c = dsp.id;
                        dd4.dealer__Status__c ='Won - GM Approval';
                        dd4.dealer__Deal_Date__c =Date.valueOf('2016-12-01 12:00:00');
                        dd4.Proposed_Delivery_Date__c =Date.valueOf('2016-12-01 12:00:00');
                        dd4.dealer__Store_Location__r = ddl;
            			dd4.RecordTypeId = retailRt.getRecordTypeId();
//                        insert dd4;
			insert(new List<dealer__Deal__c>{dd, dd1, dd2, dd3, dd4});

				ID locId = ddl.Id;

            	Budget__c bdgt = new Budget__c();
                    bdgt.Name = 'Test Budget';
            		bdgt.Budget_Type__c = 'Retail';
            		bdgt.Dollars__c = 100000;
            		bdgt.Month__c = 11;
            		bdgt.Year__c = 2016;
            		bdgt.Location__c = locId;
            		bdgt.Budget_Id__c = 'NOV_2016_OAK_r';
//            		insert bdgt;
				            
            	Budget__c bdgt_c = new Budget__c();
                    bdgt_c.Name = 'Test Budget - Comm';
            		bdgt_c.Budget_Type__c = 'Commercial';
            		bdgt_c.Dollars__c = 100000;
            		bdgt_c.Month__c = 11;
            		bdgt_c.Year__c = 2016;
            		bdgt_c.Location__c = locId;
            		bdgt_c.Budget_Id__c = 'NOV_2016_OAK_c';
//            		insert bdgt_c;
			insert(new List<Budget__c>{bdgt, bdgt_c});
            
            List<Budget__c> bdgList = [Select Id From Budget__c];
			System.assertEquals(2, bdgList.size());
            System.debug(LoggingLevel.ERROR, 'BUDGET: ' + bdgList);
/** BLL7d            
		    CommercialQuote__c quote = new CommercialQuote__c();
			        quote.Location__c = ddl.Id;
					quote.Mileage__c = 12000;
					quote.Customer__c = a.id;
					quote.Delivery_Date__c = System.Today();
					quote.Total_Gross_Profit__c = 5000;					
					quote.Status__c = 'Delivered';
					quote.Total__c = 50000;
            		quote.Location__r = ddl;
//					insert quote;
             CommercialQuote__c quote1 = new CommercialQuote__c();
			        quote1.Location__c = ddl.Id;
					quote1.Mileage__c = 10000;
					quote1.Customer__c = a.id;
					quote1.Delivery_Date__c = Date.valueOf('2016-01-01 12:00:00');
					quote1.Total_Gross_Profit__c = 3000;					
					quote1.Status__c = 'Won';
					quote1.Total__c = 30000;
            		quote1.Location__r = ddl;
//					insert quote1;
             CommercialQuote__c quote2 = new CommercialQuote__c();
			        quote2.Location__c = ddl.Id;
					quote2.Mileage__c = 17000;
					quote2.Customer__c = a.id;
					quote2.Delivery_Date__c = Date.valueOf('2016-10-10 12:00:00');
					quote2.Total_Gross_Profit__c = 7000;					
					quote2.Status__c = 'Won - GM Approval';
					quote2.Total__c = 70000;
            		quote2.Location__r = ddl;
//					insert quote2;
             CommercialQuote__c quote3 = new CommercialQuote__c();
			        quote3.Location__c = ddl.Id;
					quote3.Mileage__c = 20000;
					quote3.Customer__c = a.id;
					quote3.Delivery_Date__c = Date.valueOf('2016-11-11 12:00:00');
					quote3.Total_Gross_Profit__c = 5000;					
					quote3.Status__c = 'Won';
					quote3.Total__c = 40000;
            		quote3.Location__r = ddl;
//					insert quote3;
             CommercialQuote__c quote4 = new CommercialQuote__c();
			        quote4.Location__c = ddl.Id;
					quote4.Mileage__c = 45000;
					quote4.Customer__c = a.id;
					quote4.Delivery_Date__c = Date.valueOf('2016-12-12 12:00:00');
					quote4.Total_Gross_Profit__c = 45000;					
					quote4.Status__c = 'Won';
					quote4.Total__c = 100000;
            		quote4.Location__r = ddl;
//					insert quote4;

			insert(new List<CommercialQuote__c>{quote, quote1, quote2, quote3, quote4});          
**/                    
                    dealer__Deal__c testdeal = new dealer__Deal__c(RecordTypeId=commRt.getRecordTypeId(), Name = 'Commercial',dealer__Auto_Insurance_Agent__c='Test-com',dealer__Deal_ID__c ='Test-com',dealer__Sales_Lead__c = dsp.id,dealer__Status__c ='Won - GM Approval',dealer__Deal_Date__c =Date.valueOf('2016-11-11 12:00:00'),Proposed_Delivery_Date__c =Date.valueOf('2016-11-11 12:00:00'),dealer__Store_Location__r = ddl);
                    //insert testdeal;
            		dealer__Deal__c testdeal2 = new dealer__Deal__c(RecordTypeId=commRt.getRecordTypeId(), Name = 'Commercial2',dealer__Auto_Insurance_Agent__c='Test-com2',dealer__Deal_ID__c ='Test-com2',dealer__Sales_Lead__c = dsp.id,dealer__Status__c ='Won - GM Approval',dealer__Deal_Date__c =Date.valueOf('2016-12-12 12:00:00'),Proposed_Delivery_Date__c =Date.valueOf('2016-12-12 12:00:00'),dealer__Store_Location__r = ddl);
                    //insert testdeal2;
            		dealer__Deal__c testdeal3 = new dealer__Deal__c(RecordTypeId=commRt.getRecordTypeId(), Name = 'Commercial3',dealer__Auto_Insurance_Agent__c='Test-com3',dealer__Deal_ID__c ='Test-com3',dealer__Sales_Lead__c = dsp.id,dealer__Status__c ='Won - GM Approval',dealer__Deal_Date__c =Date.valueOf('2016-10-10 12:00:00'),Proposed_Delivery_Date__c =Date.valueOf('2016-10-10 12:00:00'),dealer__Store_Location__r = ddl);			
        			
                    dealer__Deal__c testdeal4 = new dealer__Deal__c(RecordTypeId=commRt.getRecordTypeId(), Name = 'Commercial4',dealer__Auto_Insurance_Agent__c='Test-com4',dealer__Deal_ID__c ='Test-com4',dealer__Sales_Lead__c = dsp.id,dealer__Status__c ='Won - GM Approval',dealer__Deal_Date__c =Date.valueOf('2016-01-10 12:00:00'),Proposed_Delivery_Date__c =Date.valueOf('2016-01-10 12:00:00'),dealer__Store_Location__r = ddl);			

        			insert(new List<dealer__Deal__c> {testdeal, testdeal2, testdeal3, testdeal4});

	}
	// BLL1a end

	public static  testmethod void MyunitTest(){
		FFAdata.refresh(); 	// BLL1a
		System.runAs(FFAdata.TestUser) {	// BLL1a
			
            		System.debug('Test Data: ' + FFAdata);
			
            Test.startTest();
				ManagementDashboard md = new ManagementDashboard();
		         md.getDealList();	//BLL1d next call invokes this anyway
		         md.getDealsListJSON();
           		 //BLL7d md.getcDealListJSON();
		         md.getTaskList();
		         md.getSalesUpList();
		         md.getisCMC();	
		         //md.action='read_cdeals';
		         // Mteka
		         md.action='read_cdeals_new';
           		 //BLL7d md.readCDeals(); 
           		 //md.getcDealListNew();
           		 //md.getcommCDealListNew();
		         //BLL2d md.getreadResponse();
		         String s = md.readResponse;	// BLL2a
           		 md.isTest();
		         // Mtek end
		         // BLL2a additional methods to test
		         //BLL7d md.getRetailDeals();
		         //BLL7d md.getRetailDeals1();
		         //BLL7d md.getRetailDeals2();
		         //BLL7d md.getCommercialDeals();
		         //BLL7d md.getRetail_cDeals1();
		         //BLL7d md.getRetail_cDeals2();
		         //BLL7d md.getCommercial_cDeals();
		         // BLL2 end
		         md.getselectedDeals();
		         md.getselectedcDeals();
		         md.getTestcDealListNew('');
			 Test.stopTest();
			          
		}	// BLL1a
			 
	}
}