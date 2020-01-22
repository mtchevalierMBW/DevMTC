/**
 * WMK, LLC (c) - 2018 
 *
 * InventoryItemZPLTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 05/14/2019 
 * Work Item:    W-000676
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
@isTest(SeeAllData=True)
public class InventoryItemZPLTest {

    // unitTest
	//---------------------------------------
	static testMethod void unitTest() {

		rstk__icitem__c wo = [select Id from rstk__icitem__c limit 1];

		PageReference pgRef = Page.InventoryItemZPL; 
		Test.setCurrentPage(pgRef); //Set the page for Test Method
		ApexPages.currentPage().getParameters().put('id', wo.id);
		ApexPages.currentPage().getParameters().put('retURL', '/');
		InventoryItemZPL woctl = new InventoryItemZPL();
	}
}