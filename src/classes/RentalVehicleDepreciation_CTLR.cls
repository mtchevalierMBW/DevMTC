/**
 * RentalVehicleDepreciation_CTLR
 * Tested by: RentalVehicleDepreciation_Tests
 *
 *  2016-08-17  MarinerTek
 *	2016-11-21	B. Leaman	BLL1 - reduce number per journal to avoid cpu time issues
 *	2016-12-01	B. Leaman	BLL2 - correct org Id so the email handler can be cleaned up
 *	2016-12-19	B. Leaman	BLL3 - add status code to output
 *	2017-05-18	B. Leaman	BLL4 - Change GL accounts & reduce queries used to get them.
 *	2017-07-20	B. Leaman	BLL5 - Correct logic on vehicle threshold
 */
public with sharing class RentalVehicleDepreciation_CTLR {
    public List<dealer__Vehicle_Inventory__c> vehicles {get; set;}
    public List<VehicleDepreciationWrapper> statusList {get;set;}
    public boolean allowSubmit {get;private set;}
    
    // BLL4d
    //public Id gl_1270 {get;set;}
    //public Id gl_4855 {get;set;}
    //public Id gl_8014 {get;set;}
    //public Id gl_1242 {get;set;}
    // BLL4d end
    // BLL4a
    private Set<String> glAcctNbrs = new Set<String>{'1270','1271','1272','8014','4855'};
    public Map<String,c2g__codaGeneralLedgerAccount__c> glAcctMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
    // BLL4a end
    
    public Boolean showDepreciateTable;
    public Boolean showSummaryTable;
    
    public RentalVehicleDepreciation_CTLR() {
        vehicles = [SELECT Id
            , dealer__Status_Code__c
            , Name
            , dealer__Year__c
            , dealer__Make__c
            , dealer__Model__c
            , dealer__Store_Location__r.Name
            , Rental_Vehicle_Costs__c
            , Rental_Depreciation_Exp__c
            , Rental_New_Vehicle_Cost__c
            , Insurance_Start_Date__c
            , dealer__Store_Location__r.Company__r.Id
            , dealer__Store_Location__r.Financial_Force_Dimension_1__c
            , dealer__Stock_Number__c
            , Last_Depreciation_Date__c
            , Chassis_Floorplan__c 
        FROM dealer__Vehicle_Inventory__c
        WHERE dealer__Status_Code__c IN ('Company Vehicle', 'Demo', 'Demo - Not for Sale', 'Rental','Rental - Not for sale')
        AND Chassis_Floorplan__c NOT IN ('Jefferson Leasing' ,'Union Leasing', 'Tempe')
        AND Rental_Vehicle_Costs__c > 1
        AND (Insurance_Start_Date__c = null OR Insurance_Start_Date__c < THIS_MONTH)
        AND dealer__Store_Location__r.Company__r.Id != NULL
        AND dealer__Store_Location__r.Financial_Force_Dimension_1__c != NULL
        AND (Last_Depreciation_Date__c < THIS_MONTH OR Last_Depreciation_Date__c = NULL)
        ORDER BY dealer__Store_Location__r.Company__r.Id];
        
        // BLL4d
        //gl_1270 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '1270'].Id;
        //gl_4855 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '4855'].Id;
        //gl_8014 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '8014'].Id;
        //gl_1242 = [SELECT Id FROM c2g__codaGeneralLedgerAccount__c WHERE c2g__ReportingCode__c  = '1242'].Id;
        // BLL4d end
        // BLL4a - ensure required GL accounts exist
        for(c2g__codaGeneralLedgerAccount__c gl : [
        	select Id, Name, c2g__ReportingCode__c 
        	from c2g__codaGeneralLedgerAccount__c 
        	where c2g__ReportingCode__c in :glAcctNbrs
        ]) glAcctMap.put(gl.c2g__ReportingCode__c,gl);
		for(String rc : new List<String>(glAcctNbrs)) {
        	if (!glAcctMap.containsKey(rc)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing GL Account ' + rc));
        }
        allowSubmit = glAcctNbrs.size()==glAcctMap.size();
        // BLL4a end
        
        StatusList = new List<VehicleDepreciationWrapper>();
        
        showDepreciateTable = true;
        showSummaryTable = false;
    }
    
    public List<dealer__Vehicle_Inventory__c> getVehicles() {
        return vehicles;
    }
    
    public List<VehicleDepreciationWrapper> getSummaryList() {
        return statusList;
    }
    
    public Boolean getShowDepreciateTable(){
        return showDepreciateTable;
    }
    
    public Boolean getShowSummaryTable(){
        return showSummaryTable;
    }
    
    public void submitDepreciation(){
        Integer vehicleThreshold = 124;
        vehicleThreshold = 100;	// BLL1a
        Integer vehicleCount = 0;
        Organization org = [select Id, Name from Organization limit 1];	// BLL2a
        
        String vehicleIds = '';
        ID idHolder = vehicles[0].dealer__Store_Location__r.Company__r.Id;
        String strCompany = '';
        String csvString = 'Floorplan,Status,Vehicle,Year,Make,Model,Store Location,Vehicle Cost,Depreciation Exp,New Vehicle Cost,Insurance Start Date,Status\n';	// BLL3c add status
        List<String> payloadList = new List<String>();
        
        for(dealer__Vehicle_Inventory__c item : vehicles){
            if(item.dealer__Store_Location__r.Company__r.Id == null || item.dealer__Store_Location__r.Financial_Force_Dimension_1__c == null){
                csvString = csvString + item.Chassis_Floorplan__c + ','
                	+ item.dealer__Status_Code__c + ','		// BLL3a
                	+ item.Name + ',' + item.dealer__Year__c + ',' + item.dealer__Make__c + ',' + item.dealer__Model__c + ',' 
                	+ item.dealer__Store_Location__r.Name.replace(',','') + ',' + item.Rental_Vehicle_Costs__c + ',' + item.Rental_Depreciation_Exp__c + ',' + item.Rental_New_Vehicle_Cost__c + ',' + item.Insurance_Start_Date__c + ',Vehicle could not be submitted for depreciation\n';
                VehicleDepreciationWrapper wrapper = new VehicleDepreciationWrapper();
                wrapper.vehicle = item;
                wrapper.Status = 'Vehicle could not be submitted for depreciation';
                StatusList.Add(wrapper);
            }
            else{
                String strGLCode1 = '';
                String strGLCode2 = '';
                if(idHolder != null){
                    strCompany = '"' + idHolder + '"';
                    
                    if(idHolder == item.dealer__Store_Location__r.Company__r.Id && vehicleCount <= vehicleThreshold){	// BLL5c correct logic on vehicleThreshold (was  || vehicleCount >= )
                        csvString = csvString + item.Chassis_Floorplan__c + ',' 
		                	+ item.dealer__Status_Code__c + ','		// BLL3a
                        	+ item.Name + ',' + item.dealer__Year__c + ',' + item.dealer__Make__c + ',' + item.dealer__Model__c + ',' 
	                        + item.dealer__Store_Location__r.Name.replace(',','') + ',' + item.Rental_Vehicle_Costs__c + ',' + item.Rental_Depreciation_Exp__c + ',' + item.Rental_New_Vehicle_Cost__c + ',' + item.Insurance_Start_Date__c + ',Vehicle submitted for depreciation\n';
                        VehicleDepreciationWrapper wrapper = new VehicleDepreciationWrapper();
                        wrapper.vehicle = item;
                        wrapper.Status = 'Vehicle submitted for depreciation';
                        StatusList.Add(wrapper);
                        vehicleIds = vehicleIds + item.Id + '+';
                        vehicleCount = vehicleCount + 1;
                    }
                    else{
                        system.debug('Useremail: ' + UserInfo.getUserEmail());
                        if(vehicleIds != ''){
                            vehicleIds = vehicleIds.substring(0,vehicleIds.length()-1);
                            String strCurrentPayload = '{"recordId" : ' + strCompany
                                            + ', "orgId" : "' + org.Id + '"' // BLL2c was  + strCompany
                                            + ', "requestedBy" : "' + UserInfo.getUserId() + '"'
                                            + ', "action" : "depreciate_rental"'
                                            + ', "vehicleIds" : "' + vehicleIds + '"'
                                			+ ', "emailRecipient" : "' + UserInfo.getUserEmail() + '"'
                                            + '}';
                            System.debug('MARINERTEK ' + strCurrentPayload);
                            payloadList.add(strCurrentPayload);
                            //FFAccounting.emailAsyncHandler(strCurrentPayload);
                        }
                        vehicleIds = '';
                        vehicleCount = 0;
                        csvString = csvString + item.Chassis_Floorplan__c + ',' 
		                	+ item.dealer__Status_Code__c + ','		// BLL3a
                        	+ item.Name + ',' + item.dealer__Year__c + ',' + item.dealer__Make__c + ',' + item.dealer__Model__c + ',' 
                        	+ item.dealer__Store_Location__r.Name.replace(',','') + ',' + item.Rental_Vehicle_Costs__c + ',' + item.Rental_Depreciation_Exp__c + ',' + item.Rental_New_Vehicle_Cost__c + ',' + item.Insurance_Start_Date__c + ',Vehicle submitted for depreciation\n';
                        VehicleDepreciationWrapper wrapper = new VehicleDepreciationWrapper();
                        wrapper.vehicle = item;
                        wrapper.Status = 'Vehicle submitted for depreciation';
                        StatusList.Add(wrapper);
                        vehicleIds = vehicleIds + item.Id + '+';
                    }
                    
                }
                idHolder = item.dealer__Store_Location__r.Company__r.Id;
            }
            
        }
        
        if(vehicleIds != ''){
            vehicleIds = vehicleIds.substring(0,vehicleIds.length()-1);
            String strCurrentPayload = '{"recordId" : ' + strCompany
                            + ', "orgId" : "' + org.Id + '"' // BLL2c was  + strCompany
                            + ', "requestedBy" : "' + UserInfo.getUserId() + '"'
                            + ', "action" : "depreciate_rental"'
                            + ', "vehicleIds" : "' + vehicleIds + '"'
                            + ', "emailRecipient" : "' + UserInfo.getUserEmail() + '"'
                            + '}';
            payloadList.add(strCurrentPayload);
            System.debug('MARINERTEK ' + strCurrentPayload);
            //FFAccounting.emailAsyncHandler(strCurrentPayload);
        }
        
        if(payloadList.size() > 0){
            FFAccounting.emailAsyncHandler(payloadList);
        }
        ContentVersion file = new ContentVersion(
          title = 'DepreciationSummary-' + date.today() + '.csv',
          versionData = Blob.valueOf(csvString),
          pathOnClient = '/DepreciationSummary-' + date.today() + '.csv'
        );
 
        insert file;
        
        showDepreciateTable = false;
        showSummaryTable = true;
    }
    
    public class VehicleDepreciationWrapper{
        public dealer__Vehicle_Inventory__c vehicle {get;set;}
        public String Status {get;set;}
        public VehicleDepreciationWrapper(){
            vehicle = new dealer__Vehicle_Inventory__c();
            Status = '';
        }
    }
    //public String recordId {get;set;}
    //public String orgId {get;set;}
    //public Id requestedBy {get;set;}
    //public String action {get;set;}
    //public Decimal partsReceiptValue {get;set;}
}