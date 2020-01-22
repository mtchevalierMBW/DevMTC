/**
 * WOTravelerReport3
 * Tested by: 
 * Programmer: Alexander Miller
 * Date: 4/24/2018
 *
 * 8/14/2018 - Alexander Miller - AMILLER2 - Update to add the Frame field to the report
 * Alexander Miller - 1/23/2019 - AMM3 - IR-0047743 - Update to handle changing the Scheduled Start Date from Last Scheduling date to Scheduled pick date
 * Alexander Miller - 4/29/2019 - AMM4 - W-000653 - Update to handle barcoding
 * Alexander Miller - 5/10/2019 - AMM5 - IR-0054300 - Update to handle correct Qty field on the Work Order Componet
 */
public class WOTravelerReport3 {
    
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
    
    public String vin {get;set;}
    
    public String year {get;set;}
    
    public String make {get;set;}
    
    public String model {get;set;}

    public String modelExt {get;set;}
    
    public String keyTag {get;set;}
    
    public String extColor {get;set;}
    
    public String frame {get;set;}
    
    // AMM4 
    public String barcode {get;set;}
    // AMM4
    
    public List<rstk__confcomp__c> listOfComponentsFromConfigurator {get;set;}
    
    public rstk__wocst__c WorkOrder;

    public map<Decimal, List<ItemWrapper>> GroupedList {get; private set;} 
    
    public List<ItemWrapper> GroupedDumpList {get; private set;} 
    
    public List<rstk__icitemsrl__c> SerializedComponents {get;set;}
    
    public WOTravelerReport3()
    {        
        Id workOrderId = apexpages.currentpage().getparameters().get('id');
        
        GroupedList = new Map<Decimal, List<ItemWrapper>>();
        GroupedDumpList = new List<ItemWrapper>();

        // 1. Gather Work Order Info and assign global variables the needed info
        WorkOrder = getWorkOrderInfo(workOrderId);
        vin = WorkOrder.Chassis__r.VIN__c;
        year = WorkOrder.Chassis__r.Year__c;
        make = WorkOrder.Chassis__r.Make__c;
        model = WorkOrder.Chassis__r.Model__c;
        modelExt = WorkOrder.Chassis__r.Model_Ext__c;
        keyTag = WorkOrder.Chassis__r.Key_Tag__c;
        extColor = WorkOrder.Chassis__r.Exterior_Color__c;
        frame = WorkOrder.Chassis__r.Frame__c;
        
        // AMM4
        barcode = 'http://www.barcodes4.me/barcode/c128b/' + WorkOrder.Name + '.png?IsTextDrawn=1&IsBorderDrawn=1&width=250&height=100'; 
        // AMM4  

        // 2. Get list of components with serial#s
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

        SerializedComponents = getListOfSerializedItems(srlinvitems, srlinvnbrs);
        
        strWONum = WorkOrder.rstk__wocst_ordno__c;
        strItemNum = WorkOrder.rstk__wocst_item__r.Name;//.substringBefore('(');
        
        // TODO do I really need this? Can't it only look at the parent Sales Order?
        if(WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__c != null)
        {
            strItemDesc = WorkOrder.rstk__wocst_item__r.rstk__icitem_descr__c;//.substringBefore('(');
            strSalesOrderLine = WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_confsess__r.Name;//.substringBefore('(');
            strSalesOrderId = WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_sohdr__c;    
            strSalesOrderHdr = WorkOrder.rstk__wocst_soline__r.Origin_Sales_Order_Line__r.rstk__soline_sohdr__r.Name;  
            // AMM3 
            //if(WorkOrder.rstk__wocst_lstschddtetime__c != null){
            //     
            //    strDateStart = WorkOrder.rstk__wocst_lstschddtetime__c.month() + '/' + WorkOrder.rstk__wocst_lstschddtetime__c.day() + '/' + + WorkOrder.rstk__wocst_lstschddtetime__c.year();
            //    
            //}
            
            if(WorkOrder.rstk__wocst_schedpickdte__c != null){
                strDateStart = WorkOrder.rstk__wocst_schedpickdte__c.month() + '/' + WorkOrder.rstk__wocst_schedpickdte__c.day() + '/' + + WorkOrder.rstk__wocst_schedpickdte__c.year();
            }
            // AMM3
            if(WorkOrder.rstk__wocst_duedte__c != null){
                strDateDue = WorkOrder.rstk__wocst_duedte__c.month() + '/' + WorkOrder.rstk__wocst_duedte__c.day() + '/' + + WorkOrder.rstk__wocst_duedte__c.year();
            }
            dblQty = WorkOrder.rstk__wocst_qtyreq__c;
            strUOM = WorkOrder.rstk__wocst_item__r.rstk__icitem_invuom__r.Name;
        }
        else
        {
            strItemDesc = WorkOrder.rstk__wocst_item__r.rstk__icitem_descr__c;//.substringBefore('(');
            strSalesOrderLine = WorkOrder.rstk__wocst_soline__r.rstk__soline_confsess__r.Name;//.substringBefore('(');
            strSalesOrderId = WorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__c;    
            strSalesOrderHdr = WorkOrder.rstk__wocst_soline__r.rstk__soline_sohdr__r.Name;  
            // AMM3
            // if(WorkOrder.rstk__wocst_lstschddtetime__c != null){
            //     strDateStart = WorkOrder.rstk__wocst_lstschddtetime__c.month() + '/' + WorkOrder.rstk__wocst_lstschddtetime__c.day() + '/' + + WorkOrder.rstk__wocst_lstschddtetime__c.year();
            // }
            if(WorkOrder.rstk__wocst_schedpickdte__c != null){
                strDateStart = WorkOrder.rstk__wocst_schedpickdte__c.month() + '/' + WorkOrder.rstk__wocst_schedpickdte__c.day() + '/' + + WorkOrder.rstk__wocst_schedpickdte__c.year();
            }
            // AMM3
            if(WorkOrder.rstk__wocst_duedte__c != null){
                strDateDue = WorkOrder.rstk__wocst_duedte__c.month() + '/' + WorkOrder.rstk__wocst_duedte__c.day() + '/' + + WorkOrder.rstk__wocst_duedte__c.year();
            }
            dblQty = WorkOrder.rstk__wocst_qtyreq__c;
            strUOM = WorkOrder.rstk__wocst_item__r.rstk__icitem_invuom__r.Name;
        }
       
        // 3. Gather the work order component info
        List<rstk__woorddmd__c> workOrderComponents = getWorkOrderComponentInfo(workOrderId);
    
        // 4. Gather the work order labor info
        List<rstk__woordop__c> woopers = getWorkOrderLaborInfo(workOrderId);

        // 5. Generate PDF line mapping of inventory, products, and labor
        GroupedList = getListOfPdfLine(workOrderComponents,woopers);

        // 7. Generate PDF lines mapping of inventory, products, and labor of lines which didn't have any associate with Operation #
        GroupedList = getListOfPdfLineWithNoSequenceAssociation(GroupedList, workOrderComponents, woopers);
    }

    /**
    * getListOfPdfLineWithNoSequenceAssociation
    *
    * Function which takes the work order components, labor, and 
    * converts them into lines ready for the PDF generation.
    *
    * The line needs to accomidate:
    * - Operation #
    * - Work Center
    * - Product
    * - Hours
    * - Item
    * - Item Description
    * - Qty
    * - UOM
    */
    public Map<Decimal, List<ItemWrapper>> getListOfPdfLineWithNoSequenceAssociation(Map<Decimal, List<ItemWrapper>> groupList, List<rstk__woorddmd__c> workOrderComponents, List<rstk__woordop__c> woopers)
    {
        Map<Decimal, List<ItemWrapper>> mapToReturn = groupList;

        // get list of components which did not match any labor sequences
        List<rstk__woorddmd__c> listOfComponents = getComponentsNotMatchingSequences(workOrderComponents,woopers);

        for(rstk__woorddmd__c tempComponent : listOfComponents)
        {
            if(mapToReturn.get(tempComponent.rstk__woorddmd_oper__c) == null)
            {
                mapToReturn.put(tempComponent.rstk__woorddmd_oper__c, new List<ItemWrapper>());
            }

            ItemWrapper newItem = new ItemWrapper();

            newItem.strDept = getWorkCenterFromOperationNumber(workOrderComponents, tempComponent.rstk__woorddmd_oper__c);
            newItem.lbrSeqNbr = tempComponent.rstk__woorddmd_oper__c;  
            newItem.strProduct = getProductMasterFromOperationNumber(workOrderComponents, woopers, tempComponent.rstk__woorddmd_oper__c);
                        
            if(tempComponent.rstk__woorddmd_compitem__r.Name != null)
            {
                newItem.strItemNum = tempComponent.rstk__woorddmd_compitem__r.Name.replaceAll('\\(.+?-_\\)','').replaceAll('[_]', ' ');
            } 

            if(tempComponent.rstk__woorddmd_invuom__r.Name.contains('EA'))
            { 
                newItem.strUOM = 'EA';
            }
            else 
            {
                newItem.strUOM = tempComponent.rstk__woorddmd_invuom__r.Name;
            }

            // AMM5
            //newItem.dblQty = tempComponent.rstk__woorddmd_compqty_qtyreq_ui__c;
            newItem.dblQty = tempComponent.rstk__woorddmd_qtyreq__c;
            // AMM5
            newItem.lbrSeqNbr = tempComponent.rstk__woorddmd_oper__c;   
            newItem.strItemDescr = tempComponent.rstk__woorddmd_compitem__r.rstk__icitem_descr__c.replaceAll('[-]', ' ').replaceAll('[_]', ' ');

            mapToReturn.get(tempComponent.rstk__woorddmd_oper__c).add(newItem);  
        }

        return mapToReturn;
    }

    public List<rstk__woorddmd__c> getComponentsNotMatchingSequences(List<rstk__woorddmd__c> workOrderComponents, List<rstk__woordop__c> woopers)
    {
        List<rstk__woorddmd__c> listOfComponentsToBucketAtBottom = new List<rstk__woorddmd__c>();

        // Gather all the known sequences for labor as a base-line
        Set<Decimal> setOfSequences = new Set<Decimal>();

        for(rstk__woordop__c op : woopers)
        {
            setOfSequences.add(op.rstk__woordop_oper__c);
        }

        // check the bucket of components for ones not matching the sequences found in labor
        for(rstk__woorddmd__c component : workOrderComponents)
        {
            if(!setOfSequences.contains(component.rstk__woorddmd_oper__c))
            {
                listOfComponentsToBucketAtBottom.add(component);
            }
        }

        return listOfComponentsToBucketAtBottom;
    }

    /**
    * getListOfPdfLine
    *
    * Function which takes the work order components, labor, and 
    * converts them into lines ready for the PDF generation.
    *
    * The line needs to accomidate:
    * - Operation #
    * - Work Center
    * - Product
    * - Hours
    * - Item
    * - Item Description
    * - Qty
    * - UOM
    */
    public Map<Decimal, List<ItemWrapper>> getListOfPdfLine(List<rstk__woorddmd__c> workOrderComponents, List<rstk__woordop__c> woopers)
    {
        Map<Decimal, List<ItemWrapper>> mapToReturn = new Map<Decimal, List<ItemWrapper>>();

        for(rstk__woordop__c tempLabor : woopers)
        {
            if(mapToReturn.get(tempLabor.rstk__woordop_oper__c) == null)
            {
                mapToReturn.put(tempLabor.rstk__woordop_oper__c, new List<ItemWrapper>());
            }

            ItemWrapper operline = new ItemWrapper();
            operline.strItemNum = tempLabor.Name.replaceAll('\\(.+?\\)','').replaceAll('[-]', ' ').replaceAll('[_]', ' ');
            operline.strDept = tempLabor.rstk__woordop_wctr__r.Name.substringBefore('('); 
            operline.lbrSeqNbr = tempLabor.rstk__woordop_oper__c;  
            operline.dblHours = tempLabor.rstk__woordop_runhrstd__c;
            operline.strProduct = getProductMasterFromOperationNumber(workOrderComponents, woopers, tempLabor.rstk__woordop_oper__c);//.substringBefore('(');

            mapToReturn.get(tempLabor.rstk__woordop_oper__c).add(operline);

            // Add inventory below
            List<rstk__woorddmd__c> listOfComponents = getListOfInventoryByProductAndLaborSequence(workOrderComponents, tempLabor.rstk__woordop_oper__c);

            for(rstk__woorddmd__c tempComponent : listOfComponents)
            {
                ItemWrapper newItem = new ItemWrapper();
                            
                if(tempComponent.rstk__woorddmd_compitem__r.Name != null)
                {
                    newItem.strItemNum = tempComponent.rstk__woorddmd_compitem__r.Name.replaceAll('\\(.+?-_\\)','').replaceAll('[_]', ' ');//.substringBefore('(');
                } 

                if(tempComponent.rstk__woorddmd_invuom__r.Name.contains('EA'))
                { 
                    newItem.strUOM = 'EA';
                }
                else 
                {
                    newItem.strUOM = tempComponent.rstk__woorddmd_invuom__r.Name;
                }

                newItem.dblQty = tempComponent.rstk__woorddmd_compqty_qtyreq_ui__c;
                newItem.lbrSeqNbr = tempLabor.rstk__woordop_oper__c;    
                newItem.strItemDescr = tempComponent.rstk__woorddmd_compitem__r.rstk__icitem_descr__c.replaceAll('[-]', ' ').replaceAll('[_]', ' ');
                
                System.debug(tempLabor.rstk__woordop_oper__c);
                System.debug(GroupedList.get(tempLabor.rstk__woordop_oper__c));

                mapToReturn.get(tempLabor.rstk__woordop_oper__c).add(newItem);  
            }
        }

        return mapToReturn;
    }

    /**
    * getListOfInventoryByProductAndLaborSequence
    *
    * Function which gathers the work order components by Product and operation number
    */
    public List<rstk__woorddmd__c> getListOfInventoryByProductAndLaborSequence(List<rstk__woorddmd__c> workOrderComponents, Decimal sequenceNumber)
    {
        List<rstk__woorddmd__c> listOfComponentsReturn = new List<rstk__woorddmd__c>();

        for(rstk__woorddmd__c component : workOrderComponents)
        {
            if(component.rstk__woorddmd_oper__c == sequenceNumber)
            {
                listOfComponentsReturn.add(component);
            }
        }

        return listOfComponentsReturn;
    }

    /**
    * getWorkOrderInfo
    * 
    * function which gets the work order component Product Master when the operation number matches
    */
    public String getProductMasterFromOperationNumber(List<rstk__woorddmd__c> workOrderComponents, List<rstk__woordop__c> woopers, Decimal sequenceNumber)
    {
        for(rstk__woorddmd__c comp : workOrderComponents)
        {
            if(comp.rstk__woorddmd_oper__c == sequenceNumber)
            {
                return comp.Product_Master__r.Name;
            }
        }

        return getProductMasterFromLaborNumber(woopers, sequenceNumber);
    }

    /**
    * getWorkOrderInfo
    * 
    * function which gets the work order component Product Master when the operation number matches
    */
    public String getProductMasterFromLaborNumber(List<rstk__woordop__c> woopers, Decimal sequenceNumber)
    {
        for(rstk__woordop__c comp : woopers)
        {
            if(comp.rstk__woordop_oper__c == sequenceNumber)
            {
                return comp.Product_Master__r.Name;
            }
        }

        return 'NOT FOUND';
    }

    /**
    * getWorkCenterFromOperationNumber
    * 
    * function which gets the work order component Work Center when the operation number matches
    */
    public String getWorkCenterFromOperationNumber(List<rstk__woorddmd__c> workOrderComponents, Decimal sequenceNumber)
    {
        for(rstk__woorddmd__c comp : workOrderComponents)
        {
            if(comp.rstk__woorddmd_oper__c == sequenceNumber)
            {
                return comp.rstk__woorddmd_wctr__r.Name;
            }
        }

        return 'NOT FOUND';
    }

    /**
    * getWorkOrderInfo
    * 
    * function which gets the work order header info for the PDF
    */
    public rstk__wocst__c getWorkOrderInfo(Id workOrderId)
    {
        return [SELECT Id
            , Chassis__c                                        // AMILLER1
            , Chassis__r.VIN__c
            , Chassis__r.Year__c
            , Chassis__r.Make__c
            , Chassis__r.Model__c
            , Chassis__r.Model_Ext__c
            , Chassis__r.Key_Tag__c
            , Chassis__r.Exterior_Color__c                     // / AMILLER1
            , Chassis__r.Frame__c                              // / AMILLER2
            , rstk__wocst_ordno__c
            , rstk__wocst_item__r.Name
            , rstk__wocst_item__r.rstk__icitem_descr__c
            , rstk__wocst_soline__r.rstk__soline_confsess__r.Name
            , rstk__wocst_duedte__c
            , rstk__wocst_lstschddtetime__c
            , rstk__wocst_schedpickdte__c                       // AMM3
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
            // AMM4
            , Name
            // AMM4
        FROM rstk__wocst__c
        WHERE Id = :workOrderId LIMIT 1];
    }

    /**
    * getWorkOrderComponentInfo
    * 
    * function which gets the work order component info for the PDF
    */
    public List<rstk__woorddmd__c> getWorkOrderComponentInfo(Id workOrderId)
    {
        return ([SELECT Id, 
                        Name, 
                        rstk__woorddmd_lne__c, 
                        rstk__woorddmd_desc__c, 
                        rstk__woorddmd_compitem__c, 
                        rstk__woorddmd_compitem__r.Name, 
                        rstk__woorddmd_compitem__r.rstk__icitem_descr__c,
                        rstk__woorddmd_compqty_qtyreq_ui__c, 
                        rstk__woorddmd_qtyreq__c,
                        rstk__woorddmd_invuom__c, 
                        rstk__woorddmd_invuom__r.Name,  
                        rstk__woorddmd_dmdsts__c, 
                        rstk__woorddmd_dmdsts_pl__c, 
                        rstk__woorddmd_issue_sts_pl__c,  
                        rstk__woorddmd_oper__c, 
                        rstk__woorddmd_wctr__c, 
                        Product_Master__c,
                        Product_Master__r.Name,
                        rstk__woorddmd_wctr__r.Name
                FROM rstk__woorddmd__c
                WHERE rstk__woorddmd_ordno__c = :workOrderId]);
    }

    /**
    * getWorkOrderLaborInfo
    * 
    * function which gets the work order labor info for the PDF
    */
    public List<rstk__woordop__c> getWorkOrderLaborInfo(Id workOrderId)
    {
        return ([SELECT Id, 
                        Name, 
                        rstk__woordop_oper__c, 
                        rstk__woordop_descr__c,
                        rstk__woordop_wctr__c, 
                        rstk__woordop_wctr__r.Name,
                        rstk__woordop_setuphrstd__c, 
                        rstk__woordop_machhrstd__c, 
                        rstk__woordop_runhrstd__c,
                        Product_Master__c,
                        Product_Master__r.Name,
                        ( SELECT Id, 
                                Name, 
                                rstk__woopertask_desc__c, 
                                rstk__woopertask_comments__c,
                                rstk__woopertask_assignto__c, 
                                rstk__woopertask_assignto__r.Name 
                                FROM rstk__woopertasks__r)
                FROM rstk__woordop__c
                WHERE rstk__woordop_ordno__c = :workOrderId]);
    }

    /**
    * getListOfSerializedItems
    * 
    * function which gets the work order serialized info for the PDF
    */
    public List<rstk__icitemsrl__c> getListOfSerializedItems(Set<Id> srlinvitems, Set<String> srlinvnbrs)
    {
        return ([SELECT Id, 
                        Name, 
                        rstk__icitemsrl_item__c,
                        rstk__icitemsrl_srlno__c, 
                        Exterior_Color__c,
                        Factory_Order_Number__c, 
                        Key_Tag__c, 
                        Mfg_Make__c, 
                        Mfg_Model_Ext__c, 
                        Mfg_Year__c
                FROM rstk__icitemsrl__c
                WHERE rstk__icitemsrl_item__c in :srlinvitems
                AND rstk__icitemsrl_srlno__c in :srlinvnbrs]);
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
}