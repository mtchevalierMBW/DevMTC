/**
 * SelectDealership_TC
 * Tests: SelectDealership
 *
 *	2017-05-03	B. Leaman	Replace custom Dealer_Location_Users__c obj.
 */
@isTest
Public Class SelectDealership_TC{
Static testmethod Void Myunittest(){

dealer__Dealer_Location__c ddl = new dealer__Dealer_Location__c();
ddl.Name ='Test';
ddl.dealer__City__c ='Test';
ddl.dealer__Postal_Code__c='301352';
ddl.dealer__State__c='Te';
ddl.dealer__Company_Number__c='12365';
ddl.dealer__Service_Director__c=Userinfo.getuserid();
ddl.dealer__Address__c='Test';
ddl.dealer__Company_Number__c='12234'; 
ddl.dealer__Email__c='Test@gmail.com';
ddl.dealer__General_Manager__c=Userinfo.getuserid();
ddl.dealer__Main_Phone__c='1212344';
//dealer__Physical_Location__Latitude__s,
//dealer__Physical_Location__Longitude__s, 
//dealer__Physical_Location__c, 
ddl.dealer__Website__c='WWW.TEST.COM';
ddl.Tax_Labor__c=true;
ddl.Tax_Parts__c=true;
ddl.Tax_Rate_Default__c=12;
ddl.Customer_Pay_Labor_Rate__c=12;
ddl.Internal_Labor_Rate__c=1;
ddl.Doc_Fee__c=1;
ddl.Title_Fee__c=11;
ddl.Tag_Fee__c=14;
ddl.Electronic_Filing_Fee__c=11;
ddl.Sales_Admin__c=Userinfo.getuserid();
insert ddl;

//BLL1d Dealer_Location_Users__c dlu = new Dealer_Location_Users__c();
//BLL1d dlu.Dealer_Location__c =ddl.id;
//BLL1d dlu.User__c =Userinfo.getuserid();
//BLL1d insert dlu;
// BLL1a
dealer__Dealer_Location_User__c dlu = new dealer__Dealer_Location_User__c();
dlu.dealer__Dealer_Location__c =ddl.id;	
dlu.dealer__User__c =Userinfo.getuserid();
insert dlu;
// BLL1a end

SelectDealership  sd = new SelectDealership();
sd.getmyDealerships();
sd.selectedDealershipId =ddl.id;
sd.chooseDealership(); 
}
}