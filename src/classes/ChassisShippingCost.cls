/**
* ChassisShippingCost
*
* TransitWorks (c) - 2018
* 
* Tested By:
* Programmer: Alexander Miller
* Date: 3/26/2018
*
* Invokable class from Process Builder which 
* takes the sum of all PO Receipts for Vehicle Ship Charge
* on a particular project/chassis
*
* August 19th, 2018 Alexander Miller AMILLER1 - Realized this was grabbing all POs. This update only looks at shipping lines
*/
public class ChassisShippingCost{
   
    @InvocableMethod(
        label='Update Chassis Ship Cost' 
        description='Takes the Purchase Order Receipts and ensures that all PO Ship Costs have been account for in Chassis Master'
    )
    public static void updateChassisShipCost(List<rstk__porcptap__c> receipts) 
    {
        // 1. Get the Projects involved in this transaction
        List<Id> listOfProjectIds = new List<Id>();
        
        List<Id> listOfReceiptIds = new list<Id>();

        for(rstk__porcptap__c tempReceipt : receipts)
        {
            listOfReceiptIds.add(tempReceipt.Id);
        }
        
        System.debug(listOfReceiptIds);

        List<rstk__porcptap__c> listOfReceipts = ([SELECT Id, 
                                                    rstk__porcptap_poline__r.rstk__poline_proj__c 
                                                FROM rstk__porcptap__c 
                                                WHERE Id IN :listOfReceiptIds]);

        for(rstk__porcptap__c receiptItem : listOfReceipts)
        {
            listOfProjectIds.add(receiptItem.rstk__porcptap_poline__r.rstk__poline_proj__c);
        }

        System.debug(listOfProjectIds);

        // 2. Query for all PO Receipts of the same project
        listOfReceipts = ([SELECT Id,
                                rstk__porcptap_qtycomp__c,                          // Quantity 
                                rstk__porcptap_amtcomp__c,                          // Amount
                                rstk__porcptap_poline__r.rstk__poline_proj__c       // Project
                            FROM rstk__porcptap__c
                            WHERE rstk__porcptap_poline__r.rstk__poline_proj__c IN :listOfProjectIds AND
                          		rstk__porcptap_poline__r.rstk__poline_item__r.Name LIKE '%Vehicle Ship%' ]); // AMILLER1

        System.debug(listOfReceipts);

        // 3. Break all receipts into their own projects
        Map<Id, List<rstk__porcptap__c>> mapOfPoReceiptTrans = new Map<Id, List<rstk__porcptap__c>>();
        for(rstk__porcptap__c poItems : listOfReceipts)
        {
            if(mapOfPoReceiptTrans.get(poItems.rstk__porcptap_poline__r.rstk__poline_proj__c) == null)
            {
                mapOfPoReceiptTrans.put(poItems.rstk__porcptap_poline__r.rstk__poline_proj__c, new List<rstk__porcptap__c>());
            }

            mapOfPoReceiptTrans.get(poItems.rstk__porcptap_poline__r.rstk__poline_proj__c).add(poItems);
        }

        System.debug(mapOfPoReceiptTrans);

        // 4. Query for all Chassis Masters within those
        List<Chassis_Master__c> listOfChassisMaster = ([SELECT Id,
                                                             Outbound_Ship_Cost__c,
                                                             Project_Master__c
                                                        FROM Chassis_Master__c 
                                                        WHERE Project_Master__c IN :mapOfPoReceiptTrans.KeySet()]);

        System.debug(listOfChassisMaster);

        // 5. Update Chassis Masters
        for(Chassis_Master__c tempChassis : listOfChassisMaster)
        {
            Decimal totalCost = 0;

            for(rstk__porcptap__c tempPoLines : mapOfPoReceiptTrans.get(tempChassis.Project_Master__c))
            {
                totalCost += tempPoLines.rstk__porcptap_qtycomp__c * tempPoLines.rstk__porcptap_amtcomp__c;
            }

            tempChassis.Outbound_Ship_Cost__c = totalCost;
        }

        System.debug(listOfChassisMaster);

        update listOfChassisMaster;
    }
}