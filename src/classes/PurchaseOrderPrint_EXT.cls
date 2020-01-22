/**
 * PurchaseOrderPrint_EXT
 * Tested by:
 * Written by: Bryan Leaman
 * Date: June 15, 2017
 * 
**/
public class PurchaseOrderPrint_EXT {

    private ApexPages.StandardController stdController;
    public dealer__Purchase_Order__c po;
    public List<dealer__Purchase_Order_Line__c> aPageOfLineItems {get; private set;}
    public String printedAtDT {get;private set;}
    
    public PurchaseOrderPrint_EXT(ApexPages.StandardController ctlr) {
        stdController = ctlr;
        po = (dealer__Purchase_Order__c) stdController.getRecord();
        //TimeZone tz = UserInfo.getTimeZone();
        printedAtDT = DateTime.now().format('MMMMMMMMM d, yyyy  h:mm a');

        Schema.DescribeSObjectResult dsr = dealer__Purchase_Order_Line__c.SObjectType.getDescribe();
        Map<String,Schema.SObjectField> sfMap = dsr.fields.getMap();
        List<String> fieldlist = new List<String>();
        for(String sof : sfMap.keySet()) {
            Schema.SObjectField f = sfMap.get(sof);
            if (f.getDescribe().isAccessible()) fieldlist.add(sof);
        }
        fieldlist.add('dealer__Part__r.Name');
        fieldlist.add('dealer__Part__r.dealer__Description__c');
        fieldlist.add('dealer__Service_Job_Line__r.Name');
        String polfields = String.join(fieldlist, ', ');
        String linesoql = 'select ' + polfields + ' from dealer__Purchase_Order_Line__c '
                + ' where dealer__Purchase_Order__c = \'' + po.Id + '\' '
                + ' order by Name ';
        aPageOfLineItems = Database.query(linesoql);
    }
    
}