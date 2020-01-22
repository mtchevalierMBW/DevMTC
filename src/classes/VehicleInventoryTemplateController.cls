/*
* 2016-06-07 RedTeal		RT1 - Page for creating a new template; allows template to be created without requiring certain fields
*
*
*/
public class VehicleInventoryTemplateController {
	public dealer__Vehicle_Inventory__c template {get; set;}

	public VehicleInventoryTemplateController() {
		template = new dealer__Vehicle_Inventory__c(); 	
	 	Map<String,Schema.RecordTypeInfo> recordTypeMap = Schema.SObjectType.dealer__Vehicle_Inventory__c.getRecordTypeInfosByName();	
	 	template.RecordTypeId = recordTypeMap.get('Vehicle Template').getRecordTypeId();
	 	template.dealer__VIN__c = 'N/A';
	 	template.dealer__Make__c = 'N/A';
	 	template.dealer__Year__c = 'N/A';
	 	template.dealer__Model__c = 'N/A';
	 	template.dealer__Stock_Number__c = 'Template';
	}

	public PageReference save() {
		template.Name = template.Name;
	 	template.dealer__Stock_Number__c = template.Name;

		insert template;
		return new PageReference('/' + template.Id);
	}
}