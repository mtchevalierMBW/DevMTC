/**
 * FormControl_EXT
 * Tested by: FormControl_EXT_TEST
 *
 */

public with sharing class FormControl_EXT {
	
	public dealer__Form__c form {get; set;}
	Id formId;
	//Id objId;

	// constructor
	//---------------------------
	public FormControl_EXT(ApexPages.StandardController controller) {
		Map<String,String> params = ApexPages.currentPage().getParameters();
		formId = params.get('fid');
		//objId = params.get('id');
		if(formId != null) {
			form = lookupForm(formId);
		}
    }

	public dealer__Form__c lookupForm(Id formId) {
		return [
			select Id, OwnerId, IsDeleted, Name, dealer__Active__c, dealer__Revision_Date__c, 
				dealer__Sequence__c, dealer__Library__c, dealer__Page_Name__c, dealer__Proofed_by__c, 
				dealer__Form_ID__c, dealer__Print_Type__c, dealer__Impact_Code__c, dealer__FDF_Code__c
			from dealer__Form__c
			where Id=:formId
			  and IsDeleted = false
			limit 1
		];
	}

	public Component.Apex.OutputText getFDF() {
		Component.Apex.OutputText ot = new Component.Apex.OutputText();
		if (form.dealer__FDF_Code__c!=null && form.dealer__FDF_Code__c.Length()>0){
			ot.expressions.value = form.dealer__FDF_Code__c;
		}
		return ot ; 
	}

	
}