/*
   Utility Class
   It is used to create test records for every object
   Developer: DiligentITLabs
   Date     : 12/29/2015
   Version  : 1.0

	2016-03-28	B. Leaman	Add @isTest designation so this doesn't count against us in code coverage.
*/
@isTest
public with sharing class UtilityTestData_AC {
    public Account acc{get;set;}
    public Contact con{get;set;}
    public dealer__Service_Vehicle__c  dsv{get;set;}
    public dealer__Service_Repair_Order__c dsr{get;set;}
    public dealer__Dealer_Location__c ddl{get;set;}
    public c2g__codaGeneralLedgerAccount__c gla{get;set;}
    public ServicePaymentType__c spt{get;set;}
    public dealer__Service_Job__c dsj{get;set;}
    public dealer__Time_Clock__c dtc{get;set;}
    public dealer__Technician_Job_Time__c  dtj{get;set;}
    public ServiceMiscCharges__c smc {get;set;}
    public c2g__codaPurchaseInvoiceLineItem__c cpil{get;set;}
    public c2g__codaJournal__c cj{get;set;}
    public c2g__codaPurchaseInvoice__c cpi{get;set;}
    
    public dealer__Purchase_Order__c dpo{get;set;}
    public dealer__Purchase_Order_Line__c dpol{get;set;}
    public dealer__Parts_Inventory__c dpi{get;set;}
    public dealer__Parts_Invoice__c dpinv{get;set;}
    public dealer__Parts_Invoice_Line__c dpl{get;set;}
    public dealer__Chart_of_Accounts__c  dca{get;set;}
    public dealer__Parts_Stocking_Group__c dpsg{get;set;}
    public dealer__Parts_Master__c dpm{get;set;}
    public dealer__Parts_Kit__c dpk{get;set;}
    public dealer__Parts_Kit_Item__c dpki{get;set;}
    public Kit_Category__c kc{get;set;}
    
    
    public Account InsertAccount()
    {
        //List<Account> acc_list = new List<Account>();
        dealer.TestClassUtil tc = new dealer.TestClassUtil();
        tc.insertDMSSettings();
        acc = new Account();
        acc.LastName ='Test';
        acc.AccountSource ='Dealer';
        acc.BillingState = 'CA';
        //acc_list.add(acc);
        insert acc;
        
        return acc;
    }
    public Contact InsertContact()
    {
        //List<Contact> con_list = new List<Contact>();
        con = new Contact();
        con.Phone = '8888888';
        con.LastName = 'Test';
       // con_list.add(con);
        insert con;
        
        return con;
        
    }
    public dealer__Service_Vehicle__c InsertServiceVehicle()
    {
       // List<dealer__Service_Vehicle__c> dsv_list = new List<dealer__Service_Vehicle__c>();
        dsv = new dealer__Service_Vehicle__c();
        dsv.dealer__VIN__c ='Test';
        dsv.Name='Test';
        dsv.dealer__Body_Style__c = 'Test';
        dsv.dealer__Company_Number__c='12123';
        dsv.dealer__Veh_Owner_Contact__c = con.id;
        dsv.dealer__Carline__c ='Test';
        dsv.dealer__Make__c  ='Test';
        dsv.dealer__Year__c  ='2013';
       // dsv_list.add(dsv);
        insert dsv;
        
        return dsv;
        
    } 
    public dealer__Dealer_Location__c InsertLocation()
    {
        ddl = new dealer__Dealer_Location__c();
        ddl.Name ='Test';
        ddl.dealer__City__c ='Test';
        ddl.dealer__Postal_Code__c='301352';
        ddl.dealer__State__c='Te';
        ddl.dealer__Company_Number__c='SAN';
        ddl.dealer__Service_Director__c =Userinfo.getuserid();
        insert ddl;
        
        return ddl;
    }
    
    public dealer__Service_Repair_Order__c InsertServiceRepairOrder()
    {
        dsr = new dealer__Service_Repair_Order__c();
        dsr.dealer__Customer__c =acc.id;
        dsr.dealer__Mileage_In__c =12;
        dsr.dealer__RO_Number__c ='11';
        dsr.dealer__VIN__c = dsv.dealer__VIN__c;
        dsr.dealer__Vehicle__c = dsv.Id;
        dsr.dealer__Company__c=ddl.id;
        //dsr.dealer__Company__c=[Select Id from dealer__Dealer_Location__c where dealer__Company_Number__c = 'AKR' limit 1].Id;
        insert dsr;
        return dsr;
    }
   public c2g__codaGeneralLedgerAccount__c InsertGLedgerAccount()
   {
        gla = new c2g__codaGeneralLedgerAccount__c();
        gla.c2g__ReportingCode__c ='12';
        gla.c2g__Type__c='Manual Journal';
        gla.Name='Test';
        insert gla; 
        return gla;
   }
   public ServicePaymentType__c InsertServicePayment()
   {
        spt = new ServicePaymentType__c();
        spt.Name='TestPayment';
        spt.Default_Labor_Rate__c=2;
        spt.Parts_Sales__c=gla.id;
        spt.Parts_Cost_of_Sale__c=gla.id;
        spt.Labor_Cost_of_Sale_Account__c =gla.id;
      
        insert spt;
        return spt;
   }
   public dealer__Service_Job__c InsertServiceJob()
   {
        dsj = new dealer__Service_Job__c();
        dsj.dealer__Cause__c ='Test';
        dsj.dealer__Labor_Charges__c =12;
        dsj.dealer__Service_Repair_Order__c =dsr.id;
        dsj.dealer__Labor_Type__c = 'C';  // BLL1a
        dsj.Payment_Method__c = spt.id;
        dsj.dealer__Parts_Total__c=4;
        dsj.dealer__Misc_Charges__c =5;
        insert dsj;
        return dsj;
   }
   public dealer__Time_Clock__c InsertTimeClock()
   {
         dtc = new dealer__Time_Clock__c();
         dtc.dealer__Clock_Out__c =system.today();
         dtc.dealer__Clock_In__c =system.today();
         dtc.dealer__User__c =UserInfo.getUserId();
         //dtc.Date__c =system.today(); 
         insert dtc;
         return dtc;
   }
   public dealer__Technician_Job_Time__c InsertTechJobTime()
   {
        dtj = new dealer__Technician_Job_Time__c ();
        dtj.Name ='Test';
        dtj.dealer__Service_Job_Line__c =dsj.id;
        dtj.dealer__Start_Time__c=system.today();
        dtj.dealer__End_Time__c =system.today();
        dtj.Time_Clock_Entry__c =dtc.id;
        dtj.dealer__Time_Clock__c =dtc.id;
        dtj.Labor_Total__c =23;
        insert dtj;
        return dtj;
   }
   public ServiceMiscCharges__c InsertServiceMischarge()
   {
       smc = new ServiceMiscCharges__c ();
       smc.Type__c = 'Freight';
       smc.Amount__c = 1.00;
       smc.Service_Job_Line__c = dsj.Id;
       insert smc;
       return smc;
   }
   public c2g__codaJournal__c InsertJournal()
   {
       cj= new c2g__codaJournal__c();
       cj.c2g__JournalDate__c =system.Today();
       cj.c2g__Type__c='Manual Journal';
       insert cj;
       return cj;
   }
   
   public c2g__codaPurchaseInvoice__c InsertPurchaseInvoice()
   {
     cpi = new c2g__codaPurchaseInvoice__c();
     //cpi.Name ='Test1234'; 
     cpi.c2g__AccountInvoiceNumber__c ='Test';
     cpi.c2g__InvoiceDate__c =system.today();
     cpi.c2g__DueDate__c=system.today();
     insert cpi;
     return cpi;
   }
  public c2g__codaPurchaseInvoiceLineItem__c InsertPurchaseInvoiceline()
  {
     cpil = new c2g__codaPurchaseInvoiceLineItem__c();
     cpil.c2g__Quantity__c =12;
     cpil.c2g__UnitPrice__c=11;
     cpil.c2g__PurchaseInvoice__c=cpi.id;
     insert cpil;
     return cpil;
  }
  public dealer__Purchase_Order__c InsertPurchaseOrder()
  {
     dpo = new dealer__Purchase_Order__c();
     dpo.dealer__Vendor__c =acc.id; 
     dpo.dealer__Company__c=ddl.id;
     insert dpo;
     return dpo;
  }
  public dealer__Purchase_Order_Line__c InsertPurchaseOrderline()
  {
     dpol = new dealer__Purchase_Order_Line__c();
     dpol.dealer__Purchase_Order__c =dpo.id;
     dpol.dealer__Amount__c=11;
     insert dpol;
     return dpol;
  }
  public dealer__Chart_of_Accounts__c InsertChartAccounts()
  {
     RecordType rt=[select id from RecordType where name='Sale'];
     dca = new dealer__Chart_of_Accounts__c();
     dca.Name='Test';
     dca.dealer__Description__c='Test';
     dca.RecordTypeid=rt.id;
     insert dca;
     return dca;
  }
  public dealer__Parts_Stocking_Group__c InsertPartsStockingGroup()
  {
     dpsg = new dealer__Parts_Stocking_Group__c();
     dpsg.Name ='Test';
     dpsg.dealer__Description__c='Test';
     dpsg.dealer__Internal_Sales__c =dca.id;
     dpsg.dealer__Retail_Taxable__c=dca.id;
     dpsg.dealer__Retail_Non_Taxable__c=dca.id;
     dpsg.dealer__Wholesale_Non_Taxable__c=dca.id;
     dpsg.dealer__Wholesale_Taxable__c=dca.id;
     insert dpsg;
     return dpsg;
  }
  public dealer__Parts_Master__c InsertPartsMaster()
  {
     dpm = new dealer__Parts_Master__c();
     dpm.Name='Test';
     dpm.dealer__Part_Description__c='Test';
     dpm.dealer__Pack_QTY__c=12;
     dpm.dealer__Cost__c=11;
     dpm.dealer__Retail_Price__c=11;
     insert dpm;
     return dpm;
  }
  public dealer__Parts_Inventory__c InsertPartsInventory()
  {
        dpi = new dealer__Parts_Inventory__c();
        dpi.dealer__Stocking_Group__c = dpsg.id;
        dpi.dealer__Parts_Master__c =dpm.id;
        dpi.dealer__Cost__c =11;
        dpi.dealer__List__c=1;
        dpi.dealer__Location__c =ddl.id;
        dpi.dealer__Entry_Date__c=system.today();
        dpi.dealer__On_Hand__c   =11;
        dpi.dealer__Description__c = 'Test';
        insert dpi;
        return dpi;
  }
  
  public dealer__Parts_Invoice__c InsertPartsInvoice()
  {
        dpinv = new dealer__Parts_Invoice__c();
        dpinv.dealer__Customer_Contact__c =con.id;
        dpinv.dealer__Counterman__c=userinfo.getuserid();
        dpinv.dealer__Invoice_Number__c ='1';
        insert dpinv;
        return dpinv;
  }
  public dealer__Parts_Invoice_Line__c InsertPartsInvoiceline()
  {
        dpl = new dealer__Parts_Invoice_Line__c();
        dpl.dealer__Parts_Invoice__c= dpinv.id;
        dpl.Name ='test';
        dpl.dealer__Core__c  =12;
        dpl.dealer__Cost__c=12;
        dpl.dealer__Price__c=12;
        dpl.dealer__Part_Number__c='12';
        dpl.dealer__Quantity_Sold__c=12;
        dpl.dealer__Quantity_Ordered__c =12;
        dpl.dealer__Job_Line__c= dsj.id;
        //dpl.dealer__Service_Job_Line_Number__c=12;
        //dpl.dealer__Extended_Price__c=12;
        dpl.dealer__Part_Description__c='test';
        dpl.dealer__Total_Price__c=12;
        //dpl.dealer__Service_Line_Payment_Method__c='test';
        dpl.dealer__Pay_Type__c='c';
        //dpl.dealer__Service_Job_Line_Number__c=12; 
        dpl.dealer__Service_Repair_Order__c=dsr.id;                  
        insert dpl;
        return dpl;
  }
  public Kit_Category__c InsertKitCategory()
  {
        kc = new Kit_Category__c();
        kc.External_ID__c='Test';
        kc.Order__c=1;
        kc.Type__c='category';
       // kc.Type__c='Manufacturer';
       // kc.Type__c='Sub-category';
        insert kc ;
        return kc;
  }
  public dealer__Parts_Kit__c InsertPartsKit()
  {
     dpk = new dealer__Parts_Kit__c();
     dpk.Name='TestKit';
     dpk.dealer__Description__c='Test123';
     dpk.Retail_Price__c=12;
     dpk.Parts_Cost__c=2;
     dpk.Category__c = kc.id;
     dpk.Manufacturer__c = kc.id;
     dpk.Sub_Category__c = kc.id;
     insert dpk;
     return dpk;
  }
  public dealer__Parts_Kit_Item__c InsertPartsKitItem()
  {
     dpki= new dealer__Parts_Kit_Item__c();
     dpki.dealer__Parts_Kit__c=dpk.id;
     dpki.dealer__Parts_Master__c=dpm.id;
     dpki.dealer__Part__c=dpi.id;
     dpki.dealer__Quantity__c=2;
     insert dpki;
     return dpki;
  }
  
  public dealer__Deal__c getDealBasic(Id sup, Id loc, Id a) {
        dealer__Deal__c Deal = new dealer__Deal__c();
        Deal.dealer__Deal_ID__c = '000000000000001';
        Deal.dealer__Buyer__c = a;
        Deal.dealer__Sales_Lead__c = sup;
        Deal.dealer__Store_Location__c = loc;
        Deal.dealer__Licence__c = '100';
        Deal.Name = '12342';
        dealer__Deal__c  de=new dealer__Deal__c();
    Deal.Commission__c =12.5;
    Deal.Commission_2__c=53.2;
    Deal.Commission_3__c=45.2;
    Deal.Commission_4__c=77.25;
    Deal.Flat__c=10.0;
    Deal.Commission_FI_1__c=44;
    Deal.Commission_FI_2__c=11.0;
    Deal.Commission_FI_3__c=12.0;
    Deal.Commission_FI_4__c=24.0;
    Deal.Commission_Flat_2__c=31.0;
    Deal.Commission_Flat_3__c=9.20;
    Deal.Commission_Flat_4__c=13.02;
        
        insert Deal;
        return Deal;
    } 
    
    
    
     /*
    Get Sales Up for Testing
     */ 
    public dealer__Sales_Up__c getSalesUp(Id aid) {

        dealer__Sales_Up__c SU = new dealer__Sales_Up__c();
                    
        SU.Name = 'Test SalesUP';
        SU.dealer__Customer_Account__c = aid;
        SU.dealer__Make__c = 'Telsa';
        SU.dealer__FirstName__c = 'TestFirstName';
        SU.dealer__LastName__c = 'LastName';
        insert SU;
        return SU;
    }
    
    
    
}