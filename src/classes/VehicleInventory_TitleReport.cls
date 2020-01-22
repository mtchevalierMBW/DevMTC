/**
* VehicleInventory_TitleReport
* Used in VehicleInventory_TitleReport.vfp
* Tested by: VehicleInventory_TitleReport_Test
*
* Coverage:
*   2018-10-30  80% (34/42)
*
*  Date        	Programmer  Work item   Mod# Description
*  2016-10-04	A. Bangle	            Created Class
*  2016-12-01	A. Bangle	            Created Test Class
*  2018-10-30   B. Leaman   W-000475    BLL1 Add fields: source, the total vehicle cost and the purchase date;
*                                       Ensure "days" column is # days since purchase (today - purchase date)

*/

public class VehicleInventory_TitleReport {
    public String vin_stock {get;set;}
    public String location {get;set;}
    public String filter {get;set;}
    public String test {get;set;}
    public Integer recordstotal {get;set;}
    public Integer recordsmissing {get;set;}
    public Decimal recordsage {get;set;}
    public transient List<dealer__Vehicle_Inventory__c> vehicles {get;private set;}
    public VehicleInventory_TitleReport() {
        filter = 'missingonly';
		user currentuser = [SELECT division from user where id = :userinfo.getUserId()];
        List<dealer__Dealer_Location__c> userlocs = [SELECT id from dealer__Dealer_Location__c where dealer__Company_Number__c = :currentuser.division];
        if (userlocs.size() > 0) {location = userlocs[0].id;}
        vehicles_query();
    }
    //public void donothing() {}
    public void vehicles_query() {
        recordstotal = 0;
        recordsmissing = 0;
        recordsage = 0;
        vehicles = new List<dealer__Vehicle_Inventory__c>();
        if(vin_stock == NULL) {vin_stock = '';}
        string vin_stock_var = '%'+vin_stock+'%';
        
        // build the SOQL query
        string vehicles_query = 'SELECT Id,dealer__Year__c,dealer__Make__c,dealer__Model__c,dealer__Status_Code__c,dealer__VIN__c,dealer__Stock_Number__c,'
            +' dealer__Days_in_Stock__c,dealer__Store_Location__r.dealer__Company_Number__c,dealer__Store_Location__r.dealer__City__c,Chassis_Floorplan__c,'
            +' dealer__Store_Location__R.dealer__State__c,dealer__Publish_Vehicle_Info_To_Web__c,dealer__Image_Count__c,Images_Published__c, Title_Location__c,'
            +' MSO_Title__c, MSO_Title_Pending__c, MSO_Title_Requested__c, Lien_Release__c, Lien_Release_Pending__c, Lien_Release_Requested__c,'
            +' Power_of_Attorney__c, Power_of_Attorney_Pending__c, Power_of_Attorney_Requested__c, Proof_of_Payment_Trade__c, Proof_of_Payment_Trade_Requested__c, Proof_of_Payment_Pending__c,'
            +' Source__c, dealer__Purchase_Date__c, Total_Vehicle_Cost__c, Days_Since_Purchase__c, ' // BLL1a
            +' (SELECT Id, ParentId, OwnerId, Name, LastModifiedDate, LastModifiedById, Description, CreatedDate FROM Attachments)'
                    +' FROM dealer__Vehicle_Inventory__c'
                    +' WHERE New_Used_Other__c != \'Fleet\' AND Chassis_Floorplan__c != \'GE\' AND Chassis_Floorplan__c != \'TCF\' AND Chassis_Floorplan__c != \'TEMPE\'';
        if (filter == 'missingonly') {vehicles_query +=' AND (Lien_Release_Pending__c = true OR MSO_Title_Pending__c = true OR Power_of_Attorney_Pending__c = true OR Proof_of_Payment_Pending__c = true)';}
        if (!string.isblank(location)) {vehicles_query += ' AND dealer__Store_Location__c = :location';}
        vehicles_query +=' AND (dealer__Stock_Number__c LIKE :vin_stock_var OR dealer__VIN__c LIKE :vin_stock_var)'
                    +' ORDER BY dealer__Store_Location__r.dealer__City__c ASC NULLS LAST, dealer__Stock_Number__c ASC NULLS LAST';
        //vehicles = new List<dealer__Vehicle_Inventory__c>();
        for (dealer__Vehicle_Inventory__c var : database.query(vehicles_query)) {
            recordstotal++;
            if (recordstotal < 1000) vehicles.add(var);
            if (var.dealer__Days_in_Stock__c != NULL) {recordsage += var.dealer__Days_in_Stock__c;}
            if (var.MSO_Title_Pending__c == true) {recordsmissing++;}
            if (var.Lien_Release_Pending__c == true) {recordsmissing++;}
            if (var.Power_of_Attorney_Pending__c == true) {recordsmissing++;}
            if (var.Proof_of_Payment_Pending__c == true) {recordsmissing++;}
        }
        if (recordstotal > 999) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'More than 1000 records were found only 1000 are displayed'));
        }
        //return vehicles;
        
    }

    public List<SelectOption> location_options {get{
        List<selectOption> locations_list = new List<selectOption>();
        List<dealer__Dealer_Location__c> locations = [SELECT Id,Name, dealer__Company_number__c, dealer__City__c, dealer__State__c FROM dealer__Dealer_Location__c ORDER BY dealer__City__c];
        locations_list.add(new selectOption('','All'));
        for(dealer__Dealer_Location__c loc : locations) {
            locations_list.add(new selectOption(loc.Id,loc.dealer__City__c+', '+loc.dealer__State__c+' ('+loc.dealer__Company_number__c+')'));
        }
        return locations_list;
    } private set;}
}