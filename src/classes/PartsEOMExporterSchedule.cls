global class PartsEOMExporterSchedule implements System.Schedulable, Database.AllowsCallouts {
  global void execute(SchedulableContext sc) {
    PartsEOMExporterUtility.sendReports();
  }
}