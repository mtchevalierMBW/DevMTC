/**
* changeSalesOrderDivisionController
*
* MobilityWorks (c) - 2017
*
* A controller to handle changing the Division of a Sales Order Header
* in RootStock.
*
* Tested By: changeSalesOrderDivisionControllerTest
* Developer: Alexander Miller
* Date 11/15/2017
*
* Process Architecture:
* Using the SOAPI from RootStock, a new Sales Order is created with identical information
* except for the new Division. Then the Sales Order Line Items are copied over with the same
* information except for the new Division. Then the original Sales Order is marked as Canceled.
*
* Alexander Miller - AMILLER1 - 6/12/2018 - Patch to not name the new Sales Order with auto-number pivot in business process
* Alexander Miller - AMILLER2 - 6/29/2018 - Patch to prevent the inventory division error message when pulling over SO Lines (e.g. 7" EXPANDED METAL FULL PASSENGER STEP)
* Alexander Miller - AMILLER3 - 9/24/2018 - Update to handle the new Opportunity for TransitWorks
* Alexander Miller - AMILLER4 - 10/17/2018 - W-000457 - Update to handle removing the chassis reference on SO creation
*/
public class changeSalesOrderDivisionController {

    /** chosenDivision - the ID of the division chosen to switch to for the Sales Order */
    public static Id chosenDivision;

    /** divisionExternal - the acronym for the new division */
    public static String divisionExternal;

    /** chosenDivision - the select option value selected in the drop down */
    public static String chosenDivisionSelection {get;set;}

    /** chosenSalesOrder - visualforce connection for the value of the chosen Sales Order Header */
    public static String chosenSalesOrder {get;set;}

    /** autocompleteList - A comma seperated list of Sales Order Headers available in the system */
    public static String autocompleteList {get;set;}

    /** originalSalesOrder - global param to hold the original information for ease of copying */
    public static rstk__sohdr__c originalSalesOrder {get;set;}

    /** newSalesOrder - global param to hold the new information for ease of copying */
    public static rstk__sohdr__c newSalesOrder;

    /** insertHeaderOperationTag - string using RootStock's API key term to add a Sales Order Header */
    public static String insertHeaderOperationTag = 'Add Header';

    /** insertHeaderLinesOperationTag - string using RootStock's API key term to add a Sales Order Lines */
    public static String insertHeaderLinesOperationTag = 'Add Line';

    /** updateHeaderOperationTag - string using RootStock's API key term to update a Sales Order */
    public static String updateHeaderOperationTag = 'Change Header';

    /** deleteHeaderAndLinesOperationTag - string using RootStock's API key term to delete a Sales Order and all attached lines */
    public static String deleteHeaderAndLinesOperationTag = 'Delete Both';

    /** processingStatus - visualforce link showing the current status of the transfer process */
    public static String processingStatus {get;set;}

    /** statusUnprocessed - a static value to show no validations or transfers have started yet */
    public static String statusUnprocessed = 'Unprocessed';

    /** statusComplete - a static value to show it was trasnfered successfully */
    public static String statusComplete = 'Transfered';

    /** statusPendingValidation - a static value to show it is being processed for validation*/
    public static String statusPendingValidation = 'Pending Validation';

    /** statusFailedValidation- a static value to show it has fully failed validation tests */
    public static String statusFailedValidation = 'Failed Validation';
    
    /** statusPassedValidation - a static value to show it fully passed validation */
    public static String statusPassedValidation = 'Passed Validation';

    /** statusPassedValidation - a static value to show it partially passed validation and some lines can be transfered but not all */
    public static String statusPartiallyPassedValidation = 'Partiallly Passed Validation';

    /** canValidate - an internal flag to tell the visualforce page if the validation check button should be enabled */
    public static Boolean canValidate {get;set;}

    /** canTransfer - an internal flag to tell the visualforce page if the transfer button should be enabled */
    public static Boolean canTransfer {get;set;}

    /** canEnterNewName - an internal flag to tell the visualforce page if its possible to transfer and now we need a new name */
    public static Boolean canEnterNewName {get;set;}

    /** newSalesOrderName - A string containing the newly desired Sales Order Name */
    public static String newSalesOrderName {get;set;}

    /** nameApproved - an internal flag to tell the visualforce page if the new name has not been used yet */
    public static Boolean nameApproved {get;set;}

    /** nameApprovedImage - string containing the URL reference for the image desired to be shown next to the new name */
    public static String nameApprovedImage {get;set;}

    public static String urlId {get;set;}
    
    /** chosenSalesOrder - visualforce connection for the value of the chosen Sales Order Header */
    public static String testString {get;set;}

    public static List<rstk__soline__c> retrievedLineList {get;set;}

    public static List<productLineWrapper> listOfLineWrappers {get;set;}

    public changeSalesOrderDivisionController(){
        
        urlId = ApexPages.currentPage().getParameters().get('SOID');
        
        hideAll();

        generateSalesOrderNamesForAutocomplete();
        
        processingStatus = statusUnprocessed;

        if(!String.isEmpty(urlId))
        {
            generateChosenSalesOrderInfoFromInput();
        }
    }

    public static void run()
    {
        // Grab the original info
        if(originalSalesOrder == null)
        {
            originalSalesOrder = getOriginalSalesOrderInfo();
        }

        rstk__sydiv__c tempDiv = ([SELECT Id, 
                            Name 
                            FROM rstk__sydiv__c
                            WHERE Id = :chosenDivisionSelection LIMIT 1]);
        
        chosenDivision = tempDiv.Id;
        divisionExternal = tempDiv.Name.substring(tempDiv.Name.indexOf('(')+1, tempDiv.Name.indexOf(')')) + '_';

        // Create the new Sales Order Header 
        createNewSalesOrder();

        // Grag the new info
        newSalesOrder = getNewestSalesOrderInfo();

        // Copy over as much as possible from the last order
        updateNewHeaderWithOriginInfo(newSalesOrder, originalSalesOrder, tempDiv);

        // Copy all the Sales Order Lines
        createNewSalesOrderLines();
        
        // Cancel the original Sales Order
        try{
            cancelOriginalSalesOrder(); 
        } catch(Exception e)
        {
            System.debug(e.getMessage());
        }
    }

    /**
    * validate
    *
    * Function to check if all items
    * are available in the new division
    * before processing
    */
    public static void validate()
    {
        // 1. Get the origin Sales Order information for comparison
        if(originalSalesOrder == null)
        {
            originalSalesOrder = getOriginalSalesOrderInfo();
        }

        // 2. Get the origin Sales Order Lines information to be copied over
        retrievedLineList = getOriginalSalesOrderLinesInfo(originalSalesOrder);

        // 3. Get the counterpart products in the new division
        Map<Id, rstk__soprod__c> mapOfLinesToProducts = getCounterpartProducts(retrievedLineList);

        // 4. Build the mapping of wrapper objects for analysis
        listOfLineWrappers = generateMappingOfLinesToProducts(originalSalesOrder, retrievedLineList, mapOfLinesToProducts);

        // 5. Update the status and visualforce components based on what passed or didn't
        processingStatus = getListStatus(listOfLineWrappers);
    }

    /**
    * updateNewHeaderWithOriginInfo
    *
    * Function which will carry over the information over
    * from the old order to the new one
    */
    public static void updateNewHeaderWithOriginInfo(rstk__sohdr__c order, rstk__sohdr__c originalOrder, rstk__sydiv__c newDiv)
    {
        // update Order Type
        rstk__sootype__c tempNewType = [SELECT Id 
                                        FROM rstk__sootype__c 
                                        WHERE Name = :originalOrder.rstk__sohdr_otype__r.Name AND 
                                                    rstk__sootype_div__c = :newDiv.Id LIMIT 1];
        
        if(tempNewType != null )
        {
            order.rstk__sohdr_otype__c = tempNewType.Id;
        }

        // customer PO
        order.rstk__sohdr_custpo__c = originalOrder.rstk__sohdr_custpo__c;

        // internal, external comments
        order.rstk__sohdr_intcomment__c = originalOrder.rstk__sohdr_intcomment__c;
        order.rstk__sohdr_extcomment__c = originalOrder.rstk__sohdr_extcomment__c;

        // Custom Sales rep, Chassis, Floor Style, FTA
        order.Sales_Rep__c = originalOrder.Sales_Rep__c;
        order.Floor_Style__c = originalOrder.Floor_Style__c;
        // AMILLER4
        //order.Chassis__c = originalOrder.Chassis__c;
        // AMILLER4
        order.End_User__c = originalOrder.End_User__c;

        // Opportunity Info
        order.Opportunity__c = originalOrder.rstk__sohdr_opportunity__c != null ? originalOrder.rstk__sohdr_opportunity__c : originalOrder.Opportunity__c;
        // AMILLER3
        order.Opportunity_custom__c = originalOrder.Opportunity_custom__c != null ? originalOrder.Opportunity_custom__c : originalOrder.Opportunity__c;
        // AMILLER3

        update order;
    }

    /**
    * createNewSalesOrder
    *
    * a function copies all of the old information on the Sales Order Header
    * except for the Division and creates a new Sales Order Header
    */
    public static void createNewSalesOrder()
    {
        rstk__soapi__c newSO = new rstk__soapi__c(); 

        newSO.rstk__soapi_syusr__c = getLoggedInManufacturingUser().Id;         // Manufacturing user 
        // AMILLER1
        //newSO.rstk__soapi_orderno__c = newSalesOrderName;
        // AMILLER1
        newSO.rstk__soapi_ssysdiv__c = chosenDivision;                          // Sales division 
        newSO.rstk__soapi_isysdiv__c = chosenDivision;                          // Inventory division 
        newSO.rstk__soapi_socust__c = originalSalesOrder.rstk__sohdr_custno__c; // Customer 
        newSO.rstk__soapi_throwerrors__c = true;                                // Show errors, if any 
        newSO.rstk__soapi_mode__c = insertHeaderOperationTag;                   // Operation Choice

        insert newSO; 
    }

    /**
    * createNewSalesOrderLines
    *
    * a function copies all of the old information on the Sales Order Lines
    * except for the Division and creates a new Sales Order Header
    */
    public static void createNewSalesOrderLines()
    {
        retrievedLineList = getOriginalSalesOrderLinesInfo(originalSalesOrder);

        Map<Id, rstk__soprod__c> mapOfLinesToProducts = getCounterpartProducts(retrievedLineList);

        // Create the Sales Order Lines
        List<rstk__soapi__c> newLineList = new List<rstk__soapi__c>();

        for(rstk__soline__c tempSaleLine : retrievedLineList)
        {
            if(mapOfLinesToProducts.get(tempSaleLine.Id) != null)
            {
                rstk__soapi__c newSO = new rstk__soapi__c(); 
            
                newSO.rstk__soapi_sohdr__c = newSalesOrder.Id;                              // Sales Order Id reference
                newSO.rstk__soapi_socust__c = newSalesOrder.rstk__sohdr_custno__c;          // Customer
                newSO.rstk__soapi_ssysdiv__c = chosenDivision;                              // Division
                newSO.rstk__soapi_isysdiv__c = chosenDivision;                              // AMILLER2 - Inventory Division
                newSO.rstk__soapi_qtyorder__c = tempSaleLine.rstk__soline_qtyorder__c;      // Quantity Ordered
                newSO.rstk__soapi_soprod__c = mapOfLinesToProducts.get(tempSaleLine.Id).Id; // Product 
                newSO.rstk__soapi_mode__c = insertHeaderLinesOperationTag;                  // Operation Choice
                newSO.rstk__soapi_syusr__c = tempSaleLine.rstk__soline_resp__c;             // Maufacturing user
                newSO.rstk__soapi_duedate__c = tempSaleLine.rstk__soline_duedate__c;        // Due date
                newSO.rstk__soapi_line__c = tempSaleLine.rstk__soline_line__c;              // Line number
                newSO.rstk__soapi_price__c = tempSaleLine.rstk__soline_price__c;            // Unit price
                newSO.rstk__soapi_throwerrors__c = true;                                    // Show errors, if any

                newLineList.add(newSO);

                System.debug(newSO);
            }
            else
            {
                System.debug(tempSaleLine);
            }
        }

        // create the SOCONFIG records to power work order base
        List<rstk__soconfig__c> newSoConfigList = new List<rstk__soconfig__c>();
        List<rstk__soconfig__c> oldSoConfigList = ([SELECT Id,
                                                        Product_Master__c,
                                                        rstk__externalid__c,
                                                        rstk__soconfig_dmdline__c,
                                                        rstk__soconfig_soline__c,
                                                        rstk__soconfig_soline__r.rstk__soline_line__c,
                                                        rstk__soconfig_icitem__c,
                                                    	rstk__soconfig_icitem__r.rstk__externalid__c,
                                                        rstk__soconfig_icitem__r.Name,
                                                        rstk__soconfig_qtyper__c,
                                                        rstk__soconfig_fixedqty__c,
                                                        rstk__soconfig_setqty__c,
                                                        rstk__soconfig_oper__c,
                                                        rstk__soconfig_price__c,
                                                        rstk__soconfig_procno__c,
                                                        rstk__soconfig_procno__r.rstk__externalid__c,
                                                        rstk__soconfig_wctr__c,
                                                        rstk__soconfig_wctr__r.rstk__externalid__c,
                                                        rstk__soconfig_scppct__c,
                                                        rstk__soconfig_comment__c
                                                    FROM rstk__soconfig__c 
                                                    WHERE rstk__soconfig_soline__r.rstk__soline_sohdr__c = :originalSalesOrder.Id]);
        
        List<String> listOfItemExternalIds = new List<String>();
        List<String> listOfWorkCenterExternalIds = new List<String>();
        List<String> listOfProcessExternalIds = new List<String>();
        
        for(rstk__soconfig__c tempOldConfig : oldSoConfigList)
        {
            if(tempOldConfig.rstk__soconfig_icitem__c != null && tempOldConfig.rstk__soconfig_icitem__r.rstk__externalid__c != null)
            {
                listOfItemExternalIds.add(divisionExternal + tempOldConfig.rstk__soconfig_icitem__r.rstk__externalid__c.substringAfter('_'));
            }

            if(tempOldConfig.rstk__soconfig_wctr__r != null && tempOldConfig.rstk__soconfig_wctr__r.rstk__externalid__c != null)
            {
                listOfWorkCenterExternalIds.add(divisionExternal + tempOldConfig.rstk__soconfig_wctr__r.rstk__externalid__c.substringAfter('_'));
            }

            if(tempOldConfig.rstk__soconfig_procno__r != null && tempOldConfig.rstk__soconfig_procno__r.rstk__externalid__c != null)
            {
                listOfProcessExternalIds.add(divisionExternal + tempOldConfig.rstk__soconfig_procno__r.rstk__externalid__c.substringAfter('_'));
            }
        }
        
        List<rstk__icitem__c> listOfNewItems = ([SELECT Id,
                                                  rstk__externalid__c
                                                FROM rstk__icitem__c 
                                                WHERE rstk__externalid__c IN :listOfItemExternalIds]);
        
        Map<Id, Id> mapOfOldConfigToInventory = new Map<Id, Id>();
        
        for(rstk__soconfig__c tempOldConfig : oldSoConfigList)
        {
            for(rstk__icitem__c tempItem : listOfNewItems)
            {
                if(tempOldConfig.rstk__soconfig_icitem__r.rstk__externalid__c.substringAfter('_').equals(tempItem.rstk__externalid__c.substringAfter('_')))
            	{
                	mapOfOldConfigToInventory.put(tempOldConfig.Id,tempItem.Id);
           	 	}		
            }
		}

        List<rstk__rtwctr__c> listOfNewWorkCenters = ([SELECT Id,
                                                  rstk__externalid__c
                                                FROM rstk__rtwctr__c 
                                                WHERE rstk__externalid__c IN :listOfWorkCenterExternalIds]);
        
        Map<Id, Id> mapOfOldConfigToWorkCenter = new Map<Id, Id>();
        
        for(rstk__soconfig__c tempOldConfig : oldSoConfigList)
        {
            for(rstk__rtwctr__c tempWorkCenter : listOfNewWorkCenters)
            {
                if(tempOldConfig != null && tempWorkCenter != null && 
                    tempOldConfig.rstk__soconfig_wctr__c != null && 
                    tempOldConfig.rstk__soconfig_wctr__r.rstk__externalid__c != null && 
                    tempWorkCenter.rstk__externalid__c != null &&
                    tempOldConfig.rstk__soconfig_wctr__r.rstk__externalid__c.substringAfter('_').equals(tempWorkCenter.rstk__externalid__c.substringAfter('_')))
            	{
                	mapOfOldConfigToWorkCenter.put(tempOldConfig.Id,tempWorkCenter.Id);
           	 	}		
            }
		}

        List<rstk__rtproc__c> listOfNewProcesses = ([SELECT Id,
                                                  rstk__externalid__c
                                                FROM rstk__rtproc__c 
                                                WHERE rstk__externalid__c IN :listOfProcessExternalIds]);
        
        Map<Id, Id> mapOfOldConfigToProcess = new Map<Id, Id>();
        
        for(rstk__soconfig__c tempOldConfig : oldSoConfigList)
        {
            for(rstk__rtproc__c tempProcess : listOfNewProcesses)
            {
                if(tempOldConfig != null && tempProcess != null && 
                    tempOldConfig.rstk__soconfig_procno__c != null && 
                    tempOldConfig.rstk__soconfig_procno__r.rstk__externalid__c != null && 
                    tempProcess.rstk__externalid__c != null &&
                    tempOldConfig.rstk__soconfig_procno__r.rstk__externalid__c.substringAfter('_').equals(tempProcess.rstk__externalid__c.substringAfter('_')))
            	{
                	mapOfOldConfigToProcess.put(tempOldConfig.Id,tempProcess.Id);
           	 	}		
            }
		}

        Map<Decimal, List<rstk__soconfig__c>> mapOfSoConfigs = new Map<Decimal, List<rstk__soconfig__c>>();

        Boolean shouldStop = false;

        for(rstk__soconfig__c tempConfig : oldSoConfigList)
        {
            if(mapOfSoConfigs.get(tempConfig.rstk__soconfig_soline__r.rstk__soline_line__c) == null)
            {
                mapOfSoConfigs.put(tempConfig.rstk__soconfig_soline__r.rstk__soline_line__c, new List<rstk__soconfig__c>());
            }

            // Create SOCONFIG records so the Work Order will generate pick list
            rstk__soconfig__c tempNewConfig = new rstk__soconfig__c();

            // This needs an ID and will be set in the batch
            tempNewConfig.rstk__soconfig_icitem__c = mapOfOldConfigToInventory.get(tempConfig.Id);                                              // Inventory Item
            
            if(mapOfOldConfigToInventory.get(tempConfig.Id) == null)
            {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Inventory Item does not exist in new division for SOCONFIG record ' + tempConfig.Id + '. Inventory Name: ' + tempConfig.rstk__soconfig_icitem__r.Name + '. Please contact ithelp@mobilityworks.com to proceed further.'));
                shouldStop = true;
            }

            //tempNewConfig.rstk__soconfig_dmdline__c  = tempConfig.rstk__soconfig_dmdline__c;                                                    // WO Demand Line Number
            tempNewConfig.rstk__soconfig_qtyper__c = tempConfig.rstk__soconfig_qtyper__c;                                                       // qty per
            tempNewConfig.rstk__soconfig_fixedqty__c = tempConfig.rstk__soconfig_fixedqty__c;                                                   // fixed qty
            tempNewConfig.rstk__soconfig_setqty__c = tempConfig.rstk__soconfig_setqty__c;                                                       // setup qty
            tempNewConfig.rstk__soconfig_oper__c = tempConfig.rstk__soconfig_oper__c;                                                           // operation
            tempNewConfig.rstk__soconfig_price__c = tempConfig.rstk__soconfig_price__c;                                                         // price
            tempNewConfig.rstk__soconfig_procno__c = mapOfOldConfigToProcess.get(tempConfig.Id);                                                // process master id
            tempNewConfig.rstk__soconfig_wctr__c = mapOfOldConfigToWorkCenter.get(tempConfig.Id);                                               // work center id
            tempNewConfig.rstk__soconfig_scppct__c = tempConfig.rstk__soconfig_scppct__c;                                                       // scrap factor
            tempNewConfig.rstk__soconfig_comment__c = 'Generated using the division change tool';                                               // comment
            tempNewConfig.Product_Master__c = tempConfig.Product_Master__c != null ? tempConfig.Product_Master__c : null;
			
            System.debug(tempNewConfig);
            
            mapOfSoConfigs.get(tempConfig.rstk__soconfig_soline__r.rstk__soline_line__c).add(tempNewConfig);
            newSoConfigList.add(tempNewConfig);
        }	

        // set up the Sales Order Labor Operation records
        List<rstk__sortoper__c> listOfOldSalesOps = ([SELECT Id,
                                                        Product_Master__c,
                                                        rstk__sortoper_soline__c,                   // Sales Order Line
                                                        rstk__sortoper_soline__r.rstk__soline_line__c, // line number
                                                        rstk__sortoper_type_pl__c,                  // Operation
                                                        rstk__sortoper_procno__c,                   // Process Number
                                                        rstk__sortoper_procno__r.rstk__externalid__c,
                                                        rstk__sortoper_wctr__c,                     // Work Center
                                                        rstk__sortoper_wctr__r.rstk__externalid__c,
                                                      	rstk__sortoper_runlabgrd__c,				// Run Labor Grade
                                                        rstk__sortoper_runlabgrd__r.rstk__externalid__c,
                                                      	rstk__sortoper_runhr__c,					// Run Standard Hours
                                                        rstk__sortoper_oper__c,                     // Operation Number
                                                        rstk__sortoper_descr__c,                    // Description
                                                        rstk__sortoper_setuptype_pl__c,             // Setup Time Type
                                                        rstk__sortoper_runtype_pl__c,               // Run Time Type
                                                        rstk__sortoper_price__c,                    // Sales Price Per Hour
                                                        rstk__sortoper_assignedto__c,               // Assigned To
                                                        rstk__sortoper_machtype_pl__c,              // Machine Type
                                                        rstk__sortoper_labonlyind__c,               // Labor Only Operation
                                                        rstk__sortoper_allowaccind__c,              // Allow Accept,
                                                        rstk__sortoper_movehr__c,                   // Move Hours
                                                        rstk__sortoper_labmachschtype_pl__c,        // Schedule Type
                                                        rstk__sortoper_movcompind_pl__c,            // Move/Complete
                                                        rstk__sortoper_subltdays__c,                // Subcontract Lead Time
                                                        rstk__sortoper_scrapfactor__c,              // Scrap Factor
                                                        rstk__sortoper_stddivideby__c,              // Run Hours Divided By
                                                        rstk__sortoper_altcode__c                   // Alternate Code
                                                    FROM rstk__sortoper__c  
                                                    WHERE rstk__sortoper_soline__r.rstk__soline_sohdr__c = :originalSalesOrder.Id]);
        
        System.debug('listOfOldSalesOps size: ' + listOfOldSalesOps.size());
        
        List<String> listOfNewProcessesLabor = new List<String>();
        List<String> listOfNewWorkCentersLabor = new List<String>();
        List<String> listOfNewLaborGrades = new List<String>();

        for(rstk__sortoper__c laborOp : listOfOldSalesOps)
        {
            listOfNewProcessesLabor.add(divisionExternal + laborOp.rstk__sortoper_procno__r.rstk__externalid__c.substringAfter('_'));
            listOfNewWorkCentersLabor.add(divisionExternal + laborOp.rstk__sortoper_wctr__r.rstk__externalid__c.substringAfter('_'));
            listOfNewLaborGrades.add(divisionExternal + laborOp.rstk__sortoper_runlabgrd__r.rstk__externalid__c.substringAfter('_'));
        }

        List<rstk__rtproc__c> listOfNewProcessesLaborQuery = ([SELECT Id,
                                                  rstk__externalid__c
                                                FROM rstk__rtproc__c 
                                                WHERE rstk__externalid__c IN :listOfNewProcessesLabor]);
        
        List<rstk__rtwctr__c> listOfNewWorkCentersQuery = ([SELECT Id,
                                                  rstk__externalid__c
                                                FROM rstk__rtwctr__c 
                                                WHERE rstk__externalid__c IN :listOfNewWorkCentersLabor]);
       
        List<rstk__rtlabgrd__c> listOfNewLaborGradeQuery = ([SELECT Id,
                                                  rstk__externalid__c
                                                FROM rstk__rtlabgrd__c 
                                                WHERE rstk__externalid__c IN :listOfNewLaborGrades]);

        Map<Id, Id> mapOfOldProcesses = new Map<Id, Id>();
        Map<Id, Id> mapOfOldWorkCenters = new Map<Id, Id>();
        Map<Id, Id> mapOfOldRunLaborGrades = new Map<Id, Id>();

        for(rstk__sortoper__c tempOldLab : listOfOldSalesOps)
        {
            for(rstk__rtproc__c tempProcess : listOfNewProcessesLaborQuery)
            {
                if(tempOldLab != null && tempProcess != null && 
                    tempOldLab.rstk__sortoper_procno__c != null && 
                    tempOldLab.rstk__sortoper_procno__r.rstk__externalid__c != null && 
                    tempProcess.rstk__externalid__c != null &&
                    tempOldLab.rstk__sortoper_procno__r.rstk__externalid__c.substringAfter('_').equals(tempProcess.rstk__externalid__c.substringAfter('_')))
            	{
                	mapOfOldProcesses.put(tempOldLab.Id,tempProcess.Id);
           	 	}		
            }

            for(rstk__rtwctr__c tempWorkCenter : listOfNewWorkCentersQuery)
            {
                if(tempOldLab != null && tempWorkCenter != null && 
                    tempOldLab.rstk__sortoper_wctr__c != null && 
                    tempOldLab.rstk__sortoper_wctr__r.rstk__externalid__c != null && 
                    tempWorkCenter.rstk__externalid__c != null &&
                    tempOldLab.rstk__sortoper_wctr__r.rstk__externalid__c.substringAfter('_').equals(tempWorkCenter.rstk__externalid__c.substringAfter('_')))
            	{
                	mapOfOldWorkCenters.put(tempOldLab.Id,tempWorkCenter.Id);
           	 	}		
            }
            
            for(rstk__rtlabgrd__c tempLaborGrade : listOfNewLaborGradeQuery)
            {
                if(tempOldLab != null && tempLaborGrade != null && 
                    tempOldLab.rstk__sortoper_runlabgrd__c != null && 
                    tempOldLab.rstk__sortoper_runlabgrd__r.rstk__externalid__c != null && 
                    tempLaborGrade.rstk__externalid__c != null &&
                    tempOldLab.rstk__sortoper_runlabgrd__r.rstk__externalid__c.substringAfter('_').equals(tempLaborGrade.rstk__externalid__c.substringAfter('_')))
            	{
                	mapOfOldRunLaborGrades.put(tempOldLab.Id,tempLaborGrade.Id);
           	 	}		
            }
		}

        Map<Decimal, List<rstk__sortoper__c>> mapOfNewSOLaborOps = new Map<Decimal, List<rstk__sortoper__c>>();

        for(rstk__sortoper__c tempOldLab : listOfOldSalesOps)
        {
            if(mapOfNewSOLaborOps.get(tempOldLab.rstk__sortoper_soline__r.rstk__soline_line__c) == null)
            {
                mapOfNewSOLaborOps.put(tempOldLab.rstk__sortoper_soline__r.rstk__soline_line__c, new List<rstk__sortoper__c>());
            }

            // Create SOCONFIG records so the Work Order will generate pick list
            rstk__sortoper__c tempNewSOLaborOp = new rstk__sortoper__c();

            tempNewSOLaborOp.rstk__sortoper_type_pl__c = tempOldLab.rstk__sortoper_type_pl__c;                      // Operation
            tempNewSOLaborOp.rstk__sortoper_procno__c = mapOfOldProcesses.get(tempOldLab.Id);                       // Process Number
            tempNewSOLaborOp.rstk__sortoper_wctr__c = mapOfOldWorkCenters.get(tempOldLab.Id);                       // Work Center
            tempNewSOLaborOp.rstk__sortoper_runlabgrd__c = mapOfOldRunLaborGrades.get(tempOldLab.Id);               // Run Labor Grade
            tempNewSOLaborOp.rstk__sortoper_runhr__c = tempOldLab.rstk__sortoper_runhr__c;							// Run Hours, Standard
            tempNewSOLaborOp.rstk__sortoper_oper__c = tempOldLab.rstk__sortoper_oper__c;                            // Operation Number
            tempNewSOLaborOp.rstk__sortoper_descr__c = tempOldLab.rstk__sortoper_descr__c;                          // Description
            tempNewSOLaborOp.rstk__sortoper_setuptype_pl__c = tempOldLab.rstk__sortoper_setuptype_pl__c;            // Setup Time Type
            tempNewSOLaborOp.rstk__sortoper_runtype_pl__c = tempOldLab.rstk__sortoper_runtype_pl__c;                // Run Time Type
            tempNewSOLaborOp.rstk__sortoper_price__c = tempOldLab.rstk__sortoper_price__c;                          // Sales Price Per Hour
            tempNewSOLaborOp.rstk__sortoper_assignedto__c = tempOldLab.rstk__sortoper_assignedto__c;                // Assigned To
            tempNewSOLaborOp.rstk__sortoper_machtype_pl__c = tempOldLab.rstk__sortoper_machtype_pl__c;              // Machine Type
            tempNewSOLaborOp.rstk__sortoper_labonlyind__c = tempOldLab.rstk__sortoper_labonlyind__c;                // Labor Only Operation
            tempNewSOLaborOp.rstk__sortoper_allowaccind__c = tempOldLab.rstk__sortoper_allowaccind__c;              // Allow Accept,
            tempNewSOLaborOp.rstk__sortoper_movehr__c = tempOldLab.rstk__sortoper_movehr__c;                        // Move Hours
            tempNewSOLaborOp.rstk__sortoper_labmachschtype_pl__c = tempOldLab.rstk__sortoper_labmachschtype_pl__c;  // Schedule Type
            tempNewSOLaborOp.rstk__sortoper_movcompind_pl__c = tempOldLab.rstk__sortoper_movcompind_pl__c;          // Move/Complete
            tempNewSOLaborOp.rstk__sortoper_subltdays__c = tempOldLab.rstk__sortoper_subltdays__c;                  // Subcontract Lead Time
            tempNewSOLaborOp.rstk__sortoper_scrapfactor__c = tempOldLab.rstk__sortoper_scrapfactor__c;              // Scrap Factor
            tempNewSOLaborOp.rstk__sortoper_stddivideby__c = tempOldLab.rstk__sortoper_stddivideby__c;              // Run Hours Divided By
            tempNewSOLaborOp.rstk__sortoper_altcode__c = tempOldLab.rstk__sortoper_altcode__c;                      // Alternate Code
            tempNewSOLaborOp.Product_Master__c = tempOldLab.Product_Master__c != null ? tempOldLab.Product_Master__c : null;
            
            mapOfNewSOLaborOps.get(tempOldLab.rstk__sortoper_soline__r.rstk__soline_line__c).add(tempNewSOLaborOp);
        }
        
        System.debug('mapOfNewSOLaborOps size: ' + mapOfNewSOLaborOps.size());

        // call async batch class to avoid SF limits
        if(!shouldStop)
        {
            changeSODivisionLineBatch tempBatch = new changeSODivisionLineBatch(); 
            tempBatch.setData(newLineList, retrievedLineList, mapOfSoConfigs, originalSalesOrder.Id, newSalesOrder.Id, mapOfNewSOLaborOps, UserInfo.getUserId(),newSalesOrder.Name);  
            database.executeBatch(tempBatch, 1); 
        }  
    }

    /**
    * cancelOriginalSalesOrder
    *
    * a function which takes the old Sales Order Id and updates it to a canceled status
    */
    public static void cancelOriginalSalesOrder()
    {
        rstk__soapi__c updateSO = new rstk__soapi__c(); 
         
        updateSO.rstk__soapi_sohdr__c = originalSalesOrder.Id;   // Sales Order Id reference
        updateSO.rstk__soapi_mode__c = updateHeaderOperationTag; // Operation Choice
        updateSO.rstk__soapi_cancelled__c = true;                // Canceled
        updateSO.rstk__soapi_throwerrors__c = true;              // Show errors, if any 

        insert updateSO;
    }

    /**
    * deleteOriginalSalesOrder
    *
    * a function which takes the old Sales Order Id and deletes it
    */
    public static void deleteOriginalSalesOrder()
    {
        rstk__soapi__c updateSO = new rstk__soapi__c(); 
        
        updateSO.rstk__soapi_ssysdiv__c = originalSalesOrder.rstk__sohdr_div__c;    // Sales division 
        updateSO.rstk__soapi_isysdiv__c = originalSalesOrder.rstk__sohdr_div__c;    // Inventory division 
        updateSO.rstk__soapi_socust__c = originalSalesOrder.rstk__sohdr_custno__c;  // Customer 
        updateSO.rstk__soapi_sohdr__c = originalSalesOrder.Id;                      // Sales Order Id reference
        updateSO.rstk__soapi_mode__c = deleteHeaderAndLinesOperationTag;            // Operation Choice
        updateSO.rstk__soapi_throwerrors__c = true;                                 // Show errors, if any 

        insert updateSO;
    }

    /**
    * getLoggedInManufacturingUser
    *
    * a function which looks at the logged in user and returns the Manufacturing user associated with it
    */
    public static rstk__syusr__c getLoggedInManufacturingUser()
    {
        return ([SELECT Id 
                FROM rstk__syusr__c 
                WHERE rstk__syusr_employee__c = :UserInfo.getUserId()]);
    }

    /**
    * getOriginalSalesOrderInfo
    *
    * a function which looks at the logged in user and returns the Manufacturing user associated with it
    */
    public static rstk__sohdr__c getOriginalSalesOrderInfo()
    {
        if(chosenSalesOrder != null && chosenSalesOrder != '')
        {
            return ([SELECT Id, 
                        Name,
                        rstk__sohdr_opportunity__c,                                     // Opportunity
                        Opportunity__c,                                                 // Opportunity (custom)
                        // AMILLER3
                        Opportunity_custom__c,
                        Opportunity__r.Opportunity__c,
                        rstk__sohdr_opportunity__r.Opportunity__c,
                        // AMILLER3
                        rstk__sohdr_custno__c,                                          // Sales Order Customer
                        rstk__sohdr_div__c,                                             // Division
                        rstk__sohdr_orderdate__c,                                       // Order Date
                        rstk__sohdr_custpo__c,                                          // Customer PO
                        rstk__sohdr_intcomment__c,                                      // internal comment
                        rstk__sohdr_extcomment__c,                                      // external comment
                        rstk__sohdr_otype__c,                                           // Order Type
                        rstk__sohdr_otype__r.Name,                                      // Order Type Name
                        Chassis__c,                                                     // Chassis
                        Sales_Rep__c,                                                   // Sales Rep
                        Floor_Style__c,                                                 // Floor Style
                        rstk__sohdr_div__r.rstk__sydiv_div__c,
                        End_User__c
                FROM rstk__sohdr__c 
                WHERE Name = :chosenSalesOrder 
                LIMIT 1]);
        }
        else if(urlId != null && urlId != '')
        {
            return ([SELECT Id, 
                        Name,
                        rstk__sohdr_custno__c, // Sales Order Customer
                        rstk__sohdr_div__c,     // Division
                        rstk__sohdr_div__r.rstk__sydiv_div__c
                FROM rstk__sohdr__c 
                WHERE Id = :urlId 
                LIMIT 1]);
        }
        else
        {
            return ([SELECT Id, 
                        Name,
                        rstk__sohdr_custno__c, // Sales Order Customer
                        rstk__sohdr_div__c,     // Division
                        rstk__sohdr_div__r.rstk__sydiv_div__c
                FROM rstk__sohdr__c 
                WHERE Id = :originalSalesOrder.Id 
                LIMIT 1]);
        }
        
    }

    /**
    * getOriginalSalesOrderLinesInfo
    *
    * a function which looks at the logged in user and returns the Manufacturing user associated with it
    */
    public static List<rstk__soline__c> getOriginalSalesOrderLinesInfo(rstk__sohdr__c tempOriginalSalesOrder)
    {                
        return ([SELECT Id, 
                    rstk__soline_qtyorder__c, // Quantity Ordered
                    rstk__soline_prod__c,     // Product
                    rstk__soline_prod__r.rstk__externalid__c, // product external id
                    rstk__soline_prod__r.Name,
                    rstk__soline_prod__r.rstk__soprod_prodtype__c,
                    rstk__soline_prod__r.rstk__soprod_div__c,
                    rstk__soline_prod__r.rstk__soprod_div__r.Name,
                    rstk__soline_resp__c,     // Responsible User
                    rstk__soline_duedate__c,  // Due Date
                    rstk__soline_line__c,     // Line Number
                    rstk__soline_sohdr__r.rstk__sohdr_div__c,
                    rstk__soline_price__c     // Unit Price
                FROM rstk__soline__c 
                WHERE rstk__soline_sohdr__c = :tempOriginalSalesOrder.Id]);
    }

    /**
    * getCounterpartProducts
    *
    * Function which takes the external ID of the product in the 
    * original division and searches for the same part in the next
    * division
    */
    public static Map<Id, rstk__soprod__c> getCounterpartProducts(List<rstk__soline__c> listOflines)
    {
        List<String> listOfExternalIds = new List<String>();

        System.debug(divisionExternal);

        for(rstk__soline__c temp : listOflines)
        {
            String tempString = divisionExternal + temp.rstk__soline_prod__r.rstk__externalid__c.substring(3,temp.rstk__soline_prod__r.rstk__externalid__c.length());

            System.debug(tempString);

            listOfExternalIds.add(tempString);
        }

        List<rstk__soprod__c> listOfProductsInNewDivision = ([SELECT Id,
                                                                Name, 
                                                                rstk__externalid__c,
                                                                rstk__soprod_div__c,
                                                                rstk__soprod_div__r.Name,
                                                                rstk__soprod_prodtype__c
                                                            FROM rstk__soprod__c 
                                                            WHERE rstk__externalid__c IN :listOfExternalIds AND
                                                            rstk__soprod_div__c = :chosenDivision]);
        
        Map<Id, rstk__soprod__c> mapOfOldToNewProducts = new Map<Id, rstk__soprod__c>();

        for(rstk__soline__c temp : listOflines)
        {
            String tempString = temp.rstk__soline_prod__r.rstk__externalid__c.substring(3,temp.rstk__soline_prod__r.rstk__externalid__c.length());

            for(rstk__soprod__c tempProduct : listOfProductsInNewDivision)
            {
                String tempProductString = tempProduct.rstk__externalid__c.substring(3,tempProduct.rstk__externalid__c.length());

                if(tempProductString.equalsIgnoreCase(tempString))
                {
                    mapOfOldToNewProducts.put(temp.Id, tempProduct);
                }
            }
        }

        return mapOfOldToNewProducts;
    }

    /**
    * getLoggedInManufacturingUser
    *
    * a function which looks at the logged in user and returns the Manufacturing user associated with it
    */
    public static rstk__sohdr__c getNewestSalesOrderInfo()
    {
        return ([SELECT Id,
                    rstk__sohdr_opportunity__c,
                 	Name,
                    CreatedDate,
                    // AMILLER3
                    Opportunity_custom__c,
                    Opportunity__r.Opportunity__c,
                    rstk__sohdr_opportunity__r.Opportunity__c,
                    // AMILLER3
                    End_User__c,
                    rstk__sohdr_custno__c // Customer
                FROM rstk__sohdr__c 
                WHERE CreatedById = :UserInfo.getUserId()
                ORDER BY CreatedDate DESC LIMIT 1]);
    }

    /**
    * generateSalesOrderNamesForAutocomplete
    *
    * A query used to figure out all of the current Sales Order
    * Headers in the system and then show them in a suggestion
    * dropdown
    */
    public static void generateSalesOrderNamesForAutocomplete()
    {
        List<rstk__sohdr__c> listOfSalesOrders = ([SELECT Id,
                                                        Name
                                                    FROM rstk__sohdr__c ]);
        
        for(rstk__sohdr__c tempSalesOrder : listOfSalesOrders)
        {
            autocompleteList += tempSalesOrder.Name + ',';
        }
    }

    /**
    * divisonList
    *
    * Function which queries the system
    * for al Divisons available. Does not 
    * figure out if the order is able to move 
    * to the listed division
    */
    public static List<SelectOption> divisonList
    {
        get
        {
            if(divisonList == null)
            {
                divisonList = new List<SelectOption>();
            }

            divisonList.clear();

             List<rstk__sydiv__c> listOfDivisions = new List<rstk__sydiv__c>();

            if(originalSalesOrder == null)
            {

                listOfDivisions = ([SELECT Id, 
                                        Name 
                                    FROM rstk__sydiv__c
                                    ORDER BY Name ASC]);
            }
            else
            {
                listOfDivisions = ([SELECT Id,
                                        Name
                                    FROM rstk__sydiv__c
                                    WHERE Id != :originalSalesOrder.rstk__sohdr_div__c
                                    ORDER BY Name ASC]);
            }

            for(rstk__sydiv__c tempDiv : listOfDivisions)
            {
                divisonList.add(new SelectOption(tempDiv.Id, tempDiv.Name));
            }

            return divisonList;
        }
        set;
    }

    /**
    * generateChosenSalesOrderInfoFromInput
    *
    * Function which takes the chosen Sales Order
    * in the text field
    */
    public static void generateChosenSalesOrderInfoFromInput()
    {
        if(chosenSalesOrder == null || String.isEmpty(chosenSalesOrder))
        {
            chosenSalesOrder = getOriginalSalesOrderInfo().Name; 
        }

        canValidate = false;

        chosenSalesOrder = chosenSalesOrder.trim();
        
        originalSalesOrder = ([SELECT Id,
                Name,
                rstk__sohdr_div__r.Name,
                rstk__sohdr_custno__c, // Sales Order Customer
                rstk__sohdr_div__c,     // Division
                rstk__sohdr_div__r.rstk__sydiv_div__c,
                // AMILLER3
                Opportunity_custom__c,
                Opportunity__r.Opportunity__c,
                rstk__sohdr_opportunity__r.Opportunity__c
                // AMILLER3
            FROM rstk__sohdr__c 
            WHERE Name = :chosenSalesOrder LIMIT 1]);
    }

    /**
    * generateMappingOfLinesToProducts
    *
    * Function to take all of the Sales Order Header, Sales Order Line,
    * and Product Master information found into one object for simplified
    * loading into the datatable
    *
    * 
    */
    public static List<productLineWrapper> generateMappingOfLinesToProducts(rstk__sohdr__c tempOriginHeader, List<rstk__soline__c> listOfLines, Map<Id, rstk__soprod__c> mapOfLinesToProductsTemp)
    {   
        List<productLineWrapper> listOfWrappers = new List<productLineWrapper>();

        for(rstk__soline__c tempLine : listOfLines)
        {
            productLineWrapper tempWrapper = new productLineWrapper();

            tempWrapper.soLine = tempLine;
            tempWrapper.oldProduct = new rstk__soprod__c(Id=tempLine.rstk__soline_prod__c, 
                                                        Name = tempLine.rstk__soline_prod__r.Name,
                                                        rstk__soprod_div__c = tempLine.rstk__soline_prod__r.rstk__soprod_div__c,
                                                        rstk__externalid__c = tempLine.rstk__soline_prod__r.rstk__externalid__c,
                                                        rstk__soprod_prodtype__c = tempLine.rstk__soline_prod__r.rstk__soprod_prodtype__c);
            
            tempWrapper.oldProductDivisionName = tempLine.rstk__soline_prod__r.rstk__soprod_div__r.Name;

            if(mapOfLinesToProductsTemp.get(tempLine.Id) == null)
            {
                tempWrapper.existsInNewDivision = false;
            }
            else
            {
                tempWrapper.newProduct = mapOfLinesToProductsTemp.get(tempLine.Id);
                tempWrapper.existsInNewDivision = true;
            }

            listOfWrappers.add(tempWrapper);
        }

        return listOfWrappers;
    }

    /**
    * getListStatus
    *
    * Function to evalute the "goodness" of the list shown in the validation
    */
    public static String getListStatus(List<productLineWrapper> tempList)
    {
        Integer passedCount = 0;

        for(productLineWrapper tempWrap : tempList)
        {
            if(tempWrap.existsInNewDivision)
            {
                passedCount++;
            }
        }

        if(passedCount == 0)
        {
            return statusFailedValidation;
        }
        else if(passedCount > 0 && passedCount != tempList.size())
        {
            canEnterNewName = true;
            //if(nameApproved != null && !nameApproved)
             canTransfer = true;
            return statusPartiallyPassedValidation;
        }
        else
        {
            canEnterNewName = true;
            //if(nameApproved != null && !nameApproved)
            canTransfer = true;
            return statusPassedValidation;
        }
    }

    /**
    * isNameAvailable
    * 
    * Function which helps figure out if the new name
    * param is already used in the system
    */
    public static PageReference isNameAvailable()
    {
        System.debug('fired');

        List<rstk__sohdr__c> tempList = ([SELECT Id 
                                            FROM rstk__sohdr__c 
                                            WHERE Name = :newSalesOrderName]);

        resetValidation();

        if(tempList.size() == 0)
        {
            System.debug('true');

            nameApproved = true;
            nameApprovedImage = '/img/msg_icons/confirm16.png';
            canTransfer = false;
        }
        else
        {
            System.debug('false');

            nameApproved = false;
            nameApprovedImage = '/img/msg_icons/error16.png';
            canTransfer = true;
        }


        System.debug(canTransfer);

        return null;
    }

    /** 
    * resetValidation
    *
    * In the event that the division dropdown changes
    * this function should fire in order to reset everything
    * and show a new list of products in the newly selected
    * division.
    */
    public static void resetValidation()
    {

        hideAll();

        generateSalesOrderNamesForAutocomplete();
        
        processingStatus = statusUnprocessed;

        generateChosenSalesOrderInfoFromInput();

        rstk__sydiv__c tempDiv = ([SELECT Id, 
                            Name 
                            FROM rstk__sydiv__c
                            WHERE Id = :chosenDivisionSelection LIMIT 1]);

        // 1. Get the characters between the ()
        chosenDivision = tempDiv.Id;
        divisionExternal = tempDiv.Name.substring(tempDiv.Name.indexOf('(')+1, tempDiv.Name.indexOf(')')) + '_';

        // 2. Get the origin Sales Order Lines information to be copied over
        retrievedLineList = getOriginalSalesOrderLinesInfo(originalSalesOrder);

        // 2. Refresh the list
        Map<Id, rstk__soprod__c> mapOfLinesToProducts = getCounterpartProducts(retrievedLineList);

        // 4. Build the mapping of wrapper objects for analysis
        listOfLineWrappers = generateMappingOfLinesToProducts(originalSalesOrder, retrievedLineList, mapOfLinesToProducts);

        // 5. Update the status and visualforce components based on what passed or didn't
        processingStatus = getListStatus(listOfLineWrappers);
    }

    /**
    * hideAll
    *
    * Function which sets all of the internal flags 
    * to hide the UI components on the Visualforce page
    */
    public static void hideAll()
    {
        canTransfer = true;
        canValidate = true;
        canEnterNewName= false;
    }

    public class productLineWrapper{

        /** existsInNewDivision - internal flag to track if its even possible to transfer this line to the new division */
        public Boolean existsInNewDivision {get;set;}
        
        /** toBeTransferred - checkbox on table to know if this line should be transferred  */
        public Boolean toBeTransferred {get;set;}

        /** soLine - original Sales Order Line found in the old division's Sales Order Header */
        public rstk__soline__c soLine {get;set;}

        /** oldProduct - the product found on the original Sales Order Line */
        public rstk__soprod__c oldProduct {get;set;}

        /** oldProductDivisionName - String to contain the original Product's division name */
        public String oldProductDivisionName {get;set;}

        /** newProduct - the product in the new division, if it was found */
        public rstk__soprod__c newProduct {get;set;}

        public productLineWrapper(){}
    }
}