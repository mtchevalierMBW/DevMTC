/**
 * SalesOrderLinTrigger
 * Tested by: SalesOrderDimensionProcess_TEST
 * Date: Jul 5, 2017
 * Programmer: Bryan Leaman
 *
 * August 17th, 2018 Alexander Miller AMILLER1 - Update to migrate workflow rules which are clashing with RS trigger processes
 * Alexander Miller - AMM1    - 1/17/2019 - IR-0047378 - Moving Sales Order Line process builder here to win opportunities automatically.
 * Alexander Miller - AMM2    - IR-0047426 - 1/24/2019 - Update to handle the insertion of the records so Product Names are pasted
 * Alexander Miller - AMM3    - W-000570   - 5/15/2019 - Update to handle moving Opportunity statuses on line creation
 */
trigger SalesOrderLinTrigger on rstk__soline__c (after insert, after update, before update, before insert) {

	MW_TriggerControls__c SalesOrderDimensionProcess = MW_TriggerControls__c.getInstance('SalesOrderDimensionProcess'); 
	if (SalesOrderDimensionProcess==null || SalesOrderDimensionProcess.Enabled__c==true) 
		new SalesOrderDimensionProcess(Trigger.new, Trigger.oldMap).updateLineDimensions();

	// AMILLER1
	SalesOrderLinTriggerHandler tempHandler = new SalesOrderLinTriggerHandler();

	// AMM2
	// if(Trigger.isUpdate)
	if((Trigger.isUpdate || Trigger.isInsert) && Trigger.isBefore)
	// AMM2
	{
		// setup the data
		List<rstk__soline__c> tempList = tempHandler.refreshAllFieldsNeeded(Trigger.new);

		tempHandler.salesOrderLineProductNamePasting(Trigger.new);

		tempHandler.salesOrderLineConfigurationSessionNamePasting(Trigger.new);

		tempHandler.salesOrderLineCopyDim1ToHeader(tempList);

		//AMM1
		tempHandler.winOpportunity(tempList);
		//AMM1

		// AMM3
		if(Trigger.isInsert)
		{
			tempHandler.salesOrderLinesCreatedOpportunity(Trigger.new);
		}
		// AMM3

		tempHandler.updateAllMaps();
	}
	// AMILLER1
}