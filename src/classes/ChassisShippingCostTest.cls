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
*/
@isTest(SeeAllData=true)
public class ChassisShippingCostTest {

    public static testMethod void constructor()
    {
        List<rstk__porcptap__c> listOfReceipts = ([SELECT Id,
                                                        rstk__porcptap_poline__r.rstk__poline_proj__c
                                                    FROM rstk__porcptap__c 
                                                    WHERE rstk__porcptap_poline__r.rstk__poline_item__r.Name LIKE '%Vehicle Ship%' AND
                                                        rstk__porcptap_poline__r.rstk__poline_proj__c != 'AK Home Project' AND
                                                        rstk__porcptap_poline__r.rstk__poline_proj__c != 'SC Home Project' AND
                                                        rstk__porcptap_poline__r.rstk__poline_proj__c != 'KC Home Project' AND
                                                        rstk__porcptap_amtcomp__c > 0 AND
                                                        rstk__porcptap_qtycomp__c > 0
                                                    LIMIT 1]); 

        List<Id> listOfProjects = new List<Id>();
        
        for(rstk__porcptap__c tempReceipt : listOfReceipts)
        {
            listOfProjects.add(tempReceipt.rstk__porcptap_poline__r.rstk__poline_proj__c);
        }

        List<Chassis_Master__c> listOfChassis = ([SELECT Id, 
                                                    Outbound_Ship_Cost__c 
                                                FROM Chassis_Master__c
                                                WHERE Project_Master__c IN :listOfProjects AND
                                                    Outbound_Ship_Cost__c = 0]);

        Test.StartTest();

        ChassisShippingCost.updateChassisShipCost(listOfReceipts);

        for(Chassis_Master__c tempChassis : listOfChassis)
        {
            System.assertNotEquals(0, tempChassis.Outbound_Ship_Cost__c);
        }

        Test.StopTest();
    }
}