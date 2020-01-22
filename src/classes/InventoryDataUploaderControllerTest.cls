/**
* InventoryDataUploaderControllerTest
*
* MobilityWorks (c) - 2018
*
* Developer: Alexander Miller
* Date 2/9/2018
*
* Modifications
* 2019-10-30	B. Leaman	W-000773 BLL1 - Allow matching by stock# instead of VIN; improve code coverage;
*/
@isTest
public class InventoryDataUploaderControllerTest {
    
    public static String exampleVIN = '1GNSCKE02BR299114';
    public static String exampleVIN2 = '1GKS2JKJ2FR289471';
    public static String exampleVIN3 = '1FT7W2B66FEB51673';
    public static String exampleVIN4 = '1GNKVFED2EJ305209';
    public static String exampleVIN5 = '4T4BF1FK3CR177422';
    public static String exampleVIN6 = '4T1BF18B0WU387908';
    public static String exampleVIN7 = '1G11C5SL8FF183999';

    public static String statusDelivered = 'Delivered';
    public static String statusInTransitStock = 'In Transit - Stock';
    public static String statusInProduction = 'In Production';
    public static String statusInTransitTransfer = 'In Transit - Transfer';
	public static String statusReadyForSale = 'Ready For Sale';
    
    public static String stagAtSeller = 'At Seller';
    public static String stageProductionScheduled = 'Production Scheduled';
    public static String stageProductionComplete = 'Production Complete';
    public static String stageToRetailLocation = 'To Retail Location';

    @testSetup
    public static void setup()
    {
		// BLL1
		List<dealer__Vehicle_Inventory__c> vehInvs = new List<dealer__Vehicle_Inventory__c>();
		// BLL1 end

        dealer__Vehicle_Inventory__c tempVehicle = new dealer__Vehicle_Inventory__c();
        tempVehicle.dealer__VIN__c = exampleVIN;
        tempVehicle.dealer__Stock_Number__c = 'TEST12345';
        tempVehicle.dealer__Make__c = 'CHEVROLET';
        tempVehicle.dealer__Model__c = 'Suburban';
        tempVehicle.dealer__Year__c = '2011';
        tempVehicle.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle.Stage__c = stagAtSeller;
        tempVehicle.dealer__Status_Code__c = statusDelivered;
        //insert tempVehicle;
		vehInvs.add(tempVehicle);

		// BLL1
        dealer__Vehicle_Inventory__c tempVehicle1 = new dealer__Vehicle_Inventory__c();
        tempVehicle1.dealer__VIN__c = exampleVIN;
        tempVehicle1.dealer__Stock_Number__c = 'TEST12345A';
        tempVehicle1.dealer__Make__c = 'CHEVROLET';
        tempVehicle1.dealer__Model__c = 'Suburban';
        tempVehicle1.dealer__Year__c = '2011';
        tempVehicle1.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle1.Stage__c = stagAtSeller;
        tempVehicle1.dealer__Status_Code__c = statusReadyForSale;
        //insert tempVehicle1;
		vehInvs.add(tempVehicle1);
		// BLL1 end

        dealer__Vehicle_Inventory__c tempVehicle2 = new dealer__Vehicle_Inventory__c();
        tempVehicle2.dealer__VIN__c = exampleVIN2;
        tempVehicle2.dealer__Stock_Number__c = 'TEST123456';
        tempVehicle2.dealer__Make__c = 'GMC';
        tempVehicle2.dealer__Model__c = 'Yukon XL';
        tempVehicle2.dealer__Year__c = '2015';
        tempVehicle2.ProductionCompletionDate__c = Date.newinstance(2018, 4, 5);
        tempVehicle2.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle2.Stage__c = stagAtSeller;
        tempVehicle2.dealer__Status_Code__c = statusDelivered;
        //insert tempVehicle2;
		vehInvs.add(tempVehicle2);

        dealer__Vehicle_Inventory__c tempVehicle3 = new dealer__Vehicle_Inventory__c();
        tempVehicle3.dealer__VIN__c = exampleVIN3;
        tempVehicle3.dealer__Stock_Number__c = 'TEST123457';
        tempVehicle3.dealer__Make__c = 'GMC';
        tempVehicle3.dealer__Model__c = 'Yukon XL';
        tempVehicle3.dealer__Year__c = '2015';
        tempVehicle3.ProductionCompletionDate__c = Date.newinstance(2018, 4, 5);
        tempVehicle3.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle3.Stage__c = stagAtSeller;
        tempVehicle3.dealer__Status_Code__c = statusInTransitStock;
		// BLL1
		tempVehicle3.InboundTransportRequested__c = Date.newInstance(2019, 10, 31);
		tempVehicle3.dealer__Acquisition_Date__c = Date.newInstance(2019, 10, 31);
		tempVehicle3.dealer__Retail_Ready__c = Date.newInstance(2019, 10, 31);
		tempVehicle3.OutboundTransportRequested__c = Date.newInstance(2019, 10, 31);
		tempVehicle3.ProductionCompletionDate__c = Date.newInstance(2019, 10, 31);
		tempVehicle3.OriginalProductionCompletionDate__c = Date.newInstance(2019, 10, 31);
		tempVehicle3.Conv_MFG__c = 'VMI';
		tempVehicle3.Conversion_Model__c = 'VMI Northstar';
		tempVehicle3.MV_Ramp_Type__c = 'In Floor';
		tempVehicle3.MV_Ranp_Operation__c = 'Automatic';
		tempVehicle3.FloorCut__c = 'Short';
		tempVehicle3.Kneeling__c = 'Yes';
		tempVehicle3.FeaturedVan__c = 'SPIFF';
		tempVehicle3.Tracking__c = 'SB';
		tempVehicle3.dealer__Mileage__c = 1234;
		tempVehicle3.Ramp_Location__c = 'Side Entry';
		tempVehicle3.ConversionMSRP__c = 12345.00;
		tempVehicle3.ChassisMSRP__c = 23456;
		// BLL1
        //insert tempVehicle3;
		vehInvs.add(tempVehicle3);

        dealer__Vehicle_Inventory__c tempVehicle4 = new dealer__Vehicle_Inventory__c();
        tempVehicle4.dealer__VIN__c = exampleVIN4;
        tempVehicle4.dealer__Stock_Number__c = 'TEST123458';
        tempVehicle4.dealer__Make__c = 'GMC';
        tempVehicle4.dealer__Model__c = 'Yukon XL';
        tempVehicle4.dealer__Year__c = '2015';
        tempVehicle4.ProductionCompletionDate__c = Date.newinstance(2018, 4, 5);
        tempVehicle4.InboundTransportRequested__c = Date.newinstance(2018, 4, 6);
        tempVehicle4.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle4.Stage__c = stagAtSeller;
        tempVehicle4.dealer__Status_Code__c = statusInTransitStock;
        //insert tempVehicle4;
		vehInvs.add(tempVehicle4);

        dealer__Vehicle_Inventory__c tempVehicle5 = new dealer__Vehicle_Inventory__c();
        tempVehicle5.dealer__VIN__c = exampleVIN5;
        tempVehicle5.dealer__Stock_Number__c = 'TEST123459';
        tempVehicle5.dealer__Make__c = 'GMC';
        tempVehicle5.dealer__Model__c = 'Yukon XL';
        tempVehicle5.dealer__Year__c = '2015';
        tempVehicle5.ProductionCompletionDate__c = Date.newinstance(2018, 4, 5);
        tempVehicle5.InboundTransportRequested__c = Date.newinstance(2018, 4, 6);
        tempVehicle5.dealer__Acquisition_Date__c = Date.newinstance(2018, 4, 6);
        tempVehicle5.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle5.Stage__c = stageProductionScheduled;
        tempVehicle5.dealer__Status_Code__c = statusInProduction;
        //insert tempVehicle5;
		vehInvs.add(tempVehicle5);

        dealer__Vehicle_Inventory__c tempVehicle6 = new dealer__Vehicle_Inventory__c();
        tempVehicle6.dealer__VIN__c = exampleVIN6;
        tempVehicle6.dealer__Stock_Number__c = 'TEST123460';
        tempVehicle6.dealer__Make__c = 'GMC';
        tempVehicle6.dealer__Model__c = 'Yukon XL';
        tempVehicle6.dealer__Year__c = '2015';
        tempVehicle6.ProductionCompletionDate__c = Date.newinstance(2018, 4, 5);
        tempVehicle6.InboundTransportRequested__c = Date.newinstance(2018, 4, 6);
        tempVehicle6.dealer__Retail_Ready__c = Date.newinstance(2018, 4, 6);
        tempVehicle6.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle6.Stage__c = stageProductionScheduled;
        tempVehicle6.dealer__Status_Code__c = statusInProduction;
        //insert tempVehicle6;
		vehInvs.add(tempVehicle6);

        dealer__Vehicle_Inventory__c tempVehicle7 = new dealer__Vehicle_Inventory__c();
        tempVehicle7.dealer__VIN__c = exampleVIN7;
        tempVehicle7.dealer__Stock_Number__c = 'TEST123461';
        tempVehicle7.dealer__Make__c = 'GMC';
        tempVehicle7.dealer__Model__c = 'Yukon XL';
        tempVehicle7.dealer__Year__c = '2015';
        tempVehicle7.ProductionCompletionDate__c = Date.newinstance(2018, 4, 5);
        tempVehicle7.InboundTransportRequested__c = Date.newinstance(2018, 4, 5);
        tempVehicle7.dealer__Retail_Ready__c = Date.newinstance(2018, 4, 5);
        tempVehicle7.RecordTypeId = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName().get('New').getRecordTypeId();
        tempVehicle7.Stage__c = stageToRetailLocation;
        tempVehicle7.dealer__Status_Code__c = statusInTransitTransfer;
        //insert tempVehicle7;
		vehInvs.add(tempVehicle7);

		// BLL1
		insert(vehInvs);
		// BLL1 end
    }
    
    public static testMethod void testContructor()
    {
        Test.startTest();
        InventoryDataUploaderController tempController = new InventoryDataUploaderController();
        Test.stopTest();
    }
    
    public static testMethod void testGlobals()
    {
        Test.startTest();
        System.assertEquals(null, InventoryDataUploaderController.nameFile);
        System.assertEquals(null, InventoryDataUploaderController.contentFile);
        System.assertEquals(null, InventoryDataUploaderController.mapOfInventorySheetData);
        System.assertEquals(null, InventoryDataUploaderController.twoDimOfInventorySheetData);
        System.assertEquals(null, InventoryDataUploaderController.mapOfFinalUploadData);
        Test.stopTest();
    }
    
    public static testMethod void testInventoryItem()
    {
        Test.startTest();
        InventoryDataUploaderController.InventoryItem tempItem = new InventoryDataUploaderController.InventoryItem();
        System.assertEquals(null, tempItem.VIN);
        System.assertEquals(null, tempItem.inboundTransportRequested);
        System.assertEquals(null, tempItem.outboundTransportRequested);
        System.assertEquals(null, tempItem.acquisitionDate);
        System.assertEquals(null, tempItem.retailReady);
        System.assertEquals(null, tempItem.vehicle);
        System.assertEquals('', tempItem.errorReason);
        System.assertEquals(false, tempItem.isFound);
        System.assertEquals(false, tempItem.isDuplicate);
        System.assertEquals(false, tempItem.willUpdate);
        System.assertEquals(null, tempItem.iconImage);
        Test.stopTest();
    }
    
    public static testMethod void testDateConversion()
    {
        Test.startTest();
        String firstDate = '4/5/2018';
        String secondDate = '4-5-2018';
       
        System.assertEquals(Date.newInstance(2018, 4, 5), InventoryDataUploaderController.convertStringToDate(firstDate));
        System.assertEquals(Date.newInstance(2018, 4, 5), InventoryDataUploaderController.convertStringToDate(secondDate));
        System.assertEquals(null, InventoryDataUploaderController.convertStringToDate(''));
        Test.stopTest();
    }
    
    public static testMethod void testFindColumns()
    {   
        Test.startTest();  
        InventoryDataUploaderController.filelines = new String[]{};
        String tempLine = InventoryDataUploaderController.columnHeaderVIN + ',' + InventoryDataUploaderController.columnHeaderInboundTransportRequested + ',' +
                            InventoryDataUploaderController.columnHeaderAcquisitionDate + ',' + InventoryDataUploaderController.columnHeaderRetailReady + ',' + 
                            InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ',' + InventoryDataUploaderController.columnHeaderProductionComplete;
        InventoryDataUploaderController.nameFile = tempLine;
        
        System.debug(InventoryDataUploaderController.filelines);
        
        InventoryDataUploaderController.findColumnIndexes();
        
        System.assertEquals(0, InventoryDataUploaderController.columnNumberVin);
        System.assertEquals(1, InventoryDataUploaderController.columnNumberInboundTransportRequested);
        System.assertEquals(2, InventoryDataUploaderController.columnNumberAcquisitionDate);
        System.assertEquals(3, InventoryDataUploaderController.columnNumberRetailReady);
        System.assertEquals(4, InventoryDataUploaderController.columnNumberOutboundTransportRequested);
        System.assertEquals(5, InventoryDataUploaderController.columnNumberProductionComplete);
        
        // Make sure its not static and it can move around
        
        InventoryDataUploaderController.filelines = new String[]{};
        
        tempLine = InventoryDataUploaderController.columnHeaderInboundTransportRequested + ',' +
                            InventoryDataUploaderController.columnHeaderAcquisitionDate + ',' + InventoryDataUploaderController.columnHeaderRetailReady + ',' + 
                            InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ',' + InventoryDataUploaderController.columnHeaderVIN + ',' +
                            InventoryDataUploaderController.columnHeaderProductionComplete;
        
        InventoryDataUploaderController.nameFile = tempLine;
            
        InventoryDataUploaderController.findColumnIndexes();
        System.assertEquals(0, InventoryDataUploaderController.columnNumberInboundTransportRequested);
        System.assertEquals(1, InventoryDataUploaderController.columnNumberAcquisitionDate);
        System.assertEquals(2, InventoryDataUploaderController.columnNumberRetailReady);
        System.assertEquals(3, InventoryDataUploaderController.columnNumberOutboundTransportRequested);
        System.assertEquals(4, InventoryDataUploaderController.columnNumberVin);
        System.assertEquals(5, InventoryDataUploaderController.columnNumberProductionComplete);
        Test.stopTest();
    }
    
    public static testMethod void testReturnVehicleInventory()
    {   
        Test.startTest();
        List<String> listOfVIN = new List<String>();
        listOfVIN.add(exampleVIN);
        
        InventoryDataUploaderController.returnVehicleInventory(listOfVIN);
    }

    public static testMethod void testTwoDimensialArrayStack()
    {
        Test.startTest();
        InventoryDataUploaderController.twoDimOfInventorySheetData = new List<List<InventoryDataUploaderController.InventoryItem>>();

        for(Integer i = 0; i < 1001; i++)
        {
            InventoryDataUploaderController.InventoryItem tempItem = new InventoryDataUploaderController.InventoryItem();
            InventoryDataUploaderController.addToTwoDimArrayStack(tempItem);
        }
        Test.stopTest();
    }

    public static testMethod void testGenerateRunTimeInventoryData()
    {
        Test.startTest();
        InventoryDataUploaderController.twoDimOfInventorySheetData = new List<List<InventoryDataUploaderController.InventoryItem>>();

        String tempLine = InventoryDataUploaderController.columnHeaderInboundTransportRequested + ',' +
                            InventoryDataUploaderController.columnHeaderAcquisitionDate + ',' + InventoryDataUploaderController.columnHeaderRetailReady + ',' + 
                            InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ',' + InventoryDataUploaderController.columnHeaderVIN + ',' + InventoryDataUploaderController.columnHeaderProductionComplete;

        InventoryDataUploaderController.nameFile = tempLine;

        tempLine = '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN + ',4-5-2018';

        InventoryDataUploaderController.filelines.add(tempLine);

        InventoryDataUploaderController.findColumnIndexes();

        InventoryDataUploaderController.generateRunTimeInventoryData(InventoryDataUploaderController.filelines);
        Test.stopTest();
    }

    public static testMethod void testGenerateDuplicates()
    {
        Test.startTest();
        InventoryDataUploaderController.twoDimOfInventorySheetData = new List<List<InventoryDataUploaderController.InventoryItem>>();

        String tempLine = InventoryDataUploaderController.columnHeaderInboundTransportRequested + ',' +
                            InventoryDataUploaderController.columnHeaderAcquisitionDate + ',' + InventoryDataUploaderController.columnHeaderRetailReady + ',' + 
                            InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ',' + InventoryDataUploaderController.columnHeaderVIN;

        InventoryDataUploaderController.nameFile = tempLine;

        tempLine = '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN;

        InventoryDataUploaderController.filelines.add(tempLine);
        InventoryDataUploaderController.filelines.add(tempLine);

        InventoryDataUploaderController.findColumnIndexes();

        InventoryDataUploaderController.generateRunTimeInventoryData(InventoryDataUploaderController.filelines);
        InventoryDataUploaderController.generateDuplicates(InventoryDataUploaderController.filelines); 
        Test.stopTest();
    }

    public static testMethod void testReadFile()
    {
        Test.startTest();
        // build out three lines for uploads
        String tempLine = InventoryDataUploaderController.columnHeaderInboundTransportRequested + ',' +
                            InventoryDataUploaderController.columnHeaderAcquisitionDate + ',' +
							InventoryDataUploaderController.columnHeaderRetailReady + ',' + 
                            InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ',' + 
							InventoryDataUploaderController.columnHeaderVIN + ',' + 
                            InventoryDataUploaderController.columnHeaderProductionComplete + '\n' +
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN + ',4-5-2018' +'\n' + 
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN+ ',4-5-2018' + '\n' + 
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN2+ ',4-5-2018' + '\n' + 
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN3+ ',4-5-2018' + '\n' +
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN4+ ',4-5-2018' + '\n' +
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN5+ ',4-5-2018' + '\n' +
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN6 + ',4-5-2018';

        InventoryDataUploaderController.contentFile = Blob.valueOf(tempLine);
        InventoryDataUploaderController.ReadFile();
        Test.stopTest();
    }

	// BLL1
    public static testMethod void testReadFile2()
    {
        Test.startTest();
        // build out three lines for uploads
        String tempLine =
			InventoryDataUploaderController.columnHeaderVIN + ','
			+ InventoryDataUploaderController.columnHeaderSTOCK + ','
			+ InventoryDataUploaderController.columnHeaderInboundTransportRequested + ','
			+ InventoryDataUploaderController.columnHeaderAcquisitionDate + ','
			+ InventoryDataUploaderController.columnHeaderRetailReady + ','
			+ InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ','
			+ InventoryDataUploaderController.columnHeaderProductionComplete + ','
			+ InventoryDataUploaderController.columnHeaderConvMFG + ','
			+ InventoryDataUploaderController.columnHeaderConversionModel + ','
			+ InventoryDataUploaderController.columnHeaderMVRampType + ','
			+ InventoryDataUploaderController.columnHeaderMVRampOperation + ','
			+ InventoryDataUploaderController.columnHeaderFloorCut + ','
			//+ InventoryDataUploaderController.columnHeaderConversion + ','
			+ InventoryDataUploaderController.columnHeaderKneeling + ','
			+ InventoryDataUploaderController.columnHeaderFeaturedVan + ','
			+ InventoryDataUploaderController.columnHeaderTracking + ','
			+ InventoryDataUploaderController.columnHeaderOdometer + ','
			+ InventoryDataUploaderController.columnHeaderRampLocation + ','
			+ InventoryDataUploaderController.columnHeaderConvMsrp + ','
			+ InventoryDataUploaderController.columnHeaderMsrp + '\n';
		tempLine += exampleVIN2 + ','
			+ 'TEST123456' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ 'VMI' + ','
			+ 'VMI Northstar' + ','
			+ 'In Floor' + ','
			+ 'Automatic' + ','
			+ 'Short' + ','
			//+ columnHeaderConversion + ','
			+ 'Yes' + ','
			+ 'SPIFF' + ','
			+ 'SB' + ','
			+ '1234' + ','
			+ 'Side Entry' + ','
			+ '12345.00' + ','
			+ '23456' + '\n';
		tempLine += exampleVIN3 + ','
			+ 'TEST123457' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ '10/31/2019' + ','
			+ 'VMI' + ','
			+ 'VMI Northstar' + ','
			+ 'In Floor' + ','
			+ 'Automatic' + ','
			+ 'Short' + ','
			//+ columnHeaderConversion + ','
			+ 'Yes' + ','
			+ 'SPIFF' + ','
			+ 'SB' + ','
			+ '1234' + ','
			+ 'Side Entry' + ','
			+ '12345.00' + ','
			+ '23456' + '\n';
		
        InventoryDataUploaderController.contentFile = Blob.valueOf(tempLine);
        InventoryDataUploaderController.ReadFile();
        Test.stopTest();
    }
	// BLL1 end

    public static testMethod void testUpdateInventory()
    {
        Test.startTest();
        // build out three lines for uploads
        String tempLine = InventoryDataUploaderController.columnHeaderInboundTransportRequested + ',' +
                            InventoryDataUploaderController.columnHeaderAcquisitionDate + ',' + InventoryDataUploaderController.columnHeaderRetailReady + ',' + 
                            InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ',' + InventoryDataUploaderController.columnHeaderVIN + ',' + 
                            InventoryDataUploaderController.columnHeaderProductionComplete + '\n' +
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN + ',4-5-2018';

        InventoryDataUploaderController.contentFile = Blob.valueOf(tempLine);
        InventoryDataUploaderController.updateInventory();
        Test.stopTest();
    }

    public static testMethod void testUpdateInventoryValidationError()
    {
        Test.startTest();
        // build out three lines for uploads
        String tempLine = InventoryDataUploaderController.columnHeaderInboundTransportRequested + ',' +
                            InventoryDataUploaderController.columnHeaderAcquisitionDate + ',' + InventoryDataUploaderController.columnHeaderRetailReady + ',' + 
                            InventoryDataUploaderController.columnHeaderOutboundTransportRequested + ',' + InventoryDataUploaderController.columnHeaderVIN + ',' + 
                            InventoryDataUploaderController.columnHeaderProductionComplete + '\n' +
                            '4-5-2018,4-5-2018,4-5-2018,4-5-2018,'+exampleVIN7 + ',4-5-2018';

        InventoryDataUploaderController.contentFile = Blob.valueOf(tempLine);
        InventoryDataUploaderController.updateInventory();
        Test.stopTest();
    }

    public static testMethod void testReadFileException()
    {
        Test.startTest();
        InventoryDataUploaderController.ReadFile();
        Test.stopTest();
    }
}