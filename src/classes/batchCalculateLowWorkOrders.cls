/**
* MobilityWorks (c) - 2017
*
* batchCalculateLowWorkOrders 
* Date: September 8th, 2017
* Programmer: Alexander Miller
*
* A batch class which cycles through all of the Work Orders for TransitWorks Accounts
* and figures out projected gross profits.
*
* File Structure:
* 
* 1. Info
* 2. Global Params
* 3. Salesforce batch operation (main)
* 4. Helper queries
* 5. Utility methods
*
* Architecture Model:
* 
* - Material (Non-Chassis Inventory):
* 
*   Work Order |
*              |
*               - Work Order Component | [rstk__woorddmd_qtyreq__c (Qty Required)]
*                                      |
*                                      |
*                                       - Inventory Item Master |
*                                                               |
*                                                               |
*                                                               - Inventory Item Cost/Qty | [rstk__icitemcst_lstactucsttot__c (Last Avg Unit Cost, Total)]
*
* - Material (Chassis or Conversion Only):
*     Work Order |
*                |
*                - Work Order Component | [rstk__woorddmd_qtyreq__c (Qty Required)]
*                                       |
*                                       - Work Order Project |
*                                                            |
*                                                            - Purchase Order |
*                                                                             |
*                                                                             - PO Line | [rstk__poline_unitprice__c (Unit Price)]
*
* - Material Overhead:
*    Work Order |
*               |
*               - 
*
*               
*
* - Labor:
*
*   Work Order |
*              |
*               - Work Order Operation Schedule | [rstk__wopsch_oper__c (Operation Number)]
*               |                               |
*               |                               |
*               |                               - Work Order Operation | [rstk__woordop_runhrstd__c (Run Standard Hours)]
*               |                                                      |
*               |                                                      |
*               |                                                      - Labor Grade | [rstk__rtlabgrd_price__c (Sales Price Per Hour)]
*               |
*               - [Assigned To = Manufacturing User]
*
* - Fringe/Labor Ohd:
*
*   Work Order |
*              |
*               - Work Order Operation |
*                                      |
*                                      |
*                                      Work Center |
*                                                  |
*                                                   - Mfg Department (Std Ohd Rate, Labor & Std Ohd Rate, Fringe)

*
* Overhead Note: If the Manufacturing User has either checkbox selected, then you must use their personal rate 
*                times the hour times the std overhead rate of labor and/or fringe.
* 
*               Example:
*               Labor checkbox selected, personal rate $18.69 hour, Std Labor Overhead $0.30, 1 hour labor = (18.69 * 1) + (1 * 0.30) = $18.99
*/
global class batchCalculateLowWorkOrders implements Database.Batchable<sObject>, Schedulable, Database.Stateful{

    /** cellTotal - Integer defining the cell which contains the total cost value of a given work order */
    Integer cellTotal = 0;

    /** cellLabor - Integer defining the cell which contains the total labor cost value of a given work order */
    Integer cellLabor = 1;
    
    /** cellMaterial - Integer defining the cell which contains the total material cost value of a given work order */
    Integer cellMaterial = 2;

    /** cellLabor - Integer defining the cell which contains the total labor overhead cost value of a given work order */
    Integer cellOhdLabor = 3;

    /** cellLabor - Integer defining the cell which contains the total overhead fringe cost value of a given work order */
    Integer cellOhdFringe = 4;

    /** foundSales - String containing all of the found work order sales and how they'll be shown as rows in a table*/
    global String foundSales;

    /** purchasedChassisIdentifier - String containing the universal catch-all for purchased vehicles */
    global String purchasedChassisIdentifier = 'Purchased';

    /** purchasedChassisIdentifier - String containing the universal catch-all for purchased vehicles */
    global String purchasedChassisIdentifierQuery = '%Purchased%';

    /** purchasedChassisIdentifier - String containing the universal catch-all for purchased vehicles */
    global String conversionChassisIdentifier = 'Conversion';

    /** purchasedChassisIdentifier - String containing the universal catch-all for purchased vehicles */
    global String conversionChassisIdentifierQuery = '%Conversion%';

    public batchCalculateLowWorkOrders (){}

    global void execute(SchedulableContext SC) {
        batchCalculateLowWorkOrders thisBatch = new batchCalculateLowWorkOrders();
        database.executeBatch(thisBatch, 10); 
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {  
        // Go-Live Query
        String query = 'SELECT Id, Name, CreatedDate, rstk__wocst_proj__c, rstk__wocst_ordcost_total__c, rstk__wocst_soline__r.rstk__soline_sohdr__r.Id, rstk__wocst_soline__r.rstk__soline_sohdr__r.Name FROM rstk__wocst__c WHERE rstk__wocst_ordsts_pl__c = \'5-Pick List records generated\'';

        // Development Query 
        //String query = 'SELECT Id, Name, CreatedDate, rstk__wocst_proj__c, rstk__wocst_ordcost_total__c, rstk__wocst_soline__r.rstk__soline_sohdr__r.Id, rstk__wocst_soline__r.rstk__soline_sohdr__r.Name FROM rstk__wocst__c WHERE (rstk__wocst_ordsts_pl__c = \'9-Closed\' OR rstk__wocst_ordsts_pl__c = \'8-Receipts completed\')';                                                      
        
        if(Test.IsRunningTest())
        {
            query = 'SELECT Id, Name, CreatedDate, rstk__wocst_proj__c, rstk__wocst_ordcost_total__c, rstk__wocst_soline__r.rstk__soline_sohdr__r.Id, rstk__wocst_soline__r.rstk__soline_sohdr__r.Name FROM rstk__wocst__c WHERE (rstk__wocst_ordsts_pl__c = \'9-Closed\' OR rstk__wocst_ordsts_pl__c = \'8-Receipts completed\') LIMIT 1';  
        }
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<rstk__wocst__c> woList) {
        
        // 1. get all Work Order Line Items (components)
        List<rstk__woorddmd__c> tempWOComponentList = getWorkOrderLineComponents(woList);

        // 2. get all Labor hours associated with the work
        List<rstk__woordop__c> tempLaborHours = getLaborHours(woList);

        // 3. get all Sales Orders involved
        List<rstk__sohdr__c> tempSalesOrders = getSalesOrders(woList);

        // 4. get all Manufacturing Users involved
        List<rstk__syusr__c> tempManufacturingUsers = getManufacturingUsers(woList);

        // 5. get all Inventory Item Master records
        List<rstk__icitem__c> tempInventoryMasters = getIventoryMasters(tempWOComponentList);

        // 6. get all Item Cost/Qty values
        List<rstk__icitemcst__c> tempInventoryCostList = getInventoryCostItems(tempInventoryMasters);

        // 7. get buckets of the info tied all to the Work Order
        Map<Id, List<rstk__woorddmd__c>> tempMapWorkOrderAndComponents = getMapOfWorkOrderComponentsByWorkOrder(woList, tempWOComponentList);
        Map<Id, List<rstk__icitemcst__c>> tempMapWorkOrderAndInventoryItemCost = getMapOfInventoryCostByWorkOrderComponent(tempWOComponentList, tempInventoryMasters, tempInventoryCostList);
        Map<Id, List<rstk__woordop__c>> tempMapWorkOrdersAndWorkOrderOperations = getMapOfWorkOrderOperationsByWorkOrder(woList, tempLaborHours);

        // 8. get all of the Chassis and Conversion prices
        List<rstk__poline__c> listOfChassisCosts = getChassisCost(woList);

        // 8. get all total Work Order Prices
        Map<Id, List<double>> tempWorkOrderTotals = getMapOfWorkOrderTotalPrices(woList, tempMapWorkOrderAndComponents, tempMapWorkOrderAndInventoryItemCost, tempMapWorkOrdersAndWorkOrderOperations, listOfChassisCosts);

        // 9. get all Sales Order Sale prices and figure out total GP
        Map<Id, double> tempGPMap = getGPCalculations(tempWorkOrderTotals, woList);

        // 10. DML to update all of the Work Orders
        updateWorkOrders(tempWorkOrderTotals, tempGPMap);
    }   
     
    global void finish(Database.BatchableContext BC) {}
    
    /**
    * getWorkOrderLineComponents
    *
    * function to get all Work Order Line Components related to the list 
    * of Work Orders given.
    *
    * @param List<rstk__wocst__c> - list of Work Orders in question
    *
    * @return List<rstk__woorddmd__c> - list of Work Order Components found
    */
    public List<rstk__woorddmd__c> getWorkOrderLineComponents(List<rstk__wocst__c> tempWorkOrderList){
        return ([SELECT Id, 
                Name, 
                rstk__woorddmd_compitem__c,      // lookup to inv master
                rstk__woorddmd_compitem__r.Name, // lookup to inv master
                rstk__woorddmd_qtyreq__c,        // quantity ordered
                rstk__woorddmd_ordno__c          // reference to parent work order
                FROM rstk__woorddmd__c
                WHERE rstk__woorddmd_ordno__c IN :tempWorkOrderList AND
                    rstk__woorddmd_ordno__c != null]);
    }
    
    /**
    * getIventoryMasters
    *
    * function to get all Inventory Item Masters related to the list 
    * of Work Order Components given.
    *
    * @param List<rstk__woorddmd__c> - list of Work Orders Components in question
    *
    * @return List<rstk__icitem__c> - list of Inventory Item Masters found
    */
    public List<rstk__icitem__c> getIventoryMasters(List<rstk__woorddmd__c> tempWorkOrderComponents){
        
        Map<Id,rstk__woorddmd__c> listOfInventoryItemIds = generateMapOfInventoryIds(tempWorkOrderComponents);

        return ([SELECT Id,
                Name, 
                rstk__icitem_icitemcst__c
                FROM rstk__icitem__c
                WHERE Id IN :listOfInventoryItemIds.keySet() AND
                    rstk__icitem_icitemcst__c != null]);
    }
    
    /**
    * generateMapOfInventoryIds
    *
    * function to which converts a List of Work Order Components into a Map of Ids for later processing
    *
    * @param List<rstk__woorddmd__c> - list of Work Orders Components in question
    *
    * @return Map<Id,rstk__woorddmd__c> - list of Inventory Item Masters found
    */
    public Map<Id,rstk__woorddmd__c> generateMapOfInventoryIds(List<rstk__woorddmd__c> tempWorkOrderComponents){
        
        Map<Id,rstk__woorddmd__c> listOfInventoryItemIds = new Map<Id,rstk__woorddmd__c>();
        
        for(rstk__woorddmd__c tempWorkOrderComponent : tempWorkOrderComponents){
            listOfInventoryItemIds.put(tempWorkOrderComponent.rstk__woorddmd_compitem__c, tempWorkOrderComponent);
        }
        
        return listOfInventoryItemIds;
    }
    
    /**
    * getInventoryCostItems
    *
    * function to retrieves all Inventory 
    *
    * @param List<rstk__woorddmd__c> - list of Work Orders Components in question
    *
    * @return Map<Id,rstk__woorddmd__c> - list of Inventory Item Masters found
    */
    public List<rstk__icitemcst__c> getInventoryCostItems(List<rstk__icitem__c> tempListItemMasters){
        Map<Id,rstk__icitem__c> listOfInventoryItemCostQntyIds = new Map<Id,rstk__icitem__c>();
        for(rstk__icitem__c tempInvCostQntyComponent : tempListItemMasters){
            listOfInventoryItemCostQntyIds.put(tempInvCostQntyComponent.rstk__icitem_icitemcst__c, tempInvCostQntyComponent);
        }

        return ([SELECT Id,
                Name, 
                rstk__icitemcst_lstactucsttot__c,    // total cost (material + material overhead)
                rstk__icitemcst_lstactucstmtl__c,    // total material cost
                rstk__icitemcst_lstactucstohdmtl__c, // total material overhead
                rstk__icitemcst_item__c              // parent Inventory Item Master
                FROM rstk__icitemcst__c
                WHERE Id IN :listOfInventoryItemCostQntyIds.keySet() AND
                    rstk__icitemcst_item__c != null]);
    }

    /**
    * getChassisCost
    *
    * Function which searches for the PO that generated this Chassis Inventory
    * and finds the true cost for the individual order.
    *
    * @param workOrders - List of Work Orders with Project Ids
    *
    * @return List<rstk__poline__c> - The dollar amounts found on the PO associated with this Chassis
    */
    public List<rstk__poline__c> getChassisCost(List<rstk__wocst__c> workOrders)
    {
        List<Id> ListOfProjectIds = new List<Id>();

        for(rstk__wocst__c tempWorkOrder: workOrders)
        {
            listOfProjectIds.add(tempWorkOrder.rstk__wocst_proj__c);
        }

        return ([SELECT Id, 
                        rstk__poline_qtyreq__c, 
                        rstk__poline_unitprice__c,
                        rstk__poline_proj__c,
                        rstk__poline_proj__r.Name,
                        rstk__poline_item__c,
                        rstk__poline_item__r.Name
                FROM rstk__poline__c
                WHERE rstk__poline_proj__c IN :ListOfProjectIds AND
                    (rstk__poline_item__r.Name LIKE :purchasedChassisIdentifierQuery OR 
                    rstk__poline_item__r.Name LIKE :conversionChassisIdentifierQuery)]);
    }

    /**
    * getLaborHours
    *
    * function to retrieves all Labor hours associated with the project
    *
    * @param List<rstk__wocst__c> - list of Work Orders in question
    *
    * @return List<rstk__woordop__c> - list of Work Order Operations
    */
    public List<rstk__woordop__c> getLaborHours(List<rstk__wocst__c> tempListWorkOrders){
        return ([SELECT Id, 
                rstk__woordop_runhrstd__c,
                rstk__woordop_runlabgrd__c,
                rstk__woordop_runlabgrd__r.rstk__rtlabgrd_hrrate__c,
                rstk__woordop_runlabgrd__r.rstk__rtlabgrd_price__c, 
                rstk__woordop_ordno__c,
                rstk__woordop_assignedto__c,
                rstk__woordop_assignedto__r.rstk__syusr_ohdfrngind__c,
                rstk__woordop_assignedto__r.rstk__syusr_ohdlabind__c,
                rstk__woordop_wctr__c,
                rstk__woordop_wctr__r.rstk__rtwctr_dept__c,
                rstk__woordop_wctr__r.rstk__rtwctr_dept__r.rstk__rtdept_ohdfrngrate__c, // fringe rate
                rstk__woordop_wctr__r.rstk__rtwctr_dept__r.rstk__rtdept_ohdlabrate__c  // labor ohd rate
                FROM rstk__woordop__c 
                WHERE rstk__woordop_ordno__c IN :tempListWorkOrders AND 
                    rstk__woordop_runlabgrd__r.rstk__rtlabgrd_price__c != null]);
    }

    /**
    * getSalesOrders
    *
    * function to retrieves all Sales Orders related to the given Work Orders
    *
    * @param List<rstk__wocst__c> - list of Work Orders in question
    *
    * @return List<rstk__sohdr__c> - list of Sales Orders connected to the work orders
    */
    public List<rstk__sohdr__c> getSalesOrders(List<rstk__wocst__c> tempListWorkOrders){
        
        Set<Id> setOfSalesOrderIds = new Set<Id>();

        for(rstk__wocst__c tempWorkOrder : tempListWorkOrders)
        {
            setOfSalesOrderIds.add(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.Id);
        }

        return ([SELECT Id, 
                Name, 
                rstk__sohdr_ordertotal__c 
                FROM rstk__sohdr__c 
                WHERE Id IN :setOfSalesOrderIds]);
    }

    /**
    * getManufacturingUsers
    *
    * function to retrieves all Manufacturing Users related to the given Work Orders. If the 
    *
    * @param List<rstk__wocst__c> - list of Work Orders in question
    *
    * @return List<rstk__syusr__c> - list of Manufacturing Users connected to the work orders
    */
    public List<rstk__syusr__c> getManufacturingUsers(List<rstk__wocst__c> tempListWorkOrders){
        
        return ([SELECT Id,
                rstk__syusr_ohdlabind__c,  // labor overhead checkbox
                rstk__syusr_ohdfrngind__c, // fringe overhead checkbox
                rstk__syusr_hrrate__c      // hourly rate
                FROM rstk__syusr__c
                WHERE Id IN (SELECT rstk__woordop_assignedto__c 
                            FROM rstk__woordop__c 
                            WHERE rstk__woordop_ordno__c IN :tempListWorkOrders AND 
                            rstk__woordop_assignedto__c != null)]);
    }

    /**
    * getMapOfWorkOrderComponentsByWorkOrder
    *
    * function which breaks up all work order components by work order number
    *
    * @param List<rstk__wocst__c> - list of work orders found by the original query
    * @param List<rstk__woorddmd__c> - all work orders found by work order number but not "bucketed"
    *
    * @return Map<Id, List<rstk__woorddmd__c>> - map where Id is work order and value is list of work order components related to said work order
    */
    public Map<Id, List<rstk__woorddmd__c>> getMapOfWorkOrderComponentsByWorkOrder(List<rstk__wocst__c> tempWorkOrderList, List<rstk__woorddmd__c> tempWorkOrderComponentList){
        
        Map<Id, List<rstk__woorddmd__c>> tempMap = new Map<Id, List<rstk__woorddmd__c>>();

        // break up by work order
        for(rstk__wocst__c tempWorkOrder : tempWorkOrderList)
        {
            List<rstk__woorddmd__c> tempList = new List<rstk__woorddmd__c>();

            for(rstk__woorddmd__c tempWorkOrderComponent : tempWorkOrderComponentList)
            {
                if(tempWorkOrderComponent.rstk__woorddmd_ordno__c == tempWorkOrder.Id)
                {
                    tempList.add(tempWorkOrderComponent);
                }
            }

            tempMap.put(tempWorkOrder.Id, tempList);
        }

        return tempMap;
    }

    /**
    * getMapOfInventoryCostByWorkOrderComponent
    *
    * function which breaks up all inventory cost items by work order component
    *
    * @param List<rstk__woorddmd__c> - all work orders found by work order number
    * @param List<rstk__icitem__c> - all inventory item masters found linking to the cost
    * @param List<rstk__icitemcst__c> - all inventory item cost records related to work order component
    *
    * @return Map<Id, List<rstk__icitemcst__c>> - map where Id is work order and value is list of inventory item costs related to said work order
    */
    public Map<Id, List<rstk__icitemcst__c>> getMapOfInventoryCostByWorkOrderComponent(List<rstk__woorddmd__c> tempWorkOrderComponentList, List<rstk__icitem__c> tempInventoryMasterList, List<rstk__icitemcst__c> tempInventoryItemCostList){
        
        Map<Id, List<rstk__icitemcst__c>> tempMap = new Map<Id, List<rstk__icitemcst__c>>();

        // break up by work order
        for(rstk__woorddmd__c tempWorkOrderComponent : tempWorkOrderComponentList)
        {
            List<rstk__icitemcst__c> tempList = new List<rstk__icitemcst__c>();

            for(rstk__icitem__c tempInventoryItem : tempInventoryMasterList)
            {
                if(tempWorkOrderComponent.rstk__woorddmd_compitem__c == tempInventoryItem.Id)
                {
                    for(rstk__icitemcst__c tempInventoryCost : tempInventoryItemCostList)
                    {
                        if(tempInventoryCost.rstk__icitemcst_item__c == tempInventoryItem.Id)
                        {
                            tempList.add(tempInventoryCost);
                        }
                    }
                }
            }

            tempMap.put(tempWorkOrderComponent.Id, tempList);
        }

        return tempMap;
    }

    /**
    * getMapOfWorkOrderOperationsByWorkOrder
    *
    * function which breaks up all work order operations by work order component
    *
    * @param List<rstk__wocst__c> - all work orders found by work order number
    * @param List<rstk__woordop__c> - all work order operations not bucketed yet
    *
    * @return Map<Id, List<rstk__woordop__c>> - map where Id is work order and value is list of work order operations related to said work order
    */
    public Map<Id, List<rstk__woordop__c>> getMapOfWorkOrderOperationsByWorkOrder(List<rstk__wocst__c> tempWorkOrderList, List<rstk__woordop__c> tempWorkOrderOperationList){
        
        Map<Id, List<rstk__woordop__c>> tempMap = new Map<Id, List<rstk__woordop__c>>();

        // break up by work order
        for(rstk__wocst__c tempWorkOrder : tempWorkOrderList)
        {
            List<rstk__woordop__c> tempList = new List<rstk__woordop__c>();

            for(rstk__woordop__c tempWorkOrderOperation : tempWorkOrderOperationList)
            {
                if(tempWorkOrderOperation.rstk__woordop_ordno__c == tempWorkOrder.Id)
                {
                    tempList.add(tempWorkOrderOperation);
                }
            }    

            tempMap.put(tempWorkOrder.Id, tempList);
        }

        return tempMap;
    }

    /**
    * isLaborOverheadIncluded
    *
    * function which cycles through all of the available work order operations 
    * and if at least one of the manufacturing users has the labor overhead checkbox check for
    * a given work order, then it will return true. If none found, returns false.
    *
    * @param Id - Id of the work order in question
    * @param Map<Id, List<rstk__woordop__c>> - all the work order operations grouped by work order
    *
    * @return boolean - true if at least one record has the labor over head checked. False otherwise
    */
    public boolean isLaborOverheadIncluded(Id workOrderId, Map<Id, List<rstk__woordop__c>> tempMapOfWorkOrderOperations){

        List<rstk__woordop__c> tempList = tempMapOfWorkOrderOperations.get(workOrderId);

        boolean returningValue = false;

        for(rstk__woordop__c tempWorkOrderOperation : tempList)
        {
            if(tempWorkOrderOperation != null && tempWorkOrderOperation.rstk__woordop_assignedto__c != null && tempWorkOrderOperation.rstk__woordop_assignedto__r.rstk__syusr_ohdlabind__c == true)
            {
                returningValue = true;
                break;
            }
        }

        return returningValue;
    }

    /**
    * isFringeOverheadIncluded
    *
    * function which cycles through all of the available work order operations 
    * and if at least one of the manufacturing users has the fringe overhead checkbox check for
    * a given work order, then it will return true. If none found, returns false.
    *
    * @param Id - Id of the work order in question
    * @param Map<Id, List<rstk__woordop__c>> - all the work order operations grouped by work order
    * 
    * @return boolean - true if at least one record has the fringe over head checked. False otherwise
    */
    public boolean isFringeOverheadIncluded(Id workOrderId, Map<Id, List<rstk__woordop__c>> tempMapOfWorkOrderOperations){
        
        List<rstk__woordop__c> tempList = tempMapOfWorkOrderOperations.get(workOrderId);

        boolean returningValue = false;

        for(rstk__woordop__c tempWorkOrderOperation : tempList)
        {
            if(tempWorkOrderOperation != null && tempWorkOrderOperation.rstk__woordop_assignedto__c != null && tempWorkOrderOperation.rstk__woordop_assignedto__r.rstk__syusr_ohdfrngind__c == true)
            {
                returningValue = true;
                break;
            }
        }

        return returningValue;
    }

    /**
    * getMapOfWorkOrderTotalPrices
    *
    * function to retrieves all Work Order total prices for comparisons
    *
    * List cells: [0] = total, [1] = labor, [2] = material, [3] = overhead material, [4] = overhead labor, [5] = overhead fringe
    *
    * @param List<rstk__wocst__c> - work orders involved
    * @param Map<Id, List<rstk__woorddmd__c>> - bucketed work order components by work order
    * @param Map<Id, List<rstk__icitemcst__c>> - bucketed inventory item cost records by work order component
    * @param Map<Id, List<rstk__woordop__c>> - bucketed work order operation by work order
    * @param List<rstk__syusr__c>  - list of manufactoring users containing whether their rates apply or not
    * @param List<rstk__poline__c> - list of Purchase Order Lines with the same project IDs as the work orders being processed
    * 
    * @return Map<Id, List<double>> - mapping of a given Work Order with its total price
    */
    public Map<Id, List<double>> getMapOfWorkOrderTotalPrices(List<rstk__wocst__c> tempWoList, 
                                                        Map<Id, List<rstk__woorddmd__c>> tempWorkOrderComponentMap, 
                                                        Map<Id, List<rstk__icitemcst__c>> tempWorkOrderItemCostMap, 
                                                        Map<Id, List<rstk__woordop__c>> tempWorkOrderOperationAndWorkOrders,
                                                        List<rstk__poline__c> tempWorkOrderChassisCosts){

        Map<Id, List<double>> mapOfWorkOrderTotalPrices = new Map<Id, List<double>>();
        
        System.debug('ID,Name,Material Total,Material Overhead Total,Labor Included?,Fringe Included?,Fringe Cost,Labor Overhead,Labor Hours,Labor Price	Total,Calculated Price,Actual Total	Difference');

        // work order
        for(rstk__wocst__c tempWorkOrder : tempWoList)
        {
            List<double> listOfPrices = new List<double>();
            double fringeCost = 0.0;
            double fringeRate = 0.0;
            double materialTotal = 0.0;
            double laborHourTotal = 0.0;
            double laborPriceTotal = 0.0;
            double laborOverHeadCost = 0.0;
            double laborOverHeadRate = 0.0;
            double materialOverheadTotal = 0.0;
            double total = 0.0;
            boolean laborIncluded = true; //isLaborOverheadIncluded(tempWorkOrder.Id, tempWorkOrderOperationAndWorkOrders);
            boolean fringeIncluded = true; //isFringeOverheadIncluded(tempWorkOrder.Id, tempWorkOrderOperationAndWorkOrders);

            // work order component
            for(rstk__woorddmd__c tempWorkOrderComponent : tempWorkOrderComponentMap.get(tempWorkOrder.Id))
            {   
                // Chassis Master Inventory item cost
                if(tempWorkOrderComponent.rstk__woorddmd_compitem__r.Name.contains(purchasedChassisIdentifier))
                {
                    for(rstk__poline__c tempPOLine : tempWorkOrderChassisCosts)
                    {
                        if(tempPOLine.rstk__poline_proj__c == tempWorkOrder.rstk__wocst_proj__c && tempPOLine.rstk__poline_item__r.Name.contains(purchasedChassisIdentifier))
                        {
                            System.debug('PO Line ID : ' + tempPOLine.Id);
                            System.debug('Chassis Cost: ' + (tempPOLine.rstk__poline_unitprice__c * tempPOLine.rstk__poline_qtyreq__c));
                            materialTotal = materialTotal + (tempPOLine.rstk__poline_unitprice__c * tempPOLine.rstk__poline_qtyreq__c);

                            for(rstk__icitemcst__c tempInventoryItemCost : tempWorkOrderItemCostMap.get(tempWorkOrderComponent.Id))
                            {
                                materialOverheadTotal = materialOverheadTotal + (tempInventoryItemCost.rstk__icitemcst_lstactucstohdmtl__c * tempWorkOrderComponent.rstk__woorddmd_qtyreq__c);
                            }  
                        }
                    }
                }
                // Chassis Conversion Inventory item cost
                else if(tempWorkOrderComponent.rstk__woorddmd_compitem__r.Name.contains(conversionChassisIdentifier))
                {
                    for(rstk__poline__c tempPOLine : tempWorkOrderChassisCosts)
                    {
                        if(tempPOLine.rstk__poline_proj__c == tempWorkOrder.rstk__wocst_proj__c && tempPOLine.rstk__poline_item__r.Name.contains(conversionChassisIdentifier))
                        {
                            System.debug('PO Line ID2 : ' + tempPOLine.Id);
                            System.debug('Chassis Cost2: ' + (tempPOLine.rstk__poline_unitprice__c * tempPOLine.rstk__poline_qtyreq__c));
                            materialTotal = materialTotal + (tempPOLine.rstk__poline_unitprice__c * tempPOLine.rstk__poline_qtyreq__c);
                            
                            for(rstk__icitemcst__c tempInventoryItemCost : tempWorkOrderItemCostMap.get(tempWorkOrderComponent.Id))
                            {
                                materialOverheadTotal = materialOverheadTotal + (tempInventoryItemCost.rstk__icitemcst_lstactucstohdmtl__c * tempWorkOrderComponent.rstk__woorddmd_qtyreq__c);
                            } 
                        }
                    }
                }
                // Non-Chassis Master Inventory item cost
                else
                {   
                    for(rstk__icitemcst__c tempInventoryItemCost : tempWorkOrderItemCostMap.get(tempWorkOrderComponent.Id))
                    {
                        materialTotal = materialTotal + (tempInventoryItemCost.rstk__icitemcst_lstactucstmtl__c * tempWorkOrderComponent.rstk__woorddmd_qtyreq__c);
                        materialOverheadTotal = materialOverheadTotal + (tempInventoryItemCost.rstk__icitemcst_lstactucstohdmtl__c * tempWorkOrderComponent.rstk__woorddmd_qtyreq__c);
                    }         
                }
            }

            // Labor Hours, Labor Pricing, Fringe Rate, and Labor Overhead
            for(rstk__woordop__c tempWorkOrderOperation : tempWorkOrderOperationAndWorkOrders.get(tempWorkOrder.Id))
            {
                laborHourTotal = laborHourTotal + tempWorkOrderOperation.rstk__woordop_runhrstd__c;
                laborPriceTotal = laborPriceTotal + (tempWorkOrderOperation.rstk__woordop_runhrstd__c * tempWorkOrderOperation.rstk__woordop_runlabgrd__r.rstk__rtlabgrd_hrrate__c);
                fringeRate = tempWorkOrderOperation.rstk__woordop_wctr__r.rstk__rtwctr_dept__r.rstk__rtdept_ohdfrngrate__c;
                laborOverHeadRate = tempWorkOrderOperation.rstk__woordop_wctr__r.rstk__rtwctr_dept__r.rstk__rtdept_ohdlabrate__c;
            } 

            // Fringe Costs
            if(fringeIncluded)
            {
                fringeCost = laborPriceTotal * fringeRate;
            }
            
            // Labor Cost
            if(laborIncluded)
            {
                laborOverHeadCost = laborPriceTotal * laborOverHeadRate;
            }

            // Calculated Total
            total = materialTotal + materialOverheadTotal + laborPriceTotal + laborOverHeadCost + fringeCost;

            System.debug(tempWorkOrder.Id + ',' + tempWorkOrder.Name + ',' + materialTotal + ',' + materialOverheadTotal + ',' + laborIncluded + ',' + fringeIncluded + ',' + fringeCost + 
                        ',' + laborOverHeadCost + ',' + laborHourTotal + ',' + laborPriceTotal + ',' + total + ',' + tempWorkOrder.rstk__wocst_ordcost_total__c + ',' + (total - tempWorkOrder.rstk__wocst_ordcost_total__c) + ',' + tempWorkOrder.CreatedDate.format());

            listOfPrices.add(total);
            listOfPrices.add(laborPriceTotal);
            listOfPrices.add(materialTotal);
            listOfPrices.add(materialOverheadTotal);
            listOfPrices.add(laborOverHeadCost);
            listOfPrices.add(fringeCost);

            mapOfWorkOrderTotalPrices.put(tempWorkOrder.Id, listOfPrices);
        } 

        return mapOfWorkOrderTotalPrices;
    }

    /**
    * getGPCalculations
    *
    * function which gets all of the sales orders related to the work orders. If any are found,
    * then the total sales price of the sales order is subtracted by the total work order cost price generated 
    * in earlier calculations. 
    *
    * @param Map<Id, List<double>> - 2D map containing all of the pricings
    * @param List<rstk__wocst__c> - all work orders found from the original query of the batch class
    * 
    * @return Map<Id, double> - map containing all of the GP calculations broken up by work order id
    */
    public Map<Id, double> getGPCalculations(Map<Id, List<double>> tempPriceMap, List<rstk__wocst__c> tempWorkOrderList){
        
        Map<Id, double> returningValue = new Map<Id, double>();

        Map<Id, rstk__wocst__c> tempSalesOrderList = new Map<Id, rstk__wocst__c>([SELECT Id,
                                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.Id,
                                                    rstk__wocst_soline__r.rstk__soline_sohdr__r.rstk__sohdr_ordertotal__c
                                                    FROM rstk__wocst__c
                                                    WHERE Id IN :tempWorkOrderList]);

        // Make sure to exclude freight and intercompany
        List<Id> listOfSalesOrderIds = new List<Id>();

        for(rstk__wocst__c tempWorkOrder : tempSalesOrderList.values())
        {
            listOfSalesOrderIds.add(tempWorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.Id);
        }

        Map<Id, rstk__sohdr__c> mapOfSalesOrdersAndLines = new Map<Id, rstk__sohdr__c>([SELECT Id,
                                                            (SELECT Id, Name, rstk__soline_ext__c FROM rstk__solines__r WHERE (NOT rstk__soline_prod__r.Name LIKE 'Vehicle Ship Charge%') AND (NOT rstk__soline_prod__r.Name LIKE '%inter-company%'))
                                                        FROM rstk__sohdr__c 
                                                        WHERE Id IN :listOfSalesOrderIds]);

        Map<Id, Decimal> SalesOrderTotalMap = new Map<Id, Decimal>();

        for(rstk__sohdr__c SOHEADER : mapOfSalesOrdersAndLines.values())
        {
            if(SalesOrderTotalMap.get(SOHEADER.Id) == null)
            {
                SalesOrderTotalMap.put(SOHEADER.Id, 0);
            }
            
            for (rstk__soline__c child : SOHEADER.rstk__solines__r)
            {
                Decimal tempTotal = SalesOrderTotalMap.get(SOHEADER.Id);
                SalesOrderTotalMap.put(SOHEADER.Id, tempTotal + child.rstk__soline_ext__c);
            }
        }
        
        for(rstk__wocst__c tempWorkOrder : tempWorkOrderList)
        {
            List<double> tempPriceList = tempPriceMap.get(tempWorkOrder.Id);
            
            double total = tempPriceList[cellTotal] != null ? tempPriceList[cellTotal] : 0.0;
            
            double saleTotal = SalesOrderTotalMap.get(tempSalesOrderList.get(tempWorkOrder.Id).rstk__wocst_soline__r.rstk__soline_sohdr__c) != null ? SalesOrderTotalMap.get(tempSalesOrderList.get(tempWorkOrder.Id).rstk__wocst_soline__r.rstk__soline_sohdr__c) : 0;
            
            if(total == null){
              System.debug('total work order price was null');
              break;
            }
            
            if(saleTotal == null){
              System.debug('sale total was null');
              break;
            }
            
            // (Sales Price) - (Work Order Cost)   
            double tempDifference = saleTotal - total;

            returningValue.put(tempWorkOrder.Id, tempDifference);
        }

        return returningValue;
    }

    /**
    * updateWorkOrders
    *
    * function to do a final update of all work orders based on the information given
    * 
    * @param Map<Id, List<double>> - work orders involved with a list of all values: 
    */
    public void updateWorkOrders(Map<Id, List<double>> mapOfWorkOrderVals, Map<Id, double> mapOfTotalGP)
    {
        List<rstk__wocst__c> listOfWorkOrdersToUpdate = new List<rstk__wocst__c>();

        for(Id tempId : mapOfTotalGP.KeySet())
        {
            rstk__wocst__c temp = new rstk__wocst__c();
            temp.Id = tempId;
            temp.Pre_Calculated_Total_Gross_Profit__c = mapOfTotalGP.get(tempId);

            if(mapOfWorkOrderVals.get(tempId) != null )
            {
                temp.Pre_Calculated_Total_Labor_Price__c = mapOfWorkOrderVals.get(tempId)[1];
                temp.Pre_Calculated_Total_Material_Price__c = mapOfWorkOrderVals.get(tempId)[2];
                temp.Pre_Calculated_Total_Material_Overhead__c = mapOfWorkOrderVals.get(tempId)[3];
                temp.Pre_Calculated_Total_Labor_Overhead__c = mapOfWorkOrderVals.get(tempId)[4];
                temp.Pre_Calculated_Total_Fringe_Cost__c = mapOfWorkOrderVals.get(tempId)[5];
            }

            listOfWorkOrdersToUpdate.add(temp);
        }

        Database.SaveResult[] srList = Database.update(listOfWorkOrdersToUpdate, false); 

        // Iterate through each returned result
        for (Database.SaveResult sr : srList) 
        {    
            if (!sr.isSuccess()) 
            {    
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) 
                { 
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Work Order fields that affected this error: ' + err.getFields());
                }
            }
        }   
    }
}