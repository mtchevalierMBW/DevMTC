@isTest
public with sharing class VehicleInventoryTemplateTest {
	static testmethod void VehicleInventoryTemplateControllerTest() {
		VehicleInventoryTemplateController controller = new VehicleInventoryTemplateController();
		controller.template.Name = 'Test';
		
	}

	
}