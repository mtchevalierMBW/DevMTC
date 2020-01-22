@isTest
Public Class SetSalesUpSource_TC{
Static testmethod Void Myunittest(){

Account a = new Account();
a.LastName ='Test';
a.AccountSource ='Dealer';

insert a;

a.AccountSource =null;
update a;

dealer__Sales_Up__c  dsp = new dealer__Sales_Up__c();
dsp.dealer__Lead_Date__c=System.Today();
dsp.dealer__Lead_Status__c='Pending';
dsp.dealer__Lead_Type__c='List';
dsp.dealer__Source__c ='Pride';
dsp.Solution_Type__c ='Rental';
dsp.dealer__Customer_Account__c =a.id;
insert dsp;

dsp.dealer__Source__c ='Pride';
update dsp;
}
}