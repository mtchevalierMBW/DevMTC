/*
* batchTransitWorksJournalPostTest
* Date: 5/27/2018
* Programmer: Alexander Miller
*
* Testing: batchTransitWorksJournalPost
*/
@isTest
public class batchTransitWorksJournalPostTest 
{
	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData();

	@testSetup
    static void setupFFA() 
    {
        TestHelper_MW.createBaseFFAData(FFAdata);
        c2g__codaCompany__c comp = new c2g__codaCompany__c(Id=FFAdata.CurrentCompany.Id, c2g__ExternalId__c = 'TWK');
        update(comp);
    }

    /**
    * testScheduler
    *
    * Cover the scheduling aspect of the class
    */
	public static testMethod void testScheduler()
    {        
		System.schedule('batchTransitWorksJournalPost Hourly', '0 0 * * * ?', new batchTransitWorksJournalPost() );
	}

    /**
    * testPostRunData
    *
    * Make sure journals post matching the custom setting
    */
	public static testMethod void testPostRunData()
    {
		FFAdata.refresh(); 
                       
        System.runAs(FFAdata.TestUser) {

			TestHelper_MW th = new TestHelper_MW();
            
            // customer
            Account a = th.getPersonAccount('1');
        
            // GL
			c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
			gla1.c2g__ReportingCode__c ='12';
			gla1.c2g__Type__c='Balance Sheet';
			gla1.Name='Test';
			insert gla1;

            // Company
            c2g__codaCompany__c comp = [SELECT Id, Name, c2g__ExternalId__c FROM c2g__codaCompany__c LIMIT 1];

            System.debug(comp);

            // Dimension
			c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
			dim1.c2g__ReportingCode__c = '111';
			dim1.Name = '111 Dim';
			insert(dim1);
            
            // Journal Header
            c2g__codaJournal__c newj = new c2g__codaJournal__c();
            newj.c2g__JournalDate__c =system.today();
            newj.Source__c ='GE';
            newj.c2g__Type__c='Manual Journal';
            newj.c2g__JournalStatus__c='In Progress';
            newj.c2g__JournalDescription__c = 'PORCPT';
            newj.Customer__c = a.Id;
            newj.c2g__OwnerCompany__c = comp.Id;
            insert(newj);
            
            // Journal Lines
            List<c2g__codaJournalLineItem__c> newl = new List<c2g__codaJournalLineItem__c>();
           
            newl.add(new c2g__codaJournalLineItem__c());
            newl[0].c2g__Journal__c = newj.Id;
            newl[0].c2g__Value__c = 1.00;
            newl[0].c2g__GeneralLedgerAccount__c = gla1.Id;
            newl[0].c2g__LineType__c = 'General Ledger Account'; 
            newl[0].c2g__LineNumber__c = 1;
            newl[0].Control__c = 'TestJournalLine 1';
            newl[0].Sales_Person__c = UserInfo.getUserId();
            newl[0].c2g__Dimension1__c = dim1.Id;
            newl[0].c2g__LineDescription__c = 'Test PIN12345';
            
            newl.add(new c2g__codaJournalLineItem__c());
            newl[1].c2g__Journal__c = newj.Id;
            newl[1].c2g__Value__c = -1.00;
            newl[1].c2g__GeneralLedgerAccount__c = gla1.Id;
            newl[1].c2g__LineType__c = 'General Ledger Account'; 
            newl[1].c2g__LineNumber__c = 2;
            newl[1].Control__c = 'TestJournalLine 2';
            newl[1].c2g__Dimension1__c = dim1.Id; // BLL1a
            newl[1].c2g__LineDescription__c = 'Test PIN12345';  // BLL7a
            insert(newl);

            Test.startTest(); 

            System.debug('testing started');

            // initialize the custom setting powering the batch class
            TransitForceSettings__c settings = TransitForceSettings__c.getInstance();
            if(settings.id == null) {
                settings.Journal_Accept_Document_Sources__c = 'NIC ISSUE,PORCPT,SOISS,Invoice Detail for Sales Invoice,OPLAB,WORCPT,WOISS,INVLOCADD,OPLABR,INVLOCADJ, PORCPTR,WOISSR,WORCPTR,ODC,SOISSR,INVLOCLOC,INVDOLADJ,PU,SC,VV,WO,WOCLOSE,POCLOSE,INVDIVDIV,INVLOCSCRP';
                insert settings;
    
                System.debug(settings);
            }

			batchTransitWorksJournalPost temp = new batchTransitWorksJournalPost();
			database.executeBatch(temp, 1);
			
			Test.stopTest();
			
			// All data post batch 
			c2g__codaJournal__c tempValue = [SELECT Id, c2g__JournalStatus__c FROM c2g__codaJournal__c LIMIT 1];

            // make sure it posted
			System.assertEquals('Complete', tempValue.c2g__JournalStatus__c); 
        }
	}

    /**
    * testPostRunData
    *
    * Make sure journals DON'T post when they don't match the custom setting
    */
    public static testMethod void testManualDoesntPost()
    {
		FFAdata.refresh(); 
                       
        System.runAs(FFAdata.TestUser) {

			TestHelper_MW th = new TestHelper_MW();
            
            // customer
            Account a = th.getPersonAccount('1');
        
            // GL
			c2g__codaGeneralLedgerAccount__c gla1 = new c2g__codaGeneralLedgerAccount__c();
			gla1.c2g__ReportingCode__c ='12';
			gla1.c2g__Type__c='Balance Sheet';
			gla1.Name='Test';
			insert gla1;

            // Company
            c2g__codaCompany__c comp = [SELECT Id, Name, c2g__ExternalId__c FROM c2g__codaCompany__c LIMIT 1];

            System.debug(comp);

            // Dimension
			c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
			dim1.c2g__ReportingCode__c = '111';
			dim1.Name = '111 Dim';
			insert(dim1);
            
            // Journal Header
            c2g__codaJournal__c newj = new c2g__codaJournal__c();
            newj.c2g__JournalDate__c =system.today();
            newj.Source__c ='GE';
            newj.c2g__Type__c='Manual Journal';
            newj.c2g__JournalStatus__c='In Progress';
            newj.c2g__JournalDescription__c = 'RECLASS';
            newj.Customer__c = a.Id;
            newj.c2g__OwnerCompany__c = comp.Id;
            insert(newj);
            
            // Journal Lines
            List<c2g__codaJournalLineItem__c> newl = new List<c2g__codaJournalLineItem__c>();
           
            newl.add(new c2g__codaJournalLineItem__c());
            newl[0].c2g__Journal__c = newj.Id;
            newl[0].c2g__Value__c = 1.00;
            newl[0].c2g__GeneralLedgerAccount__c = gla1.Id;
            newl[0].c2g__LineType__c = 'General Ledger Account'; 
            newl[0].c2g__LineNumber__c = 1;
            newl[0].Control__c = 'TestJournalLine 1';
            newl[0].Sales_Person__c = UserInfo.getUserId();
            newl[0].c2g__Dimension1__c = dim1.Id;
            newl[0].c2g__LineDescription__c = 'Test PIN12345';
            
            newl.add(new c2g__codaJournalLineItem__c());
            newl[1].c2g__Journal__c = newj.Id;
            newl[1].c2g__Value__c = -1.00;
            newl[1].c2g__GeneralLedgerAccount__c = gla1.Id;
            newl[1].c2g__LineType__c = 'General Ledger Account'; 
            newl[1].c2g__LineNumber__c = 2;
            newl[1].Control__c = 'TestJournalLine 2';
            newl[1].c2g__Dimension1__c = dim1.Id; // BLL1a
            newl[1].c2g__LineDescription__c = 'Test PIN12345';  // BLL7a
            insert(newl);

            Test.startTest(); 

            System.debug('testing started');

            // initialize the custom setting powering the batch class
            TransitForceSettings__c settings = TransitForceSettings__c.getInstance();
            if(settings.id == null) {
                settings.Journal_Accept_Document_Sources__c = 'NIC ISSUE,PORCPT,SOISS,Invoice Detail for Sales Invoice,OPLAB,WORCPT,WOISS,INVLOCADD,OPLABR,INVLOCADJ, PORCPTR,WOISSR,WORCPTR,ODC,SOISSR,INVLOCLOC,INVDOLADJ,PU,SC,VV,WO,WOCLOSE,POCLOSE,INVDIVDIV,INVLOCSCRP';
                insert settings;
    
                System.debug(settings);
            }
            
			batchTransitWorksJournalPost temp = new batchTransitWorksJournalPost();
			database.executeBatch(temp, 1);
			
			Test.stopTest();
			
			// All data post batch 
			c2g__codaJournal__c tempValue = [SELECT Id, c2g__JournalStatus__c FROM c2g__codaJournal__c LIMIT 1];

            // make sure it posted
			System.assertNotEquals('Complete', tempValue.c2g__JournalStatus__c); 
        }
	}
}