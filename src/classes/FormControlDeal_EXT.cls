/**
 * FormControlDeal_EXT
 * Tested by: FormControlDeal_EXT_TEST
 * Copied from DealerTeam and added custom fields.
 *
 * Coverage:
 *	2018-09-05	87% (248/284)
 *	2019-01-10	86% (238/274)
 *
 * Modifications:
 *	2017-05-11	B. Leaman	BLL1 - add user information from location references (GM, SA, SM, etc)
 *	2018-09-05	B. Leaman	BLL2 - add summary of ESCs by type.
 *	2019-01-07	B. Leaman	W-000538 BLL3 - Need additional salesperson 1 name fields -- move to static method in DealProcess.
 */

public with sharing class FormControlDeal_EXT {
    private ApexPages.StandardController stdController;
    //public SObjectType obj;

	public String form_id {get;set;}
   	//public String form_id_editor {get;set;}
	public String deal_id {get;set;}
	public String deal_name {get;set;}
	public String formCode {get;set;}
	public dealer__Form__c form {get;set;}
	public dealer__Form__c newForm { get; set; }
	public dealer__Sales_Up__c sup {get; set;} // here to get a native deal lookup

	public dealer__Deal__c deal {get;set;}
	public dealer__Vehicle_Inventory__c vehicle {get;set;}
	public dealer__Dealer_Location__c location {get;set;}
	public dealer__Finance_Company__c financeCo {get;set;}

	public List<dealer__Trade_In__c> tradeInList {get; set;}

	public List<dealer__Deal_Tax__c> taxList {get; set;}
	public List<dealer__Discount_Rebate__c> discountList {get; set;}
	public List<dealer__After_Market__c> aftermarketList {get; set;}
	public List<dealer__Service_Contract__c> serviceContractList {get; set;}
	
	// BLL2a
	public List<String> escType {get; private set;}
	public List<Decimal> escSalePrice {get; private set;}
	// BLL2a end

	//public Account Buyer {get;set;}
	//public boolean isPersonAccount {get;set;}
	//public Account CoBuyer {get;set;}

	public List<dealer__Trade_In__c> tradeInList2 {get; set;}
	public dealer__Trade_In__c tradeIn1 {get; set;}
	public dealer__Trade_In__c tradeIn2 {get; set;}
	public dealer__Trade_In__c tradeIn3 {get; set;}

	public Map<Integer, List<List<String>>> formLines;
	public dealer__SalesDeskLogSettings__c config {get;private set;}
	//public dealer__SalesDeskLogSettings__c getConfig() {
	//	return config;
	//}
    
    transient DescribeSObjectResult desAcct;	// BLL1a
	List<String> acctFieldNames;	// BLL1a
    
    public FormControlDeal_EXT(ApexPages.StandardController ctlr) {

		// BLL3
		/**
		List<String> fields = new List<String>();
		//fields.add('Desired_Vehicles__c');
		// BLL1a add all fields from Deal object
		fields.addAll(dealer__Deal__c.getSObjectType().getDescribe().fields.getMap().keySet());	// BLL1a
		fields.add('dealer__Desk_Manager__r.Name');
		fields.add('dealer__Store_Location__r.dealer__Postal_Code__c');
		fields.add('dealer__Store_Location__r.Dealer_License_Name__c');
		fields.add('dealer__Store_Location__r.dealer__State__c');
		fields.add('dealer__Store_Location__r.dealer__Address__c');
		fields.add('dealer__Store_Location__r.dealer__Street__c');
		fields.add('dealer__Store_Location__r.dealer__City__c');
		
		Set<String> accountFields = new Set<String>{'Name','FirstName','LastName','BillingStreet','BillingCity','BillingState','BillingPostalCode','Phone','PersonHomePhone','PersonMobilePhone','PersonEmail','BusinessMobilePhone__c','dealer__Billing_Email__c'};
		for(String s : accountFields) fields.add('Third_Party_Pay_1__r.'+s);
		for(String s : accountFields) fields.add('Third_Party_Pay_2__r.'+s);
		for(String s : accountFields) fields.add('Third_Party_Pay_3__r.'+s);
		//fields.add('');
		if(!Test.isRunningTest()) ctlr.addFields(fields);
		**/
		Set<String> fields = DealProcess.DealFieldsToRetrieve();
		if(!Test.isRunningTest()) ctlr.addFields(new List<String>(fields));
		// BLL3 end

		formLines = new Map<Integer, List<List<String>>>();
		config = dealer__SalesDeskLogSettings__c.getValues(UserInfo.getUserId());
		desAcct = Account.getSObjectType().getDescribe();	// BLL1a
		acctFieldNames = new List<String>( desAcct.fields.getMap().keySet() );	// BLL1a

		deal = (dealer__Deal__c) ctlr.getRecord();
		stdController = ctlr;
		deal_id = deal.Id;

		newForm = new dealer__Form__c();
        form	= new dealer__Form__c();
		sup 	= new dealer__Sales_Up__c();

        if(ApexPages.currentPage()!=null) {

			form_id = ApexPages.currentPage().getParameters().get('fid');
	        //form_id_editor = ApexPages.currentPage().getParameters().get('id');
			//deal_id = ApexPages.currentPage().getParameters().get('did');

			if(form_id!=null) {
				form = lookupForm(ID.valueOf(form_id));
				System.debug(form.dealer__Impact_Code__c);
				if (!String.IsBlank(form.dealer__Impact_Code__c)) {
					System.debug(form.dealer__Impact_Code__c);
					formCode = base64Decode(form.dealer__Impact_Code__c);
				}
			} 
	        
			//if(form_id_editor!=null) {
			//	form = lookupForm(ID.valueOf(form_id_editor));
			//	formCode = base64Decode(form.dealer__Impact_Code__c);
			//} 

			if(deal_id!=null) {
				deal = lookupDeal(ID.valueOf(deal_Id));
			} else {
				dealer__Deal__c d = [Select Id from dealer__Deal__c where IsDeleted = false limit 1];
				deal = lookupDeal(d.Id);
				deal_id = d.Id;
			}	

			// Making Finance company Available
			if( deal != null ) {
				if(deal.dealer__Store_Location__r != null) {
					this.location = deal.dealer__Store_Location__r;
				}
				if(deal.dealer__Vehicle__r != null) {
					this.vehicle = deal.dealer__Vehicle__r;
				}
				if(deal.dealer__Finance_Institution_Account__r != null) this.financeCo = deal.dealer__Finance_Institution_Account__r;


			}

			tradeInList2 = lookupTradeIns(deal_id);
			if(tradeInList2.size() > 0 && tradeInList2[0] != null) tradeIn1 = tradeInList2[0];
			if(tradeInList2.size() > 1 && tradeInList2[1] != null) tradeIn2 = tradeInList2[1];
			if(tradeInList2.size() > 2 && tradeInList2[2] != null) tradeIn3 = tradeInList2[2];

			taxList = retrieveTaxList();
			discountList = retrieveDiscountList();
			aftermarketList = retrieveAftermarketList();
			serviceContractList = retrieveServiceContractList();
			retrieveEscSummary();	// BLL2a

		}

	}

	public List<String> getObjectFieldNames() {
		// Only Deal Object supported for impact printing
        Map<String, Schema.SObjectField> M = Schema.SObjectType.dealer__Deal__c.fields.getMap();
        List<String> af = new List<String>();
        Set<String> fieldnames = M.keySet(); 
        for(String fn : fieldnames) {
        	af.add('{!'+fn+'}');
        }
        // af.addAll(fieldnames);	
        return af;	
	}

	public String getObjectFieldNamesSimple() {
		// Only Deal Object supported for impact printing
        Map<String, Schema.SObjectField> M = Schema.SObjectType.dealer__Deal__c.fields.getMap();
        List<String> af = new List<String>();
        Set<String> fieldnames = M.keySet(); 

        // Generate Response
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartArray();

        for(String fn : fieldnames) {
	        //gen.writeString(fn);

        	//af.add('{!'+fn+'}');
        	//af.add(fn);
            gen.writeStartObject();
	            //gen.writeStringField('name', fn);
	            gen.writeStringField('name', '{!deal.' + fn +'}');
	            gen.writeStringField('value', '{!deal.' + fn +'}');
            gen.writeEndObject();
        }
        // af.addAll(fieldnames);	

        gen.writeEndArray();
        return gen.getAsString();    
        //return af;	
	}

	//public PageReference newForm() {
	//	return Page.ImpactFormNew;
	//}

	//public PageReference saveNewForm() {

	//	dealer__Form__c insertForm = new dealer__Form__c();

	//	System.debug(newForm);
	//	System.debug(form);
		
    //    if(newForm.Name != null) {
	//        insertForm.dealer__Print_Type__c = 'Impact';
	//        insertForm.Name = newForm.Name;
	//        insertForm.Form_ID__c = newForm.Form_ID__c;
	//        insertForm.Sequence__c = newForm.Sequence__c;
    //    } else {
    //    	insertForm = form.clone();
    //    }

	//	insert insertForm;
	//	return Page.ImpactForms;
	//}

	//public PageReference updateForm() {
	//	update form;
	//	return Page.ImpactForms;
	//}

	//public PageReference formsList() {
	//	return Page.ImpactForms;
	//}

	public Component.Apex.OutputText getPreview () {
		Component.Apex.OutputText ot = new Component.Apex.OutputText();

		if(form.dealer__Impact_Code__c!=null && form.dealer__Impact_Code__c.Length()>0){
			ot.expressions.value = base64Decode(form.dealer__Impact_Code__c);
		}
		
		return ot ;
	}

	/**
	 * getFDF - fdf string compiler
	 * @return OutputText component for render in page
	 */
	public Component.Apex.OutputText getFDF() {

		Component.Apex.OutputText ot = new Component.Apex.OutputText();

		if(form.dealer__FDF_Code__c!=null && form.dealer__FDF_Code__c.Length()>0){
			ot.expressions.value = form.dealer__FDF_Code__c;
		}
		return ot ;		
	}

	public String base64Decode(String s) {
		//if (Utility.IsBlank(s)) {
		if (String.IsBlank(s)) return '';

		Blob decodeBlob = EncodingUtil.base64Decode(s);
		String decodeString = decodeBlob.toString();
		if(!decodeString.contains('{!')) return '';

		return decodeString;
	}

	public dealer__Form__c lookupForm(Id formId) {
		return [SELECT Id, OwnerId, IsDeleted, Name, dealer__Active__c, dealer__Revision_Date__c, dealer__Sequence__c, dealer__Library__c, dealer__Page_Name__c, dealer__Proofed_by__c, dealer__Form_ID__c, dealer__Print_Type__c, dealer__Impact_Code__c, dealer__FDF_Code__c FROM dealer__Form__c
			Where Id=:formId
			and IsDeleted = false
			limit 1];
	}

	/**
	 * lookupDeal
	 * @param  dealId record Id of the deal you would like to view
	 * @return        [returns a database query of the selected deal]
	 */
	public dealer__Deal__c lookupDeal(Id dealId) {

		// Deal
		DescribeSObjectResult desDeal = dealer__Deal__c.getSObjectType().getDescribe();
		List<String> fieldNames = new List<String>( desDeal.fields.getMap().keySet() );	

		// Vehicle
		DescribeSObjectResult desVeh = dealer__Vehicle_Inventory__c.getSObjectType().getDescribe();
		List<String> fieldNamesV = new List<String>( desVeh.fields.getMap().keySet() );
		List<String> rNamesV = new List<String>();
		for (String fName : fieldNamesV) {
			rNamesV.add('dealer__Vehicle__r.'+fName);
		}
		rNamesV.add('dealer__Vehicle__r.RecordType.Name');


		// Location
		DescribeSObjectResult desLocation = dealer__Dealer_Location__c.getSObjectType().getDescribe();
		List<String> fieldNamesL = new List<String>( desLocation.fields.getMap().keySet() );
		List<String> rNamesL = new List<String>();
		for (String fName : fieldNamesL) {
			rNamesL.add('dealer__Store_Location__r.'+fName);
		}
		// BLL1a Add selected user fields for each user reference
		List<String> userfields = new List<String>{'Name','FirstName','LastName','Email','Phone'};
		List<String> userrefs = new List<String>{'dealer__General_Manager__r','Sales_Admin__r','dealer__Service_Director__r',
			'F_I_Manager__r','Rental_Manager__r','Commercial_Sales_Admin__r'};
		List<String> userreffields = new List<String>();
		for(String ur : userrefs) {
			for(String uf : userfields) {
				userreffields.add('dealer__Store_Location__r.'+ur+'.'+uf);
			}
		}
		rNamesL.addAll(userreffields);
		// BLL1a end

		// Finance Company
		DescribeSObjectResult desFinanceCo = dealer__Finance_Company__c.getSObjectType().getDescribe();
		List<String> fieldNamesFI = new List<String>( desFinanceCo.fields.getMap().keySet() );
		List<String> rNamesFI = new List<String>();
		for (String fName : fieldNamesFI) {
			rNamesFI.add('dealer__Finance_Institution_Account__r.'+fName);
		}

		// Add the related lookup fields for Vehicle and Location to the field name List<String> // Jarrett
		fieldNames.addAll(rNamesV);
		fieldNames.addAll(rNamesL);		
		fieldNames.addAll(rNamesFI);

		// Manually Adding Fields
		fieldNames.add( 'dealer__Salesperson_1__r.Name' );	
		// BLL3
		fieldNames.add( 'dealer__Salesperson_1__r.FirstName' );	
		fieldNames.add( 'dealer__Salesperson_1__r.LastName' );	
		// BLL3 end

		String query =
		  ' SELECT ' +
		      String.join( fieldNames, ',' ) +
		  ' FROM ' +
		      desDeal.getName() +
		  ' Where Id = \''+ dealId +'\'' +
		  ' AND IsDeleted = false ' +
		  ' Order By CreatedDate ASC LIMIT 1';

		return Database.query( query );

	}
	
	/**
	 * lookupTradeIns
	 * 
	 */
	public List<dealer__Trade_In__c> lookupTradeIns(Id dealId) {
        DescribeSObjectResult desTradeIn = dealer__Trade_In__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>( desTradeIn.fields.getMap().keySet() );

        fieldNames.add('dealer__Pay_Off_Account__r.Name');
        
        String query =
            ' SELECT ' +
            String.join( fieldNames, ',' ) +
            ' FROM ' +
            desTradeIn.getName() +
            ' Where dealer__Car_Deal__c = \''+ dealId +'\'' +
            ' AND IsDeleted = false ' +
            ' Order By CreatedDate ASC';
        
        List<dealer__Trade_In__c> tradeIns = Database.query(query);
        
		//avoids needing 'if' statements in visualforce to check for nulls 
        if(tradeIns.size() == 0) tradeIns.add(new dealer__Trade_In__c());
        
        return tradeIns;
	}	

	//public List<dealer__Form__c> getForms() {
	//	return [Select Id, Name, dealer__Form_ID__c, dealer__Active__c, dealer__Library__c, dealer__Print_Type__c, dealer__Proofed_by__c, 
	//				dealer__Revision_Date__c, dealer__Sequence__c, CreatedDate, CreatedById
	//			from dealer__Form__c
	//			where dealer__Print_Type__c = 'Impact'
	//			Order By dealer__Sequence__c ASC
	//			limit 5000];
	//}

    //public PageReference compileFormSource() {
    //	update form;
    //	return null;
	//}

	public PageReference setDealId() {
		System.debug(sup);
		System.debug(sup.dealer__Car_Deal__c);

		if(sup!=null && sup.dealer__Car_Deal__c !=  null) {
			System.debug(sup);
			
			deal = lookupDeal(sup.dealer__Car_Deal__c);
			System.debug(deal);

			deal_Id = deal.Id;
		} 

		return null;
	}

	public Account getBuyer() {

		if(deal != null && deal.dealer__Buyer__c != null) {

			// Deal
			//BLL1d DescribeSObjectResult desAcct = Account.getSObjectType().getDescribe();
			//BLL1d List<String> fieldNames = new List<String>( desAcct.fields.getMap().keySet() );
			//BLL1d List<String> fieldNames = new List<String>( desAcct.fields.getMap().keySet() );
			//BLL1d List<String> fieldNames = new List<String>( desAcct.fields.getMap().keySet() );
			String query =
			  ' SELECT ' +
			      String.join( acctFieldNames, ',' ) +
			  ' FROM ' +
			      desAcct.getName() +
			  ' Where Id = \''+ deal.dealer__Buyer__c +'\'' +
			  ' AND IsDeleted = false ' +
			  ' Order By CreatedDate ASC LIMIT 1';

			return Database.query( query );
		}
		return null;
	}

	public Account getCoBuyer() {
		if(this.deal != null && deal.dealer__Co_Buyer__c != null) {

			// Deal
			//DescribeSObjectResult desAcct = Account.getSObjectType().getDescribe();
			//List<String> fieldNames = new List<String>( desAcct.fields.getMap().keySet() );
			String query =
			  ' SELECT ' +
			      String.join( acctFieldNames, ',' ) +
			  ' FROM ' +
			      desAcct.getName() +
			  ' Where Id = \''+ deal.dealer__Co_Buyer__c +'\'' +
			  ' AND IsDeleted = false ' +
			  ' Order By CreatedDate ASC LIMIT 1';

			return Database.query( query );
		} 

		return null;
	}

	public Account getThirdParty1() {
		if (deal==null) return null;
		return queryAccountInfo(deal.Third_Party_Pay_1__c);
	}
	public Account getThirdParty2() {
		if (deal==null) return null;
		return queryAccountInfo(deal.Third_Party_Pay_2__c);
	}
	public Account getThirdParty3() {
		if (deal==null) return null;
		return queryAccountInfo(deal.Third_Party_Pay_3__c);
	}
	public Account queryAccountInfo(Id acctid) {
		if(acctid != null) {

			// Deal
			//BLL1d DescribeSObjectResult desAcct = Account.getSObjectType().getDescribe();
			//BLL1d List<String> fieldNames = new List<String>( desAcct.fields.getMap().keySet() );
			String query =
			  ' SELECT ' +
			      String.join( acctFieldNames, ',' ) +
			  ' FROM ' +
			      desAcct.getName() +
			  ' Where Id = \''+ acctid +'\'' +
			  ' AND IsDeleted = false ' +
			  ' Order By CreatedDate ASC LIMIT 1';

			return Database.query( query );
		}
		return null;
	}

	public Boolean getisPersonAccount() {
		if(this.deal != null && deal.dealer__Buyer__c != null) {

			Account retA = [SELECT isPersonAccount FROM Account Where Id =:deal.dealer__Buyer__c Limit 1];

			return retA.isPersonAccount;
		} 

		return null;
	}

	public dealer__Trade_In__c gettradeIn1() {
		return tradeIn1;
	}
	public dealer__Trade_In__c gettradeIn2() {
		return tradeIn2;
	}
	public dealer__Trade_In__c gettradeIn3() {
		return tradeIn3;
	}

	public List<dealer__Deal_Tax__c> retrieveTaxList() {
		if(deal != null) {

			// Deal
			DescribeSObjectResult desSObj = dealer__Deal_Tax__c.getSObjectType().getDescribe();
			List<String> fieldNames = new List<String>( desSObj.fields.getMap().keySet() );
			String query =
			  ' SELECT ' +
			      String.join( fieldNames, ',' ) +
			  ' FROM ' +
			      desSObj.getName() +
			  ' Where dealer__Deal__c = \''+ deal.Id +'\'' +
			  ' AND dealer__Deal__c != null ' +
			  ' AND IsDeleted = false ' +
			  ' Order By CreatedDate ASC LIMIT 99';

			return Database.query( query );
		}
		return null;
	}

	public List<dealer__Discount_Rebate__c> retrieveDiscountList() {
		if(deal != null) {

			// Deal
			DescribeSObjectResult desSObj = dealer__Discount_Rebate__c.getSObjectType().getDescribe();
			List<String> fieldNames = new List<String>( desSObj.fields.getMap().keySet() );
			String query =
			  ' SELECT ' +
			      String.join( fieldNames, ',' ) +
			  ' FROM ' +
			      desSObj.getName() +
			  ' Where dealer__Deal__c = \''+ deal.Id +'\'' +
			  ' AND dealer__Deal__c != null ' +
			  ' AND IsDeleted = false ' +
			  ' Order By CreatedDate ASC LIMIT 99';

			return Database.query( query );
		}
		return null;
	}

	public List<dealer__After_Market__c> retrieveAftermarketList() {

		if(deal != null) {

			// Deal
			DescribeSObjectResult desSObj = dealer__After_Market__c.getSObjectType().getDescribe();
			List<String> fieldNames = new List<String>( desSObj.fields.getMap().keySet() );
			String query =
			  ' SELECT ' +
			      String.join( fieldNames, ',' ) +
			  ' FROM ' +
			      desSObj.getName() +
			  ' Where dealer__Car_Deal__c = \''+ deal.Id +'\'' +
			  ' AND dealer__Car_Deal__c != null ' +
			  ' AND IsDeleted = false ' +
			  ' Order By dealer__Order__c ASC LIMIT 199';

			return Database.query( query );
		}
		return null;
	}

	// BLL2a
	public void retrieveEscSummary() {
		escType = new List<String>();
		escSalePrice = new List<Decimal>();		
		for(AggregateResult ar : [
			select Type__c, sum(dealer__Sale_Price__c) price from dealer__Service_Contract__c
			where dealer__Car_Deal__c=:deal.Id and isDeleted=false 
			group by Type__c
		]) {
			escType.add((String) ar.get('Type__c'));
			Decimal price = (Decimal) ar.get('price');
			escSalePrice.add(price.setScale(2));
		}
	}
	// BLL2a end

	public List<dealer__Service_Contract__c> retrieveServiceContractList() {

		if(deal != null) {

			// Deal
			DescribeSObjectResult desSObj = dealer__Service_Contract__c.getSObjectType().getDescribe();
			List<String> fieldNames = new List<String>( desSObj.fields.getMap().keySet() );
			String query =
			  ' SELECT ' +
			      String.join( fieldNames, ',' ) +
			  ' FROM ' +
			      desSObj.getName() +
			  ' Where dealer__Car_Deal__c = \''+ deal.Id +'\'' +
			  ' AND dealer__Car_Deal__c != null ' +
			  ' AND IsDeleted = false ' +
			  ' Order By dealer__Order__c ASC LIMIT 199';

			return Database.query( query );
		}
		return null;
	}


	/*
	@RemoteAction
	public static List<cDeal> getDealList() {

		List<dealer__Deal__c> deals = [SELECT Id, Name, dealer__Buyer_First_Name__c, dealer__Buyer_Last_Name__c FROM Deal__c ORDER BY CreatedDate DESC LIMIT 1000];

		List<cDeal> cDeals = new List<cDeal>();

		if(deals.size()>0){
			for(dealer__Deal__c d:deals){
				cDeals.add(new cDeal(d));
			}
		}

		return cDeals;
	}
	*/

	public class cDeal {
		public String Id {get;set;}
		public String name {get;set;}
		public String buyerName {get;set;}

		public cDeal(dealer__Deal__c d){
			Id = d.Id;
			name = d.name;
			if(d.dealer__Buyer_First_Name__c != null && d.dealer__Buyer_Last_Name__c != null) {
				buyerName = d.dealer__Buyer_First_Name__c + ' ' + d.dealer__Buyer_Last_Name__c;
			}
		}
	}

	// Remote Actions
	/*
	@RemoteAction
	public static String compileForm(String sJson) {

		Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(sJson);
		String formId = String.valueOf(m.get('formId'));
		String dealId = String.valueOf(m.get('dealId'));

		// Get Form Logic
		dealer__Form__c form = [Select Id, dealer__Impact_Code__c from dealer__Form__c where Id=:formId limit 1];

		// Deal 
		Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get('dealer__Deal__c').getDescribe().fields.getMap();
		String query = 'Select ';
		for(String s : objectFields.keySet()) {
		   query += ' ' + s + ', ';
		}
		if (query.subString(query.Length()-1,query.Length()) == ','){
		    query = query.subString(0,query.Length()-1);
		}

		query += ' where Id =\''+String.escapeSingleQuotes(dealId)+'\' limit 1';

  		dealer__Deal__c deal = Database.query(query);

  		return '';

	}
	*/
}