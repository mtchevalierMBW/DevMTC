/**
 * FloorplanLine_CTLR
 * Tested by: FloorplanLine_TEST
 * Date: Jan 18, 2016
 * Programmer: Bryan Leaman
 * 
 * 
 */
public with sharing class FloorplanLine_CTLR {

    public Map<String,FloorplanSummary> Summary {get; private set;}
    public Map<String,FloorplanLine__c> Floorplans {get; private set;}
    public Map<String,Decimal> Curtailments {get;private set;}

    public FloorplanLine_CTLR() {
        Summary = new Map<String,FloorplanSummary>();
        Floorplans = new Map<String,FloorplanLine__c>();
        Curtailments = new Map<String,Decimal>();
        retrieveFloorplans();
        calcFloorplanAmounts();
    }

    public Map<String,FloorplanLine__c> retrieveFloorplans() {
        for(FloorplanLine__c f : [
                select Id, Name, LineAmount__c
                from FloorplanLine__c
                where Active__c=true
                order by Name
            ]) {
            Floorplans.put(f.Name,f);
        }
        return Floorplans;
    }

    public void calcFloorplanAmounts() {
        Decimal TotalCurtailments = 0.00;
        
        // Add summary item for all active floorplans
        for(FloorplanLine__c f : Floorplans.values()) {
            Summary.put(f.Name, new FloorplanSummary(f.Name, f.Id, f.LineAmount__c));
        }
        
        // Get summarized amounts
        List<AggregateResult> ar = [
            select Chassis_Floorplan__c, dealer__Status_Code__c, 
                sum(Current_Floored_Amount__c) flooredamt, sum(dealer__Vehicle_Cost__c) vehiclecost,  sum(Conversion_Cost__c) conversioncost,
                sum(Curtailments__c) curtailments  
            from dealer__Vehicle_Inventory__c
            where Floorplanned__c=true and Paid__c=false and Current_Floored_Amount__c > 0
            //  and Chassis_Floorplan__c in :Floorplans
            group by Chassis_Floorplan__c, dealer__Status_Code__c
            order by Chassis_Floorplan__c
        ];
        System.debug(ar);
        if (ar.size()>0) {
            System.debug(ar[0]);
            String fp = (String) ar[0].get('Chassis_Floorplan__c');
            for(AggregateResult r : ar) {
                fp = (String) r.get('Chassis_Floorplan__c');
                Decimal Amount = (Decimal) r.get('flooredamt');
                String sts = (String) r.get('dealer__Status_code__c');
                Decimal curtailed = (Decimal) r.get('curtailments');
                FloorplanSummary fps = Summary.get(fp);
                if (fps!=null) {
                    TotalCurtailments += curtailed!=null ? curtailed : 0.00;
                    if (sts=='Delivered') fps.AmountDlvNotPaid += Amount;
                    else fps.AmountUsed += Amount;
                    fps.calcRemaining();
                }
            }
        }
        Curtailments.put('Total Curtailments', TotalCurtailments);
    }
    
    
    public class FloorplanSummary {
        public String Floorplan {get;set;}
        public Id FloorplanId {get;set;}
        public Decimal LineAmount {get;set;}
        public Decimal AmountUsed {get;set;}
        public Decimal AmountDlvNotPaid {get;set;}
        public Decimal Remaining {get;set;}
        
        public FloorplanSummary(String fp, Id fpId, Decimal line) {
            Floorplan = fp;
            FloorplanId = fpId;
            LineAmount = line;
            AmountUsed = 0.00;
            AmountDlvNotPaid = 0.00;
            Remaining = 0.00;
        }
        
        private Decimal nullZero(Decimal d) {
            return d==null ? 0.00 : d;
        }
        
        public void calcRemaining() {
            Remaining = nullZero(LineAmount) - nullZero(AmountUsed) - nullZero(AmountDlvNotPaid);
        }
    }

}