/**
 * RentalAgreementMW_EXT
 * Tested by: RentalAgreementMW_EXT_TEST
 * 
 * Fields added:
 * Journal Rules: FieldName__c, ReverseValue__c
 * RentalAgreement: Location__c
 *
 * Coverage:
 * 	2018-09-19	81% (186/228)
 *
 * Modifications:
 *	2015-10-14  B. Leaman	BLL1 derive period in FF based on return date.
 *	2015-10-20  B. Leaman	BLL2 store customer on all lines.
 *	2015-10-30  B. Leaman	BLL3 If return date is in a closed period, choose current open period.
 *	2015-12-16  B. Leaman	BLL4 Record tax in Avalara. Post when agreement is marked "Paid".
 *	2016-03-21	B. Leaman	BLL5 Asunc posting; do not include taxes in taxable amount sent to Avalara;
 *							Navigation/usability improvements
 *	2016-05-17	B. Leaman	BLL6 IT#24070 - Add per diem charge field.
 *	2016-07-29	B. Leaman	BLL7 Use CurrentUserSingleton.
 *	2016-08-22	B. Leaman	BLL8 Set discount percentage to null so DealerTeam doesn't wipe out discount amount.
 *	2016-09-21	B. Leaman	BLL9 - add goodwill amount
 *	2016-11-22	B. Leaman	BLL10 - adjust how account & contact interact with each other, add custom contact field.
 *	2016-12-19	B. Leaman	BLL11 - Not using "Returned" status -- DealerTeam imposed record lockdown on that status.
 *	2017-01-19	B. Leaman	BLL12 IR-0006223 - Don't submit posting if update of status fails.
 *	2018-09-19	B. Leaman	BLl13 - chgs to update posttaxdt on objects.
 *	2018-12-06	B. Leaman	W-000513 BLL14 changes for lightning, store vehicle, mileage, nbr days, etc.; fix pagereferences;
 *	2019-07-09	B. Leaman	W-000723 BLL15 don't use return mileage
 *	2019-11-08	BLL3 - Flag rental when posting is submitted so it cannot be posted twice.
 */
public with sharing class RentalAgreementMW_EXT {
    public dealer__Rental_Agreements__c rentalagreement {get; set;}
    public String accountName {get; private set;}
    private ApexPages.StandardController stdController;
    public String Mode {get;set;}
    public Decimal Total_Charges {get; private set;}
    public Decimal Total_Amount_Due {get; private set;}
    //public String referedBy {get;set;}
    public String retURL {get;private set;}
    
    public RentalAgreementMW_EXT(ApexPages.StandardController ctlr) {

       stdController = ctlr;
       rentalagreement = (dealer__Rental_Agreements__c) ctlr.getRecord();
       //referedBy = getReferer();
       if (rentalAgreement.Id==null) {
           //BLL11d rentalAgreement.dealer__Agreement_Status__c = 'Returned';
           rentalAgreement.dealer__Agreement_Status__c = 'Open';	// BLL11a
       }
       
       Mode = 'view';
       //Mode = 'edit';
       Map<String,String> URLParameters = ApexPages.currentPage().getParameters();
       if (URLParameters.containsKey('retURL')) {
           retURL = URLParameters.get('retURL');
       } else if (retURL==null) {
           retURL = ApexPages.currentPage().getHeaders().get('Referer');
       }
       
       // BLL5d
       // attempt to tell if this was invoked via Edit button
       //if (rentalagreement!=null && URLParameters.containsKey('retURL')) {
       //    Mode = 'edit';
       //}  
       // BLL5d end

       if (URLParameters.containsKey('mode')) {
          String m = URLParameters.get('mode');
          if (m.equals('edit')) {
              Mode = 'edit';
          } else {
              Mode = 'view';
          }
       }
           
       if (rentalagreement.Id==null) {
            Mode = 'edit';
            rentalagreement.Excess_Miles_Charge__c = 0.00;
            rentalagreement.dealer__Refueling_Fee__c = 0.00;
            rentalagreement.dealer__Discount__c = 0.00;
            rentalagreement.Sales_Tax__c = 0.00;
            rentalagreement.CountySalesTax__c = 0.00;
            rentalagreement.CitySalesTax__c = 0.00;
            rentalagreement.ThirdTierRentalTax__c = 0.00;
            rentalagreement.TotalPerDiemTax__c = 0.00;	// BLL6a
            //rentalagreement.GoodwillAmount__c = 0.00;	// BLL9a
           rentalagreement.dealer__Return_Date__c = Date.today();
           defaultLocation();
       }
       if (rentalagreement.dealer__Agreement_Status__c=='Paid') {
            Mode = 'view'; // !! IMPORTANT !!
       }
 
       changeAccount();
       changeContact();
       
       //reTotal();
       Total_Charges = 0.00;
       Total_Amount_Due = 0.00;
       updateTotals();
       
/** BLL5d - with async posting, current company is no longer important 
       if (rentalagreement.Location__c!=null) {
            try {
                 dealer__Dealer_Location__c loc = [select Id, Name, Company__c from dealer__Dealer_Location__c where Id=:rentalagreement.Location__c limit 1];
               c2g__codaCompany__c comp = getFFCompany(loc.Company__c);
            } catch(Exception companyerr) {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, companyerr.getMessage()));
            }
       }
BLL5d end **/

    }

    // defaultLocation
    public void defaultLocation() {
      //BLL7d User u = [select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
      User u = CurrentUserSingleton.getInstance();	// BLL7a
      try {
        dealer__Dealer_Location__c loc = [select Id, Name from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division limit 1];
        rentalagreement.Location__c = loc.Id;
      } catch(Exception noLocation) {}
    }

    // updateAccount
    // Retrieve related account name when contact is updated
    public void changeAccount() {
      Account a = null;
      Contact c = null;	// BLL10a
      if (rentalagreement.CustomerContact__c!=null) rentalagreement.dealer__Contact__c = rentalagreement.CustomerContact__c;	// BLL10a
      if (rentalagreement.dealer__Contact__c!=rentalagreement.CustomerContact__c) rentalagreement.CustomerContact__c = rentalagreement.dealer__Contact__c;	// BLL10a
      try {
        System.debug('Account id='+rentalagreement.Account__c);
          a = [select Id, Name, PersonContactId from Account where Id=:rentalagreement.Account__c limit 1];
          System.debug('PersonContact id='+a.PersonContactId);
          if (a.PersonContactId!=null) {
              rentalagreement.dealer__Contact__c = a.PersonContactId;
              rentalagreement.CustomerContact__c = a.PersonContactId;	// BLL10a
          } else {	// BLL10a
			  c = [select Id, Name, AccountId from Contact where Id=:rentalagreement.dealer__Contact__c limit 1];
          	  if (c!=null && c.AccountId!=a.Id) {
          	  	 rentalagreement.dealer__Contact__c = null;
          	  	 rentalagreement.CustomerContact__c = null;
				 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Contact was removed because it was not associated with this account.'));
          	  }
          	  // BLL10a end
          }
          //Account a = [select Id, Name from Account where Id=:c.AccountId];
          //System.debug('Account name=' + a.Name);
          //accountName = a.Name;
      } catch(Exception noAccount) {}
    }

    // updateContact
    // Retrieve related account name when contact is updated
    public void changeContact() {
      Contact c = null;
      if (rentalagreement.CustomerContact__c!=null) rentalagreement.dealer__Contact__c = rentalagreement.CustomerContact__c;	// BLL10a
      if (rentalagreement.dealer__Contact__c!=rentalagreement.CustomerContact__c) rentalagreement.CustomerContact__c = rentalagreement.dealer__Contact__c;	// BLL10a
      try {
        System.debug('Contact id='+rentalagreement.dealer__Contact__c);
          c = [select Id, Name, AccountId from Contact where Id=:rentalagreement.dealer__Contact__c limit 1];
          System.debug('Account id='+c.AccountId);
          rentalagreement.Account__c = c.AccountId;
          if (c!=null && c.AccountId==null) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact must bet associated with an account.'));
          //Account a = [select Id, Name from Account where Id=:c.AccountId];
          //System.debug('Account name=' + a.Name);
          //accountName = a.Name;
      } catch(Exception noContact) {}
    }

    // updateTotals
    public void updateTotals() {
      Total_Charges = 0.00;
      Total_Amount_Due = 0.00;
      if (rentalagreement.Rental_fee__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.Rental_fee__c);
      }
      if (rentalagreement.Pickup_Delivery_Fee__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.Pickup_Delivery_Fee__c);
      }
      if (rentalagreement.Excess_Miles_Charge__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.Excess_Miles_Charge__c);
      }
      if (rentalagreement.dealer__Refueling_Fee__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.dealer__Refueling_Fee__c);
      }
      if (rentalagreement.dealer__Adjustment_Charges__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.dealer__Adjustment_Charges__c);
      }
      if (rentalagreement.dealer__Discount__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.dealer__Discount__c);
      }
      if (rentalagreement.Sales_Tax__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.Sales_Tax__c);
      }
      if (rentalagreement.CountySalesTax__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.CountySalesTax__c);
      }
      if (rentalagreement.CitySalesTax__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.CitySalesTax__c);
      }
      if (rentalagreement.ThirdTierRentalTax__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.ThirdTierRentalTax__c);
      }
      // BLL6a
      if (rentalagreement.TotalPerDiemTax__c!=null) {
        Total_Charges += NullAsZero(rentalagreement.TotalPerDiemTax__c);
      }
      System.debug(Total_Charges);
      // BLL6a end
      Total_Amount_Due = Total_Charges;
      // BLL9a
      //JRP1 if (rentalagreement.GoodwillAmount__c!=null) {
      //JRP1   Total_Amount_Due -= NullAsZero(rentalagreement.GoodwillAmount__c);
      //JRP1 }
      System.debug(Total_Charges);
      // BLL9a end
      if (rentalagreement.dealer__Deposit_Amount__c!=null) {
        Total_Amount_Due -= NullAsZero(rentalagreement.dealer__Deposit_Amount__c);
      }
      System.debug(Total_Amount_Due);
    }
    
    public Decimal NullAsZero(Decimal amt) {
    	return amt==null ? 0 : amt;
    }

    public boolean validAgreement() {
      boolean valid=true;
      if (rentalagreement.Account__c==null) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account is required'));
      	valid=false;
      }
      if (rentalagreement.dealer__Contact__c==null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact is required'));
      		valid=false;
      } else {
          Contact c=null;
          try {
              c = [select Id, Name, AccountId from Contact where Id=:rentalagreement.dealer__Contact__c limit 1];
          } catch(Exception noContact) {} 
            if (c==null && c.AccountId!=rentalagreement.Account__c) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact is not associated with the selected account'));
                valid=false;
            }
        }
    if (rentalagreement.ThirdPartyPayor__c!=null) {
        Account payor = [select Id, Name, RecordType.Name from Account where Id=:rentalagreement.ThirdPartyPayor__c limit 1];
        if (!payor.RecordType.Name.startsWith('Third')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payor is not a Third Party Payor account'));
          valid=false;
        }
    }
    return valid;
    }

    public ApexPages.PageReference save() {
      
      // Minor adjustments
      if (rentalagreement.Rentcentric_Contract__c!=null) {
          rentalagreement.Rentcentric_Contract__c = rentalagreement.Rentcentric_Contract__c.toUpperCase();
      }
      rentalagreement.dealer__Contact__c = rentalagreement.CustomerContact__c;	// BLL10a
      
      // Fill in required values not being required on entry screen!
      //rentalagreement.dealer__Return_Date__c = rentalagreement.dealer__Return_Date__c; 
      rentalagreement.dealer__Date_DUE_In__c = rentalagreement.dealer__Return_Date__c; 
      rentalagreement.dealer__Date_Out__c = rentalagreement.dealer__Return_Date__c.addDays(-1); 
      rentalagreement.dealer__Drivers_Birthdate__c = Date.newInstance(1915, 1, 1);
      rentalagreement.dealer__Drivers_Lic__c = 'n/a';
      rentalagreement.dealer__Drivers_Lic_Exp__c = Date.today().addYears(2);
      rentalagreement.dealer__Fuel_Charge_per_Gallon__c = 0;
      rentalagreement.dealer__Insurer__c = 'See RentCentric';
	  // BLL14
	  //rentalagreement.dealer__Return_Mileage__c = 101;
      //BLL15d if (rentalagreement.dealer__Return_Mileage__c==null || rentalagreement.dealer__Return_Mileage__c==0) rentalagreement.dealer__Return_Mileage__c = 2;
	  // BLL14 end
      // BLL15d rentalagreement.dealer__Mileage_Out__c = rentalagreement.dealer__Return_Mileage__c - 1;
	  // BLL15
	  rentalagreement.dealer__Return_Mileage__c = null;
	  rentalagreement.dealer__Mileage_Out__c = null;
	  // BLL15 end
      rentalagreement.dealer__Policy_No__c = 'See RentCentric';
      rentalagreement.dealer__Policy_Expiration_Date__c = Date.today().addYears(1);
      rentalagreement.dealer__Time_OUT__c = '06:00:00';
      rentalagreement.dealer__Time_DUE_IN__c = '20:00:00';
      rentalagreement.dealer__Excess_Miles_Fee__c = 1.00;
      rentalagreement.dealer__Discount_Percentage__c = null;	// BLL8a
      
      if (validAgreement()) {
          try {
              // Use standard controller's save method
              upsert(rentalagreement);
          } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
          }
      } else {
        return null;
      }
        //return null;  
        Mode = 'view';
        PageReference nextpage = Page.RentalAgreementMW;
        nextpage.getParameters().put('id', rentalagreement.Id);
        nextpage.getParameters().put('mode', Mode);	// BLL5a
        if (retURL!=null) nextpage.getParameters().put('returl', retURL);	// BLL5a
        //BLL5d Map<String,String> URLParameters = ApexPages.currentPage().getParameters();
        //if (URLParameters.containsKey('retURL')) {
        //  nextpage = new PageReference(URLParameters.get('retURL'));
        //}    
        nextpage.setRedirect(true);

		// BLL14
		nextpage = (new ApexPages.StandardController(rentalagreement)).view();
		// BLL14

        return nextpage;
    }

    // backToList
    // generate page reference to return to the return url (or recent items list if null)
    //--------------------------------------------------------------------------------------
    // BLL14
	//public ApexPages.PageReference backToList() {
    //    PageReference nextpage;
    //    //nextpage = stdController.cancel(); 
    //    
    //    if (retURL!=null) {
    //        nextpage = new PageReference(retURL);          
    //    } else {
    //        Schema.DescribeSObjectResult result = dealer__Rental_Agreements__c.SObjectType.getDescribe();
    //        nextpage = new PageReference('/' + result.getKeyPrefix() + '/o');
    //    } 
    //    
    //    nextpage.setRedirect(true);
    //    return nextpage;
    //}
	// BLL14 end

    // editMode - switch to edit mode
    //---------------------------------------------
    public ApexPAges.PageReference editMode() {
      Mode = 'edit';
        PageReference nextpage = Page.RentalAgreementMW;
        nextpage.getParameters().put('id', rentalagreement.Id);
        nextpage.getParameters().put('mode', 'edit');
        if (retURL!=null) {
          nextpage.getParameters().put('retURL', retURL);
        }
        nextpage.setRedirect(true);
        return nextpage;
    }

    // editMode - switch to detail/display mode 
    //---------------------------------------------
    public ApexPAges.PageReference displayMode() {
      //BLL14
      //if (rentalagreement.Id==null) {
	  //	return backToList();
      //}
	  //BLL14 end
      Mode = 'view';
        PageReference nextpage = Page.RentalAgreementMW;
        nextpage.getParameters().put('id', rentalagreement.Id);
        nextpage.getParameters().put('mode', 'view');
        if (retURL!=null) {
          nextpage.getParameters().put('retURL', retURL);
        }
        nextpage.setRedirect(true);
        return nextpage;
    }
    
    //public String getReferer(){
    //   return ApexPages.currentPage().getHeaders().get('Referer');
    //} 
 
    // Custom exception class
    //BLL5d public class PostingTemplateException extends Exception {}
    public class PostingException extends Exception {}
    

/** BLL5d 
    // getLocationFFCompany
    //----------------------------------------------------
    public c2g__codaCompany__c getFFCompany(Id compid) {
    // Get FF Company Information - TODO: Based on location this is for!
        c2g__codaCompany__c comp=null;
        if (compid!=null) {
      List<c2g__codaCompany__c> comps = [select Id, Name from c2g__codaCompany__c where Id=:compid];
      if (comps.size()>0) {
            comp = comps[0];
            System.debug('Using company ' + comp.Name);
      } else {
              throw new PostingException('Not authorized to the financial company');
      }
        } else {
            throw new PostingException('Missing the financial company');
        }
        
        // Currently selected company
        List<ID> groupIds = new List<ID>();
    for(GroupMember member : [select GroupId from GroupMember where Group.Type = 'Queue' and UserOrGroupId = :UserInfo.getUserId()]) {
      groupIds.add(member.GroupId);        
    } 
    c2g__codaCompany__c[] companies = 
      [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];
    // Ensure the user has a single current company
    if (companies.size() == 0)
      throw new PostingException('Current company has not been set for this user');
    if (companies.size() > 1)
      throw new PostingException('This operation is not valid in multiple company mode'); 
    if (companies[0].Id!=comp.Id) 
        throw new PostingException('Your current company is ' + companies[0].Name + '. '
              + 'Please select the transaction company ' + comp.Name + '.');

    return comp;
    }

BLL5d end **/


    // canEdit
    //-----------------------------------------------------------
    public boolean getCanEdit() {
      return rentalagreement.dealer__Agreement_Status__c == null 
             || rentalagreement.dealer__Agreement_Status__c != 'Paid';
    }


    // canPost
    //-----------------------------------------------------------
    public boolean getCanPost() {
      return rentalagreement.dealer__Agreement_Status__c == null 
             || rentalagreement.dealer__Agreement_Status__c != 'Paid';
    }

    
    // post
    // Create FinancialForce journal from posting template
    //-----------------------------------------------------------
    public PageReference post() {
      PageReference nextPage = null;
	  
	  // prevent double-posting
	  dealer__Rental_Agreements__c checkra = [select Id, Name, dealer__Agreement_Status__c, PostingSubmitted__c from dealer__Rental_Agreements__c where Id=:rentalagreement.Id limit 1];
	  if (checkra.PostingSubmitted__c) throw new PostingException('Rental ' + checkra.Name + ' was already posted');

      String priorStatus = rentalagreement.dealer__Agreement_Status__c;
		// BLL5a
		try {
			try {
				postTaxes();
			} catch(Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, e.getMessage()));
			}
    		Organization org = [select Id, Name from Organization limit 1];
    		String payload = '{"recordId":"' + rentalagreement.Id 
    			+ '","orgId":"' + org.Id + '","action":"rental_agreement_post","requestedBy":"' + UserInfo.getUserId() + '"}';
			//BLL12d FFAccounting.emailAsyncHandler(payload);
			rentalagreement.dealer__Agreement_Status__c = 'Paid';
			update(rentalagreement);
			FFAccounting.emailAsyncHandler(payload);	// BLL12a
			nextPage = new ApexPages.StandardController(rentalagreement).view();
	        if (retURL!=null) nextpage.getParameters().put('returl', retURL);	// BLL5a
			
			nextPage.setRedirect(true);
		} catch(Exception e) {
			rentalagreement.dealer__Agreement_Status__c = priorStatus;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		// BLL5a end    	
/** BLL5d moved to FFA_RentalDepartment 
      try {
        Id custacctId = rentalagreement.Account__c;
        if (rentalagreement.Other_payor__c!=null) {
          custacctId = rentalagreement.Other_Payor__c;
        }
        Map<String, Id> customerpaymap = new Map<String, Id>{
             'dealer__Customer_Pay_Amount__c'=>custacctId, 
             'Payor_Pay_Amount__c'=>rentalagreement.ThirdPartyPayor__c};
        Map<String, Id> referencemap = new Map<String, Id>{
             'Customer'=>rentalagreement.Account__c,
             'ThirdPartyPayor'=>rentalagreement.ThirdPartyPayor__c,
             'OtherPayor'=>rentalagreement.Other_payor__c,
             'Vendor'=>null, 
             'Location'=>rentalagreement.Location__c
          };
        Map<String, String> journalmap = new Map<String, String>{
             'Control'=>'Name', 
             'JournalDate'=>'dealer__Return_Date__c'
          };
      try {
            postTaxes();
      } catch(Exception e) {
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, e.getMessage()));
      }
        c2g__codaJournal__c jrn = createJournal('REN', journalmap, rentalagreement, customerpaymap, referencemap);
          rentalagreement.dealer__Agreement_Status__c = 'Paid';
          update(rentalagreement);
          nextPage = new ApexPages.StandardController(jrn).view();
            nextPage.setRedirect(true);
      } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
      }
BLL5d end **/

      return nextPage;
    }
    
    // Store total tax collected in Avalara
  public void postTaxes() {
    Avatax_MBW tax = Avatax_MBW.getInstanceRentalId(rentalagreement.Id);
    if (tax.AutomaticCalc) {
      tax.calculateTax();
      tax.debugTaxResultSummary();
      tax.saveRentalTaxDetail();
      tax.updRentalTaxHeader(rentalagreement);
      update(rentalagreement);	// BLL12a - force update here before sending to Avalara
    }
    Decimal TotalTax = NullAsZero(rentalagreement.Sales_Tax__c) + NullAsZero(rentalagreement.CountySalesTax__c) 
    	+ NullAsZero(rentalagreement.CitySalesTax__c) + NullAsZero(rentalagreement.ThirdTierRentalTax__c)
    	+ NullAsZero(rentalagreement.TotalPerDiemTax__c); 
    Decimal TotalChg = rentalagreement.Total_Charges__c - TotalTax; // BLL5a
    MW_TriggerControls__c postTax = MW_TriggerControls__c.getInstance('RentalPostTax');
    System.debug(postTax);
      if (postTax==null || postTax.Enabled__c) {
      	//BLL5d tax.postTax(rentalagreement.Total_Charges__c, TotalTax, true);
      	//BLL13d tax.postTax(TotalChg, TotalTax, true); // BLL5a
      	Avatax_MBW.postRentalFuture(new Set<Id>{rentalagreement.Id});	// BLL13a
      }
  }


/** BLL5d    
    // createJournal
    // Create journal entries for any object with a posting template & tied to a location
    //------------------------------------------------------------------------------------
    public c2g__codaJournal__c createJournal(String sourceReference, Map<String, String> journalmap, SObject obj, Map<String, Id> customerpaymap, Map<String, Id> referencemap) {
      //Map<String, String> postMap = new Map<String, String>{
      //  'Rental Revenue - Basic Revenue'=>'Rental_fee__c',
      //  'Rental Revenue - Excess Mileage Charge'=>'Excess_Miles_Charge__c',
      //  'Rental Revenue - Pickup/Delivery Charge'=>'Pickup_Delivery_Fee__c',
      //  'Rental Revenue - Refueling Fee'=>'dealer__Refueling_Fee__c',
      //  'Rental Misc Charges'=>'dealer__Adjustment_Charges__c',
      //  'Rental Discounts'=>'dealer__Discount__c',
      //  'Rental Deposit'=>'dealer__Deposit_Amount__c',
      //  'Sales Tax Payable'=>'Sales_Tax__c',
      //  'Sales Tax Payable - County'=>'CountySalesTax__c',
      //  'Sales Tax Payable - City'=>'CitySalesTax__c',
      //  'Sales Tax Payable - 3 Tier Rental Tax'=>'ThirdTierRentalTax__c',
      //  'Account Receivable'=>'Total_Amount_Due__c'
      //};
      //Set<String> reverseValueFields = new Set<String>{
      //  'Rental_fee__c', 'Excess_Miles_Charge__c', 'Pickup_Delivery_Fee__c', 'dealer__Refueling_Fee__c', 
      //  'dealer__Adjustment_Charges__c', / * 'dealer__Discount__c', 'dealer__Deposit_Amount__c', * / 
      //  'Sales_Tax__c', 'CountySalesTax__c', 'CitySalesTax__c', 'ThirdTierRentalTax__c' / *, 'Total_Amount_Due__c' * /
      //};
      
      // Read in posting template
      //PostingTemplate__c template = [
      //    select Id, Name, Active__c, Object_Name__c
      //    from PostingTemplate__c
      //    where Active__c=true and Name='Rental' and Object_Name__c = 'Rental Agreement' 
      //    limit 1
      //];
        String objlabel = obj.getSObjectType().getDescribe().getLabel();
       String soql = 'select Id, Name, Active__c, Object_Name__c from PostingTemplate__c '
                   + 'where Active__c=true and Object_Name__c = \'' + objLabel + '\' ';
       // TODO: optional selector for different types of transaction processes on a single object
       // if (selector!=null) {
         // soql += ' and TemplateSelector__c=\'' + selector + '\' ';
       // }

        PostingTemplate__c template = null;
       List<PostingTemplate__c> templates = Database.query(soql);
       if (templates.size()!=1) {
         throw new PostingTemplateException('Did not find a unique posting template for object ' + rentalagreement.getSObjectType() );
       } else {
         template = templates[0];
       }
      
      // Get posting template rules (account mapping)
      List<PostingTemplateEntryRule__c> rules = [
          select Id, Name, Action__c, Default_Memo__c, General_Ledger_Account__c, Posting_Template__c, Page_Order__c,
                 FieldName__c, ReverseValue__c, LineType__c
          from PostingTemplateEntryRule__c
          where Posting_Template__c = :template.Id
          order by Page_Order__c
      ];
      if (rules.size()==0) {
         throw new PostingTemplateException('No posting template entry rules found');
      }
      
      // apply field mapping & reverse flags
      //for(PostingTemplateEntryRule__c rule : rules) {
      //  System.debug(rule);
      //  if (rule.FieldName__c==null && postMap!=null) {
      //    rule.FieldName__c = postMap.get(rule.Action__c);
      //    System.debug(rule.Action__c + ' => ' + rule.FieldName__c);
      //    rule.ReverseValue__c = reverseFields.contains(rule.FieldName__c);
      //  }
      //}


        // Get FF dimensions
        // Store Location of transaction
        Id locId = referencemap.get('Location');
        dealer__Dealer_Location__c loc=null;
        c2g__codaDimension1__c dim1;
    if(locId != null) {
      loc = [
          Select Id, Name, Financial_Force_Dimension_1__c, Company__c 
        from dealer__Dealer_Location__c 
        where Id=:locId
        limit 1
      ];
      dim1 = [
          Select Id, Name 
          from c2g__codaDimension1__c 
          where Id=:loc.Financial_Force_Dimension_1__c 
          limit 1
      ];  
    }

        c2g__codaCompany__c comp = getFFCompany(loc.Company__c);
        
      // Create journal header
      c2g__codaJournal__c journal = new c2g__codaJournal__c();
        journal.c2g__OwnerCompany__c = comp.Id;
        journal.Source__c = sourceReference;
        journal.c2g__JournalDescription__c = template.name + ' ' + (String) obj.get('Name');
        journal.c2g__Reference__c = (String) obj.get(journalMap.get('Control'));
        //journal.Control__c = (String) obj.get(journalMap.get('Control'));
        //System.debug(rentalagreement.dealer__Return_Date__c);
        journal.c2g__JournalDate__c = (Date) obj.get(journalmap.get('JournalDate')); 
        if (journal.c2g__JournalDate__c == null) {
            journal.c2g__JournalDate__c = Date.today();
            System.debug('Using today for journal date');
        } 
        
    // BLL3a - next open period ending after transaction date
    c2g__codaPeriod__c period = [
      select Id, c2g__StartDate__c, c2g__EndDate__c, c2g__AP__c, c2g__Closed__c 
      from c2g__codaPeriod__c
      where c2g__OwnerCompany__c=:comp.Id and c2g__EndDate__c>=:journal.c2g__JournalDate__c 
        and c2g__Closed__c!=true and c2g__AR__c!=true
      order by c2g__StartDate__c
      limit 1
    ];
    // If the period starts after the transaction date (posting next month), force current period & chg date
    if (period.c2g__StartDate__c > journal.c2g__JournalDate__c) {
      journal.c2g__Period__c = period.Id;
      journal.ffgl__DerivePeriod__c = false;
      journal.c2g__JournalDate__c = period.c2g__StartDate__c;
    } else {  // Otherwise, let FF determine period
      journal.ffgl__DerivePeriod__c = true;      
    }
    // BLL3a end determine period/date
        
        journal.Customer__c = referencemap.get('Customer');
        journal.Third_Party_Payor__c = referencemap.get('ThirdPartyPayor');
        journal.Other_Payor__c = referencemap.get('OtherPayor');
        journal.Vendor__c = referencemap.get('Vendor');
        journal.Sales_Person__c = referencemap.get('Salesperson');
        journal.Proposal__c = referencemap.get('Proposal');
        journal.Rental_Agreement__c = referencemap.get('RentalAgreement');
        journal.Repair_Order__c = referencemap.get('RepairOrder');
        journal.Purchase_Order__c = referencemap.get('PurchaseOrder');

    // Get Accounting Currency (or set ffgl__DeriveCurrency__c=true (dft))
        c2g__codaAccountingCurrency__c curr=null;
        List<c2g__codaAccountingCurrency__c> currs = [
           Select Id, Name 
           from c2g__codaAccountingCurrency__c 
           where Name='USD' and c2g__OwnerCompany__c =:journal.c2g__OwnerCompany__c 
         ];
         if (currs.size()>0) {
             curr = currs[0];
             System.debug('Currency ' + curr.Name);
            journal.c2g__JournalCurrency__c = curr.Id;
         } else {
        throw new PostingException('Could not find USD currency for company');
         }

    // Get Period Data (or set ffgl__DerivePeriod__c=true (dft))
        //c2g__codaPeriod__c period = null;
      //List<c2g__codaPeriod__c> periods = [
      //    Select Id, Name 
      //    from c2g__codaPeriod__c 
      //    where c2g__OwnerCompany__c=:journal.c2g__OwnerCompany__c
      //      and c2g__Closed__c=false
      //      and c2g__EndDate__c >= :journal.c2g__JournalDate__c  
      //    order by c2g__StartDate__c
      //];
      //if (periods.size()>0) {
      //   period = periods[0];
      //  System.debug('Using period ' + period.Name);
      //} else {
      //   System.debug(journal.c2g__JournalDate__c);
      //  throw new PostingException('Could not determine open accounting period for '
      //            + journal.c2g__JournalDate__c.format());
      //}
        //journal.c2g__Period__c = period.Id;
        journal.ffgl__DerivePeriod__c=true;   // was false;  // BLL1a 

      // Process rules to create journal entries
      List<c2g__codaJournalLineItem__c> lines = new List<c2g__codaJournalLineItem__c>();
      Integer i=1;
      for(PostingTemplateEntryRule__c rule : rules) {
        System.debug(rule);
        c2g__codaJournalLineItem__c line = new c2g__codaJournalLineItem__c();

        // Add the journal reference later -- make sure all lines will be created w/out error first!
        //line.c2g__Journal__c = journal.Id;
        
        if (dim1!=null) {
               line.c2g__Dimension1__c = dim1.Id;
        } 
            line.c2g__LineNumber__c = i++;
            line.c2g__LineDescription__c = template.name + ' - ' + String.valueOf(rule.Action__c) + ': ' + (String) obj.get('Name');
            line.c2g__GeneralLedgerAccount__c = rule.General_Ledger_Account__c;
            line.Control__c = (String) obj.get(journalMap.get('Control'));
            
            line.c2g__LineType__c = (rule.LineType__c!=null) ? rule.LineType__c : 'General Ledger Account';   // Deposit & AR s/b 'Account - Customer'
            if (line.c2g__LineType__c=='Account - Customer') {
                line.c2g__Account__c = (customerpaymap.containsKey(rule.FieldName__c)) ? customerpaymap.get(rule.FieldName__c) : referencemap.get('Customer'); 
            }
            if (line.c2g__LineType__c=='Account - Vendor') {
               line.c2g__Account__c = referencemap.get('Vendor');
          } 

            line.Customer_Name__c = referencemap.get('Customer');  // BLL2c re-activate 
            //line.Third_Party_Payor__c = referencemap.get('Payor');
            //line.Vendor_Name__c = referencemap.get('Vendor');

            try {
                line.c2g__Value__c = (Decimal) obj.get(rule.FieldName__c);
            } catch(Exception fielderr) {
              throw new PostingTemplateException('Unable to access field ' + rule.FieldName__c + ' in rule ' + rule.Action__c);
            }

            if (line.c2g__Value__c!=null && rule.ReverseValue__c!=null && rule.ReverseValue__c==true) {
              line.c2g__Value__c = -line.c2g__Value__c;
            }
            if (line.c2g__Value__c != null && line.c2g__Value__c!=0) {
           lines.add(line);
           System.debug(line);
            } 
      }
      
      try {  // BLL1a
          insert(journal);
          // now add journal id reference to lines
          for(c2g__codaJournalLineItem__c line : lines) {
            line.c2g__Journal__c = journal.Id;
          }
        insert(lines);
      } catch(Exception e) { // BLL1a
        journal = null;  // BLL1a
        throw new PostingException('Unable to post. Error is ' + e.getMessage());  // BLL1a
      } // BLL1a
      return journal;
    }
BLL5d end **/
   
}