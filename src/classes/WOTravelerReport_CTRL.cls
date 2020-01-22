/**
 * WOTravelerReport_CTRL
 * Tested by: WOTravelerReport_CTRL_TEST
 *
 *	2017-05-09	B. Leaman	BLL1 - Fix list of serialized components
 *	2017-12-01	B. Leaman	BLL2 - sequence by labor sequence number, department, item.
 */
public class WOTravelerReport_CTRL {
    public string strWONum {get;set;}
    public string strItemNum {get;set;}
    public string strItemDesc {get;set;}
    public string strSalesOrderLine {get;set;}
    public string strConfigurationSession {get;set;}
    public string strDateStart {get;set;}
    public string strDateDue {get;set;}
    public double dblQty {get;set;}
    public string strUOM {get;set;}
    
    public map<string, List<ItemWrapper>> GroupedList;
    //public List<rstk__woordsrl__c> SerializedParts {get;set;}
    public List<rstk__icitemsrl__c> SerializedComponents {get;set;}
    
    public map<string, List<ItemWrapper>> getGroupedList(){
        return GroupedList;
    }
    
    public WOTravelerReport_CTRL(){
        Id id = apexpages.currentpage().getparameters().get('id');
        
        GroupedList = new map<string, List<ItemWrapper>>();
        rstk__wocst__c WorkOrder = [SELECT Id
                , rstk__wocst_ordno__c
                , rstk__wocst_item__r.Name
                , rstk__wocst_item__r.rstk__icitem_descr__c
                , rstk__wocst_soline__r.rstk__soline_confsess__r.Name
                , rstk__wocst_duedte__c
                , rstk__wocst_lstschddtetime__c
                , rstk__wocst_qtyreq__c
                , rstk__wocst_item__r.rstk__icitem_invuom__r.Name
            FROM rstk__wocst__c
            WHERE Id = :id];
        
        // BLL1d This gets parts serialized to the work order, but not the correct serialized part record. :(
        //SerializedParts = [SELECT rstk__woordsrl_srlno__c
        //        , rstk__woordsrl_icitemsrl__r.Exterior_Color__c
        //        , rstk__woordsrl_icitemsrl__r.Factory_Order_Number__c
        //        , rstk__woordsrl_icitemsrl__r.Key_Tag__c
        //        , rstk__woordsrl_icitemsrl__r.Mfg_Make__c
        //        , rstk__woordsrl_icitemsrl__r.Mfg_Model_Ext__c
        //        , rstk__woordsrl_icitemsrl__r.Mfg_Year__c
        //    FROM rstk__woordsrl__c
        //    WHERE rstk__woordsrl_ordno__c = :id];
        // BLL1d end
        
        // BLL1a
        // Try again for serialized parts
        // Get list of components with serial#s
        List<rstk__woorddmdcst__c> WODemandWithSerialNumbers = [
			select Id, Name, rstk__woorddmdcst_woorddmd__c, rstk__woorddmdcst_compitem__c, rstk__woorddmdcst_srlno__c
			from rstk__woorddmdcst__c
			where rstk__woorddmdcst_woorddmd__r.rstk__woorddmd_ordno__c=:id
			  and rstk__woorddmdcst_srlno__c!=null
		];
		Set<String> srlinvnames = new Set<String>();
		Set<Id> srlinvitems = new Set<Id>();
		Set<String> srlinvnbrs = new Set<String>();
		for(rstk__woorddmdcst__c dtl : WODemandWithSerialNumbers) {
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
		// BLL1a end
        
        strWONum = WorkOrder.rstk__wocst_ordno__c;
        strItemNum = WorkOrder.rstk__wocst_item__r.Name;
        strItemDesc = WorkOrder.rstk__wocst_item__r.rstk__icitem_descr__c;
        strSalesOrderLine = WorkOrder.rstk__wocst_soline__r.rstk__soline_confsess__r.Name;
        if(WorkOrder.rstk__wocst_lstschddtetime__c != null){
            strDateStart = WorkOrder.rstk__wocst_lstschddtetime__c.month() + '/' + WorkOrder.rstk__wocst_lstschddtetime__c.day() + '/' + + WorkOrder.rstk__wocst_lstschddtetime__c.year();
        }
        if(WorkOrder.rstk__wocst_duedte__c != null){
            strDateDue = WorkOrder.rstk__wocst_duedte__c.month() + '/' + WorkOrder.rstk__wocst_duedte__c.day() + '/' + + WorkOrder.rstk__wocst_duedte__c.year();
        }
        dblQty = WorkOrder.rstk__wocst_qtyreq__c;
        strUOM = WorkOrder.rstk__wocst_item__r.rstk__icitem_invuom__r.Name;
        
        List<rstk__confdcomp__c> tempList = [
        	SELECT Id
        		, rstk__confdcomp_labseq__c	// BLL2a
            	, rstk__confdcomp_desc__c
            	, rstk__confdcomp_line__c
            	, rstk__confdcomp_rtindoper__c
            	, rstk__confdcomp_rtindoper__r.Name
            	, rstk__confdcomp_icitem__r.rstk__icitem_item__r.Name
            	, rstk__confdcomp_icitem__r.rstk__icitem_invuom__r.Name
            	, rstk__confdcomp_icitem__r.rstk__icitem_descr__c
            	, rstk__confdcomp_qtyper__c
            	, rstk__confdcomp_syuom__c 
            	, rstk__confdcomp_syuom__r.Name
            	, rstk__confdcomp_confsess__r.rstk__confsess_soline__r.rstk__soline_wocstordno__r.Name
            	, rstk__confdcomp_itemtype__c
        	FROM rstk__confdcomp__c
        	WHERE rstk__confdcomp_confsess__r.rstk__confsess_soline__r.rstk__soline_wocstordno__c = :id
        	ORDER BY rstk__confdcomp_labseq__c, rstk__confdcomp_rtindoper__r.Name, rstk__confdcomp_icitem__r.rstk__icitem_item__r.Name	// BLL2a
        ];
        
        for(rstk__confdcomp__c record:tempList) {
            if(!GroupedList.containsKey(record.rstk__confdcomp_desc__c)){
                GroupedList.put(record.rstk__confdcomp_desc__c, new List<ItemWrapper>());
            }
			ItemWrapper newItem = new ItemWrapper();
			if(record.rstk__confdcomp_itemtype__c == 'Labor'){
				newItem.strItemNum = record.rstk__confdcomp_rtindoper__r.Name;
				if(record.rstk__confdcomp_rtindoper__c != null){
					newItem.TaskList = [SELECT rstk__rtindopertask_desc__c
											, rstk__rtindopertask_assignto__r.Name
									   FROM rstk__rtindopertask__c
									   WHERE rstk__rtindopertask_rtindoper__c = :record.rstk__confdcomp_rtindoper__c];
				}
				newItem.dblHours = record.rstk__confdcomp_qtyper__c;
			} else {
				if(record.rstk__confdcomp_icitem__r.rstk__icitem_item__r.Name != null){
					newItem.strItemNum = record.rstk__confdcomp_icitem__r.rstk__icitem_item__r.Name.replaceAll('\\(.+?\\)','');
				}
				if(record.rstk__confdcomp_icitem__r.rstk__icitem_invuom__r.Name == null){
					newItem.strUOM = 'EACH';
				}
				else{
					newItem.strUOM = record.rstk__confdcomp_icitem__r.rstk__icitem_invuom__r.Name;
				}
				newItem.dblQty = record.rstk__confdcomp_qtyper__c;
			}
			newItem.lbrSeqNbr = record.rstk__confdcomp_labseq__c;	// BLL2a
			newItem.strDept = record.rstk__confdcomp_rtindoper__r.Name;	// BLL2a
			newItem.strItemDescr = record.rstk__confdcomp_icitem__r.rstk__icitem_descr__c;
			GroupedList.get(record.rstk__confdcomp_desc__c).add(newItem);
            
        }
    }
    public class ItemWrapper{
    	public Decimal lbrSeqNbr {get;set;}	// BLL2a
    	public String strDept {get;set;}	// BLL2a
        public string strItemNum {get;set;}
        public string strItemDescr {get;set;}
        public double dblQty {get;set;}
        public double dblHours {get;set;}
        public string strUOM {get;set;}
        public List<rstk__rtindopertask__c> TaskList {get;set;}
    }
}