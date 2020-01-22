/**
 * Test class for PartsEOM
 *
 *  Note for Bryan.  /me says in the voice of that guy on the dos equis commercial, the most interesting man in the world character.
 *      "I don't always set the seeAllData flag to true, but when I do, it's cause the background data required to test is obsene."
 * See: https://trailhead.salesforce.com/content/learn/modules/unit-testing-on-the-lightning-platform/why-we-test
 *
 *	2016.09.14       |Gaurav               |
 * Increased code coverage
 *	2017-05-04		B. Leaman		BLL1 - test data must pass validation Cost<Price
 *	2019-07-22	B. Leaman	BLL2 - New validation rule - contacts must reference accounts on an RO
 *	2019-09-18	B. Leaman	W-000730 BLL3 - DT 5.x new requirements in parts invoices
 **/
@isTest

private class Test_PartsEOM {

    static testmethod void testPartsEOM() {
        
        //Account objAccount = new Account();
        //objAccount.Name = 'Test Account';
        //insert objAccount;
		TestHelper_MW th = new TestHelper_MW();
		Account objAccount = th.getBusinessAccount('1');
        
        Contact objContact = new Contact();
        objContact.LastName = 'Test Contact';
		objContact.AccountId = objAccount.Id;	// BLLx
        insert objContact;
        
        c2g__codaDimension1__c objDimension1 = new c2g__codaDimension1__c();
        objDimension1.Name = 'Crown Motors';
        objDimension1.c2g__ReportingCode__c = 'abcdefgh';
        insert objDimension1;        
        
        dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c();
        loc.Name = 'Crown Motors';        
        loc.dealer__Company_Number__c = dealer.TestClassUtil.generateRandomString(3);
        loc.dealer__City__c = 'Redding';
        loc.dealer__State__c= 'CA';
        loc.dealer__Postal_Code__c='96001';
        loc.Financial_Force_Dimension_1__c = objDimension1.Id;
        insert loc;                 
        
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        dealer.TestClassUtil.insertDealerLocation('12515','Test Company');
        
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
    
        c2g__codaGeneralLedgerAccount__c objGeneralLedgerAcct = new c2g__codaGeneralLedgerAccount__c();
        objGeneralLedgerAcct.Name = 'Test Ledger Account';
        objGeneralLedgerAcct.c2g__ReportingCode__c = 'abcdefgh';
        objGeneralLedgerAcct.c2g__Type__c = 'Balance Sheet';
        objGeneralLedgerAcct.c2g__ExternalId__c = '1220';
        insert objGeneralLedgerAcct;
                
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
		// BLL3
		objPartInvoice.dealer__Location__c = loc.Id;
		objPartInvoice.dealer__Company_Number__c = loc.dealer__Company_Number__c;
		// BLL3
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
        objSRO.dealer__Company_Number__c = 'Location 1';
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
        objSRO = [Select Id, Name,dealer__Parts_Cost__c, dealer__Posted_Date_Time__c, Total_Parts_Cost__c, dealer__Total_Repair_Order_Charges__c  from dealer__Service_Repair_Order__c WHERE Id =: objSRO.Id];
        System.debug('SRO One->>'+objSRO);          
        System.debug('SRO-->>'+[Select Id, Name,dealer__Parts_Cost__c, dealer__Posted_Date_Time__c, Total_Parts_Cost__c, dealer__Total_Repair_Order_Charges__c  from dealer__Service_Repair_Order__c WHERE Id =: objSRO.Id]);    
        
        Map<String, Decimal> testlocation_wip_value = new Map<String, Decimal>();
        Map<Id, String> testlocation_names = new Map<Id, String>();
        Map<Id, String> testlocation_dimmension_names = new Map<Id, String>();
        Map<String, Decimal> testgeneral_ledger_value = new Map<String, Decimal>();        
        testlocation_names.put(loc.Id,objDimension1.Name);
        testlocation_wip_value.put(testlocation_names.get(loc.Id),objSRO.dealer__Parts_Cost__c);
        testlocation_dimmension_names.put(objDimension1.Id, objDimension1.Name);
        testgeneral_ledger_value.put(testlocation_dimmension_names.get(objDimension1.Id),100.0);
        Apexpages.currentPage().getParameters().put('location',loc.Name);
        PartsEOM peom = new PartsEOM();
        peom.location_names = testlocation_names;
        peom.location_wip_value = testlocation_wip_value;
        peom.location_dimmension_names = testlocation_dimmension_names;
        peom.general_ledger_value = testgeneral_ledger_value;
        peom.geteom();
        peom.geteomdata_json();
        peom.backToEOM();
        peom.evalLocation();
        PartsEOM.balanceLines(objSRO.Id);
    }
}