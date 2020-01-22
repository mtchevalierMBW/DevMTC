/**
 * PartsSalesLineTriggerTest
 * Tests: PartsSalesLineTrigger
 * 
 * Date             |Developer            |Work#
 * Notes
 * ---------------------------------------------
 * 2016.09.09       |Gaurav               |Case-00002028
 * Test class for PartsLineTrigger that is used for adding Extended price value to its Parent Service Job's part total field
 * 2017-05-04	B. Leaman		        BLL1 - parts line must meet new validation Cost<Price.
 * 2017-05-11	B. Leaman		        BLL2 - getting Too many soql queries errors.
**/

@isTest
public class PartsSalesLineTriggerTest {
    
    //Global definition of service repair order and service job
    public static dealer__Service_Repair_Order__c objServiceRepairOrder;
    public static dealer__Service_Job__c objServiceJob;

    //test method to validate PartsSalesLine
    public static testmethod void validateTrigger1(){     
        //Insert DMS Setting
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();


        //Create Account for SRO
        //Account objAccount = new Account(Name = 'Test Account');
        //insert objAccount;
		TestHelper_MW th = new TestHelper_MW();
		Account objAccount = th.getBusinessAccount('1');
        
        //Create contact for SRO Account
        Contact objContact = new Contact();
        objContact.LastName = 'Test Contact';
        objContact.AccountId = objAccount.Id;
        insert objContact;
        
        //Create Test SRO
        objServiceRepairOrder = new dealer__Service_Repair_Order__c();
        objServiceRepairOrder.dealer__Customer__c = objAccount.Id;
        objServiceRepairOrder.dealer__Mileage_In__c = 10; 
        objServiceRepairOrder.dealer__Customer_Contact__c = objContact.Id;
        objServiceRepairOrder.dealer__RO_Number__c = 'RONUMBER2727';
        insert objServiceRepairOrder;
        
        //Create Test Service Job
        objServiceJob = new dealer__Service_Job__c();
        objServiceJob.Name = 'Test Service Job';
        objServiceJob.dealer__Service_Repair_Order__c = objServiceRepairOrder.Id;        
        objServiceJob.dealer__Op_Code__c = 'Test Op Code';
        objServiceJob.dealer__Line_Number__c = 100;
        objServiceJob.dealer__Estimate__c = 2000.0;
        insert objServiceJob;
        
        // Create a Second Service job to test cost on Parts
		dealer__Service_Job__c sj2 = new dealer__Service_Job__c(
       		name='Job Line#2',
            dealer__Service_Repair_Order__c=objServiceRepairOrder.Id,
            dealer__Op_Code__c='Test Op Code',
            dealer__Line_Number__c=200,
            dealer__Estimate__c=99.99,
            dealer__Labor_Type__c='I'
        );
        insert sj2;

        
        
        Test.startTest();	// BLL2a

        //Insert Parts
        dealer__Dealer_Location__c loc = dealer.TestClassUtil.insertDealerLocation('rd1', 'Redding Motors');
        dealer__Parts_Master__c pm = dealer.TestClassUtil.insertPartsMaster();
        dealer__Parts_Inventory__c part = dealer.TestClassUtil.insertPartInventory(pm.Id, loc.Id);
        //Insert Parts Invoice 
        String partInvoiceId =  tc.insertPartsInvoice();
        
        //For loop to insert Parts Lines for SRO and Service Job
        List<dealer__Parts_Invoice_Line__c> partslines = new List<dealer__Parts_Invoice_Line__c>();	// BLL1a
        for(Integer i=0; i<=5;i++){
        	// System.debug('Line loop count='+String.valueOf(i));	// BLL1a
            dealer__Parts_Invoice_Line__c objPartLine = new dealer__Parts_Invoice_Line__c();
            objPartLine.Name = objServiceJob.Name;            
            objPartLine.dealer__Service_Repair_Order__c = objServiceRepairOrder.Id;
            objPartLine.dealer__Job_Line__c = objServiceJob.Id;    
            objPartLine.dealer__Price__c = 10+i;
            objPartLine.dealer__Quantity_Sold__c = 1+i;
            objPartLine.dealer__Core__c = 5+i;
            objPartLine.dealer__Part_Number__c='12'+i;
            objPartLine.dealer__Parts_Invoice__c =partInvoiceId;
            objPartLine.dealer__Part__c = part.id;
            //BLL1d objPartLine.dealer__Cost__c = 50.0;            
            objPartLine.dealer__Cost__c = 10.0;	// BLL1a
            //BLL1d insert objPartLine;
            partslines.add(objPartLine);	// BLL1a                
        } 
		insert(partslines);	// BLL1a

        
        //Query Service job's Parts total field for assertion of total calculated by trigger
        objServiceJob = [SELECT ID, dealer__Parts_Total__c FROM dealer__Service_Job__c WHERE ID =: objServiceJob.Id];
        
        dealer__Parts_Invoice_Line__c pil = new dealer__Parts_Invoice_Line__c(
        	name='Line#2',
            dealer__Service_Repair_Order__c=objServiceRepairOrder.Id,
            dealer__Job_Line__c=sj2.Id,
            dealer__Parts_Invoice__c=partInvoiceId,
            dealer__Price__c=25.99,
            dealer__Quantity_Sold__c=2, // Important to capture the item value as the price
            dealer__Part_Number__c='A-100',
            dealer__Cost__c=10,
            dealer__Part__c = part.Id,
            dealer__Pay_Type__c='I'
        );
        system.debug('PartTest '+[SELECT Id From dealer__Parts_Inventory__c]);
        insert pil;
        // System.debug(pil);
        dealer__Parts_Invoice_Line__c pilAfter = [SELECT Id, dealer__Price__c, dealer__Total_Price__c FROM dealer__Parts_Invoice_Line__c WHERE Id=:pil.Id LIMIT 1];
        // System.debug(pilAfter);
		System.assert(pilAfter.dealer__Price__c == 5, 'Price should be set to cost on Internal/Warranty Lines. Current price = '+pilAfter.dealer__Price__c);
        	
        Test.stopTest();	// BLL2a
            
        //Assert Parts total
        // BLL1d wrong total: System.assertEquals(785.00, objServiceJob.dealer__Parts_Total__c);        
        System.assertEquals(325.00, objServiceJob.dealer__Parts_Total__c);	// BLL1a 6-line total (0-5)
        /**	extnd = Qty * Price + Core
        i	Qty	Price	Core	Extnd	Running
		0	1	10		5		15		15
		1	2	11		6		28		43
		2	3	12		7		43		86
		3	4	13		8		60		146
		4	5	14		9		79		225
		5	6	15		10		100		325
        **/
        
    }
}