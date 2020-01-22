/**
* VehicleInventory_PictureReport
* Used in VehicleInventory_PhotoReport.vfp
* Tested by: VehicleInventory_PictureReport_Test
 *
*  Date        Programmer  Description
*  2016-02-29  A. Bangle   Created Class
*  2016-09-19  A. Bangle   Updated Image Query and Added Filters.  Added Images_Published__c as new field to Salesforcec
*/

public class VehicleInventory_PictureReport {
    public String vin_stock {get;set;}
    public String location {get;set;}
    public String filter {get;set;}
    public Integer recordstotal {get;set;}
    public Integer recordsmissing {get;set;}
    public Decimal recordsage {get;set;}
    public transient List<dealer__Vehicle_Inventory__c> vehicles {get;private set;}
    public VehicleInventory_PictureReport() {
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
        
        // build the SOQL query - this query is also used in VehicleInventory_PictureReportEmail for Batch sending of emails, update there as well
        string vehicles_query = 'SELECT Id,dealer__Year__c,dealer__Make__c,dealer__Model__c,dealer__Status_Code__c,dealer__VIN__c,dealer__Stock_Number__c,'
            +' dealer__Days_in_Stock__c,dealer__Store_Location__r.dealer__Company_Number__c,dealer__Store_Location__r.dealer__City__c,'
            +' dealer__Store_Location__R.dealer__State__c,dealer__Publish_Vehicle_Info_To_Web__c,dealer__Image_Count__c,Images_Published__c,'
           			+' (SELECT Id,Preview__c,dealer__Image_URL__c,dealer__Image_Name__c,dealer__Sequence_Number__c,dealer__Publish__c,CreatedById,CreatedDate'
                    +' FROM dealer__Inventory_Images__r ORDER BY dealer__Sequence_Number__c ASC)'
                    +' FROM dealer__Vehicle_Inventory__c'
                    +' WHERE (dealer__Status_Code__c = \'Ready For Sale\' OR dealer__Status_Code__c = \'Not For Sale\')';
        if (filter == 'missingonly') {vehicles_query +=' AND Images_Published__c < 10';}
        vehicles_query +=' AND dealer__Store_Location__r.dealer__Company_Number__c != \'COR\'';
        if (!string.isblank(location)) {vehicles_query += ' AND dealer__Store_Location__c = :location';}
        vehicles_query +=' AND (dealer__Stock_Number__c LIKE :vin_stock_var OR dealer__VIN__c LIKE :vin_stock_var)'
                    +' ORDER BY dealer__Store_Location__r.dealer__City__c ASC NULLS LAST, dealer__Stock_Number__c ASC NULLS LAST';
        //vehicles = new List<dealer__Vehicle_Inventory__c>();
        for (dealer__Vehicle_Inventory__c var : database.query(vehicles_query)) {
            if (filter != 'pendingonly' || var.dealer__Image_Count__c > var.Images_Published__c) {
                recordstotal++;
                if (recordstotal < 1000) vehicles.add(var);
                if (var.dealer__Days_in_Stock__c != NULL) {
                	recordsage += var.dealer__Days_in_Stock__c;
                }
            }
            if (var.dealer__Image_Count__c < 10) {
                recordsmissing++;
            }
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