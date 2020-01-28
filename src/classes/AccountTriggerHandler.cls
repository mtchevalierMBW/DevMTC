/**
 * AccountTriggerHandler
 * Tested by: AccountTriggerHandler_TEST.cls
 *
 * * Coverage:
 * 2020-01-24	100%    (31/31)
 *
 * 2020-01-23 M. Chevalier MTC1 Implemented updateClosestStorePerAccount
 * 2020-01-27 M. Chevalier MTC2 Refactored trigger and implemented trigger handler framework
 */

public with sharing class AccountTriggerHandler extends TriggerHandler {

    @TestVisible
    private List<Account>        accountsOld;
    @TestVisible
    private List<Account>        accountsNew;
    @TestVisible
    private Map<Id, Account>     accountsOldMap;
    @TestVisible
    private Map<Id, Account>     accountsNewMap;
    @TestVisible
    private Map<String, Boolean> controlFeatures;

    public AccountTriggerHandler() {
        this.accountsOld    = (List<Account>) Trigger.old;
        this.accountsNew    = (List<Account>) Trigger.new;
        this.accountsOldMap = (Map<Id, Account>) Trigger.oldMap;
        this.accountsNewMap = (Map<Id, Account>) Trigger.newMap;
        setupControlFeatures();
    }

    @TestVisible
    private void setupControlFeatures() {
        MW_TriggerControls__c accountCounty   = MW_TriggerControls__c.getInstance('AccountCounty');
        MW_TriggerControls__c accountRcdType  = MW_TriggerControls__c.getInstance('AccountRcdType');
        MW_TriggerControls__c accountRLCounts = MW_TriggerControls__c.getInstance('AccountRLCounts');
        MW_TriggerControls__c uploadHelper    = MW_TriggerControls__c.getInstance('uploadAccountHelper');
        this.controlFeatures = new Map<String, Boolean>{
                'accountCountyEnabled'  => (accountCounty != null)   ? accountCounty.Enabled__c   : false,
                'accountRcdTypeEnabled' => (accountRcdType != null)  ? accountRcdType.Enabled__c  : false,
                'accountRLCountsEnabled'=> (accountRLCounts != null) ? accountRLCounts.Enabled__c : false,
                'uploadHelperEnabled'   => (uploadHelper != null)    ? uploadHelper.Enabled__c    : false
        };
    }

    public override void beforeInsert() {
        AccountProcess.DefaultCompanyAssignment(accountsNew);
        AccountProcess.BuildDefaultDataValuesValidationsSummaries(accountsNew, accountsOldMap, controlFeatures);
    }

    public override void beforeUpdate() {
        AccountProcess.RestrictRecordTypeChanges(accountsNew, accountsOldMap);
        AccountProcess.BuildDefaultDataValuesValidationsSummaries(accountsNew, accountsOldMap, controlFeatures);
        AccountProcess.updateClosestStorePerAccount(accountsNew);
    }

    public override void beforeDelete() {
        AccountProcess.CleanUpInfluencerAssociations(accountsOld);
    }

    public override void afterInsert() {
        AccountProcess.AssignCountyJurisdiction(accountsNew, controlFeatures.get('accountCountyEnabled'));
    }

    public override void afterUpdate() {
        AccountProcess.UpdateRelatedObjectOwners(accountsNew, accountsOldMap);
        AccountProcess.AssignCountyJurisdiction(accountsNew, controlFeatures.get('accountCountyEnabled'));
    }
}