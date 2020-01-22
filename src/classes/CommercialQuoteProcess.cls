/**
 * CommercialQuoteProcess
 * Tested by: CommercialQuoteProc_TEST
 * Programmer: Bryan Leaman
 * Date: 2016-02-19
 * 
 *
 *	2016-05-12	B. Leaman	BLL1 - Need owner of RO to be the special location-specific owner: Service_Reporting_User__c 
 *	2016-05-13	B. Leaman	BLL2 - Require releasing dealer if the type of sale is 'Releasing Dealer', select posting template if only 1.
 *	2016-05-17	B. Leaman	BLL3 - Commercial deal needs to record sale date and due days (1=cash, 5=finance)
 *	2016-06-17	B. Leaman	BLL4 - Require vehicle reference & correct unit# before marking as delivered
 *	2016-06-24	B. Leaman	BLL5 - routines for recalculating GP and commission
 *	2016-09-23	B. Leaman	BLL6 - Require market segment and New Customer fields on order checklist page
 *	2016-12-21	B. Leaman	BLL7 - Don't assign RO numbers -- it's done via DealerTeam trigger now. 
 */
public class CommercialQuoteProcess {

	// LostOpportunity (mark quotes lost)
	public static void LostOpportunity(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
		Set<Id> LostOppIds = new Set<Id>();
		for(Opportunity Opp : newMap.values()) {
			Opportunity oldOpp = oldMap.get(Opp.Id);
			System.debug(Opp);
			System.debug(oldOpp);
			if (Opp.StageName=='Lost' && oldOpp!=null && oldOpp.StageName!='Lost') LostOppIds.add(Opp.Id);
		}
		if (LostOppIds.size()>0) {
			List<CommercialQuote__c> cqs = [
				select Id, Name, Status__c, Opportunity__c, SolutionOpportunity__c
				from CommercialQuote__c
				where Opportunity__c in :LostOppIds
			];
			List<CommercialQuote__c> LostCQs = new List<CommercialQuote__c>();
			for(CommercialQuote__c cq : cqs) {
				Opportunity o = newMap.get(cq.Opportunity__c);
				if (cq.Status__c.contains('Won') || cq.Status__c.contains('Posted')) o.addError('Opportunity '+o.Name+' has a won quote so it cannot be lost');
				if (cq.Status__c=='Pending') LostCQs.add(new CommercialQuote__c(Id=cq.Id, Status__c='Lost'));
			}
			if (LostCQs.size()>0) Database.update(LostCQs);
		}
	}


	// LostSolutionOpportunity (mark quotes lost)
	public static void LostSolutionOpportunity(Map<Id, dealer__Sales_Up__c> newMap, Map<Id, dealer__Sales_Up__c> oldMap) {
		Set<Id> LostSolOppIds = new Set<Id>();
		for(dealer__Sales_Up__c SolOpp : newMap.values()) {
			dealer__Sales_Up__c oldSolOpp = oldMap.get(SolOpp.Id);
			System.debug(SolOpp);
			System.debug(oldSolOpp);
			if (SolOpp.dealer__Lead_Status__c=='Lost' && oldSolOpp!=null && oldSolOpp.dealer__Lead_Status__c!='Lost') LostSolOppIds.add(SolOpp.Id);
		}
		if (LostSolOppIds.size()>0) {
			List<CommercialQuote__c> cqs = [
				select Id, Name, Status__c, Opportunity__c, SolutionOpportunity__c
				from CommercialQuote__c
				where SolutionOpportunity__c in :LostSolOppIds
			];
			List<CommercialQuote__c> LostCQs = new List<CommercialQuote__c>();
			for(CommercialQuote__c cq : cqs) {
				dealer__Sales_Up__c so = newMap.get(cq.SolutionOpportunity__c);
				if (cq.Status__c.contains('Won') || cq.Status__c.contains('Posted')) so.addError('Solution Opportunity '+so.Name+' has a won quote so it cannot be lost');
				if (cq.Status__c=='Pending') LostCQs.add(new CommercialQuote__c(Id=cq.Id, Status__c='Lost'));
			}
			if (LostCQs.size()>0) Database.update(LostCQs);
		}
	}

	
	// WonCommercialQuote (mark opportunity/solution opp Won)
	public static void WonCommercialQuote(List<CommercialQuote__c> newList, Map<Id, CommercialQuote__c> oldMap) {
		Set<Id> WonOpportunities = new Set<Id>();
		//Set<Id> WonSolutionOpportunities = new Set<Id>();
		for(CommercialQuote__c cq : newList) {
			if (!cq.AdministrativeUpdate__c) {
				if (cq.Status__c.contains('Won') && cq.TypeOfSale__c=='Releasing Dealer' && cq.ReleasingDealer__c==null) cq.addError('Quote ' + cq.Name + ' is missing the Releasing Dealer on the Order Checklist' );	// BLL2a
				if (cq.Status__c.contains('Won') && cq.TypeOfSale__c!='Build for Stock' && cq.Market_Segment__c==null) cq.addError('Quote ' + cq.Name + ' is missing the Market Segment on the Order Checklist' );	// BLL6a
				if (cq.Status__c.contains('Won') && cq.TypeOfSale__c!='Build for Stock' && cq.New_Customer__c==null) cq.addError('Quote ' + cq.Name + ' is missing the New Customer selection on the Order Checklist' );	// BLL6a
			}
			CommercialQuote__c oldCQ = oldMap.get(cq.Id);
			if (cq.Status__c.contains('Won') && oldCQ!=null && !oldCQ.Status__c.contains('Won')) {
				if (cq.Opportunity__c!=null) WonOpportunities.add(cq.Opportunity__c);
				//if (cq.SolutionOpportunity__c!=null) WonSolutionOpportunities.add(cq.SolutionOpportunity__c);
			}
		}
		if (WonOpportunities.size()>0) {
			List<Opportunity> Opps = [select Id, Name, StageName from Opportunity where Id in :WonOpportunities and StageName!='Won'];
			for (Opportunity o : Opps) o.StageName = 'Won';
			if (Opps.size()>0) Database.update(Opps);
		}
		//if (WonSolutionOpportunities.size()>0) {
		//	List<dealer__Sales_Up__c> SolOpps = [select Id, Name, dealer__Lead_Status__c from dealer__Sales_Up__c where Id in :WonSolutionOpportunities and dealer__Lead_Status__c!='Won' and dealer__Lead_Status__c!='Booked'];
		//	for (dealer__Sales_Up__c so : SolOpps) so.dealer__Lead_Status__c = 'Won';
		//	if (SolOpps.size()>0) Database.update(SolOpps);
		//}
	}

	// WonCommercialVehicle (mark vehicle Sold - Not Delivered)
	public static void WonCommercialVehicle(List<CommercialQuote__c> newList, Map<Id, CommercialQuote__c> oldMap) {
		Set<Id> WonVehicleIds = new Set<Id>();
		for(CommercialQuote__c cq : newList) {
			CommercialQuote__c oldCQ = oldMap.get(cq.Id);
			if ((cq.Status__c.contains('Production') || cq.Status__c.contains('Deposit')) && oldCQ!=null && !oldCQ.Status__c.contains('Won') && !oldCQ.Status__c.contains('Delivered')) {
				if (cq.VehicleInventory__c!=null) WonVehicleIds.add(cq.VehicleInventory__c);
			}
		}
		if (WonVehicleIds.size()>0) {
			List<dealer__Vehicle_Inventory__c> vehs = [select Id, Name, dealer__Status_Code__c 
				from dealer__Vehicle_Inventory__c 
				where Id in :WonVehicleIds and dealer__Status_Code__c!='Sold - Not Delivered' and dealer__Status_Code__c!='Delivered'];
			for (dealer__Vehicle_Inventory__c v : vehs) v.dealer__Status_Code__c = 'Sold - Not Delivered';
			if (vehs.size()>0) Database.update(vehs);
		}
	}

	// DeliveredCommercialVehicle (mark vehicle delivered) - also check for open ROs
	public static void DeliveredCommercialVehicle(List<CommercialQuote__c> newList, Map<Id, CommercialQuote__c> oldMap) {
		Set<Id> DlvVehicleIds = new Set<Id>();
		for(CommercialQuote__c cq : newList) {
			CommercialQuote__c oldCQ = oldMap.get(cq.Id);
			if (cq.Status__c.contains('Delivered') && oldCQ!=null && !oldCQ.Status__c.contains('Delivered')) {
				if (cq.VehicleInventory__c!=null) DlvVehicleIds.add(cq.VehicleInventory__c);
				if (cq.VehicleInventory__c==null && !cq.AdministrativeUpdate__c) cq.addError('The commercial vehicle is required before marking the quote "Delivered."');	// BLL4a
			}
		}
		if (DlvVehicleIds.size()>0) {
			Map<Id,dealer__Vehicle_Inventory__c> vehMap = new Map<Id,dealer__Vehicle_Inventory__c>([
				select Id, Name, dealer__Status_Code__c, dealer__Stock_Number__c, // BLL4c add Stock Number
					( select Id, Name from dealer__Service_Repair_Orders__r 
					  where dealer__Status__c not in ('Posted','Void') 
					) 
				from dealer__Vehicle_Inventory__c 
				where Id in :DlvVehicleIds
			]);
			List<dealer__Vehicle_Inventory__c> updVeh = new List<dealer__Vehicle_Inventory__c>();
			for(CommercialQuote__c cq : newList) {
				dealer__Vehicle_Inventory__c veh = vehMap.get(cq.VehicleInventory__c);
				if (veh!=null) {
					// BLL4a check stock# ?= unit number
					String vehStockNo = (veh.dealer__Stock_Number__c!=null) ? veh.dealer__Stock_Number__c.replaceAll('[-_\\s]','') : null;
					String quoteStockNo = (cq.UnitNumber__c!=null) ? cq.UnitNumber__c.replaceAll('[-_\\s]','') : null;
					if (vehStockNo!=quoteStockNo && !cq.AdministrativeUpdate__c) {
						cq.addError('Unit number on quote (' + cq.UnitNumber__c + ') does not match the vehicle (' + veh.dealer__Stock_Number__c + ')');
					}
					cq.UnitNumber__c = veh.dealer__Stock_Number__c;	// if the above doesn't generate an error, standardize quote unit# to match stock number
					// BLL4a end
					if (veh.dealer__Service_Repair_Orders__r.size()>0) {
						List<String> roList = new List<String>();
						for(dealer__Service_Repair_Order__c ro : veh.dealer__Service_Repair_Orders__r) roList.add(ro.Name);
						cq.addError('Quote ' + cq.Name + ' has open repair orders: ' + String.join(roList, ', '));
					} else {
						Integer duedays = (cq.LienHolder__c!=null) ? 5 : 1;	// BLL3a
						if (veh.dealer__Status_Code__c!='Delivered' && cq.TypeOfSale__c!='Build for Stock') {	// BLL4c only if not build-for-stock
							updVeh.add(new dealer__Vehicle_Inventory__c(Id=veh.Id, dealer__Status_Code__c='Delivered', dealer__Sale_Date__c=cq.Delivery_Date__c, PaymentDueDays__c=duedays));	// BLL3c add PaymentDueDays__c
						}
						// BLL4a
						if (veh.dealer__Status_Code__c!='Not for Sale' && cq.TypeOfSale__c=='Build for Stock') {
							updVeh.add(new dealer__Vehicle_Inventory__c(Id=veh.Id, dealer__Status_Code__c='Not for Sale'));	
						}
						// BLL4a
					}
				}
			}
			if (updVeh.size()>0) Database.update(updVeh);
		}
	}


	// CQPostingEntry (create posting entry if there are no transactions links to this quote)
	public static void CreatePostingEntry(List<CommercialQuote__c> newList, Map<Id, CommercialQuote__c> oldMap) {
		Set<Id> CQtoPost = new Set<Id>();
		for(CommercialQuote__c cq : newList) {
			CommercialQuote__c oldCQ = oldMap.get(cq.Id);
			if (cq.Status__c.contains('Delivered') && oldCQ!=null && !oldCQ.Status__c.contains('Delivered')) {
				CQtoPost.add(cq.Id);
			}
		}
		
		// BLL2a
		// Posting templates
		List<PostingTemplate__c> tmplts = new List<PostingTemplate__c>([select Id, Object_Name__c from PostingTemplate__c where Object_Name__c='Commercial Quote' and Active__c=true]);
		//Map<String,PostingTemplate__c> tmpltMap = new Map<String,PostingTemplate__c>();
		//for(PostingTemplate t : [select Id, Object_Name__c, RcdType__c from PostingTemplate__c where Active__c=true ]) tmplts.put(t.RcdType__c, t);
		// BLL2a end
		
		List<Posting_Entry__c> postingEntries = new List<Posting_Entry__c>();
		// Get quotes in list that do not already have a transaction associated with them (related list)
		List<CommercialQuote__c> cqlist = [
			select Id, VehicleInventory__c, Location__c,
				(select Id from Transactions__r)
			from CommercialQuote__c
			where Id in :CQtoPost
		];
		if (cqlist.size()>0) {
			for(CommercialQuote__c cq : cqlist) {
				if (cq.Transactions__r.size()==0) {
					PostingTemplate__c t = tmplts.size()==1 ? tmplts[0] : null;	// BLL2a
					// PostingTemplate__c t = tmpltMap.containsKey(cq.TypeOfQuote__c) ? tmpltMap.get(cq.TypeOfQuote__c) : null;
					Posting_Entry__c pe = new Posting_Entry__c(
						CommercialQuote__c = cq.Id,
						Posting_Template__c = t!=null ? t.Id : null,
						Stock__c = cq.VehicleInventory__c,
						Location__c = cq.Location__c
					);
					postingEntries.add(pe);
				}
			}
			if (postingEntries.size()>0) Database.insert(postingEntries);
		}
	}


	// AutoCreateDeliveryRO (create RO when commercial quote with additional options is first marked won)
	public static void AutoCreateDeliveryRO(List<CommercialQuote__c> newList, Map<Id, CommercialQuote__c> oldMap) {
		if (newList.size()==1) {	// Only run on individual approvals
			for(CommercialQuote__c cq : newList) {
				CommercialQuote__c oldCQ = oldMap.get(cq.Id);
				if (cq.Status__c.contains('Production') && oldCQ!=null && !oldCQ.Status__c.contains('Production') 
					&& cq.ServiceRepairOrder__c==null && cq.VehicleInventory__c!=null) {
					CommercialQuoteProcess.CreateROFromCommercialQuote(cq);
					// Notify Service Mgr (and GM)
					CommercialQuoteProcess.NotifyManagerOfRepairOrder(cq);
				}
			}
		}
	}


	// NotifyManagerOfRepairOrder
	public static void NotifyManagerOfRepairOrder(CommercialQuote__c cq) {
		String emailbody = '';
		String roname = '';
		String vehname = '';
		if (cq.Location__c!=null) {
			dealer__Dealer_Location__c location = [Select Id, Name, dealer__Company_Number__c, dealer__Service_Director__c, dealer__General_Manager__c, Legacy_systems__c from dealer__Dealer_Location__c WHERE Id =:cq.Location__c limit 1];
			if (location.Legacy_systems__c==false) {
				dealer__Vehicle_Inventory__c veh = null;
				try {veh =[Select Id, Name from dealer__Vehicle_Inventory__c WHERE Id =:cq.VehicleInventory__c limit 1];
				} catch(Exception e) {}
				vehname = ((veh==null) ? 'n/a' : veh.Name);
				dealer__Service_Repair_Order__c ro=null;
				try { ro = [Select Id, Name from dealer__Service_Repair_Order__c WHERE Id =:cq.ServiceRepairOrder__c limit 1];
				} catch(Exception e) {}
				roname = ((ro==null) ? 'n/a' : ro.Name); 
				List<Id> uids = new List<Id>();
				if (location.dealer__Service_Director__c!=null) uids.add(location.dealer__Service_Director__c);
				if (location.dealer__General_Manager__c!=null) uids.add(location.dealer__General_Manager__c);
				if (uids.size()>0) {
					List<User> recipients = [select Id, Name, Email from User where Id in :uids];
			        List<String> toAddresses = new List<String>();
					for(User u : recipients) toAddresses.add(u.Email);
			        Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
			        mail.setToAddresses(toAddresses); 
			        mail.setSubject('Commercial quote ' + cq.Name + ' created Repair Order ' + roname);
			        emailbody += 'Repair order ' + roname + ' was created to make the following changes to commercial vehicle ' + vehname + '\r';
					for(CommercialQuoteLine__c cql : [
			        	select Id, Description__c, Quantity__c 
	        			from CommercialQuoteLine__c 
	        			where Commercial_Quote__c=:cq.Id and LockedOption__c=false 
	        			limit 50
	        		]) {  
	        			emailbody += '(' + String.valueOf(cql.Quantity__c) + ') ' + cql.Description__c + ' \r'; 
	        		}
			        mail.setPlainTextBody(emailbody);
			        try {
			            if (ro!=null) Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			        } catch(Exception e) {}      
	
				}
			} else {
				// No automatic RO created!
			}
		}
			
	}

	
	// CreateROFromCommercialQuote
	// Expected to run from trigger, but if not, the required CommercialQuote__c fields are:
	//     Id, Location__c, VehicleInventory__c, Customer__c, ServiceRepairOrder__c
	// Sets: ServiceRepairOrder__c but does not update.
	public static void CreateROFromCommercialQuote(CommercialQuote__c cq) {
		
		// Don't create anything if there's no vehicle
		if (cq.VehicleInventory__c==null || cq.ServiceRepairOrder__c!=null) return;
		// Don't create ro if there are no new options
		List<CommercialQuoteLine__c> cqlines = [
        	select Id from CommercialQuoteLine__c 
        	where Commercial_Quote__c=:cq.Id and LockedOption__c=false 
        	limit 1
        ];  
		if (cqlines.size()==0) return;
		
		// Get Associated Creating User
		String invoiceName = 'RO#';

		// Get location information
		dealer__Dealer_Location__c location = [Select Id, Name, dealer__Company_Number__c, dealer__Service_Director__c, Service_Reporting_User__c from dealer__Dealer_Location__c WHERE Id =:cq.Location__c limit 1];	// BLL1a Need to set owner of RO to Service_Reporting_User__c

		// Get the vehicle record
		dealer__Vehicle_Inventory__c vi = [select Id, Name from dealer__Vehicle_Inventory__c where Id=:cq.VehicleInventory__c limit 1];

		// Get service vehicle record
		dealer__Service_Vehicle__c sv = null;
		// Service vehicle not specified on the commercial quote  
		//if (cq.VehicleInventory__c!=null) {
		//	sv = [Select Id from dealer__Service_Vehicle__c where Id=:dealObject.Service_Vehicle__c limit 1];
		//}
        if (sv==null && cq.VehicleInventory__c!=null) {
        	try { 
        		sv = [Select Id, dealer__Last_Odometer__c from dealer__Service_Vehicle__c where dealer__Sales_Inventory__c=:cq.VehicleInventory__c limit 1];
        	} catch(Exception e) { /* No service vehicle attached to inventory vehicle */ } 
        }
        
        // Instantiate the RO  
        dealer__Service_Repair_Order__c ro = new dealer__Service_Repair_Order__c();
        // BLL7d 
        //dealer__FixedOperationsSettings__c fixedOpsSettings = dealer__FixedOperationsSettings__c.getOrgDefaults();
        //ro.dealer__RO_Number__c = String.valueOf(fixedOpsSettings.dealer__Repair_Order_Index__c.setScale(0)); 
        //// Check to see if the index is in alignment
        //dealer__Service_Repair_Order__c[] roIndexCheck = [Select Id from dealer__Service_Repair_Order__c where dealer__RO_Number__c=:ro.dealer__RO_Number__c limit 1];
        //if(roIndexCheck.size()>0) {
        //    fixedOpsSettings.dealer__Repair_Order_Index__c++;
        //    ro.dealer__RO_Number__c = String.valueOf(fixedOpsSettings.dealer__Repair_Order_Index__c.setScale(0));
        //}
        //try { 
        //    fixedOpsSettings.dealer__Repair_Order_Index__c++; 
        //    update fixedOpsSettings;
        //} Catch(DmlException e) { cq.addError('Unable to create the delivery repair order ' + e.getMessage()); }
		
        //ro.Name = 'RO#' + location.dealer__Company_Number__c + '-' + ro.dealer__RO_Number__c;
        // BLL7d end 
        
        ro.dealer__Company_Number__c = location.dealer__Company_Number__c;
        ro.dealer__Company__c  = location.Id; 
        ro.dealer__Create_Date_Time__c = Datetime.now();
        ro.dealer__Service_Advisor__c = location.dealer__Service_Director__c;
        if (sv!=null) {
            ro.dealer__Vehicle__c = sv.Id;
        }
        ro.dealer__Vehicle_Inventory__c = cq.VehicleInventory__c;
        ro.dealer__Mileage_In__c = (sv!=null) ? sv.dealer__Last_Odometer__c : null;
        if (ro.dealer__Mileage_In__c==null) ro.dealer__Mileage_In__c = 0;
        ro.dealer__Customer__c = cq.Customer__c;
        ro.CommercialQuote__c = cq.Id; 
		if (location.Service_Reporting_User__c!=null) ro.OwnerId = location.Service_Reporting_User__c;	// BLL1a

        System.debug(ro);
        try {
            insert ro;
            CommercialQuoteProcess.CreateROLinesFromCommercialQuote(cq, ro);
        } catch(DmlException e) { cq.addError('Unable to create the delivery repair order ' + e.getMessage()); }   

        // Update the Commercial Quote
        cq.ServiceRepairOrder__c = ro.Id;

	}


	// CreateROLinesFromCommercialQuote
	// Called from CreateROFromCommercialQuote
	public static void CreateROLinesFromCommercialQuote(CommercialQuote__c cq, dealer__Service_Repair_Order__c ro) {
        
        // Create Job Lines based on the Added Equipment Items (Excluding those pre-installed on the vehicle)
        List<CommercialQuoteLine__c> cqlines = [
        	select Id, Description__c, Quantity__c
        	from CommercialQuoteLine__c 
        	where Commercial_Quote__c=:cq.Id and LockedOption__c=false 
        	limit 500
        ];  

        // Get Default Op Code
        dealer__StandardOpCode__c[] sop = [select Id, Name from dealer__StandardOpCode__c where Name = '99PROD' limit 1];

        // Get NUO Payment Methods 
        Map<String,ServicePaymentType__c> sptMap = new Map<String,ServicePaymentType__c>();
        for(ServicePaymentType__c spt : [select Id, Name from ServicePaymentType__c where Name in ('MCEO')]) {
        	sptMap.put(spt.Name, spt);
        }

        List<dealer__Service_Job__c> jobLines = new List<dealer__Service_Job__c>();
        Integer i = 1;
        for(CommercialQuoteLine__c cql : cqlines) {
            dealer__Service_Job__c newLine = new dealer__Service_Job__c();
            newLine.dealer__Service_Repair_Order__c = ro.Id;
            newLine.Name = ro.Name + '-' + i;
            newLine.dealer__Line_Number__c = i;
            newLine.dealer__Service_Type__c = 'MR';
            newLine.dealer__Labor_Type__c = 'I';
            newLine.dealer__CustomerConcern__c = (cql.Quantity__c<0 ? 'REMOVE ' : '') + cql.Description__c;

            if(sop.size()>0) {
                newLine.dealer__Standard_Operation_Code__c = sop[0].Id;
                newLine.dealer__Op_Code__c = sop[0].Name;
            }

			newLine.Payment_Method__c = sptMap.containsKey('MCEO') ? sptMap.get('MCEO').Id : null;

            jobLines.add(newLine);

            i++;
        }   

        if(jobLines.size()>0) {
            try {
                insert jobLines;
            } catch (DmlException e) { cq.addError('Unable to create the delivery repair order job lines ' + e);  }
        } 

 	}


	// BLL5a
	// Recalc GP and commissions 
	public static void RecalcGPandCommission(CommercialQuote__c cq) {
		Set<String> UseActualGP = new Set<String>{'Won - Delivered', 'Won - Posted', 'Delivered', 'Booked', 'Received'};
		
		if (cq.Chassis_QTY__c==null) cq.Chassis_QTY__c = 1;
		Decimal chassis_cost =  (cq.Chassis_Cost__c!=null && cq.Chassis_QTY__c!=null) ? (cq.Chassis_Cost__c * cq.Chassis_QTY__c) : 0.00;
		Decimal chassis_price = (cq.Chassis_Price__c!=null && cq.Chassis_QTY__c!=null) ? (cq.Chassis_Price__c * cq.Chassis_QTY__c) : 0.00;
		Decimal commercial_rebate = cq.Commercial_Rebate__c!=null ? cq.Commercial_Rebate__c : 0.00;
		Decimal options_cost = cq.Total_Options_Cost__c!=null ? cq.Total_Options_Cost__c : 0.00;
		Decimal conversion_cost = cq.StockVehConversionCost__c!=null ? cq.StockVehConversionCost__c : 0.00;
		Decimal options_price = cq.Total_Options_Price__c!=null ? cq.Total_Options_Price__c : 0.00;
		Decimal freight_cost =  cq.Freight_Cost__c!=null ? cq.Freight_Cost__c : 0.00;
		Decimal freight_price=  cq.Freight_Amount__c!=null ? cq.Freight_Amount__c : 0.00;
		Decimal comm_rate = cq.Commission_Rate__c!=null ? cq.Commission_Rate__c : 0.00;

		Decimal cost = chassis_cost + options_cost + freight_cost;
		Decimal costActual = chassis_cost + conversion_cost;	

		Decimal price = chassis_price + options_price + freight_price;
		Decimal gross = price - cost - commercial_rebate;
		Decimal grossActual = price - costActual - commercial_rebate; 
		//Decimal fm = freight_price - freight_cost;
		//Decimal chassis_gross = (chassis_price - chassis_cost);
		//Decimal chassis_grossActual = (chassis_price - chassis_cost);

		Decimal unit_gross = gross / cq.Chassis_QTY__c;
		Decimal unit_grossActual = grossActual / cq.Chassis_QTY__c;
        
		Decimal comm = 0;
		Decimal commActual = 0;	
		// determine if we are setting flat rate or not.
		if ( cq.Commission_Flat_Rate__c ) {
			comm = cq.Commission__c;
			commActual = cq.Commission__c;
		} else {
			comm = (gross * (comm_rate / 100));
			commActual = (grossActual * (comm_rate / 100));
		}
		comm = comm.setScale(2, System.RoundingMode.HALF_UP);
		commActual = CommActual.setScale(2, System.RoundingMode.HALF_UP);

		System.debug('ScreenFieldUpdate__c = ' + (cq.ScreenFieldUpdate__c ? 'true':'false'));
		System.debug('UnitGrossChanged__c = ' + (cq.UnitGrossChanged__c ? 'true':'false'));
		if (UseActualGP.contains(cq.Status__c)) {
			if (!cq.ScreenFieldUpdate__c) cq.UnitGrossChanged__c = cq.UnitGrossChanged__c || (cq.Unit_Gross_Profit__c!=unit_grossActual);
			cq.Commission__c = commActual;
			cq.Total_Gross_Profit__c = grossActual; 
            cq.Unit_Gross_Profit__c = unit_grossActual;       
			
		} else {
			if (!cq.ScreenFieldUpdate__c) cq.UnitGrossChanged__c = cq.UnitGrossChanged__c || (cq.Unit_Gross_Profit__c!=unit_gross);
			cq.Commission__c = comm;
			cq.Total_Gross_Profit__c = gross; 
            cq.Unit_Gross_Profit__c = unit_gross;       
		}
		System.debug('ScreenFieldUpdate__c = ' + (cq.ScreenFieldUpdate__c ? 'true':'false'));
		System.debug('UnitGrossChanged__c = ' + (cq.UnitGrossChanged__c ? 'true':'false'));
	}
	
	
	public static void RecalcGPandCommissionBulk(List<CommercialQuote__c> newList, Map<Id,CommercialQuote__c> oldMap) {
		Set<String> NoUpdateStatus = new Set<String>{'Won - Posted', 'Booked'};
		MW_TriggerControls__c protectPostedQuote = MW_TriggerControls__c.getInstance('ProtectPostedQuote');
		for(CommercialQuote__c cq : newList) {
			CommercialQuote__c oldcq = (oldMap!=null) ? oldMap.get(cq.Id) : null;
			if (oldcq!=null && (!NoUpdateStatus.contains(oldcq.Status__c) || (protectPostedQuote!=null && protectPostedQuote.Enabled__c==false))) CommercialQuoteProcess.RecalcGPandCommission(cq);
			// If viewing on-screen reset changed flag. This is done because changing a line on-screen
			// causes the unit gross changed flag to be set, but this line allows subsequent recalc & save commissions
			// to reset it so they don't see a notification next time the quote is viewed. 
			if (cq.ScreenFieldUpdate__c) cq.UnitGrossChanged__c = false;
			// Always reset this field.
			cq.ScreenFieldUpdate__c = false; 
		}
	}
	// BLL5a end 

}