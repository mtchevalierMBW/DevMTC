/**
* WMK (c) - 2019
*
* ReportExporterScheduleTW
* 
* Programmer: Alexander Miller
* Date: 3/18/2019
* Work Item:  W-000623
* Tested By:
*
* Modified By         Alias       Work Item       Date     Reason
* -----------------------------------------------------------------
*
*/
global class ReportExporterScheduleTW implements System.Schedulable, Database.AllowsCallouts {
     
    global void execute(SchedulableContext sc) 
    {
        ReportExporterUtilityTW.sendReports();
    }
}