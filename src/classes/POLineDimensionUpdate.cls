global class POLineDimensionUpdate implements Database.Batchable<dealer__Purchase_Order_Line__c> {
    
    //Query all the data object records to be migrated
    global List<dealer__Purchase_Order_Line__c> start(Database.BatchableContext BC) {
       return [SELECT Id, Dimension_1__c,dealer__Purchase_Order__r.dealer__Company__r.Financial_Force_Dimension_1__c,
                dealer__Part__r.Dealer__Status__c FROM dealer__Purchase_Order_Line__c where Dimension_1__c = null AND 
                dealer__Purchase_Order__r.dealer__Company__r.Financial_Force_Dimension_1__c != null AND 
                (dealer__Purchase_Order__r.dealer__Status__c = 'Accepted' OR dealer__Purchase_Order__r.dealer__Status__c = 'Open') AND 
                dealer__Purchase_Order__r.RecordType.Name = 'Vehicle Purchase'];
    }
    
    //Execute that records fetched from the query
    global void execute(Database.BatchableContext BC, List<dealer__Purchase_Order_Line__c> purchaseList) {
       //   PO Lines with dimension = null and PO status Open or Accepted
       for(dealer__Purchase_Order_Line__c objPurchase : purchaseList){
            objPurchase.Dimension_1__c = objPurchase.dealer__Purchase_Order__r.dealer__Company__r.Financial_Force_Dimension_1__c;
        }
        update purchaseList;
    }

    global void finish(Database.BatchableContext BC) {}
}