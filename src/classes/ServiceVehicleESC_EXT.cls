/**
 * ServiceVehicleESC_EXT
 * Tested by: ServiceVehicleESC_EXT_TEST
 * Date: May 4, 2018
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *  2018-05-04  100% (22/22)
 * 
 * Modification log:
 *
 *
 */

public with sharing class ServiceVehicleESC_EXT {
    private ApexPages.StandardController stdController;
    public SObject obj;
    public dealer__Service_Vehicle__c srvveh;
    public dealer__Service_Repair_Order__c sro;
    public dealer__Service_Estimate__c est;
    public List<dealer__Service_Contract__c> ServiceContracts {
        get { 
            System.debug(soql);
            return (srvveh!=null && srvveh.Id!=null) ? Database.query(soql) : new List<dealer__Service_Contract__c>(); 
        }
        private set;
    }
    private String soql;
    
    // extension constructor
    public ServiceVehicleESC_EXT(ApexPages.StandardController ctlr) {

        obj = (SObject) ctlr.getRecord();
        stdController = ctlr;
        setupQuery();

    }       
    
    public void setupQuery() {
        
        // Determine source: repair order, service vehicle, ...
        List<String> fields = new List<String>();
        if (obj.getSobjectType()==Schema.dealer__Service_Vehicle__c.SObjectType) srvveh = (dealer__Service_Vehicle__c) obj;
        if (obj.getSObjectType()==Schema.dealer__Service_Estimate__c.SObjectType) {
            est = [select Id, dealer__Service_Vehicle__c from dealer__Service_Estimate__c where Id=:obj.Id limit 1];
            srvveh = new dealer__Service_Vehicle__c(Id=est.dealer__Service_Vehicle__c);
        }
        if (obj.getSObjectType()==Schema.dealer__Service_Repair_Order__c.SObjectType) {
            sro = [select Id, dealer__Vehicle__c from dealer__Service_Repair_Order__c where Id=:obj.Id limit 1];
            srvveh = new dealer__Service_Vehicle__c(Id=sro.dealer__Vehicle__c);
        }

        // Select all fields from dealer__Service_Contract__c
        Map<String, Schema.SObjectField> objFieldMap =  Schema.dealer__Service_Contract__c.SObjectType.getDescribe().fields.getMap();
        List<String> objFieldList = new List<String>();
        for(string f : objFieldMap.keySet()) if (objFieldMap.get(f).getDescribe().isAccessible()) objFieldList.add(f);
        String objfields = String.join(objFieldList,',');
        soql = 'select ' + objfields 
            + ' from dealer__Service_Contract__c '
            + ' where dealer__Service_Vehicle__c = \'' + srvveh.Id + '\' '
            + '   and dealer__Car_Deal__c!=null and Proposal_status__c in (\'Won - Delivered\',\'Won - Posted\') '
            + ' order by dealer__Status__c NULLS LAST ';
        System.debug(obj);
        System.debug(est);
        System.debug(sro);
        System.debug(srvveh);
        System.debug(soql);
    }

}