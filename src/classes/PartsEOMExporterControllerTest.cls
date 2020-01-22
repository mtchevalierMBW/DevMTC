/**
 * PartsEOMExporterControllerTest
 * Tests:
 *
 *	2017-05-04	B. Leaman	BLL1 - test data needs to meet validation rule (Cost<Price)
 *	2019-02-28	B. Leaman	W-000604 BLL2 - increase coverage of PartsEOM.cls;
 *	2019-07-22	B. Leaman	BLL3 - New validation rule - contacts must reference accounts on an RO
 *	2019-09-18	B. Leaman	W-000730 BLL4 - DT 5.x new data requirements on parts invoices
 */
@isTest
public class PartsEOMExporterControllerTest {
    
	// BLL2a - moved data creation to setup method
	private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

	@testSetup
	static void setupData() {
		TestHelper_MW.createBaseFFAData(FFAdata);
		dealer.TestClassUtil tc = new dealer.TestClassUtil();
		tc.insertDMSSettings();
	// BLL2 end 
		TestHelper_MW th = new TestHelper_MW();
        //Account objAccount = new Account();
        //objAccount.Name = 'Test Account';
        //insert objAccount;
		Account objAccount = th.getBusinessAccount('1');
        
        Contact objContact = new Contact();
        objContact.LastName = 'Test Contact';
		objContact.AccountId = objAccount.Id;	// BLL3
        insert objContact;
        
		// BLL2
        //c2g__codaDimension1__c objDimension1 = new c2g__codaDimension1__c();
        //objDimension1.Name = 'Crown Motors';
        //objDimension1.c2g__ReportingCode__c = 'abcdefgh';
        //insert objDimension1;  
        //
        //dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c();
        //loc.Name = 'Crown Motors';        
        //loc.dealer__Company_Number__c = dealer.TestClassUtil.generateRandomString(3);
        //loc.dealer__City__c = 'Redding';
        //loc.dealer__State__c= 'CA';
        //loc.dealer__Postal_Code__c='96001';
        //loc.Financial_Force_Dimension_1__c = objDimension1.Id;
        //insert loc;                 
        //
        //dealer.TestClassUtil tc = new dealer.TestClassUtil();
        //tc.insertDMSSettings();
        //dealer.TestClassUtil.insertDealerLocation('12515','Test Company');
		c2g__codaDimension1__c objDimension1 = FFAData.Dimension1;
		dealer__Dealer_Location__c loc = FFAData.DealerLocation;
		// BLL2
        
        dealer__Parts_Master__c objPartMasterOne = new dealer__Parts_Master__c();
        objPartMasterOne.Name = 'Test Part: Master 1';
        objPartMasterOne.dealer__Retail_Price__c = 199.99;
        objPartMasterOne.dealer__Cost__c = 19.99;
        objPartMasterOne.dealer__Manufacturer__c = 'ABG';
        insert objPartMasterOne;     
        
        dealer__Parts_Master__c objPartMasterTwo = new dealer__Parts_Master__c();
        objPartMasterTwo.Name = 'Test Part: Master 2';
        objPartMasterTwo.dealer__Retail_Price__c = 99.99;
        objPartMasterTwo.dealer__Cost__c = 9.99;
        objPartMasterTwo.dealer__Manufacturer__c = 'FD';
        insert objPartMasterTwo;         
               
        dealer__Parts_Inventory__c part = new dealer__Parts_Inventory__c();
        part.dealer__Description__c = 'Oil Filter 1';
        part.dealer__Cost__c = 10;
        part.dealer__Source__c = 'Stocking';
        part.dealer__On_Hand__c = -1;
        part.dealer__Part_No__c = 'FL1B';
        part.dealer__List__c = 22;
        part.dealer__Parts_Master__c = objPartMasterOne.Id;
        part.dealer__Location__c = loc.Id;
        part.dealer__MFG__c = 'Test MGF1';
        part.dealer__Pack_QTY__c = 20;
        part.dealer__List__c = 100;
        insert part;
        
        dealer__Parts_Inventory__c objPartOne = new dealer__Parts_Inventory__c();
        objPartOne.dealer__Description__c = 'Oil Filter 2';
        objPartOne.dealer__Cost__c = 10;
        objPartOne.dealer__Source__c = 'Stocking';
        objPartOne.dealer__On_Hand__c = 1;
        objPartOne.dealer__Part_No__c = 'FL1A';
        objPartOne.dealer__List__c = 22;
        objPartOne.dealer__Parts_Master__c = objPartMasterTwo.Id;
        objPartOne.dealer__Location__c = loc.Id;
        objPartOne.dealer__MFG__c = 'Test MGF2';
        objPartOne.dealer__Pack_QTY__c = 20;
        objPartOne.dealer__List__c = 100;        
        insert objPartOne;        
        
        dealer__Parts_Ledger__c objPartsLedger = new dealer__Parts_Ledger__c();
        objPartsLedger.dealer__Item_Value__c = 10.0;
        objPartsLedger.dealer__Quantity__c = 5;
        objPartsLedger.dealer__Part__c = part.Id;
        insert objPartsLedger;
        
        c2g__codaCompany__c objCompany = new c2g__codaCompany__c();
        objCompany.Name = 'Test Company';
        objCompany.c2g__Street__c = 'Cardale Park';
        objCompany.c2g__StateProvince__c = 'Beckwith Head Road';
        objCompany.c2g__City__c = 'Harrogate';
        objCompany.c2g__ZipPostCode__c = 'HG3 1RY';
        objCompany.c2g__Country__c = 'United Kingdom';
        objCompany.c2g__Phone__c = '+44 (0)1423 537728)';
        objCompany.OwnerId = UserInfo.getUserId();
        insert objCompany;
        
        dealer__Finance_Company__c objFinanceCompany = new dealer__Finance_Company__c();
        objFinanceCompany.Name = 'Test Finance Company';
        objFinanceCompany.dealer__Days_in_Year__c = 360;
        objFinanceCompany.dealer__Screen_Order__c = 101;
        insert objFinanceCompany;                 

        /*c2g__codaTransaction__c objTransaction = new c2g__codaTransaction__c();
        objTransaction.c2g__TransactionDate__c = System.today();
        objTransaction.c2g__OwnerCompany__c = objCompany.Id;
        objTransaction.c2g__TransactionType__c = 'Invoice';
        objTransaction.Finance_Company__c = objFinanceCompany.Id;
        insert objTransaction;*/

        /*c2g__codaJournal__c objJournal = [SELECT ID, Name, c2g__JournalDate__c, c2g__Reference__c, c2g__JournalDescription__c,
                                          c2g__Transaction__c FROM c2g__codaJournal__c WHERE c2g__Transaction__c != null LIMIT 1];        
        
        c2g__codaTransaction__c objTransaction = [SELECT ID, Name, c2g__TransactionDate__c, c2g__OwnerCompany__c, c2g__TransactionType__c,
                                                  Finance_Company__c FROM c2g__codaTransaction__c WHERE ID =: objJournal.c2g__Transaction__c];*/
    
        // BLL2
		//c2g__codaGeneralLedgerAccount__c objGeneralLedgerAcct = new c2g__codaGeneralLedgerAccount__c();
        //objGeneralLedgerAcct.Name = 'Test Ledger Account';
        //objGeneralLedgerAcct.c2g__ReportingCode__c = 'abcdefgh';
        //objGeneralLedgerAcct.c2g__Type__c = 'Balance Sheet';
        //objGeneralLedgerAcct.c2g__ExternalId__c = '1220';
        //insert objGeneralLedgerAcct;
		List<c2g__codaGeneralLedgerAccount__c> glaccts = new List<c2g__codaGeneralLedgerAccount__c>();
		glaccts.add(new c2g__codaGeneralLedgerAccount__c(Name='1220 - Parts Inventory', c2g__ReportingCode__c='1220', c2g__ExternalId__c='1220', c2g__Type__c='Balance Sheet'));
		glaccts.add(new c2g__codaGeneralLedgerAccount__c(Name='1209 - Test', c2g__ReportingCode__c='1209', c2g__ExternalId__c='1209', c2g__Type__c='Balance Sheet'));
		insert(glaccts);
		// BLL2 end
                
        /*c2g__codaTransactionLineItem__c objTransactionLineItem = new c2g__codaTransactionLineItem__c();
        objTransactionLineItem.c2g__LineNumber__c = 100;
        objTransactionLineItem.c2g__GeneralLedgerAccount__c = objGeneralLedgerAcct.Id;
        objTransactionLineItem.c2g__Dimension1__c = objDimension1.Id;
        objTransactionLineItem.c2g__Transaction__c = objTransaction.Id;
        insert objTransactionLineItem;*/

        dealer__Parts_Invoice__c objPartInvoice = new dealer__Parts_Invoice__c();
        objPartInvoice.Name = 'Test Part Invoice';
        objPartInvoice.dealer__Invoice_Number__c = 'qwertywfdf';
        objPartInvoice.dealer__Open_Date_Time__c = System.Now();
		// BLL4
		objPartInvoice.dealer__Location__c = FFAdata.DealerLocation.Id;
		objPartInvoice.dealer__Company_Number__c = FFAdata.DealerLocation.dealer__Company_Number__c;
		// BLL4
        insert objPartInvoice;
        
        dealer__Parts_Invoice_Line__c objPILine = new dealer__Parts_Invoice_Line__c();
        objPILine.Name = 'Test Part Invoice Line';
        objPILine.dealer__Part_Number__c = '10245';
        objPILine.dealer__Quantity_Sold__c = 25;
        objPILine.dealer__Cost__c = 1000;
        objPILine.dealer__Price__c = 1001;	// BLL1a
        objPILine.dealer__Parts_Invoice__c = objPartInvoice.Id;
        insert objPILine;
        
        /*c2g__codaJournal__c objJournal = new c2g__codaJournal__c();
        objJournal.c2g__JournalDate__c = System.today();
        objJournal.c2g__Reference__c = 'RO#CLT-31431';
        objJournal.c2g__JournalDescription__c = 'RO Cashier RO#CLT-31431';
        objJournal.c2g__Transaction__c = objTransaction.Id;
        insert objJournal;*/        
        
        dealer__Service_Repair_Order__c objSRO = new dealer__Service_Repair_Order__c();        
        objSRO.dealer__Customer__c = objAccount.Id;
        objSRO.dealer__Deposit__c = 100;
        objSRO.dealer__Customer_Contact__c = objContact.Id;
        objSRO.Name = 'Test Service Repair Order';
        objSRO.dealer__Customer_Charges__c = 50.35;
		// BLL2
        //objSRO.dealer__Company_Number__c = 'Location 1';
		objSRO.dealer__Company_Number__c = FFAData.DealerLocation.dealer__Company_Number__c;
		objSRO.dealer__Company__c = FFAData.DealerLocation.Id;	
		// BLL2 end
        objSRO.dealer__Tax__c = 30;
        objSRO.dealer__Shop_Supplies__c = 20;
        objSRO.dealer__RO_Number__c = 'RO100';
        objSRO.dealer__Mileage_In__c = 10;
        objSRO.dealer__Mileage_Out__c = 5;
        objSRO.dealer__Internal_Charges__c = 50.35;
        objSRO.dealer__Warranty_Charges__c = 49.30;
        objSRO.dealer__Parts_Invoice__c = objPartInvoice.Id;
        //objSRO.Journal__c = objJournal.Id;
        //objSRO.dealer__Posted_Date_Time__c = System.now();
        insert objSRO;
	}

    public static testMethod void validatePartsEOM(){
    
		// BLL2
		FFAdata.refresh(); 
		System.runAs(FFAdata.TestUser) {
			TestHelper_MW th = new TestHelper_MW();
			dealer__Service_Repair_Order__c sro = [select Id, dealer__Company__c from dealer__Service_Repair_Order__c limit 1];
		// BLL2 end

	        PartsEOMExporterController objPartsEOM = new PartsEOMExporterController();
	        objPartsEOM.geteom();

		// BLL2
			PartsEOM peom = new PartsEOM();
			peom.geteom();
			peom.backToEOM();
			peom.locationName = FFAData.Dimension1.Name;
			peom.evalLocation();
			peom.purchaseOrdersNoGL();
			peom.getmissingPurchaseOrderJournals();
			PartsEOM.oobItems oob = new PartsEOM.oobItems(null, null, null, null, null);
			PartsEOM.balanceLines(sro.Id);
			PartsEOM.anyReferenceJournalLines(sro.Id);
			PartsEOM.postCorrectiveJournal(sro.Id + ':1');
		}
		// BLL2 end

    }
    
}