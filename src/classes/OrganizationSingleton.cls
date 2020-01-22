/**
 * OrganizationSingleton
 * Tested by: ServiceRepairOrder2_TC, AvaTax_MBW_TEST, VehicleInvenotryEmailHandler_TEST and many others
 * Programmer: Bryan Leaman
 * Date: 2018-10-18
 *
 */
 public with sharing class OrganizationSingleton {
    private static Organization currentOrg;

	public static Organization getInstance() {
		if (currentOrg==null) {
			currentOrg = [
				select Id, Name, isSandbox
				from Organization
				limit 1
			];
		}
		return currentOrg;
	}
}