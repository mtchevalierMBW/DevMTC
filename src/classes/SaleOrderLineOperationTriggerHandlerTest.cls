/**
 * WMK, LLC (c) - 2018 
 *
 * WorkOrderOperationTriggerHandlerTest
 * 
 * Created By:   Alexander Miller
 * Created Date: 10/3/2018 
 *
 * Modified By         Alias       Work Item       Date       Reason
 * -----------------------------------------------------------------
 * Alexander Miller    AMM1        IR-0050863     3/15/2019   Update to handle test class failure due to RS v19.6.2
 * Alexander Miller    AMM2        IR-0051388     3/25/2019   Update to handle test class failure
 */
@isTest(SeeAllData=true)
public class SaleOrderLineOperationTriggerHandlerTest {

    public static testMethod void testInsertion()
    {
        // AMM1
       	// rstk__soline__c line = [SELECT Id FROM rstk__soline__c WHERE rstk__soline_linestatustext__c = 'Planned' AND rstk__soline_line__c = 1 LIMIT 1];
        // rstk__rtproc__c process = [SELECT Id FROM rstk__rtproc__c WHERE rstk__rtproc_div__r.Name LIKE '%AK%' LIMIT 1];
        // rstk__rtwctr__c workCenter = [SELECT Id FROM rstk__rtwctr__c WHERE rstk__rtwctr_div__r.Name LIKE '%AK%' LIMIT 1];
        // rstk__rtlabgrd__c labGrade = [SELECT Id FROM rstk__rtlabgrd__c WHERE rstk__rtlabgrd_div__r.Name LIKE '%AK%' LIMIT 1];
        
        // rstk__sortoper__c tempOp = new rstk__sortoper__c();
        // tempOp.rstk__sortoper_soline__c = line.Id;
        // tempOp.rstk__sortoper_runhr__c= 1;
        // tempOp.rstk__sortoper_oper__c = 1;
        // tempOp.rstk__sortoper_type_pl__c = 'Standard Operation';
        // tempOp.rstk__sortoper_procno__c = process.Id;
        // tempOp.rstk__sortoper_wctr__c = workCenter.Id;
        // tempOp.rstk__sortoper_runlabgrd__c = labGrade.Id;
        // tempOp.rstk__sortoper_setuptype_pl__c = 'None';                         // Setup Time Type
        // tempOp.rstk__sortoper_runtype_pl__c = 'Per Piece';                      // Run Time Type
        // tempOp.rstk__sortoper_allowaccind__c = true;                            // Allow Accept,
        // tempOp.rstk__sortoper_movehr__c = 1;                                    // Move Hours
        // tempOp.rstk__sortoper_labmachschtype_pl__c = 'Subcontract & Labor';     // Schedule Type
        // tempOp.rstk__sortoper_movcompind_pl__c = 'Complete & Move in 1-step';   // Move/Complete
        // tempOp.rstk__sortoper_subltdays__c = 0;                                 // Subcontract Lead Time
        // tempOp.rstk__sortoper_stddivideby__c = 1;                               // Run Hours Divided By
        
        // insert tempOp;
        Test.StartTest();
		
        // AMM2
        //rstk__soline__c line = [SELECT Id, CreatedDate FROM rstk__soline__c WHERE rstk__soline_linestatustext__c = 'Planned' AND rstk__soline_line__c = 1 ORDER BY CreatedDate DESC LIMIT 1];
        rstk__soline__c line = [SELECT Id, CreatedDate FROM rstk__soline__c WHERE rstk__soline_linestatustext__c = 'Planned' AND rstk__soline_line__c = 1 AND rstk__soline_prodtype__c = 'Configured' ORDER BY CreatedDate DESC LIMIT 1];
        // AMM2
        rstk__rtproc__c process = [SELECT Id, CreatedDate FROM rstk__rtproc__c WHERE rstk__rtproc_div__r.Name LIKE '%AK%' ORDER BY CreatedDate DESC LIMIT 1];
        rstk__rtwctr__c workCenter = [SELECT Id, CreatedDate FROM rstk__rtwctr__c WHERE rstk__rtwctr_div__r.Name LIKE '%AK%' ORDER BY CreatedDate DESC LIMIT 1];
        rstk__rtlabgrd__c labGrade = [SELECT Id, CreatedDate FROM rstk__rtlabgrd__c WHERE rstk__rtlabgrd_div__r.Name LIKE '%AK%' ORDER BY CreatedDate DESC LIMIT 1];
        
        rstk__sortoper__c tempOp = new rstk__sortoper__c();
        tempOp.rstk__sortoper_soline__c = line.Id;
        tempOp.rstk__sortoper_runhr__c= 1;
        tempOp.rstk__sortoper_oper__c = 1;
        tempOp.rstk__sortoper_type_pl__c = 'Standard Operation';
        tempOp.rstk__sortoper_procno__c = process.Id;
        tempOp.rstk__sortoper_wctr__c = workCenter.Id;
        tempOp.rstk__sortoper_runlabgrd__c = labGrade.Id;
        tempOp.rstk__sortoper_setuptype_pl__c = 'None';                         // Setup Time Type
        tempOp.rstk__sortoper_runtype_pl__c = 'Per Piece';                      // Run Time Type
        tempOp.rstk__sortoper_allowaccind__c = true;                            // Allow Accept,
        tempOp.rstk__sortoper_movehr__c = 1;                                    // Move Hours
        tempOp.rstk__sortoper_labmachschtype_pl__c = 'Subcontract & Labor';     // Schedule Type
        tempOp.rstk__sortoper_movcompind_pl__c = 'Complete & Move in 1-step';   // Move/Complete
        tempOp.rstk__sortoper_subltdays__c = 0;                                 // Subcontract Lead Time
        tempOp.rstk__sortoper_stddivideby__c = 1;                               // Run Hours Divided By
        
        insert tempOp;
        Test.StopTest();
        // AMM1
	}
}