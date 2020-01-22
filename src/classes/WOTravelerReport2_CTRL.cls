/**
 * WOTravelerReport2_CTRL
 * Tested by: WOTravelerReport_CTRL_TEST
 *
 *  2017-12-18  B. Leaman   Rewritten for work order instead of configuration. 
 *  2017-12-21  A. Miller   Removed Factory Order #, Added Chassis Master Connection, removed duplicate Work Center Bug (AMILLER1)
 *  2018-1-3    A. Miller   Functionality requested to pair all inventory and labor with a product from the configurator (AMILLER2)
 *  2018-3-19   A. Miller   Functionality to handle multi-division orders (AMILLER3)
 */
public class WOTravelerReport2_CTRL {
    
    public string strWONum {get;set;}
    public string strItemNum {get;set;}
    public string strItemDesc {get;set;}
    public string strSalesOrderLine {get;set;}
    public string strSalesOrderId {get;set;}
    public string strSalesOrderHdr {get;set;} 
    public string strConfigurationSession {get;set;}
    public string strDateStart {get;set;}
    public string strDateDue {get;set;}
    public double dblQty {get;set;}
    public string strUOM {get;set;}
    // AMILLER1
    public String vin {get;set;}
    public String year {get;set;}
    public String make {get;set;}
    public String modelExt {get;set;}
    public String keyTag {get;set;}
    public String extColor {get;set;}
    // / AMILLER1

    // AMILLER2
    public List<rstk__confcomp__c> listOfComponentsFromConfigurator {get;set;}
    // / AMILLER2
    
    public rstk__wocst__c WorkOrder;

    public map<Decimal, List<ItemWrapper>> GroupedList {get; private set;} 
    public List<ItemWrapper> GroupedDumpList {get; private set;} 
    public List<rstk__icitemsrl__c> SerializedComponents {get;set;}
    
    public WOTravelerReport2_CTRL(){

        Id workOrderId = apexpages.currentpage().getparameters().get('id');
        
        GroupedList = new map<Decimal, List<ItemWrapper>>();

        GroupedDumpList = new List<ItemWrapper>();

        WorkOrder = [SELECT Id
                , Chassis__c										// AMILLER1
                , Chassis__r.VIN__c
                , Chassis__r.Year__c
                , Chassis__r.Make__c
                , Chassis__r.Model_Ext__c
                , Chassis__r.Key_Tag__c
                , Chassis__r.Exterior_Color__c                     // / AMILLER1
                , rstk__wocst_ordno__c
                , rstk__wocst_item__r.Name
                , rstk__wocst_item__r.rstk__icitem_descr__c
                , rstk__wocst_soline__r.rstk__soline_confsess__r.Name
                , rstk__wocst_duedte__c
                , rstk__wocst_lstschddtetime__c
                , rstk__wocst_qtyreq__c
                , rstk__wocst_item__r.rstk__icitem_invuom__r.Name
                , rstk__wocst_soline__r.rstk__soline_sohdr__c   
                , rstk__wocst_soline__r.rstk__soline_sohdr__r.Name  
                , rstk__wocst_soline__r.Origin_Sales_Order_Line__c // AMILLER3
                , rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c
                , rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__r.Name
                , rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_sohdr__c
                , rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_sohdr__r.Name
                , rstk__wocst_div__c
                , rstk__wocst_soline__r.rstk__soline_confsess__c
            FROM rstk__wocst__c
            WHERE Id = :workOrderId];
        
        vin = WorkOrder.Chassis__r.VIN__c;
    	year = WorkOrder.Chassis__r.Year__c;
    	make = WorkOrder.Chassis__r.Make__c;
    	modelExt = WorkOrder.Chassis__r.Model_Ext__c;
    	keyTag = WorkOrder.Chassis__r.Key_Tag__c;
    	extColor = WorkOrder.Chassis__r.Exterior_Color__c;

        // Get list of components with serial#s
        List<rstk__woorddmdcst__c> WODemandWithSerialNumbers = [
            select Id, Name, rstk__woorddmdcst_woorddmd__c, rstk__woorddmdcst_compitem__c, rstk__woorddmdcst_srlno__c
            from rstk__woorddmdcst__c
            where rstk__woorddmdcst_woorddmd__r.rstk__woorddmd_ordno__c=:workOrderId
              and rstk__woorddmdcst_srlno__c!=null
        ];
        Set<String> srlinvnames = new Set<String>();
        Set<Id> srlinvitems = new Set<Id>();
        Set<String> srlinvnbrs = new Set<String>();
        for(rstk__woorddmdcst__c dtl : WODemandWithSerialNumbers) 
        {
            srlinvnames.add(dtl.Name.left(49) + '_' + dtl.rstk__woorddmdcst_srlno__c);
            srlinvitems.add(dtl.rstk__woorddmdcst_compitem__c);
            srlinvnbrs.add(dtl.rstk__woorddmdcst_srlno__c);
        }

        System.debug(srlinvnames);
        System.debug(srlinvitems);
        System.debug(srlinvnbrs);

        SerializedComponents = [
            SELECT Id, Name, rstk__icitemsrl_item__c 
                , rstk__icitemsrl_srlno__c
                , Exterior_Color__c
                , Factory_Order_Number__c
                , Key_Tag__c
                , Mfg_Make__c
                , Mfg_Model_Ext__c
                , Mfg_Year__c
            FROM rstk__icitemsrl__c
            WHERE rstk__icitemsrl_item__c in :srlinvitems
              and rstk__icitemsrl_srlno__c in :srlinvnbrs
        ];
        
        strWONum = WorkOrder.rstk__wocst_ordno__c;
        strItemNum = WorkOrder.rstk__wocst_item__r.Name;
        
        // AMILLER3

        if(WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__c != null)
        {
            strItemDesc = WorkOrder.rstk__wocst_item__r.rstk__icitem_descr__c;
            strSalesOrderLine = WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__r.Name;
            strSalesOrderId = WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_sohdr__c;    
            strSalesOrderHdr = WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_sohdr__r.Name;  
            if(WorkOrder.rstk__wocst_lstschddtetime__c != null){
                strDateStart = WorkOrder.rstk__wocst_lstschddtetime__c.month() + '/' + WorkOrder.rstk__wocst_lstschddtetime__c.day() + '/' + + WorkOrder.rstk__wocst_lstschddtetime__c.year();
            }
            if(WorkOrder.rstk__wocst_duedte__c != null){
                strDateDue = WorkOrder.rstk__wocst_duedte__c.month() + '/' + WorkOrder.rstk__wocst_duedte__c.day() + '/' + + WorkOrder.rstk__wocst_duedte__c.year();
            }
            dblQty = WorkOrder.rstk__wocst_qtyreq__c;
            strUOM = WorkOrder.rstk__wocst_item__r.rstk__icitem_invuom__r.Name;
        }
        else
        {
            strItemDesc = WorkOrder.rstk__wocst_item__r.rstk__icitem_descr__c;
            strSalesOrderLine = WorkOrder.rstk__wocst_soline__r.rstk__soline_confsess__r.Name;
            strSalesOrderId = WorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__c;    
            strSalesOrderHdr = WorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.Name;  
            if(WorkOrder.rstk__wocst_lstschddtetime__c != null){
                strDateStart = WorkOrder.rstk__wocst_lstschddtetime__c.month() + '/' + WorkOrder.rstk__wocst_lstschddtetime__c.day() + '/' + + WorkOrder.rstk__wocst_lstschddtetime__c.year();
            }
            if(WorkOrder.rstk__wocst_duedte__c != null){
                strDateDue = WorkOrder.rstk__wocst_duedte__c.month() + '/' + WorkOrder.rstk__wocst_duedte__c.day() + '/' + + WorkOrder.rstk__wocst_duedte__c.year();
            }
            dblQty = WorkOrder.rstk__wocst_qtyreq__c;
            strUOM = WorkOrder.rstk__wocst_item__r.rstk__icitem_invuom__r.Name;
        }

        // / AMILLER3
       
    
        List<rstk__woorddmd__c> wodemand = [
            select Id, Name, rstk__woorddmd_lne__c, rstk__woorddmd_desc__c, 
                rstk__woorddmd_compitem__c, rstk__woorddmd_compitem__r.Name, 
                rstk__woorddmd_compqty_qtyreq_ui__c, rstk__woorddmd_invuom__c, rstk__woorddmd_invuom__r.Name,  
                rstk__woorddmd_dmdsts__c, rstk__woorddmd_dmdsts_pl__c, rstk__woorddmd_issue_sts_pl__c,  
                rstk__woorddmd_oper__c, rstk__woorddmd_wctr__c, rstk__woorddmd_wctr__r.Name
            from rstk__woorddmd__c
            where rstk__woorddmd_ordno__c=:WorkOrder.Id
            order by rstk__woorddmd_oper__c, rstk__woorddmd_lne__c
        ];
    
        List<rstk__woordop__c> woopers = [
            select Id, Name, rstk__woordop_oper__c, rstk__woordop_descr__c,
                rstk__woordop_wctr__c, rstk__woordop_wctr__r.Name,
                rstk__woordop_setuphrstd__c, rstk__woordop_machhrstd__c, rstk__woordop_runhrstd__c,
                ( select Id, Name, rstk__woopertask_desc__c, rstk__woopertask_comments__c,
                    rstk__woopertask_assignto__c, rstk__woopertask_assignto__r.Name 
                  from rstk__woopertasks__r)
            from rstk__woordop__c
            where rstk__woordop_ordno__c=:WorkOrder.Id
            order by rstk__woordop_oper__c
        ];
        
        Map<Decimal, rstk__woordop__c> woopermap = new Map<Decimal, rstk__woordop__c>();
        
        for(rstk__woordop__c wooper : woopers) 
        { 
            woopermap.put(wooper.rstk__woordop_oper__c, wooper);
        }

        Map<Id, ComponentWrapper> mappingOfComponents = getConfigurationSelectionComponents();

        Map<Decimal, Decimal> mapOfUsedLaborSequences = new Map<Decimal, Decimal>();

        for(Id tempComponent : mappingOfComponents.KeySet())
        {
            // Cycle through all labors, usally its just one or two labors 
            for(rstk__confcomp__c tempLabor : mappingOfComponents.get(tempComponent).listOfLabor)
            {
                mapOfUsedLaborSequences.put(tempLabor.rstk__confcomp_labseq__c,tempLabor.rstk__confcomp_labseq__c);

                if(!GroupedList.containsKey(tempLabor.rstk__confcomp_labseq__c))
                {
                    GroupedList.put(tempLabor.rstk__confcomp_labseq__c, new List<ItemWrapper>());

                    ItemWrapper operline = new ItemWrapper();
                    operline.strItemNum = tempLabor.Name.replaceAll('\\(.+?\\)','').replaceAll('[-]', ' ').replaceAll('[_]', ' ');
                    operline.strDept = tempLabor.rstk__confcomp_rtindoper__r.rstk__rtindoper_rtwctr__r.Name;
                    operline.lbrSeqNbr = tempLabor.rstk__confcomp_labseq__c;  
                    if(mappingOfComponents.get(tempComponent).listOfProducts.size() > 0)
                    {
                        operline.strProduct = mappingOfComponents.get(tempComponent).listOfProducts.get(0).rstk__confcomp_soprod__r.Name; // AMILLER2
                    }
                    
                     // It says qty per but thats how labor defines the hours, go figure...
                    if(mappingOfComponents.get(tempComponent).multiplyHours != null)
                    {
                         operline.dblHours = tempLabor.rstk__confcomp_qtyper__c * mappingOfComponents.get(tempComponent).multiplyHours;
                    }
                    else
                    {
                        operline.dblHours = tempLabor.rstk__confcomp_qtyper__c;
                    }
                    //operline.TaskList = tempLabor.rstk__woopertasks__r;

                    GroupedList.get(tempLabor.rstk__confcomp_labseq__c).add(operline);

                    // Add Inventory
                    for(rstk__confcomp__c tempRecord : mappingOfComponents.get(tempComponent).listOfInventory)
                    {
                        if(tempRecord.rstk__confcomp_labseq__c == tempLabor.rstk__confcomp_labseq__c)
                        {
                            ItemWrapper newItem = new ItemWrapper();
                            
                            if(tempRecord.rstk__confcomp_icitem__r.Name != null)
                            {
                                newItem.strItemNum = tempRecord.rstk__confcomp_icitem__r.Name.replaceAll('\\(.+?-_\\)','').replaceAll('[_]', ' ');
                            } 

                            if(tempRecord.rstk__confcomp_syuom__r.Name == null)
                            { 
                                newItem.strUOM = 'EA';
                            }
                            else 
                            {
                                newItem.strUOM = tempRecord.rstk__confcomp_syuom__r.Name;
                            }

                            newItem.dblQty = tempRecord.rstk__confcomp_qtyper__c;
                            newItem.lbrSeqNbr = tempLabor.rstk__confcomp_labseq__c;    
                            newItem.strItemDescr = tempRecord.rstk__confcomp_icitem__r.rstk__icitem_descr__c.replaceAll('[-]', ' ').replaceAll('[_]', ' ');
                            GroupedList.get(tempLabor.rstk__confcomp_labseq__c).add(newItem);  
                        } 
                    }
                }
            }
        }

        // WIP Alex 1.22.2018. Issue with inventory not showing up for items which dont have a product or labor sequence
        // Find everything that didn't have a labor sequence product to associate
        for(Id tempComponent : mappingOfComponents.KeySet())
        {
            // Add Inventory
            for(rstk__confcomp__c tempRecord : mappingOfComponents.get(tempComponent).listOfInventory)
            {
                if(mapOfUsedLaborSequences.get(tempRecord.rstk__confcomp_labseq__c) == null)
                {
                    ItemWrapper newItem = new ItemWrapper();
                    
                    if(tempRecord.rstk__confcomp_icitem__r.Name != null)
                    {
                        newItem.strItemNum = tempRecord.rstk__confcomp_icitem__r.Name.replaceAll('\\(.+?\\)','');
                    } 

                    if(tempRecord.rstk__confcomp_syuom__r.Name == null)
                    { 
                        newItem.strUOM = 'EA';
                    }
                    else 
                    {
                        newItem.strUOM = tempRecord.rstk__confcomp_syuom__r.Name;
                    }

                    newItem.dblQty = tempRecord.rstk__confcomp_qtyper__c;
                    newItem.lbrSeqNbr = tempRecord.rstk__confcomp_labseq__c;    
                    newItem.strItemDescr = tempRecord.rstk__confcomp_icitem__r.rstk__icitem_descr__c;
                    if(!isDuplicate(tempRecord, mappingOfComponents.get(tempComponent).listOfInventory))
                    {
                        GroupedDumpList.add(newItem); 
                    }
                } 
            }

            GroupedDumpList.sort();
        }

        // for(Decimal temp : mapOfUsedLaborSequences.KeySet())
        // {
        //     System.debug(temp);
        // }

        // debugging
        for(Id tempComponent : mappingOfComponents.KeySet())
        {
            for(rstk__confcomp__c tempRecord : mappingOfComponents.get(tempComponent).listOfInventory)
            {
                if(tempRecord.rstk__confcomp_labseq__c == null && tempRecord.rstk__formula_isinventory__c == true)
                {
                    System.debug('Selection Id: ' + tempRecord.rstk__confcomp_confsel__c);
                    System.debug('Inventory Item: '+tempRecord.rstk__confcomp_icitem__c);
                    System.debug('Inventory Name: '+tempRecord.rstk__confcomp_icitem__r.Name);
                    if(tempRecord.rstk__confcomp_icitem__c != null)
                    {
                        System.debug('Inventory Name (clean): '+tempRecord.rstk__confcomp_icitem__r.Name.replaceAll('\\(.+?\\)',''));
                        System.debug('Inventory Description: '+tempRecord.rstk__confcomp_icitem__r.rstk__icitem_descr__c);
                    } 
                    System.debug('Work Center: '+tempRecord.rstk__confcomp_rtindoper__r.rstk__rtindoper_rtwctr__c);
                    System.debug('Labor Sequence: '+tempRecord.rstk__confcomp_labseq__c);
                }
            }
        }

        }

        public Map<Id, ComponentWrapper> getConfigurationSelectionComponents()
        {
            Map<Id, ComponentWrapper> mapOfConfigurationComponents = new Map<Id, ComponentWrapper>();

            // Work Order Components
            List<rstk__woorddmd__c> listOfWorkOrderComponents = ([SELECT Id, 
                                                                    rstk__woorddmd_compitem__c  
                                                                FROM rstk__woorddmd__c
                                                                WHERE rstk__woorddmd_ordno__c = :WorkOrder.Id]);

            // Work Order Operations
            List<rstk__woordop__c> listOfWorkOrderOperations = ([SELECT Id,
                                                                    rstk__woordop_oper__c, 
                                                                    rstk__woordop_wctr__c  
                                                                FROM rstk__woordop__c 
                                                                WHERE rstk__woordop_ordno__c = :WorkOrder.Id]);


            // AMILLER3
            // Configuration Session Selections
            List<rstk__confdsel__c> listOfConfigurationSessionSelections;
            List<rstk__confcomp__c> listOfConfigurationSelectionComponents;
            List<rstk__confdcomp__c> listOfSessionSelectionComponents;

            if(WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__c != null)
            {
                listOfConfigurationSessionSelections = ([SELECT Id,
                                                        rstk__confdsel_confsel__c 
                                                    FROM rstk__confdsel__c 
                                                    WHERE rstk__confdsel_confsess__c = :WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c]);

                // Configuration Selection Components
                listOfConfigurationSelectionComponents = ([SELECT Id,
                                                                Name,
                                                                rstk__confcomp_confsel__c,                                  // Selection Id to bring all of it together
                                                                rstk__confcomp_icitem__c,                                   // Inventory Item
                                                                rstk__confcomp_icitem__r.Name,                              // Inventory Item Name
                                                                rstk__confcomp_icitem__r.rstk__icitem_descr__c,             // Inventory Item Description
                                                                rstk__confcomp_soprod__c,                                   // Product Master
                                                                rstk__confcomp_soprod__r.Name,                              // Product Master Name
                                                                rstk__confcomp_rtindoper__c,                                // Labor Operation
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_runhours__c,    // Run Hours
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_hours__c,       // Estimate Hours
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_rtwctr__c,      // Work Center Id
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_rtwctr__r.Name, // Work Center Name
                                                                rstk__confcomp_labseq__c,                                   // Labor Sequence
                                                                rstk__confcomp_syuom__c,                                    // Unit of Measure
                                                                rstk__confcomp_syuom__r.Name,                               // Unit of Measure Name
                                                                rstk__confcomp_qtyper__c,                                   // Qty Per
                                                                rstk__formula_isinventory__c,                               // Inventory Flag
                                                                rstk__formula_islabor__c,                                   // Labor Flag
                                                                rstk__formula_isproduct__c                                  // Product Flag
                                                            FROM rstk__confcomp__c
                                                            WHERE rstk__confcomp_confsel__c IN 
                                                            (SELECT rstk__confdsel_confsel__c
                                                                FROM rstk__confdsel__c 
                                                                WHERE rstk__confdsel_confsess__c = :WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c
                                                            )
                                                            ORDER BY rstk__confcomp_confsel__c]);
                
                listOfSessionSelectionComponents = ([SELECT Id,
                                                            rstk__confdcomp_icitem__c,
                                                            rstk__confdcomp_qtyper__c,
                                                            rstk__confdcomp_confdsel__c,
                                                            rstk__confdcomp_confcomp__c // Selection Component
                                                        FROM rstk__confdcomp__c
                                                        WHERE rstk__confdcomp_confsess__c = :WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__c AND 
                                                                rstk__confdcomp_itemtype__c = 'Inventory' AND
                                                                rstk__confdcomp_icitem__c != null]);
            }
            else
            {
                listOfConfigurationSessionSelections = ([SELECT Id,
                                                        rstk__confdsel_confsel__c 
                                                    FROM rstk__confdsel__c 
                                                    WHERE rstk__confdsel_confsess__c = :WorkOrder.rstk__wocst_soline__r.rstk__soline_confsess__c]);

                // Configuration Selection Components
                listOfConfigurationSelectionComponents = ([SELECT Id,
                                                                Name,
                                                                rstk__confcomp_confsel__c,                                  // Selection Id to bring all of it together
                                                                rstk__confcomp_icitem__c,                                   // Inventory Item
                                                                rstk__confcomp_icitem__r.Name,                              // Inventory Item Name
                                                                rstk__confcomp_icitem__r.rstk__icitem_descr__c,             // Inventory Item Description
                                                                rstk__confcomp_soprod__c,                                   // Product Master
                                                                rstk__confcomp_soprod__r.Name,                              // Product Master Name
                                                                rstk__confcomp_rtindoper__c,                                // Labor Operation
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_runhours__c,    // Run Hours
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_hours__c,       // Estimate Hours
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_rtwctr__c,      // Work Center Id
                                                                rstk__confcomp_rtindoper__r.rstk__rtindoper_rtwctr__r.Name, // Work Center Name
                                                                rstk__confcomp_labseq__c,                                   // Labor Sequence
                                                                rstk__confcomp_syuom__c,                                    // Unit of Measure
                                                                rstk__confcomp_syuom__r.Name,                               // Unit of Measure Name
                                                                rstk__confcomp_qtyper__c,                                   // Qty Per
                                                                rstk__formula_isinventory__c,                               // Inventory Flag
                                                                rstk__formula_islabor__c,                                   // Labor Flag
                                                                rstk__formula_isproduct__c                                  // Product Flag
                                                            FROM rstk__confcomp__c
                                                            WHERE rstk__confcomp_confsel__c IN 
                                                            (SELECT rstk__confdsel_confsel__c
                                                                FROM rstk__confdsel__c 
                                                                WHERE rstk__confdsel_confsess__c = :WorkOrder.rstk__wocst_soline__r.rstk__soline_confsess__c
                                                            )
                                                            ORDER BY rstk__confcomp_confsel__c]);
                
                listOfSessionSelectionComponents = ([SELECT Id,
                                                            rstk__confdcomp_icitem__c,
                                                            rstk__confdcomp_qtyper__c,
                                                            rstk__confdcomp_confdsel__c,
                                                            rstk__confdcomp_confcomp__c // Selection Component
                                                        FROM rstk__confdcomp__c
                                                        WHERE rstk__confdcomp_confsess__c = :WorkOrder.rstk__wocst_soline__r.rstk__soline_confsess__c AND 
                                                                rstk__confdcomp_itemtype__c = 'Inventory' AND
                                                                rstk__confdcomp_icitem__c != null]);
            }
            

            

            

            for(rstk__confcomp__c temp1 : listOfConfigurationSelectionComponents) 
            {
                System.debug('Id: '+temp1.Id);
                System.debug('Name: '+temp1.Name);
                System.debug('Selection Id: ' + temp1.rstk__confcomp_confsel__c);
                System.debug('Inventory Item: '+temp1.rstk__confcomp_icitem__c);
                System.debug('Inventory Name: '+temp1.rstk__confcomp_icitem__r.Name);
                System.debug('Product Master: '+temp1.rstk__confcomp_soprod__c);
                System.debug('Labor Operation: '+temp1.rstk__confcomp_rtindoper__c);
                System.debug('Work Center: '+temp1.rstk__confcomp_rtindoper__r.rstk__rtindoper_rtwctr__c);
                System.debug('Labor Sequence: '+temp1.rstk__confcomp_labseq__c);
                System.debug('Run Hours: '+temp1.rstk__confcomp_rtindoper__r.rstk__rtindoper_runhours__c);
                System.debug('unit of Measure: '+temp1.rstk__confcomp_syuom__c);
                System.debug('QTY: '+temp1.rstk__confcomp_qtyper__c);

                // Create a Component Wrapper by Selection Id if it doesn't exist
                if(mapOfConfigurationComponents.get(temp1.rstk__confcomp_confsel__c) == null)
                {
                    mapOfConfigurationComponents.put(temp1.rstk__confcomp_confsel__c, new ComponentWrapper());
                } 

                // Place Labor, Inventory, and Products into their own buckets grouped by the Selection Id
                if(temp1.rstk__formula_isinventory__c)
                {
                    // apply correct inventory quantities selected (variable boxes) and multiply hours accordingly
                    for(rstk__confdcomp__c selectionComponent : listOfSessionSelectionComponents)
                    {
                        if(selectionComponent.rstk__confdcomp_confcomp__c == temp1.Id &&
                            selectionComponent.rstk__confdcomp_icitem__c == temp1.rstk__confcomp_icitem__c &&
                            selectionComponent.rstk__confdcomp_qtyper__c != temp1.rstk__confcomp_qtyper__c)
                        {
                            temp1.rstk__confcomp_qtyper__c = selectionComponent.rstk__confdcomp_qtyper__c; 
                            
                            if(mapOfConfigurationComponents.get(temp1.rstk__confcomp_confsel__c).multiplyHours == null)
                            {
                                mapOfConfigurationComponents.get(temp1.rstk__confcomp_confsel__c).addMultiplyHours(selectionComponent.rstk__confdcomp_qtyper__c);
                                System.debug(selectionComponent.rstk__confdcomp_qtyper__c);
                            }
                        }
                    }

                    mapOfConfigurationComponents.get(temp1.rstk__confcomp_confsel__c).listOfInventory.add(temp1);
                } 
                else if(temp1.rstk__formula_islabor__c)
                {
                    mapOfConfigurationComponents.get(temp1.rstk__confcomp_confsel__c).listOfLabor.add(temp1);
                } 
                else if(temp1.rstk__formula_isproduct__c)
                {
                    mapOfConfigurationComponents.get(temp1.rstk__confcomp_confsel__c).listOfProducts.add(temp1);
                }
            }
 
            return mapOfConfigurationComponents;
        }

    public Boolean isDuplicate(rstk__confcomp__c temp, List<rstk__confcomp__c> listOfAll)
    {
        Integer counter = 0;

        for(rstk__confcomp__c tempComponent : listOfAll)
        {
            if(temp.rstk__confcomp_labseq__c == tempComponent.rstk__confcomp_labseq__c &&
                temp.rstk__confcomp_icitem__r.Name.equalsIgnoreCase(tempComponent.rstk__confcomp_icitem__r.Name))
            {
                counter++;
            }
        }

        if(counter == 1)
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    public class ItemWrapper implements Comparable {
        public Decimal lbrSeqNbr {get;set;} 
        public String strDept {get;set;}    
        public string strItemNum {get;set;}
        public String strProduct {get;set;} // AMILLER2
        public string strItemDescr {get;set;}
        public double dblQty {get;set;}
        public double dblHours {get;set;}
        public string strUOM {get;set;}
        public List<rstk__woopertask__c> TaskList {get;set;}

        /**
        * The comparator method used in sorting
        *
        * @param obj The object to compare to
        * @return the integer value of the comparison between the objects
        */
        public Integer compareTo(Object obj) {
            ItemWrapper item = (ItemWrapper)(obj);

            if (this.lbrSeqNbr > item.lbrSeqNbr) {
                return 1;
            }

            if (this.lbrSeqNbr == item.lbrSeqNbr) {
                return 0;
            }

            return -1;
        }
    }

    public class ComponentWrapper{
        
        public List<rstk__confcomp__c> listOfProducts {get;set;}
        public List<rstk__confcomp__c> listOfInventory {get;set;}
        public List<rstk__confcomp__c> listOfLabor {get;set;}
        public Decimal multiplyHours {get;set;}

        public ComponentWrapper()
        {
            listOfProducts = new List<rstk__confcomp__c>();
            listOfInventory = new List<rstk__confcomp__c>();
            listOfLabor = new List<rstk__confcomp__c>();
        }

        public ComponentWrapper(List<rstk__confcomp__c> tempLabor, List<rstk__confcomp__c> tempProduct, List<rstk__confcomp__c> tempInventory)
        {
            this.listOfProducts = tempProduct;
            this.listOfInventory = tempInventory;
            this.listOfLabor = tempLabor;
        }

        public List<rstk__confcomp__c> getInventoryByOperation(Decimal operation)
        {
            List<rstk__confcomp__c> inventory = new List<rstk__confcomp__c>();

            for(rstk__confcomp__c tempInventory : listOfProducts)
            {
                if(tempInventory.rstk__confcomp_labseq__c == operation)
                {
                    inventory.add(tempInventory);
                }
            }

            return inventory;
        }

        public List<rstk__confcomp__c> getLaborByOperation(Decimal operation)
        {
            List<rstk__confcomp__c> labor = new List<rstk__confcomp__c>();

            for(rstk__confcomp__c tempLabor : listOfLabor)
            {
                if(tempLabor.rstk__confcomp_labseq__c == operation)
                {
                    labor.add(tempLabor);
                }
            }

            return labor;
        }

        public void addMultiplyHours(Decimal moreHours)
        {
            if(multiplyHours == null)
            {
                multiplyHours = moreHours;
            }
            else
            {
                multiplyHours += moreHours;
            }
        }
    }
}