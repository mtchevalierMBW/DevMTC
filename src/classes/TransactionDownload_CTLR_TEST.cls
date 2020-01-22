/**
 * TransactionDownload_CTLR_TEST
 * Tests: TransactionDownload_CTLR
 * 
 * 
 */
@isTest
private class TransactionDownload_CTLR_TEST{

 static testMethod void testController() {
        TransactionDownload_CTLR ctl = new TransactionDownload_CTLR();
        ctl.untilTransaction=null;
        ctl.overrideSelection=false;
        ctl.logSubmit();
        ctl.dummyProc();
        ctl.submitDownload();
        
    }
    }