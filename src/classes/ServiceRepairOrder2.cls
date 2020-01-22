/**
 * ServiceRepairOrder2
 * Tested by: ServiceRepairOrder2_TC
 * 
 *   2015-11-20  B. Leaman  BLL2 Add support for Avalara AvaTax.
 *   2015-01-26  B. Leaman  BLL3 Support for "Tax exempt service" flag (when to be paid by the VA).
 *   2016-01-31  J. Kuljis   JVK1 - Support for toggle of centralized parts
 *  2016-02-16  RedTeal     RT1  - New sublet sum field
 *  2016-02-19  J. Kuljis   JVK2 - calcTaxes , if error encountered return null
 *  2016-02-20  J. Kuljis   JVK3 - Customer Account Name can only be 50 characters.  (VF_PAGE_MESSAGE GetTax Error: LengthError : CustomerCode length must be between 1 and 50 characters.) * In Progress *
 *	2017-12-20	B. Leaman	BLL4 - allow taxes to recalc after invoice step (since invoice doesn't mean anything to MW).
 *	2019-04-22	B. Leaman	W-000575 BLL5 - @remote actions need to be global to be included in an iframe (within a lightning component)
 *	2019-12-09	B. Leaman	W-000788 BLL6 - support for splitting actual from book times
 */
// BLL5
//public with sharing class ServiceRepairOrder2 {
global with sharing class ServiceRepairOrder2 {
// BLL5 end

    public String rId {get;set;}

    public dealer__Service_Repair_Order__c ro {get;set;}
    private ApexPages.StandardController ctlr;

  // BLL2a
  private AvaTax_MBW serviceTaxation; 
  public list<ServiceTaxes__c> Taxes;
  public Decimal TaxTotal {
    get {
      Decimal total = 0.00;
      if (Taxes==null) getTaxes();
      if (Taxes!=null) {
        for (ServiceTaxes__c t : Taxes) {
          total += t.Tax__c;
        }
      }
      return total;
    }
    private set;
  }
  public boolean PrintCashierRequireTaxCalc {get; private set;}
  // BLL2a end


    public ServiceRepairOrder2(ApexPages.StandardController c) {

    // BLL2a need additional field...
        // Get all the custom field for use in the VF UI
        //Map<String, Schema.SObjectField> M = Schema.SObjectType.dealer__Service_Repair_Order__c.fields.getMap();
        //Set<String> fieldnames = M.keySet(); 
        //List<String> af = new List<String>();
        //af.add('TaxHash__c'); 
        //af.add('dealer__Customer_Tax__c');
        //af.add('TaxCalcDT__c');
        //af.add('TaxPostDT__c');
        //af.add('TaxCommitDT__c');
        //af.add('TaxCancelDT__c');
        //af.add('dealer__Company__r');
        //af.addAll(fieldnames);
        //if(!Test.isRunningTest()) {             
        //    c.addFields(af);
        //}
        ctlr = c;  
        PrintCashierRequireTaxCalc = true;
        MW_TriggerControls__c AvataxRepair = MW_TriggerControls__c.getInstance('AvataxRepair');  // BLL8a
         if (AvataxRepair!=null && AvataxRepair.Enabled__c==false) PrintCashierRequireTaxCalc = false;
        // BLL2a end
         
        if(ApexPages.currentPage().getParameters().get('id')!='' && ApexPages.currentPage().getParameters().get('id') != null) {
            this.rId = ApexPages.currentPage().getParameters().get('id');
            this.ro = [SELECT Id, dealer__Vehicle__c, dealer__Company__c, dealer__Company__r.dealer__Company_Number__c, 
                      TaxHash__c, dealer__Tax__c, dealer__Customer_Tax__c, dealer__Status__c,  // BLL2a
                      TaxCalcDT__c, TaxPostDT__c, TaxCommitDT__c, TaxCancelDT__c, // BLL2a 
                      dealer__Company__r.Centralized_Purchasing_On_Off__c // JVK1
					  , dealer__Company__r.LaborBookEqualsActualTime__c	// BLL6
                   FROM dealer__Service_Repair_Order__c WHERE Id =:rId  ];
            //this.ro = (dealer__Service_Repair_Order__c) c.getRecord();
        }

    }

    public PageReference save() {
        if(ro.dealer__Vehicle__c!=null) {
            dealer__Service_Vehicle__c v = [Select Id, dealer__VIN__c from dealer__Service_Vehicle__c 
                                            where Id=:ro.dealer__Vehicle__c limit 1];
            ro.dealer__VIN__c = v.dealer__VIN__c;
        }

    checkTaxUpdate(false); // BLL2a
    //Savepoint sp = Database.setSavepoint(); // BLL2a

        try {
            if(ro.Id==null) {
                insert ro;
            } else {
                update ro;
            }
        } catch(DmlException e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
        }

        return new ApexPages.StandardController(ro).view();
    }

    public PageReference detailUpdate() {
    boolean recalc = false; // BLL2a
    // not with every update: recalc = checkTaxUpdate(true); // BLL2a
    checkTaxRecalc(); // BLL2a
    //Savepoint sp = Database.setSavepoint(); // BLL2a
    
        ro = [SELECT dealer__Comments__c, dealer__Company_Number__c, dealer__Create_Date_Time__c, dealer__Customer_Charges__c, dealer__Customer_Contact__c, dealer__Customer_Invoice_Total__c, dealer__Customer_Labor_Charges__c, dealer__Customer_Number__c, dealer__Customer_Parts_Charges__c, dealer__Customer_Sublet_Charges__c, dealer__Customer_Tax__c, dealer__Customer__c, dealer__Days_Down__c, dealer__Deposit__c, dealer__Discount_Code__c, dealer__Discount_Total__c, dealer__Discount_Type__c, dealer__Dispatched__c, dealer__Estimate__c, dealer__Franchise_Code__c, dealer__Hazardous_Materials__c, dealer__Internal_Charges__c, dealer__Inventory_Vehicle_Status__c, dealer__Invoiced_Date_Time__c, dealer__Location__c, dealer__Mileage_In__c, dealer__Mileage_Out__c, dealer__Parts_Invoice__c, dealer__Posted_Date_Time__c, dealer__Promise_Date__c, dealer__Promise_Time__c, dealer__RO_Number__c, dealer__Recommendations__c, dealer__Rewards_ID__c, dealer__Rewards_Number__c, dealer__Sales_Inventory_Id__c, dealer__Service_Advisor_ID__c, dealer__Service_Advisor_Name__c, dealer__Service_Advisor__c, dealer__Shop_Supplies__c, dealer__Status__c, dealer__Tag__c, dealer__Tax__c, dealer__Taxable__c, dealer__VIN__c, dealer__Vehicle_Inventory__c, dealer__Vehicle__c, dealer__Waiting__c, dealer__Warranty_Charges__c, dealer__Customer_Pay_Labor__c, dealer__Customer_Pay_Parts__c, dealer__Internal_Labor_Charges__c, dealer__Internal_Parts_Charges__c, dealer__Number_of_Repair_Lines__c, dealer__Open_Flat_Rate_Hours__c, dealer__Open_Job_Lines__c, dealer__Total_Flat_Rate_Hours__c, dealer__Warranty_Labor_Charges__c, dealer__Warranty_Parts_Charges__c, dealer__Company__c, dealer__Color_Code__c, External_ID__c, upload_Customer__c, Conversion_Manufacturer__c, Lift_Model__c, Lift_Cycle_Count__c, Lift_MFG__c, Lift_Serial_Number__c, Name, Id,
             TaxHash__c,  // BLL2a 
                TaxCalcDT__c, TaxPostDT__c, TaxCommitDT__c, TaxCancelDT__c // BLL2a 
          FROM dealer__Service_Repair_Order__c
            where Id=:ro.Id
            limit 1];

    // BLL2a
    System.debug(ro);
    //if (recalc) {
      //    return save(); // force refresh of page
    //}
    // BLL2a end
        return null;
    }

    /*
    *
    *   Return to the RO Page
    *
    */
    public PageReference returnToRo() {
        PageReference r = new ApexPages.StandardController(ro).view();
        return r;
    }

    /**
     * SImple Remote Action to get the job lines...
     * @param  masterRecordId The ID of the RO to be requested
     * @return Service Job List.
     */
    
    //RT1 added sublet sum to query
    @RemoteAction
	// BLL5
    //public static List<dealer__Service_Job__c> loadServiceJobLines(String masterRecordId) {
    global static List<dealer__Service_Job__c> loadServiceJobLines(String masterRecordId) {
	// BLL5 end
        return [Select d.dealer__Stat__c, d.dealer__Standard_Operation_Code__c, d.dealer__Standard_Operation_Code__r.dealer__Service_Type__c, 
                    d.dealer__Standard_Operation_Code__r.dealer__Op_Code_Description__c, d.dealer__Service_Repair_Order__c, 
                    d.dealer__RO_Number__c, d.dealer__RO_Invoice_Date_Time__c, d.dealer__Parts_Cost__c, d.dealer__Op_Code__c, 
                    d.dealer__Line_Number__c, d.dealer__Labor_Type__c, d.dealer__Labor_Rate__c, d.dealer__Labor_Charges__c, 
                    d.dealer__Job_Start__c, d.dealer__Job_Finish__c, d.dealer__Estimate__c, d.dealer__Correction__c, 
                    d.dealer__CustomerConcern__c, d.dealer__Cause__c, d.dealer__CauseExtended__c, d.dealer__Book_Time__c, d.dealer__Actual_Time__c, dealer__Currently_Active__c,
                    d.Name, d.LastModifiedDate, d.LastModifiedById, d.dealer__Line_Total__c, d.dealer__Sublet_Total__c, Sublet_Sum__c, d.dealer__Parts_Total__c,
                    d.Id, d.CreatedDate, d.CreatedById, dealer__Service_Repair_Order__r.dealer__Status__c,
                        (Select Id, Name, dealer__Counterman__c, dealer__Core__c, dealer__Cost__c, dealer__Price__c, dealer__List__c, 
                            dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Part__c, dealer__Price_Level__c, dealer__Transaction_Code__c, 
                            dealer__Part_Number__c, dealer__Part_Description__c, dealer__Bin__c, dealer__Extended_Price__c, dealer__Job_Line__c
                             From dealer__Parts_Lines__r)
                    From dealer__Service_Job__c d
                    where d.dealer__Service_Repair_Order__c = :masterRecordId 
                    order by d.dealer__Line_Number__c asc
                    limit 100];
    }


    @RemoteAction
	// BLL5
    //public static Decimal laborTotal(String lineId) {
    global static Decimal laborTotal(String lineId) {
	// BLL5 end
        AggregateResult[] sumLabor = [Select SUM(Labor_Total__c) tsum FROM dealer__Technician_Job_Time__c 
                                        where  dealer__Service_Job_Line__c=:lineId];
        return (decimal) sumLabor[0].get('tsum');       
    }
    
    // BLL2a begin
    public void checkTaxRecalc() {
    System.debug(serviceTaxation);
    if (serviceTaxation!=null && serviceTaxation.AutomaticCalc==true) {  
      serviceTaxation = AvaTax_MBW.getInstanceSROId(ro.Id); // force review
      try {
        System.debug('Checking if recalc tax is needed');
        if (getNeedToRecalcTax()==true) {
          System.debug('Will need to recalculate taxes');
        }
      } catch(Exception e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
      }
    }
    }
    
    public boolean checkTaxUpdate(boolean dml) {
    boolean updated = false;
    System.debug(serviceTaxation);
    if (serviceTaxation!=null && serviceTaxation.AutomaticCalc==true) { 
      serviceTaxation = AvaTax_MBW.getInstanceSROId(ro.Id); // force review
      try {
        System.debug('Checking if recalc tax is needed');
        if (getNeedToRecalcTax()==true) {
          System.debug('Recalculating taxes');
          calcTax(); 
          updated = true;
          serviceTaxation.saveServiceTaxDetail();
          if (dml==true) {
            serviceTaxation.saveServiceTaxHeader();
          } else {
            serviceTaxation.updServiceTaxHeader(ro);
          }
          System.debug('Taxes saved to RO: ' + ro.Id);
        }
      } catch(Exception e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
      }
    }
    return updated;
    }

    // getTaxes
  //-----------------------------
  public list<ServiceTaxes__c> getTaxes() {
    if (Taxes==null && ro.Id!=null) {
      Taxes = [
        select Id, Name, TaxType__c, JurisType__c, JurisName__c, Taxable__c, TaxRate__c, Tax__c
        from ServiceTaxes__c
        where ServiceRepairOrder__c=:ro.Id
      ];
    }
    return Taxes;
  }

  // pageCalcTax
  //-----------------------------
  public ApexPages.PageReference pageCalcTax() {
    ApexPages.PageReference refreshPage = ApexPages.currentPage();
    //refreshPage.setRedirect(true);
    if (/*BLL4d ro.dealer__Status__c!='Invoiced' && */ ro.dealer__Status__c!='Posted') { //
      try {
        calcTax(); 
        serviceTaxation.saveServiceTaxDetail();
        serviceTaxation.saveServiceTaxHeader();
      } catch(Exception e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        return null; // JVK2
      }
    } else {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Taxes are not recalculated after invoicing.'));
      return null; // BLL add
    }
    return new ApexPages.StandardController(ro).view();
  }

  // calcTax
  //-----------------------------
  public void calcTax() {
    serviceTaxation = AvaTax_MBW.getInstanceSROId(ro.Id);
    String hash = serviceTaxation.getHash();
    serviceTaxation.calculateTax();
    serviceTaxation.updServiceTaxHeader(ro);
    Taxes = null;
  }

  // getNeedToRecalcTax
  //-----------------------------
  public boolean getNeedToRecalcTax() {
    String hash = null; 
    if (serviceTaxation==null && ro.Id!=null) {
      serviceTaxation = AvaTax_MBW.getInstanceSROId(ro.Id);
    }
    if (serviceTaxation!=null) {
      hash = serviceTaxation.getHash();
    }
    return hash!=ro.TaxHash__c || TaxTotal!=ro.dealer__Customer_Tax__c;
  }
    // BLL2a end
    
    
}