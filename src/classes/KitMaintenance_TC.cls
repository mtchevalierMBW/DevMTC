@isTest(Seealldata=True)
Public Class KitMaintenance_TC{
Static testmethod Void Myunittest(){

dealer__Parts_Kit__c dpk = new dealer__Parts_Kit__c();
dpk.Name='Test12';
dpk.dealer__Description__c ='Testabc';
dpk.Retail_Price__c =1;
dpk.Parts_Cost__c=1;
dpk.CMC_Price__c =0;
insert dpk;

dpk.CMC_Price__c =0;
update  dpk;

dealer__Parts_Kit__c dpk1 = new dealer__Parts_Kit__c();
dpk1.Name='Test123';
dpk1.dealer__Description__c ='Testabac';
dpk1.Retail_Price__c =1;
dpk1.Parts_Cost__c=1;
insert dpk1;



}
}