/*
 * BudgetUpsert_Ctrl_TC
 * Author: MarinerTek
 * Tests: BudgetUpsert_Ctrl
 * 
*/
@isTest
public class BudgetUpsert_Ctrl_TC {
	// BLL1a
	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupFFA() {
		TestHelper_MW.createBaseFFAData(FFAdata);

	}
	// BLL1a end

	public static  testmethod void MyunitTest(){
		FFAdata.refresh(); 	// BLL1a
		System.runAs(FFAdata.TestUser) {	// BLL1a
			
			BudgetUpsert_Ctrl md = new BudgetUpsert_Ctrl();
			
			 Account a = new Account();
			        a.LastName ='Test';
			        a.AccountSource ='Dealer';
			        a.Phone ='Test';
			        a.dealer__Active__c='YES';
			        a.dtffa__Active__c='YES';
			        a.Active__c =True;
			        insert a;
            Account b = new Account();
			        b.LastName ='TestName';
			        b.AccountSource ='Dealer';
			        b.Phone ='Test';
			        b.dealer__Active__c='YES';
			        b.dtffa__Active__c='YES';
			        b.Active__c =True;
			        insert b;
			        
		        dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
			        ddl.Name ='Oakland';
			        ddl.dealer__City__c ='Oakland';
			        ddl.dealer__Postal_Code__c='94606';
			        ddl.dealer__State__c='CA';
			        ddl.dealer__Company_Number__c='OAK';
			        ddl.dealer__Service_Director__c =Userinfo.getuserid();
			        insert ddl;
            
                dealer__Dealer_Location__c ddloc = new dealer__Dealer_Location__c();
                        ddloc.Name ='Bay Village';
                        ddloc.dealer__City__c ='Bay Village';
                        ddloc.dealer__Postal_Code__c='44140';
                        ddloc.dealer__State__c='OH';
                        ddloc.dealer__Company_Number__c='BYV';
                        ddloc.dealer__Service_Director__c =Userinfo.getuserid();
                        insert ddloc;

            	Budget__c bdgt = new Budget__c();
            		bdgt.Budget_Type__c = 'Retail';
            		bdgt.Dollars__c = 100000;
            		bdgt.Month__c = 11;
            		bdgt.Year__c = 2016;
            		bdgt.Location__c = ddl.id;
            		bdgt.Budget_Id__c = 'NOV_2016_OAK';
            		bdgt.Name = 'Test Budget';
            		bdgt.Units__c = 100;
            		insert bdgt;
            
            	Budget__c bdg = new Budget__c();
            		bdg.Budget_Type__c = 'Commercial';
            		bdg.Dollars__c = 10000;
            		bdg.Month__c = 11;
            		bdg.Year__c = 2016;
            		bdg.Location__c = ddl.id;
            		bdg.Budget_Id__c = 'NOV_2016_OAK_c';
            		bdg.Name = 'Test Budget Commercial';
            		bdg.Units__c = 90;
            		insert bdg;

            		string csvTest = ', Plan , Plan , Plan , Plan , Plan , Plan , Plan , Plan , Plan , Plan , Plan , Plan ,2017 ,,\n';
					csvTest = csvTest + ',Jan-17,Feb-17,Mar-17,Apr-17,Jun-17,Jun-17,Jul-17,Aug-17,Sep-17,Oct-17,Nov-17,Dec-17, Total ,Check,Id\n';
					csvTest = csvTest + 'Oakland, 35.000 , 42.000 , 57.000 , 49.000 , 62.000 , 60.000 , 58.000 , 57.000 , 61.000 , 60.000 , 48.000 , 55.000 , 644.000 , -   ,OAK';
					csvTest = csvTest + 'Bay Village, 35.000 , 42.000 , 57.000 , 49.000 , 62.000 , 60.000 , 58.000 , 57.000 , 61.000 , 60.000 , 48.000 , 55.000 , 644.000 , -   ,BYV';
            		md.csvFileBody = Blob.valueOf(csvTest);	
            		md.updateRecords();
            		md.getRadioTypes();
            		md.importCSVFile();
            md.divisionUpdate();
		}	
	}
}