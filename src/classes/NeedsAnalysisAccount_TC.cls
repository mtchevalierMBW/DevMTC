/**
* 2018-09-13	B. Leaman	Trying to reduce SOQL queries. But it could be an internal system error in salesforce.
**/

@isTest
Public Class NeedsAnalysisAccount_TC{
	Static testmethod Void Myunittest(){
		
		contact con = new contact();
		con.Phone = '8888888';
		con.LastName = 'Test';
		insert con;
		
		Account a = new Account();
		a.LastName ='Test';
		a.AccountSource ='Dealer';
		a.dtffa__A__c=2; 
		a.dtffa__B__c=3;
		a.dtffa__Actual_Estimate__c='Actual';
		a.dtffa__C__c=1; 
		a.dtffa__Chair_Brand__c='Test';
		//a.dtffa__Chair_Dimensions_Diagram__c='Test';
		a.dtffa__Chair_Model__c='Test';
		a.Claim_Number__c='12';
		a.dtffa__Client_In_Chair_Weight__c=2;
		a.dtffa__End_User__c='Driver'; 
		a.dtffa__Physical_Challenge__c='ALS';
		a.dtffa__AnalysisDate__c=system.Today();
		a.dtffa__PlannedChanges__c='Test';
		a.NeedsAssessmentRecordedBy__c=UserInfo.getUserId();
		insert a;
		
		dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c();
		dsp.dealer__Lead_Date__c=System.Today();
		dsp.dealer__Lead_Status__c='Pending';
		dsp.dealer__Lead_Type__c='List';
		dsp.dealer__Source__c ='Pride';
		dsp.Solution_Type__c ='Rentel';
		dsp.dealer__Customer_Account__c =a.id;
		dsp.End_User__c='Driver';
		dsp.Physical_Challenge__c='ALS';
		dsp.Planned_Changes__c='Test';
		dsp.Claim_Number__c=12; 
		dsp.Actual_Estimate__c='Actual';
		dsp.A__c=1;
		dsp.B__c=2;
		dsp.C__c=1;
		dsp.Chair_Brand__c='Test';
		dsp.Chair_Model__c='Test'; 
		dsp.Client_In_Chair_Weight__c=12; 
		dsp.Needs_Analysis_Recorded__c=system.Today();
		//dsp.Chair_Dimensions_Diagram__c='Test';
		dsp.dealer__Buyer_Contact__c =con.id;
		insert dsp;
		
		ApexPages.StandardController sc = new ApexPages.StandardController(dsp);
		ApexPages.currentPage().getParameters().put('id', dsp.id);
		
		Test.startTest();	// BLL1a
		
		NeedsAnalysisAccount  nas = new NeedsAnalysisAccount(new ApexPages.StandardController(dsp));
		nas.performNewNeedsAssesment();
		nas.saveNeedsAssesment();
		
		Test.stopTest();	// BLL1a

	}
}