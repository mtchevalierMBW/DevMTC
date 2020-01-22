/**
 * SerialInvProcess_TEST
 * Tests: SerialInvProcess, Copy_PO_Data_To_Serial_Receipt
 * 
 * Cannot create test division, so we need to use SeeAllData=true!
 *
 * 5/13/2018 - Alexander Miller (AMILLER) - Updated due to picklist restrictions
 * 7/31/2018 - Alexander Miller (AMILLER1) - Update to handle failing test class for status validation rules
 * 2/15/2019 - Alexander Miller (AMM2) - IR-0049157 - Update ot handle RootStock 18.30 update which caused this to fail
 * Alexander Miller    AMM3        IR-0050863     3/15/2019   Update to handle test class failure due to RS v19.6.2
*/
@isTest(seeAllData=true)
public class SerialInvProcess_TEST {

    public static testMethod void unitTest() {
        rstk__sydiv__c div = [select Id, Name from rstk__sydiv__c limit 1];
        List<rstk__icitemsrl__c> nl = new List<rstk__icitemsrl__c>();
        nl.add(new rstk__icitemsrl__c(
            rstk__icitemsrl_serial__c = 'TestSerial#1'
        ));
        Map<String,chassis_Master__c> chassismap= new Map<String,chassis_master__c>();
	    chassismap.put('TestSerial#1', new chassis_master__c(
    	  year__c = '2017', 
    	  make__c = 'Toyota',
          Model__c = 'Sienna', // AMILLER
    	  //model_ext__c = 'Sienna', AMILLER
    	  Division__c = div.Id, 
    	  Key_Tag__c = 'Test123', 
    	  VIN__c = 'TestSerial#1'));
      // need chassis master to exist for some lines of code to execute
      insert(chassismap.values());	// BLLa 
      
      SerialInvProcess sip = new SerialInvProcess();
      sip.copyChassisDataToReceipt(nl);
      sip.copyChassisDataToReceipt(nl, chassismap);
    }

    public static testMethod void unitTestTrigger() {
        rstk__sydiv__c div = [select Id, Name from rstk__sydiv__c limit 1];
    //rstk__icitem_item__c ei = [select Id, Name from rstk__icitem_item__c where rstk__peitem_tracksrl_pl__c='Yes' limit 1]; 
        // AMM3
        //rstk__icitem__c im = [select Id, Name from rstk__icitem__c where rstk__icitem_item__r.rstk__peitem_tracksrl_pl__c='Yes' limit 1];
        rstk__icitem__c im = [select Id, Name, CreatedDate from rstk__icitem__c where rstk__icitem_item__r.rstk__peitem_tracksrl_pl__c='Yes' ORDER BY CreatedDate DESC limit 1];
        // AMM3

        Map<String,chassis_Master__c> chassismap= new Map<String,chassis_master__c>();
	    chassismap.put('TestSerial#1', new chassis_master__c(
    	  year__c = '2017', 
    	  make__c = 'Toyota',
          Model__c = 'Sienna', // AMILLER
    	  // model_ext__c = 'Sienna', AMILLER
    	  Division__c = div.Id, 
    	  Key_Tag__c = 'Test123', 
    	  VIN__c = 'TestSerial#1',
          Status__c = 'On Order' // AMILLER1
        ));
      	// need chassis master to exist for some lines of code to execute
      	insert(chassismap.values());	// BLLa 

        List<rstk__icitemsrl__c> nl = new List<rstk__icitemsrl__c>();
        nl.add(new rstk__icitemsrl__c(
            rstk__icitemsrl_div__c = div.Id,
            rstk__icitemsrl_item__c = im.Id,
            rstk__icitemsrl_srlno__c = 'TestSerial#1',
            rstk__icitemsrl_serial__c = 'TestSerial#1',
            // AMM2
            rstk__icitemsrl_lotno__c = '1',
            // AMM2
            rstk__icitemsrl_origin__c = 'P'
        ));
    insert(nl);        

    } 

}