/**
* InventoryDataUploaderController
*
* MobilityWorks (c) - 2018
*
* A controller to handle mass updating inventory in MobilityWorks
*
* Tested By: InventoryDataUploaderControllerTest
* Developer: Alexander Miller
* Date 2/9/2018
*
* A. Miller - AMILLER1 - 7.27.2018 - Update to handle more fields
* A. MILLER - AMILLER2 - 8-21-2018 - Update to list all vehicles found, regardless of their status.
* A. Miller - AMILLER3 - W-000470 - 10/25/2018 - Update to handle string to decimal conversions by taking out spaces
* A. Miller - AMM4     - W-000577 - 2/7/2019   - Update to handle the Conversion MSRP and regular MSRP updating
* 2019-10-30	B. Leaman	W-000773 BLL1 - Allow matching by stock# instead of VIN; fix spelling of listOfCoulmHeaders (unmarked);
*							When matching by VIN, skip delivered vehicles;
*/
global with sharing class InventoryDataUploaderController {

    public static String nameFile { get; set;}
    public static Blob contentFile { get; set;}
    public static String[] filelines = new String[]{};

    public static Map<String, InventoryItem> mapOfInventorySheetData {get;set;}
    public static List<List<InventoryItem>> twoDimOfInventorySheetData {get;set;}
    public static Map<String, InventoryItem> mapOfFinalUploadData {get;set;}
    public static List<InventoryItem> listOfAllRecords {get;set;}   
    // AMILLER1
    public static Map<String, dealer__Parts_Kit__c> mapOfConversionPartsKits {get;set;}
    // AMILLER1

    public static Integer columnNumberVin;
	// BLL1
	public static Integer columnNumberStock;
	// BLL1 end
    public static Integer columnNumberInboundTransportRequested;
    public static Integer columnNumberAcquisitionDate;
    public static Integer columnNumberRetailReady;
    public static Integer columnNumberOutboundTransportRequested;
    public static Integer columnNumberProductionComplete;
    // AMILLER1
    public static Integer columnNumberConvMFG;
    public static Integer columnNumberConversionModel;
    public static Integer columnNumberMVRampType;
    public static Integer columnNumberMVRampOperation;
    public static Integer columnNumberFloorCut;
    public static Integer columnNumberConversion;
    public static Integer columnNumberKneeling;
    public static Integer columnNumberFeaturedVan;
    public static Integer columnNumberTracking;
    public static Integer columnNumberOdometer;
    public static Integer columnNumberRampLocation;
    // AMILLER1
    // AMM4
    public static Integer columnNumberConvMsrp;
    public static Integer columnNumberMsrp;
    // AMM4

    public static String columnHeaderVIN = 'VIN';
	// BLL1
	public static String columnHeaderSTOCK = 'STOCK';
	// BLL1 end
    public static String columnHeaderInboundTransportRequested = 'Del Date';
    public static String columnHeaderAcquisitionDate = 'Order Date';
    public static String columnHeaderRetailReady = 'Complete Date';
    public static String columnHeaderOutboundTransportRequested = 'Date Shipped';
    public static String columnHeaderProductionComplete = 'Compl Dt';
    // AMILLER1
    public static String columnHeaderConvMFG = 'Conv MFG';
    public static String columnHeaderConversionModel = 'Conversion Model';
    public static String columnHeaderMVRampType = 'MV Ramp Type';
    public static String columnHeaderMVRampOperation = 'MV Ramp Operation';
    public static String columnHeaderFloorCut = 'Floor Cut';
    public static String columnHeaderConversion = 'Conversion';
    public static String columnHeaderKneeling = 'Kneeling';
    public static String columnHeaderFeaturedVan = 'Featured Van';
    public static String columnHeaderTracking = 'Tracking';
    public static String columnHeaderOdometer = 'Odometer';
    public static String columnHeaderRampLocation = 'Ramp Location';
    // AMILLER1
    // AMM4
    public static String columnHeaderConvMsrp = 'Conv MSRP';
    public static String columnHeaderMsrp = 'Chassis MSRP';
    // AMM4
    public static String errorCodeDuplicateVehicleEntry = 'This vehicle has multiple entries the file';
    public static String errorCodeVehicleNotFound = 'Vehicle not found';
    public static String errorCodeNonNullField = 'Field already populated and will not update';
    public static String errorCodeStatusIncorrect = 'The status of this vehicle is not compatible with the update';
    public static String errorCodeDateMatches = 'The Salesforce record matches the upload data. No update is needed';

    public static String iconError = '/img/msg_icons/error16.png';
    public static String iconWarning = '/img/msg_icons/warning16.png';
    public static String iconPass = '/img/msg_icons/confirm16.png';

    public static Set<String> setOfTooLateStages = new Set<String>{'Production Complete', 'To Recon Center', 'To Retail Location', 'Recondition', 'Available', 'Vehicle Placed or Requested', 'In Transit to Location'};
    public static Set<String> setOfTooLateStatuses = new Set<String>{'Not For Sale', 'Ready For Sale','Delivered'};

    global InventoryDataUploaderController(){}
    
    public static Pagereference ReadFile()
    {
        try
        {
            nameFile=contentFile.toString();
            filelines = nameFile.split('\n');
    
            mapOfInventorySheetData = new Map<String, InventoryItem>();
            twoDimOfInventorySheetData = new List<List<InventoryItem>>();
            mapOfFinalUploadData = new Map<String, InventoryItem>();
        	listOfAllRecords = new List<InventoryItem>();
            mapOfConversionPartsKits = new Map<String, dealer__Parts_Kit__c>(); // AMILLER1

            findColumnIndexes();

            generateRunTimeInventoryData(filelines);

            // AMILLER1
            generatePartKitMappings();
            // AMILLER1

            generateDuplicates(filelines);

            for(List<InventoryItem> itemList : twoDimOfInventorySheetData)
            {
                for(InventoryItem tempItem : itemList)
                {
                    if(!tempItem.isDuplicate)
                    {
                        // BLL1
						//mapOfFinalUploadData.put(tempItem.VIN, tempItem);
						mapOfFinalUploadData.put(tempItem.KEY, tempItem);
						// BLL1 end
                    }

                    listOfAllRecords.add(tempItem);
                }
            }

            generateUploadStatus();

        } catch(Exception e)
        {
            System.debug(e.getCause());
            System.debug(e.getLineNumber());
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());

            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage() + ' - ' + e.getStackTraceString());
            ApexPages.addMessage(errormsg);
            return null;
        }

        return null;
    }

    /**
    * updateInventory
    *
    * Function which takes the appropriate inventory and updates the system
    */
    public static PageReference updateInventory()
    {
        ReadFile(); 
        InventoryDataUploaderBatch tempBatch = new InventoryDataUploaderBatch();
        tempBatch.jsonString = JSON.serialize(listOfAllRecords); 
        Database.executeBatch(tempBatch,1);  

        // Alert Message
        ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.INFO,'Process started. You will receive an email once the process is done with the results.');
        ApexPages.addMessage(errormsg);

        return null;
    }

    /**
    * generateUploadStatus
    *
    * Function which iterates over the map of data and 
    * figures out what the status should be.
    *
    * - The row should not be allowed to update if:
    * - - The row is a duplicate of another
    * - - The records in the system attempting to be written to are not null
    * - The row should update if:
    * - - It is unique and the data presented is matching to null fields
    */
    public static void generateUploadStatus()
    {
		// BLL1 reuse listOfVIN to be VIN or STOCK#
        List<String> listOfVIN = new List<String>();

        for(String itemList : mapOfFinalUploadData.KeySet())
        {
            if(!mapOfFinalUploadData.get(itemList).isDuplicate)
            {
                // BLL1
				//System.debug(mapOfFinalUploadData.get(itemList).VIN);
                //listOfVIN.add(mapOfFinalUploadData.get(itemList).VIN);
				String key;
				InventoryItem invitm = mapOfFinalUploadData.get(itemList);
				if (ColumnNumberStock!=null) key = invitm.STOCK;
				else key = invitm.VIN;
				System.debug(itemList);
				System.debug(mapOfFinalUploadData.get(itemList));
				System.debug(key);
				if (!String.isBlank(key)) {
					System.debug(key);
					listOfVIN.add(key);
				}
				// BLL1 end
            }
        }

        List<dealer__Vehicle_Inventory__c> listOfVehicleInvToEval = returnVehicleInventory(listOfVIN);

        for(dealer__Vehicle_Inventory__c tempDealerInv : listOfVehicleInvToEval)
        {
			// BLL1
            InventoryItem tempInv = mapOfFinalUploadData.get(String.valueOf(tempDealerInv.dealer__VIN__c));
			if (ColumnNumberStock!=null) tempInv = mapOfFinalUploadData.get(String.valueOf(tempDealerInv.dealer__Stock_Number__c));
			// BLL1 end

            if(tempInv != null)
            {
                // BLL1
				//mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv; // AMILLER2
				mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv; 
				// BLL1 end
            }
                    
            // Production Completion from Braun date
            if(tempInv.productionComplete != null && tempInv.productionComplete != tempDealerInv.ProductionCompletionDate__c)
            {
                tempDealerInv.ProductionCompletionDate__c = tempInv.productionComplete;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end
                System.debug('1');
            }
            else if(tempInv.productionComplete != null && 
                (tempDealerInv.ProductionCompletionDate__c != null && tempInv.productionComplete == tempDealerInv.ProductionCompletionDate__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeDateMatches;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeDateMatches;
				// BLL1 end
                System.debug('2');
            }

            if(setOfTooLateStages.contains(tempDealerInv.Stage__c) ||
                setOfTooLateStatuses.contains(tempDealerInv.dealer__Status_Code__c))
            {
                if(tempInv.productionComplete == null && 
                    (tempDealerInv.ProductionCompletionDate__c != null && tempInv.productionComplete != tempDealerInv.ProductionCompletionDate__c))
                {
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeStatusIncorrect;
                    mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeStatusIncorrect;
					// BLL1 end
                    System.debug('3');
                }
                //continue;
            }

            if(tempDealerInv.dealer__Status_Code__c == 'In Transit - Stock' && 
                tempDealerInv.Stage__c != 'Transport Requested' &&  
                tempDealerInv.Stage__c != 'Transport Accepted')
            {
                // Inbound Transport Requested
                if(tempInv.inboundTransportRequested != null && tempDealerInv.InboundTransportRequested__c == null)
                {
                    tempDealerInv.InboundTransportRequested__c = tempInv.inboundTransportRequested;
                    tempDealerInv.dealer__Status_Code__c = 'In Transit - Stock';
                    tempDealerInv.Stage__c = 'Transport Requested';
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
					// BLL1 end
                }
                else if(tempInv.inboundTransportRequested != null && tempDealerInv.InboundTransportRequested__c == null)
                {
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + 'Inbound Transport Requested ' + errorCodeNonNullField;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + 'Inbound Transport Requested ' + errorCodeNonNullField;
					// BLL1 end
                }
            }

            if (tempDealerInv.dealer__Status_Code__c != 'In Production' && 
                tempDealerInv.Stage__c != 'Production Scheduled')
            {
                // Acquisition Date
                if(tempInv.acquisitionDate != null && tempDealerInv.dealer__Acquisition_Date__c == null)
                {
                    tempDealerInv.dealer__Acquisition_Date__c = tempInv.acquisitionDate;
                    tempDealerInv.dealer__Status_Code__c = 'In Production';
                    tempDealerInv.Stage__c = 'Production Scheduled';
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
					// BLL1 end
                }
                else if(tempInv.acquisitionDate != null && tempDealerInv.dealer__Acquisition_Date__c != null)
                {
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + 'Acquisition Date ' + errorCodeNonNullField;
					mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
					mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
					mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
					mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + 'Acquisition Date ' + errorCodeNonNullField;
					// BLL1 end
                }
            }

            if(tempDealerInv.dealer__Status_Code__c == 'In Production' && 
                tempDealerInv.Stage__c != 'Production Completed')
            {
                // Retail Ready
                if(tempInv.retailReady != null && tempDealerInv.dealer__Retail_Ready__c == null)
                {
                    tempDealerInv.dealer__Retail_Ready__c = tempInv.retailReady;
                    tempDealerInv.dealer__Status_Code__c = 'In Production';
                    tempDealerInv.Stage__c = 'Production Completed';
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
					// BLL1 end
                }
                else if(tempInv.retailReady != null && tempDealerInv.dealer__Retail_Ready__c != null)
                {
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + 'Retail Ready Date ' + errorCodeNonNullField;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + 'Retail Ready Date ' + errorCodeNonNullField;
					// BLL1 end
                }
            }
            
            if(tempDealerInv.dealer__Status_Code__c != 'In Transit - Transfer' && 
                tempDealerInv.Stage__c != 'To Retail Location')
            {
                // Outbound Transport Requested
                if(tempInv.outboundTransportRequested != null && tempDealerInv.OutboundTransportRequested__c == null)
                {
                    tempDealerInv.OutboundTransportRequested__c = tempInv.OutboundTransportRequested;
                    tempDealerInv.dealer__Status_Code__c = 'In Transit - Transfer';
                    tempDealerInv.Stage__c = 'To Retail Location';
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
					// BLL1 end
                }
                else if(tempInv.outboundTransportRequested != null && tempDealerInv.OutboundTransportRequested__c != null)
                {
					// BLL1
                    //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                    //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                    //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                    //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + 'Outbound Transport Requested ' + errorCodeNonNullField;
                    mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                    mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                    mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                    mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + 'Outbound Transport Requested ' + errorCodeNonNullField;
					// BLL1 end
                }
            }

			// BLL1
            //if(mapOfFinalUploadData.get(tempInv.VIN).iconImage == null || mapOfFinalUploadData.get(tempInv.VIN).iconImage.equalsIgnoreCase(''))
            if(mapOfFinalUploadData.get(tempInv.KEY).iconImage == null || mapOfFinalUploadData.get(tempInv.KEY).iconImage.equalsIgnoreCase(''))
			// BLL1 end
            {
				// BLL1 
                //mapOfFinalUploadData.get(tempInIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInIN).errorReason += '\n' + 'No matching date, status, or stage use cases.';
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + 'No matching date, status, or stage use cases.';
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
				// BLL1 end
            }
            
            // BLL1
			//System.debug(mapOfFinalUploadData.get(tempInv.VIN));
			System.debug(mapOfFinalUploadData.get(tempInv.KEY));
			// BLL1 end
            
            // AMILLER1
            // ConvMFG
            if(tempInv.convMFG != null && tempInv.convMFG != tempDealerInv.Conv_MFG__c)
            {
                tempDealerInv.Conv_MFG__c = tempInv.convMFG;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.convMFG != null && 
                (tempDealerInv.Conv_MFG__c != null && tempInv.convMFG == tempDealerInv.Conv_MFG__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Conversion Model
            if(tempInv.conversionModel != null && tempInv.conversionModel != tempDealerInv.Conversion_Model__c)
            {
                tempDealerInv.Conversion_Model__c = tempInv.conversionModel;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.convMFG != null && (tempDealerInv.Conversion_Model__c != null && tempInv.conversionModel == tempDealerInv.Conversion_Model__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end
                System.debug('2');
            }

            // MV Ramp Type
            if(tempInv.MVRampType != null && tempInv.MVRampType != tempDealerInv.MV_Ramp_Type__c)
            {
                tempDealerInv.MV_Ramp_Type__c = tempInv.MVRampType;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end
                System.debug('1');
            }
            else if(tempInv.MVRampType != null && 
                (tempDealerInv.MV_Ramp_Type__c != null && tempInv.MVRampType == tempDealerInv.MV_Ramp_Type__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end
                System.debug('2');
            }
            
            // MV Ramp Operation
            if(tempInv.MVRampOperation != null && tempInv.MVRampOperation != tempDealerInv.MV_Ranp_Operation__c)
            {
                tempDealerInv.MV_Ranp_Operation__c = tempInv.MVRampOperation;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end
                System.debug('1');
            }
            else if(tempInv.MVRampOperation != null && 
                (tempDealerInv.MV_Ranp_Operation__c != null && tempInv.MVRampOperation == tempDealerInv.MV_Ranp_Operation__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Floor Cut
            if(tempInv.floorCut != null && tempInv.floorCut != tempDealerInv.FloorCut__c)
            {
                tempDealerInv.FloorCut__c = tempInv.floorCut;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.floorCut != null && 
                (tempDealerInv.FloorCut__c != null && tempInv.floorCut == tempDealerInv.FloorCut__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
				mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Conversion
            if(tempInv.conversion != null && mapOfConversionPartsKits.get(tempInv.conversion) !=null && tempInv.conversion != tempDealerInv.Conversion__r.External_ID__c)
            {
                tempDealerInv.Conversion__c = mapOfConversionPartsKits.get(tempInv.conversion).Id;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.conversion != null && 
                (tempDealerInv.Conversion__r.External_ID__c != null && tempInv.conversion == tempDealerInv.Conversion__r.External_ID__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Kneeling
            if(tempInv.kneeling != null && tempInv.kneeling != tempDealerInv.Kneeling__c)
            {
                tempDealerInv.Kneeling__c = tempInv.kneeling;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.kneeling != null && 
                (tempDealerInv.Kneeling__c != null && tempInv.kneeling == tempDealerInv.Kneeling__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
				mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
				mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
				mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
				mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Feature Van
            if(tempInv.featuredVan != null && tempInv.featuredVan != tempDealerInv.FeaturedVan__c)
            {
                tempDealerInv.FeaturedVan__c = tempInv.featuredVan;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.featuredVan != null && 
                (tempDealerInv.FeaturedVan__c != null && tempInv.featuredVan == tempDealerInv.FeaturedVan__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Tracking
            if(tempInv.tracking != null && tempInv.tracking != tempDealerInv.Tracking__c)
            {
                tempDealerInv.Tracking__c = tempInv.tracking;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.tracking != null && 
                (tempDealerInv.Tracking__c != null && tempInv.tracking == tempDealerInv.Tracking__c))
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Odometer
            // AMILLER3
            // if(tempInv.odometer != null && Decimal.valueOf(tempInv.odometer) != tempDealerInv.dealer__Mileage__c)
            if(tempInv.odometer != null && Decimal.valueOf(tempInv.odometer.trim()) != tempDealerInv.dealer__Mileage__c)
            // AMILLER3
            {
                // AMILLER3
                //tempDealerInv.dealer__Mileage__c = Decimal.valueOf(tempInv.odometer.);
                tempDealerInv.dealer__Mileage__c = Decimal.valueOf(tempInv.odometer.trim());
                // AMILLER3
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.odometer != null && 
                // AMILLER3
                //(tempDealerInv.dealer__Mileage__c != null && Decimal.valueOf(tempInv.odometer) == tempDealerInv.dealer__Mileage__c))
                (tempDealerInv.dealer__Mileage__c != null && Decimal.valueOf(tempInv.odometer.trim()) == tempDealerInv.dealer__Mileage__c))
                // AMILLER3
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }

            // Ramp Location
            if(tempInv.rampLocation != null && tempInv.rampLocation != tempDealerInv.Ramp_Location__c)
            {
                tempDealerInv.Ramp_Location__c = tempInv.rampLocation;
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end

                System.debug('1');
            }
            else if(tempInv.odometer != null && tempDealerInv.Ramp_Location__c != null && tempInv.rampLocation == tempDealerInv.Ramp_Location__c)
            {
				// BLL1
                //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
                //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
                //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
                //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
                //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
                mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
                mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
                mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
                mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
                mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end

                System.debug('2');
            }
            // AMILLER1

	        // AMM4 
	        // Conversion MSRP
	        if(tempInv.convMSRP != null && tempInv.convMSRP != tempDealerInv.ConversionMSRP__c)
	        {
	            tempDealerInv.ConversionMSRP__c = tempInv.convMSRP;
				// BLL1
	            //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
	            //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
	            //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
	            //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
	            mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
	            mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
	            mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
	            mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end
	            System.debug('1');
	        }
	        else if(tempInv.convMSRP != null && tempDealerInv.ConversionMSRP__c != null && tempInv.convMSRP == tempDealerInv.ConversionMSRP__c)
	        {
				// BLL1
	            //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
	            //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
	            //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
	            //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
	            //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
	            mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
	            mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
	            mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
	            mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
	            mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end
	            System.debug('2');
	        }
	        // Chassis MSRP
	        if(tempInv.MSRP != null && tempInv.MSRP != tempDealerInv.ChassisMSRP__c)
	        {
	            tempDealerInv.ChassisMSRP__c = tempInv.MSRP;
				// BLL1
	            //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
	            //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = true;
	            //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconPass;
	            //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
	            mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
	            mapOfFinalUploadData.get(tempInv.KEY).willUpdate = true;
	            mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconPass;
	            mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
				// BLL1 end
	            System.debug('1');
	        }
	        else if(tempInv.odometer != null && tempDealerInv.ChassisMSRP__c != null && tempInv.MSRP == tempDealerInv.ChassisMSRP__c)
	        {
				// BLL1
	            //mapOfFinalUploadData.get(tempInv.VIN).vehicle = tempDealerInv;
	            //mapOfFinalUploadData.get(tempInv.VIN).willUpdate = false;
	            //mapOfFinalUploadData.get(tempInv.VIN).iconImage = iconWarning;
	            //mapOfFinalUploadData.get(tempInv.VIN).isFound = true;
	            //mapOfFinalUploadData.get(tempInv.VIN).errorReason += '\n' + errorCodeNonNullField;
	            mapOfFinalUploadData.get(tempInv.KEY).vehicle = tempDealerInv;
	            mapOfFinalUploadData.get(tempInv.KEY).willUpdate = false;
	            mapOfFinalUploadData.get(tempInv.KEY).iconImage = iconWarning;
	            mapOfFinalUploadData.get(tempInv.KEY).isFound = true;
	            mapOfFinalUploadData.get(tempInv.KEY).errorReason += '\n' + errorCodeNonNullField;
				// BLL1 end
	            System.debug('2');
	        }
	        // AMM4

        }


        for(String itemList : mapOfFinalUploadData.KeySet())
        {
            if(!mapOfFinalUploadData.get(itemList).isDuplicate && !mapOfFinalUploadData.get(itemList).isFound)
            {
                mapOfFinalUploadData.get(itemList).willUpdate = false;
                mapOfFinalUploadData.get(itemList).iconImage = iconError;
                mapOfFinalUploadData.get(itemList).errorReason = errorCodeVehicleNotFound;
            }
        }
    }

    /**
    * generateDuplicates
    *
    * Function which iterates over the CSV raw data and
    * identifies which rows are duplicates.
    */
    public static void generateDuplicates(String[] data)
    {
        Map<String, Integer> mapOfDupes = new Map<String, Integer>();

        for(Integer i = 0; i < twoDimOfInventorySheetData.size(); i++)
        {
            for(Integer m = 0; m < twoDimOfInventorySheetData.get(i).size(); m++)
            {
				// BLL1
                //if(mapOfDupes.get(twoDimOfInventorySheetData.get(i).get(m).VIN) == null)
                if(mapOfDupes.get(twoDimOfInventorySheetData.get(i).get(m).KEY) == null)
				// BLL1 end
                {
					// BLL1
                    //mapOfDupes.put(twoDimOfInventorySheetData.get(i).get(m).VIN, 1);
                    mapOfDupes.put(twoDimOfInventorySheetData.get(i).get(m).KEY, 1);
					// BLL1 end
                }
                else
                {
					// BLL1
                    //mapOfDupes.put(twoDimOfInventorySheetData.get(i).get(m).VIN, mapOfDupes.get(twoDimOfInventorySheetData.get(i).get(m).VIN) + 1);
                    mapOfDupes.put(twoDimOfInventorySheetData.get(i).get(m).KEY, mapOfDupes.get(twoDimOfInventorySheetData.get(i).get(m).KEY) + 1);
					// BLL1 end

                    twoDimOfInventorySheetData.get(i).get(m).isDuplicate = true;
                    twoDimOfInventorySheetData.get(i).get(m).errorReason = errorCodeDuplicateVehicleEntry;
                    twoDimOfInventorySheetData.get(i).get(m).iconImage = iconError;
                    
                    // Ensure all copies of the data is marked as duplicate
                    for(Integer i2 = 0; i2 < twoDimOfInventorySheetData.size(); i2++)
                    {
                        for(Integer m2 = 0; m2 < twoDimOfInventorySheetData.get(i2).size(); m2++)
                        {
							// BLL1
                            //if(twoDimOfInventorySheetData.get(i2).get(m2).VIN == twoDimOfInventorySheetData.get(i).get(m).VIN)
                            if(twoDimOfInventorySheetData.get(i2).get(m2).KEY == twoDimOfInventorySheetData.get(i).get(m).KEY)
							// BLL1 end
                            { 
                                twoDimOfInventorySheetData.get(i2).get(m2).isDuplicate = true;
                                twoDimOfInventorySheetData.get(i2).get(m2).errorReason = errorCodeDuplicateVehicleEntry;
                                twoDimOfInventorySheetData.get(i2).get(m2).iconImage = iconError;
                            }
                        }   
                    }
                }
            }
        }
    }   

    // AMILLER1
    /**
    * generatePartKitMappings
    *
    * Function which generates the Part Kit Conversion Ids for computation later
    *
    * @param listOfExternal - list of String external Ids
    */
    public static void generatePartKitMappings()
    {
        List<String> listOfExternal = new List<String>();

        for(List<InventoryItem> tempList : twoDimOfInventorySheetData)
        {
            for(InventoryItem tempItem : tempList)
            {
                if(tempItem.conversion != null && tempItem.conversion != '')
                {
                    listOfExternal.add(tempItem.conversion);
                }
            }
        }

        List<dealer__Parts_Kit__c> listOfPartKits = ([SELECT Id,
                                                        External_ID__c
                                                    FROM dealer__Parts_Kit__c
                                                    WHERE External_ID__c IN :listOfExternal]);

        for(dealer__Parts_Kit__c tempPartKit : listOfPartKits)
        {
            System.debug(tempPartKit);
            mapOfConversionPartsKits.put(tempPartKit.External_ID__c, new dealer__Parts_Kit__c(Id = tempPartKit.Id, External_ID__c = tempPartKit.External_ID__c));
        }
    }

    /**
    * generateRunTimeInventoryData
    *
    * Function which takes the CSV data and tries to create runtime records
    * to be evaluated later
    */
    public static void generateRunTimeInventoryData(String[] data)
    {
        for (Integer i=1;i<filelines.size();i++)
        {     
            String[] inputvalues = new String[]{};

            inputvalues = filelines[i].split(',');
            
            InventoryItem tempInvItem = new InventoryItem();
            
			// BLL1
            // tempInvItem.VIN = inputvalues[columnNumberVin];
			if (columnNumberVin!=null) tempInvItem.VIN = inputvalues[columnNumberVin];
			if (columnNumberStock!=null) tempInvItem.STOCK = inputvalues[columnNumberStock];
			if (columnNumberStock!=null) tempInvItem.KEY = tempInvItem.STOCK;
			else tempInvItem.KEY = tempInvItem.VIN;
			// BLL1 end

            if(columnNumberInboundTransportRequested != null && inputvalues[columnNumberInboundTransportRequested] != null && !String.isEmpty(inputvalues[columnNumberInboundTransportRequested]))
            {
                tempInvItem.inboundTransportRequested = convertStringToDate(inputvalues[columnNumberInboundTransportRequested]);
            }
            if(columnNumberOutboundTransportRequested != null && inputvalues[columnNumberOutboundTransportRequested] != null && !String.isEmpty(inputvalues[columnNumberOutboundTransportRequested]))
            {
                tempInvItem.outboundTransportRequested = convertStringToDate(inputvalues[columnNumberOutboundTransportRequested]);
            }
            if(columnNumberAcquisitionDate != null && inputvalues[columnNumberAcquisitionDate] != null && !String.isEmpty(inputvalues[columnNumberAcquisitionDate]))
            {
                tempInvItem.acquisitionDate = convertStringToDate(inputvalues[columnNumberAcquisitionDate]);
            }
            if( columnNumberRetailReady != null && inputvalues[columnNumberRetailReady] != null && !String.isEmpty(inputvalues[columnNumberRetailReady]))
            {
                tempInvItem.retailReady = convertStringToDate(inputvalues[columnNumberRetailReady]);
            }
            if( columnNumberProductionComplete != null && inputvalues[columnNumberProductionComplete] != null && !String.isEmpty(inputvalues[columnNumberProductionComplete]))
            {
                tempInvItem.productionComplete = convertStringToDate(inputvalues[columnNumberProductionComplete]);
            }
            // AMILLER1
            if( columnNumberConvMFG != null && inputvalues[columnNumberConvMFG] != null && !String.isEmpty(inputvalues[columnNumberConvMFG]))
            {
                tempInvItem.convMFG = inputvalues[columnNumberConvMFG];
            }
            if( columnNumberConversionModel != null && inputvalues[columnNumberConversionModel] != null && !String.isEmpty(inputvalues[columnNumberConversionModel]))
            {
                tempInvItem.conversionModel = inputvalues[columnNumberConversionModel];
            }
            if( columnNumberMVRampType != null && inputvalues[columnNumberMVRampType] != null && !String.isEmpty(inputvalues[columnNumberMVRampType]))
            {
                tempInvItem.MVRampType = inputvalues[columnNumberMVRampType];
            }
            if( columnNumberMVRampOperation != null && inputvalues[columnNumberMVRampOperation] != null && !String.isEmpty(inputvalues[columnNumberMVRampOperation]))
            {
                tempInvItem.MVRampOperation = inputvalues[columnNumberMVRampOperation];
            }
            if( columnNumberFloorCut != null && inputvalues[columnNumberFloorCut] != null && !String.isEmpty(inputvalues[columnNumberFloorCut]))
            {
                tempInvItem.floorCut = inputvalues[columnNumberFloorCut];
            }
            if( columnNumberConversion != null && inputvalues[columnNumberConversion] != null && !String.isEmpty(inputvalues[columnNumberConversion]))
            {
                tempInvItem.conversion = inputvalues[columnNumberConversion];
            }
            if( columnNumberKneeling != null && inputvalues[columnNumberKneeling] != null && !String.isEmpty(inputvalues[columnNumberKneeling]))
            {
                tempInvItem.kneeling = inputvalues[columnNumberKneeling];
            }
            if( columnNumberFeaturedVan != null && inputvalues[columnNumberFeaturedVan] != null && !String.isEmpty(inputvalues[columnNumberFeaturedVan]))
            {
                tempInvItem.featuredVan = inputvalues[columnNumberFeaturedVan];
            }
            if( columnNumberTracking != null && inputvalues[columnNumberTracking] != null && !String.isEmpty(inputvalues[columnNumberTracking]))
            {
                tempInvItem.tracking = inputvalues[columnNumberTracking];
            }
            if( columnNumberOdometer != null && inputvalues[columnNumberOdometer] != null && !String.isEmpty(inputvalues[columnNumberOdometer]))
            {
                tempInvItem.odometer = inputvalues[columnNumberOdometer];
            }
            if( columnNumberRampLocation != null && inputvalues[columnNumberRampLocation] != null && !String.isEmpty(inputvalues[columnNumberRampLocation]))
            {
                tempInvItem.rampLocation = inputvalues[columnNumberRampLocation];
            }
            // AMILLER1
            // AMM4
            if( columnNumberConvMsrp != null && inputvalues[columnNumberConvMsrp] != null && !String.isEmpty(inputvalues[columnNumberConvMsrp]))
            {
                tempInvItem.convMSRP = Decimal.valueOf(inputvalues[columnNumberConvMsrp].trim());
            }
            if( columnNumberMsrp != null && inputvalues[columnNumberMsrp] != null && !String.isEmpty(inputvalues[columnNumberMsrp]))
            {
                tempInvItem.MSRP = Decimal.valueOf(inputvalues[columnNumberMsrp].trim());
            }
            // AMM4

            addToTwoDimArrayStack(tempInvItem);
        } 
    }

    /**
    * addToTwoDimArrayStack
    *
    * Function which takes the new inventory item 
    * and adds it to the next available spot in the 
    * two dimensional array. Salesforce has a limit
    * of 1,000 entities per list collection
    * and this is how to avoid it while still
    * maintaining the ability to prove
    * duplicates (e.g. multiple VINs)
    */
    public static void addToTwoDimArrayStack(InventoryItem tempInv)
    {
        if(twoDimOfInventorySheetData.size() == 0)
        {
            twoDimOfInventorySheetData.add(new List<InventoryItem>());

            twoDimOfInventorySheetData.get(0).add(tempInv);
        }
        else
        {
            if(twoDimOfInventorySheetData.get(twoDimOfInventorySheetData.size()-1).size() < 1000)
            {
                twoDimOfInventorySheetData.get(twoDimOfInventorySheetData.size()-1).add(tempInv);
            }
            else
            {
                twoDimOfInventorySheetData.add(new List<InventoryItem>());

                twoDimOfInventorySheetData.get(twoDimOfInventorySheetData.size()-1).add(tempInv);
            }
        }
    }

    /**
    * convertStringToDate
    *
    * Function which takes the CSV's date data and converts it to 
    * Apex acceptable dates. This function assumes the dates in the CSV
    * are either written in MM/DD/YYYY or MM-DD-YYYY formats.
    *
    * @param tempDateString - String with the raw CSV date data to be converted
    *
    * @return Date - converted date
    */
    public static Date convertStringToDate(String tempDateString)
    {
        Integer month = 0;
        Integer day = 0;
        Integer year = 0;

        if(tempDateString.contains('/'))
        {
            month = Integer.valueOf(tempDateString.split('/')[0].trim());
            day = Integer.valueOf(tempDateString.split('/')[1].trim());
            year = Integer.valueOf(tempDateString.split('/')[2].trim());
        }
        else if(tempDateString.contains('-'))
        {
            month = Integer.valueOf(tempDateString.split('-')[0].trim());
            day = Integer.valueOf(tempDateString.split('-')[1].trim());
            year = Integer.valueOf(tempDateString.split('-')[2].trim());
        }
        else
        {
            return null;
        }
         
        return Date.newInstance(year, month, day);
    }

    /**
    * returnVehicleInventory
    *
    * Function which takes the VIN of the list and
    * checks if it exists in the org
    */
    public static List<dealer__Vehicle_Inventory__c> returnVehicleInventory(List<String> listOfInv)
    {
		// BLL1
        //return ([SELECT Id,
        //            Name,
        //            dealer__VIN__c,
        //            dealer__Status_Code__c,
        //            Stage__c,
        //            dealer__Stock_Number__c,
        //            dealer__Retail_Ready__c,
        //            InboundTransportRequested__c,
        //            OutboundTransportRequested__c,
        //            dealer__Acquisition_Date__c,
        //            ProductionCompletionDate__c,
		//			  // AMM4
		//			  dealer__MSRP__c,
		//			  ConversionMSRP__c,
		//			  ChassisMSRP__c,
		//			  // AMM4
        //            // AMILLER1
        //            Conversion__c,
        //            Conversion__r.External_ID__c,
        //            Conv_MFG__c,
        //            Conversion_Model__c,
        //            MV_Ramp_Type__c,
        //            MV_Ranp_Operation__c,
        //            FloorCut__c,
        //            Kneeling__c,
        //            FeaturedVan__c,
        //            Tracking__c,
        //            dealer__Mileage__c,
        //            Ramp_Location__c
        //            // AMILLER1
        //        FROM dealer__Vehicle_Inventory__c
        //        WHERE dealer__VIN__c IN :listOfInv]);
		String soql = 'select Id, '
        	+ 'Name, '
        	+ 'dealer__VIN__c, '
        	+ 'dealer__Status_Code__c, '
        	+ 'Stage__c, '
        	+ 'dealer__Stock_Number__c, '
        	+ 'dealer__Retail_Ready__c, '
        	+ 'InboundTransportRequested__c, '
        	+ 'OutboundTransportRequested__c, '
        	+ 'dealer__Acquisition_Date__c, '
        	+ 'ProductionCompletionDate__c, '
			+ 'dealer__MSRP__c, '
			+ 'ConversionMSRP__c, '
			+ 'ChassisMSRP__c, '
        	+ 'Conversion__c, '
        	+ 'Conversion__r.External_ID__c, '
        	+ 'Conv_MFG__c, '
        	+ 'Conversion_Model__c, '
        	+ 'MV_Ramp_Type__c, '
        	+ 'MV_Ranp_Operation__c, '
        	+ 'FloorCut__c, '
        	+ 'Kneeling__c, '
        	+ 'FeaturedVan__c, '
        	+ 'Tracking__c, '
        	+ 'dealer__Mileage__c, '
        	+ 'Ramp_Location__c '
        	+ 'from dealer__Vehicle_Inventory__c '
			+ 'where ';
		if (columnNumberStock!=null) soql += 'dealer__Stock_Number__c in ';
		else  soql += 'dealer__Status_Code__c!=\'Delivered\' and dealer__VIN__c in ';
		System.debug(listOfInv);
		soql += '(\'' + String.join(listOfInv, '\',\'') + '\') ';
		System.debug(soql);
		return Database.query(soql);
		// BLL1 end
    }

    /**
    * findColumnIndexes 
    *
    * Function which assigns the column indexes per the fields to be updated
    */
    public static void findColumnIndexes()
    {     
        ParseCSV parser = ParseCSV.StrictParser();
        parser.setCsvData(nameFile);
        List<String> listOfColumHeaders = parser.getColumnNames();

        for(Integer i = 0; i < listOfColumHeaders.size(); i++)
        {    
            listOfColumHeaders[i] = listOfColumHeaders[i].escapeCsv().trim();

            System.debug(listOfColumHeaders[i]);

            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderVIN))
            {
                columnNumberVin = i;
                System.debug('vin column number: ' + String.valueOf(columnNumberVin));
            }
			// BLL1
			if (listOfColumHeaders[i].equalsIgnoreCase(columnHeaderSTOCK)) {
				columnNumberStock = i;
				System.debug('stock# column number: ' + String.valueOf(columnNumberStock));
			}
			// BLL1 end
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderInboundTransportRequested))
            {
                columnNumberInboundTransportRequested = i;
                System.debug(columnNumberInboundTransportRequested);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderAcquisitionDate))
            {
                columnNumberAcquisitionDate = i;
                System.debug(columnNumberAcquisitionDate);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderRetailReady))
            {
                columnNumberRetailReady = i;
                System.debug(columnNumberRetailReady);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderOutboundTransportRequested))
            {
                columnNumberOutboundTransportRequested = i;
                System.debug(columnNumberOutboundTransportRequested);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderProductionComplete))
            {
                columnNumberProductionComplete = i;
                System.debug(columnNumberProductionComplete);
            }
            // AMILLER1
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderConvMFG))
            {
                columnNumberConvMFG = i;
                System.debug(columnNumberConvMFG);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderConversionModel))
            {
                columnNumberConversionModel = i;
                System.debug(columnNumberConversionModel);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderMVRampType))
            {
                columnNumberMVRampType = i;
                System.debug(columnNumberMVRampType);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderMVRampOperation))
            {
                columnNumberMVRampOperation = i;
                System.debug(columnNumberMVRampOperation);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderFloorCut))
            {
                columnNumberFloorCut = i;
                System.debug(columnNumberFloorCut);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderConversion))
            {
                columnNumberConversion = i;
                System.debug(columnNumberConversion);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderKneeling))
            {
                columnNumberKneeling = i;
                System.debug(columnNumberKneeling);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderFeaturedVan))
            {
                columnNumberFeaturedVan = i;
                System.debug(columnNumberFeaturedVan);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderTracking))
            {
                columnNumberTracking = i;
                System.debug(columnNumberTracking);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderOdometer))
            {
                columnNumberOdometer = i;
                System.debug(columnNumberOdometer);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderRampLocation))
            {
                columnNumberRampLocation = i;
                System.debug(columnNumberRampLocation);
            }
            // AMILLER1
            // AMM4
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderConvMsrp))
            {
                columnNumberConvMsrp = i;
                System.debug(columnNumberConvMsrp);
            }
            if(listOfColumHeaders[i].equalsIgnoreCase(columnHeaderMsrp))
            {
                columnNumberMsrp = i;
                System.debug(columnNumberMsrp);
            }
            // AMM4
        }
    }           

    /**
    * InventoryItem
    *
    * Class which holds the CSV data in run time for 
    * evaluation before updating the system
    */
    global class InventoryItem {

		// BLL1
		// key can be stock# or VIN
		global String KEY {get;set;}
		global String STOCK {get;set;}
		// BLL1 end

        /** VIN - VIN of the vehicle in question, primary identifier */
        global String VIN {get;set;}

        /** inboundTransportRequested */
        global Date inboundTransportRequested {get;set;}

        /** outboundTransportRequested */
        global Date outboundTransportRequested {get;set;}

        /** acquisitionDate */
        global Date acquisitionDate {get;set;}

        /** retailReady */
        global Date retailReady {get;set;}

        /** productionComplete */
        global Date productionComplete {get;set;}

        // AMILLER1

        /** convMFG */
        global String convMFG {get;set;}

        /** conversionModel */
        global String conversionModel {get;set;}

        /** MVRampType */
        global String MVRampType {get;set;}

        /** MVRampOperation */
        global String MVRampOperation {get;set;}

        /** floorCut */
        global String floorCut {get;set;}

        /** conversion */
        global String conversion {get;set;}

        /** kneeling */
        global String kneeling {get;set;}

        /** featuredVan */
        global String featuredVan {get;set;}

        /** tracking */
        global String tracking {get;set;}

        /** odometer */
        global String odometer {get;set;}

        /** Ramp Location */
        global String rampLocation {get;set;}

        // AMILLER1
        // AMM4 
        /** Conversion MSRP */
        global Decimal convMSRP {get;set;}

        /** MSRP */
        global Decimal MSRP {get;set;}
        // AMM4

        /** vehicle */
        global dealer__Vehicle_Inventory__c vehicle {get;set;}

        /** errorReason */
        global String errorReason {get;set;}

        /** isFound */
        global Boolean isFound {get;set;}

        /** isDuplicate */
        global Boolean isDuplicate {get;set;}
        
        /** willUpdate */
        global Boolean willUpdate {get;set;}

        /** iconImage */
        global String iconImage {get;set;}

        global InventoryItem(){
            isDuplicate = false;
            isFound = false;
            willUpdate = false;
            errorReason = '';
        }
    }
}