/**
 * FormManager_EXT
 * Tested by: FormManager_EXT_TEST
 *
 * 2017-05-11	B. Leaman	BLL1 Add support for vehicle inventory.
 * 2017-06-05	B. Leaman	BLL2 - conditional inclusion of forms based on record being printed.
 * 	2017-11-27	B. Leaman	BLL3 - don't escape the fdf data (prevent changing & to &amp;, etc)
 *	2018-03-27	B. Leaman	BLL4 - use current user's location (state) for vehicle forms;
 *							use case: vehicle at BraunAbility and store anticipating it needs to print buyers guide;
 */

public with sharing class FormManager_EXT {
    private ApexPages.StandardController stdController;
    
	public String docName {get; private set;}
	public List<dealer__Form__c> formList {get; private set;}
	public String buyerState;
	public String storeState;

	public string xmlTag {get; private set;}
    public String formId {get; set;}
    public dealer__Form__c form {get;private set;}

	public ApexPages.StandardController stdCtlr;

	public Id objId {get; private set;}
	public String objName {get; private set;}
	public String SObjectName {get; private set;}	// BLL1a

    private SObject Sobj;
    private transient Schema.SObjectType objType;
    private transient Schema.DescribeSObjectResult dsr;
    private transient Map<String,Schema.SObjectField> fieldMap;

	private Map<String,String> buyerStateFld = new Map<String,String>{'Commercial Quote'=>'State__c', 'Conversion Build'=>'State__c', 'Vehicle Inventory'=>'dealer__Store_Location__r.dealer__State__c'};	// BLL1c
	private Map<String,String> storeStateFld = new Map<String,String>{'Commercial Quote'=>'Location__r.dealer__State__c', 'Conversion Build'=>'Location__r.dealer__State__c', 'Vehicle Inventory'=>'dealer__Store_Location__r.dealer__State__c'};	// BLL1c

	// constructor
	//---------------------------
    public FormManager_EXT(ApexPages.StandardController ctlr) {
		stdController = ctlr;
		formList = new List<dealer__Form__c>();
    	form = new dealer__Form__c();
		xmlTag = '<?xml version="1.0" encoding="UTF-8"?>';
		buyerState = '';
		storeState = '';
		List<String> fields = new List<String>();

		Map<String,String> params = ApexPages.currentPage().getParameters();
		objId = params.get('id');
		if (objId!=null) {
			objType = objId.getSObjectType();
			dsr = objType.getDescribe();
			fieldMap = dsr.fields.getMap();
			objName = dsr.getLabel();
			System.debug('Object name is ' + objName);
			if (objName=='Conversion Build') objName='Commercial Quote';
			// BLL1
			Set<String> statefields = new Set<String>();
			statefields.add(buyerStateFld.get(objName));
			statefields.add(storeStateFld.get(objName));
			// BLL1a end
			String soql = 'select Id, Name, ' + String.join(new List<String>(statefields), ',')	// BLL1c
				+ ' from ' + dsr.getName() + ' where Id=\'' + objId + '\' limit 1';
			System.debug(soql);
			SObj = Database.query(soql);
			System.debug(SObj);
			SObjectName = (String) SObj.get('Name');	// BLL1a
			buyerState = getSObjFieldAsString(SObj, (String) buyerStateFld.get(objName));
			storeState = getSObjFieldAsString(SObj, (String) storeStateFld.get(objName));
			// BLL4a
			// For vehicles, use user's current location state (for when vehicles are at manufacturer like BraunAbility)
			if (objName=='Vehicle Inventory' && buyerStateFld.get(objName)==storeStateFld.get(objName)) {
				User u = CurrentUserSingleton.getInstance();
				LocationsSingleton ls = LocationsSingleton.getInstance();
				ls.addLocationAbbrevs(new set<String>{u.Division});
				dealer__Dealer_Location__c loc = ls.getLocationByAbbrev(u.Division);
				if (loc!=null) buyerState = loc.dealer__State__c;
			}
			// BLL4a end
			System.debug(buyerState);
			System.debug(storeState);
			rtvFormList();
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing object ID reference in URL'));
		}
		
    }
    
    public String getSObjFieldAsString(SObject sobj, String qualifiedfield) {
    	List<String> fieldparts = qualifiedfield.split('\\.');
    	System.debug(fieldparts);
    	SObject o = sobj;
    	System.debug(o);
    	for(Integer i=0; i<fieldparts.size()-1 && o!=null; ++i) {
    		o = o.getSObject(fieldparts[i]);
    		System.debug(fieldparts[i]);
    		System.debug(o);
    	}
    	String rtn = o!=null ? (String) o.get(fieldparts[fieldparts.size()-1]) : null;
    	System.debug(rtn); 
    	return rtn;
    }
    
    public void rtvFormList() {
    	formList = [
			select Id, Name, dealer__Active__c, dealer__Form_ID__c, dealer__Impact_Code__c, dealer__Library__c, dealer__Page_Name__c, 
				dealer__Print_Type__c, dealer__Proofed_by__c, dealer__Revision_Date__c, dealer__Sequence__c, 
				dealer__Flatten__c, dealer__DocumentContentId__c, AvailabilityExpression__c	// BLL2c availability expression
			from dealer__Form__c
			where DocumentType__c includes (:objName) and dealer__Active__c=true
              and (States_Available__c=null or States_Available__c includes (:buyerState) or States_Available__c includes (:storeState))
            Order by dealer__Sequence__c ASC
            limit 500 
    	];
    }
    
	// BLL2a
	public Component.Apex.outputPanel getFormsTableRows() {
		Component.Apex.outputPanel op = new Component.Apex.outputPanel();
		op.childComponents.add(new Component.Apex.outputText(escape=false,
			value='<table class="table table-hover"><tr><th>Name</th><th>Form ID</th><th>Revision Date</th><th>Action</th></tr>'
		));
		//List<Component.Apex.outputText> ftrows = new List<Component.Apex.outputText>();
		for(dealer__Form__c f : [
				SELECT dealer__Active__c, dealer__Form_ID__c, dealer__Impact_Code__c, dealer__Library__c, dealer__Page_Name__c, dealer__Print_Type__c, dealer__Proofed_by__c, 
					dealer__Revision_Date__c, dealer__Sequence__c, Name, Id, dealer__Flatten__c, dealer__DocumentContentId__c,
					AvailabilityExpression__c	
				FROM dealer__Form__c
				where DocumentType__c includes (:objName) and dealer__Active__c=true
    	          and (States_Available__c=null or States_Available__c includes (:buyerState) or States_Available__c includes (:storeState))
				Order by dealer__Sequence__c ASC 
				limit 500]) {
			Component.Apex.outputText ot = new Component.Apex.outputText();
			ot.escape=false;
			if (!String.isBlank(f.AvailabilityExpression__c)) {
				ot.expressions.rendered=f.AvailabilityExpression__c;
			} else {
				ot.rendered=true;
			}
			String button = '';
			if (f.dealer__Print_Type__c=='Laser') {
				button += '<button class="btn btn-primary btn-xs" onclick="window.open(\'/apex/' + f.dealer__Page_Name__c + '?id=' + ObjId + '\')">Print Laser Document</button>';
			}
			if (f.dealer__Print_Type__c=='Impact') {
				button += '<button class="btn btn-primary btn-xs" onclick="printImpactForm(\'' + f.Id + '\')">Print Impact Form</button>';
			}
			if (f.dealer__Print_Type__c=='FDF') {
				button += '<button type="button" id="printPDFButton" onclick="printPDF_FDF(\'' + f.Id + '\', \'' + f.dealer__DocumentContentId__c + '\', \'' + f.dealer__Flatten__c + '\', \'' + f.Name + '\')" '	
                	+ ' class="btn btn-primary btn-xs">Print Laser Form</button>';
			}
			
			ot.value='<tr>'  
				+ '<td>' + f.Name + '</td>'
				+ '<td>' + (f.dealer__Form_ID__c!=null?f.dealer__Form_ID__c:'') + '</td>'
				+ '<td>' + (f.dealer__Revision_Date__c!=null?f.dealer__Revision_Date__c.format():'') + '</td>'
				+ '<td>' + button + '</td>'
				+ '</tr>';
			op.childComponents.add(ot);
		}
		//System.debug(ftrows.size());
		//op.childComponents.add(ftrows);
		op.childComponents.add(new Component.Apex.outputText(escape=false, value='</table>'));
		return op;
	}
	// BLL2a end
    
    
    public PageReference selectImpactForm() {
    	System.debug(formId);
        if(formId!=null && formId!='') {
            form = [Select Id, dealer__Impact_Code__c from dealer__Form__c where Id=:formId limit 1];
        }
        System.debug(form);
        return null;
    }

    public Component.Apex.OutputText getcompiled_form () {
        Component.Apex.OutputText ot = new Component.Apex.OutputText();
        if(form.dealer__Impact_Code__c != null) {
            ot.expressions.value = base64Decode(form.dealer__Impact_Code__c);
            ot.escape = false;	// BLL3a
        }
        return ot ;
    }   

    public String base64Decode(String s) {
        if (s==null && s=='') {
            return '';
        }
        Blob decodeBlob = EncodingUtil.base64Decode(s);
        String decodeString = decodeBlob.toString();
        if(!decodeString.contains('{!')) {
            return '';
        }
        return decodeString;
    }   
    
    public PageReference returnToDocument() {
    	PageReference backto = new ApexPages.StandardController(Sobj).view();
    	backto.setRedirect(true);
    	return backto;
    }

    //@RemoteAction 
    //public static String compileFDF(String fd) {
	//	Map<String, Object> js = (Map<String, Object>)JSON.deserializeUntyped(fd);
	//	String formId = (String)js.get('form');
	//	String objId = (String)js.get('obj');
	//	String urlPR = '/apex/FormFDFData?fid='+formId+'&did='+objId;
	// 
	//	PageReference p = new PageReference(urlPR);
	//	Blob uContetent = p.getContent();
	// 
	//	return uContetent.toString();
	//}
	
}