/**
* MobilityWorks (c) - 2018
*
* SalesUpMBWContactOppHandlerTest
*
* Created By: Alexander Miller
*
* Modifications:
*	2019-10-18	B. Leaman	W-000730 BLL1 - Avoid failure from new DT 5.x update - vehicle not in stock.
*/
@isTest
public class SalesUpMBWContactOppHandlerTest {

    private static TestHelper_MW th = new TestHelper_MW();
    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 
    
    @testSetup
    public static void setupFFA() {
        
        // Base setup
        TestHelper_MW.createBaseFFAData(FFAdata);
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        insert(new dealer__FixedOperationsSettings__c(dealer__Repair_Order_Index__c=1));
        insert(new RetailDefaults__c(ProposalNumber__c=7));  
        
        // Account
        Account a = th.getPersonAccount('1');
        
        // create vehicle 
        dealer__Vehicle_Inventory__c veh = new dealer__Vehicle_Inventory__c(
            Name='(TESTX) 2020 Toyota Future',
            New_Used_Other__c='Used', Division__c='Commercial',
            dealer__Status_Code__c = 'Ready For Sale', 
			dealer__In_Stock__c = true,	// BLL1
            dealer__Stock_Number__c='TESTX',
            dealer__VIN__c='11234567890TUVWXY',
            dealer__Year__c='2020', dealer__Make__c='Toyota', dealer__Model__c='Future',
            dealer__Mileage__c=123000
        );
        insert(veh);
            
        // Solution Opportunity
        dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c(
            dealer__Lead_Date__c=System.Today(),
            dealer__First_Store_Visit_Date__c = DateTime.now(),   // BLL1a
            dealer__Lead_Status__c='Pending',
            dealer__Lead_Type__c='List',
            dealer__Source__c ='Pride',
            Solution_Type__c ='Chassis/Conversion',
            dealer__Customer_Account__c =a.id,
            dealer__Trade_Year__c = '2017',
            dealer__Trade_Make__c = 'Toyota',
            dealer__Trade_Model__c = 'Greatness',
            dealer__Desired_Stock_Num__c = veh.Id,
            Decision_Date__c = System.Today()
        );
        insert dsp;

        dealer__Deal__c oldd = new dealer__Deal__c(
             Name = 'Test',
             dealer__Deal_Type__c = 'Retail Vehicle Sale', 
             RecordTypeId = Schema.SObjectType.dealer__Deal__c.getRecordTypeInfosByName().get('Retail').getRecordTypeId(),
             TaxCalcDT__c = DateTime.now(),   
             dealer__Auto_Insurance_Agent__c='Test',
             dealer__Deal_ID__c ='Test',
             dealer__Sales_Lead__c = dsp.id,
             dealer__Status__c ='Pending',
             dealer__Deal_Date__c =System.Today(),
             Proposed_Delivery_Date__c =System.Today(),
             dealer__Vehicle__c = veh.Id,
             dealer__Store_Location__c = FFAdata.DealerLocation.Id,
             Funding_option__c = 'Cash', 
             dealer__DeliveryRepairOrder__c = null 
        );
        insert oldd;
    }

    public static testMethod void testOpportunityIsConnectedToFreshSlop()
    {
        Test.StartTest();

        List<dealer__Sales_Up__c> tempSlops = [SELECT Id, 
                                            Opportunity__c
                                        FROM dealer__Sales_Up__c 
                                        WHERE Solution_Type__c = 'Chassis/Conversion' AND 
                                            dealer__Trade_Year__c = '2017' 
                                        LIMIT 1];
        dealer__Sales_Up__c tempSlop = tempSlops.size()>0 ? tempSlops[0] : null;
        
        //if (tempSlop!=null) System.assertNotEquals(null, tempSlop.Opportunity__c);

        Test.StopTest();
    }

    public static testMethod void testProposals()
    {
        Test.startTest();

        List<Opportunity> tempOpps = [SELECT Id 
                                FROM Opportunity 
                                WHERE Solution_Opportunity__c != null 
                                LIMIT 1];
        Opportunity tempOpp = tempOpps.size()>0 ? tempOpps[0] : null;

        if (tempOpp!=null) tempOpp.Amount = 100;

        if (tempOpp!=null) update tempOpp;

        List<dealer__Sales_Up__c> tempSlops = [SELECT Id,
                                            Decision_Date__c,
                                            BDC_Created__c,
                                            Status__c,
                                            BuyerContact__c,
                                            dealer__Lead_Type__c,
                                            dealer__Source__c,
                                            Solution_Type__c,
                                            dealer__Store_Location__c,
                                            dealer__Trade_Year__c,
                                            dealer__Trade_Make__c,
                                            dealer__Trade_Model__c,
                                            Opportunity__c
                                         FROM dealer__Sales_Up__c
                                         WHERE Opportunity__c != null
                                         LIMIT 1];
        dealer__Sales_Up__c tempSlop = tempSlops.size()>0 ? tempSlops[0] : null;

        if (tempSlop!=null) update tempSlop;

        Test.stopTest();
    }
    
    public static testMethod void testConstructor()
    {
        Test.startTest();
        
        SalesUpMBWContactOppHandler tempHandler = new SalesUpMBWContactOppHandler();
        
        Test.stopTest();
    }
    
    public static testMethod void testSyncOpportunity()
    {        
        Test.startTest();
        
        SalesUpMBWContactOppHandler tempHandler = new SalesUpMBWContactOppHandler();
        
        List<dealer__Sales_Up__c> tempSlops = [SELECT Id,
                                            Decision_Date__c,
                                            BDC_Created__c,
                                            Status__c,
                                            BuyerContact__c,
                                            dealer__Lead_Type__c,
                                            dealer__Source__c,
                                            Solution_Type__c,
                                            dealer__Store_Location__c,
                                            dealer__Trade_Year__c,
                                            dealer__Trade_Make__c,
                                            dealer__Trade_Model__c,
                                            Opportunity__c
                                         FROM dealer__Sales_Up__c
                                         WHERE Opportunity__c != null
                                         LIMIT 1];
        dealer__Sales_Up__c tempSlop = tempSlops.size()>0 ? tempSlops[0] : null;
        
        System.debug(tempSlop);
        
        Contact con = new Contact();
        con.Phone = '8888888';
        con.LastName = 'Test';
        insert con;
        
        if (tempSlop!=null) {
        tempSlop.Decision_Date__c = System.Today() + 1;
        tempSlop.BDC_Created__c = true;
        tempSlop.BuyerContact__c = con.Id;
        tempSlop.dealer__Lead_Type__c = 'Walk-In';
        tempSlop.dealer__Source__c = '$1000 Off';
        tempSlop.Solution_Type__c = 'Wholesale';
        //tempSlop.dealer__Store_Location__c = FFAdata.DealerLocation.Id;
        
        update tempSlop;
        }

        Test.stopTest();
    }
}