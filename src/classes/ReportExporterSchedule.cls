/*
    2016-09-30  S. Utture   SSU1 - Create a schedule class to export reports in csv format and mail  
    2016-11-02  S. Utture   SSU2 - updates to avoid callouts in schedule class exception     
*/
global class ReportExporterSchedule implements System.Schedulable, Database.AllowsCallouts {
  global void execute(SchedulableContext sc) {
    ReportExporterUtility.sendReports();//SSU2
  }
}