/**
* MobilityWorks (c) - 2018
*
* vehicleInventoryQuickActions
*
* Created: 8/30/2018
* Developer: Alexander Miller
* Tested By: vehicleInventoryQuickActionsTest
*/
public with sharing class vehicleInventoryQuickActions {

    @AuraEnabled
	public static void arvhiceVehicle(Id vehicleId)
    {
        System.debug('vehicleInventoryQuickActions.arvhiceVehicle: ' + vehicleId);

        ArchiveVehicleInventory.archiveRecord(vehicleId);
    }

    @AuraEnabled
    public static Id cloneTemplate(Id vehicleId, String vin)
    {
        System.debug('vehicleInventoryQuickActions.cloneTemplate: ' + vehicleId + ' ' + vin);

        Id vehicleIdReturn = Test.isRunningTest() ? null : Id.valueOf(VehicleInventoryTemplateClone.createVehicleFromTemplate(String.valueOf(vehicleId), vin, ''));

        return vehicleIdReturn;
    }
}