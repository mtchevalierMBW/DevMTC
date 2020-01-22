/**
 * VehicleTransfer
 * Tested by: VehicleTransfer_TEST
 * Date: Dec 23, 2015
 * Programmer: Bryan Leaman
 * MW Trigger Controls: RestrictVehicleLocation, DealerTradeIntegrity, DealerTradeStatusChange
 * 
 * Code coverage:
 *	2017-10-04	83% (681/811)
 *	2018-03-19	84% (692/823)
 *	2018-05-21	82%	(643/781) (moved email code to workflow action, rmv LockInGPSharing routine that wasn't used)
 *	2018-08-21	82% (647/785)
 * 
 * Todo: ?Recall after shipment recorded - reverse prior journal?
 *	2016-09-16	B. Leaman	BLL1 - Fix how to handle if cost isn't in the GL - was creating out-of-balance journals the old way
 *							When only some cost was in the GL.
 *	2016-10-03	B. Leaman	BLL2 - Send inventory team notification upon initial approval rather than intransit. (per Steve M.)
 *	2016-10-04	B. Leaman	BLL3 - Don't require carrier at this time. Will need it when POs are generated automatically for the carrier.
 *	2016-10-14	B. Leaman	BLL4 - Fix action on In Transit instead of Approved; add execution monitor to trap why journals are missing.
 *	2016-10-26	B. Leaman	BLL5 - additional email alerts to potential problems.
 *	2016-11-18	B. Leaman	BLL6 #IR-0003241 - Save & reset vehicle status after transfer. In-transit will now be "In Transit - Transfer"
 *	2016-12-06	B. Leaman	BLL7 - Inventory message should go out at approval time, not in-transit time.
 *	2016-12-07	B. Leaman	BLL8 - Carrier required upon approval because of inventory email & setting up transportation.
 *	2016-12-09	B. Leaman	BLL9 - Additional logging.
 *	2016-12-21	B. Leaman	BLL10 - Don't assign RO numbers -- it's done via DealerTeam trigger now. 
 *	2016-12-28	B. Leaman	BLL11 - need to pull the RO number since it's not assigned until added to the DB.
 *	2017-01-03	B. Leaman	BLL12 - Remove unused field dealer__Deal__c.Location__c. (using dealer__Store_Location__c instead).
 *	2017-02-17	B. Leaman	BLL13 - Stop generating error emails when intercompany journals are empty. Just ignore.
 *	2017-03-07	B. Leaman	BLL14 - Let vehicle status remain as "Not For Sale" after creating GetReady RO. 
 *							Also, create commercial equipment RO instead of GetReady for Commercial vehicles. 
 *							Also, don't use vehicle cost if there's nothing in the G/L 
 * 	2017-03-30	B. Leaman	BLL15 - need RO number for job line creation.
 * 	2017-04-27	B. Leaman	BLL16 - add notes to inventory email.
 *	2017-05-24	B. Leaman	BLL17 - Ensure vehicle is in the "from location" when requested *and* when approved.
 *	2017-06-22	B. Leaman	BLL18 - Don't create RO for rentals.
 *  2017-08-31  A. Miller   AMM1  - W-000035 updating email notification with Stock# and "Transfer From " + Store
 *	2017-10-04	B. Leaman	BLL19 - Include dealer trade# in journal description.
 * 	2017-11-20	B. Leaman	BLL20 - Don't send error emails when journal is empty (no G/L to update).
 *	2018-02-05	B. Leaman	BLL21 - Don't create RO or affect vehicle status when "from" store is a conversion mfg;
 *							Send inventory email at first step (in transit) when outbound location is a manufacturer;
 *	2018-03-12	B. Leaman	BLL22 - Set received veh status to "SND" instead of "NFS" if it's got a won proposal on it.
 *							Also set vehicle status date when updating it.
 *	2018-04-02	B. Leaman	BLL23 - When vehicle is requested, calc GP sharing and save pending & won deals in the target store for this vehicle.
 *	// Handled in workflow: 2018-04-19	B. Leaman	BLL24 - Notification for MBW Truck transport method.
 *	2018-05-21	B. Leaman	BLL25 - Move email messages to workflow messages; didn't need "LockInGPSharing" routine after all;
 *							Don't allow submission without transport method (requesting location specifies this -per Anson)
 *	2018-07-18	B. Leaman	BLL26 - For vehicle transfer from mfg location, don't update vehicle status on receipt, just locations info.
 *	2018-08-21	B. Leaman	BLL27 - Change standard op-code used for created RO.
 *	2018-09-04	B. Leaman	BLL28 - messed up & it was updating vehicle's home location all the time instead of just when xfer from mfg. 
 *	2019-03-29	B. Leaman	W-000634 BLL29 - Use std op code CCCs when creating job lines (see bll27).
 *	2019-08-21	B. Leaman	W-000728 BLL30 improve SOQL count efficiency
 *	2019-09-10	B. Leaman	W-000751 BLL31 - simplify fixing issues. DealerTrade wasn't updated and inbound intercompany
 *							was not created. Resetting status re-created another outbound intercompany. Don't generate new
 *							journal if one is already on the dealer trade.
 */
public with sharing class VehicleTransfer {
    Organization org;
    String StandardOpCode = '30CONSUMERVEHICLETRANSFER';
    Set<String> newVeh = new Set<String>{'New', 'Fleet'};
    Set<String> newConv = new Set<String>{'New', 'New/Used'}; 
    
    public Set<Id> TradeIds {get;private set;}
    public List<dealer__Dealer_Trade__c> DealerTrades {get;private set;}
    public Map<Id,dealer__Vehicle_Inventory__c> TradedVehiclesMap {get;private set;}
    Map<Id,dealer__Dealer_Location__c> DealerLocationsMap;
    Map<Id,c2g__codaCompany__c> CompanyMap;
    Map<String,c2g__codaGeneralLedgerAccount__c> VehicleTradeGLAcctMap;
    Map<Id,c2g__codaAccountingCurrency__c> CurrencyMap;
    Map<Id,List<dealer__Deal__c>> openProposals;    // Id is vehicle Id
    Map<Id,List<CommercialQuote__c>> openQuotes;    // Id is vehicle Id
    MonitorExecution mon;	// BLL4a
    boolean errors;	// BLL4a
            
    // constructor
    //-------------------------------------
    public VehicleTransfer() {
        //org = [select Id, Name, isSandbox from Organization];
		org = OrganizationSingleton.getInstance();
        mon = new MonitorExecution('VehicleTransfer');	// BLL4a
        errors=false;	// BLL4a
    }
    
    public VehicleTransfer(Set<Id> tIds) {
    	this();
        //org = [select Id, Name, isSandbox from Organization];
        TradeIds = tIds;
        getDealerTrades();
        //mon = new MonitorExecution('VehicleTransfer');	// BLL4a
        //errors=false;	// BLL4a
    }

    public VehicleTransfer(List<dealer__Dealer_Trade__c> trades) {
    	this();
        //org = [select Id, Name, isSandbox from Organization];
        DealerTrades = trades!=null ? trades : new List<dealer__Dealer_Trade__c>();	// use the getDealerTrades method!
        TradeIds = new Set<Id>();
        for(dealer__Dealer_Trade__c dt : DealerTrades) TradeIds.add(dt.Id);
        getDealerTrades();
        //mon = new MonitorExecution('VehicleTransfer');	// BLL4a
        //errors=false;	// BLL4a
    }

    // ProcessOutboundTrades
    //-------------------------------------
    public void ProcessOutboundTrades() {
        for(Id i : tradeIds) {
            String payload = '{ "recordId":"' + i + '", "orgId": "' + org.Id + '", "requestedby":"' + UserInfo.getUserId() + '", "action":"outbound_trade"}';
			mon.log(payload);	// BLL4a
			try {	// BLL4a
            	FFAccounting.emailAsyncHandler(payload);
	        } catch(Exception e) {	// BLL4a
	        	mon.log('Error sending email: ' + e.getMessage());	// BLL4a
	        	errors=true;	// BLL4a
	        }	// BLL4a
        }
    }
    
    // ProcessInboundTrades
    //-------------------------------------
    public void ProcessInboundTrades() {
        for(Id i : tradeIds) {
            String payload = '{ "recordId":"' + i + '", "orgId": "' + org.Id + '", "requestedby":"' + UserInfo.getUserId() + '", "action":"inbound_trade"}';
			mon.log(payload);	// BLL4a
			try {	// BLL4a
            	FFAccounting.emailAsyncHandler(payload);
	        } catch(Exception e) {	// BLL4a
	        	mon.log('Error sending email: ' + e.getMessage());	// BLL4a
	        	errors=true;	// BLL4a
	        }	// BLL4a
        }
    }

    // ProcessOutboundIntercompany
    //-------------------------------------
    public void ProcessOutboundIntercompany() {
        for(Id i : tradeIds) {
            String payload = '{ "recordId":"' + i + '", "orgId": "' + org.Id + '", "requestedby":"' + UserInfo.getUserId() + '", "action":"outbound_intercomp_trade"}';
			mon.log(payload);	// BLL4a
			try {	// BLL4a
            	FFAccounting.emailAsyncHandler(payload);
	        } catch(Exception e) {	// BLL4a
	        	mon.log('Error sending email: ' + e.getMessage());	// BLL4a
	        	errors=true;	// BLL4a
	        }	// BLL4a
        }
    }
    
    // ProcessInboundIntercompnay
    //-------------------------------------
    public void ProcessInboundIntercompany() {
        for(Id i : tradeIds) {
            String payload = '{ "recordId":"' + i + '", "orgId": "' + org.Id + '", "requestedby":"' + UserInfo.getUserId() + '", "action":"inbound_intercomp_trade"}';
			mon.log(payload);	// BLL4a
			try {	// BLL4a
            	FFAccounting.emailAsyncHandler(payload);
	        } catch(Exception e) {	// BLL4a
	        	mon.log('Error sending email: ' + e.getMessage());	// BLL4a
	        	errors=true;	// BLL4a
	        }	// BLL4a
        }
    }

    // Change vehicles to new location and reset vehicle status
    //-------------------------------------
    public void UpdateVehicleLocations() {
        getDealerTrades();
        TradedVehiclesMap = null;	// BLL14a - force re-query vehicle inventory for latest status.
        getTradedVehiclesMap();
 		getDealerLocationsMap();	// BLL21a
        Map<Id,dealer__Vehicle_Inventory__c> updVeh = new Map<Id,dealer__Vehicle_Inventory__c>();
        for(dealer__Dealer_Trade__c t : DealerTrades) {
            System.debug(t);
            dealer__Dealer_Location__c frLoc = DealerLocationsMap.get(t.dealer__Outbound_Location__c);
            dealer__Dealer_Location__c toLoc = DealerLocationsMap.get(t.dealer__Store_Location__c);	// BLL26a
            dealer__Vehicle_Inventory__c veh = TradedVehiclesMap.get(t.dealer__Stock_No__c);
            System.debug(veh);
            if (veh!=null && veh.dealer__Store_Location__c!=t.dealer__Store_Location__c	) {
            	String newsts = veh.dealer__Status_Code__c=='Not For Sale' ? veh.dealer__Status_Code__c : veh.StatusPriorToTrade__c;	// BLL14a
				if (frloc!=null && frloc.ManufacturingLocation__c==true)	// BLL21a 
					newsts = veh.dealer__Status_Code__c;	// bll21a don't change status on xfer from manufacturer
					//newsts = veh.StatusPriorToTrade__c;	// BLL21a
				// BLL22a - mark SND instead of RFS if there is a won proposal for the veh.
				if (veh.dealer__R00N70000002II35EAG__r.size()>0 && newsts=='Not For Sale')
					newsts = 'Sold - Not Delivered';
				// BLL22a end
				dealer__Vehicle_Inventory__c uv = new dealer__Vehicle_Inventory__c(
                    Id=veh.Id, UpdateVehicleLocation__c=true, 
                    dealer__Store_Location__c = t.dealer__Store_Location__c,
                    //BLL28d only update home location on xfer from mfg 
                    //BLL28d HomeLocation__c = toloc.Id,	// BLL26a 
                    Physical_Location__c = toloc.Name,	// BLL26a
                    //BLL6d dealer__Status_Code__c = 'Not For Sale'     // veh.StatusPriorToTrade__c
                    //BLL14d dealer__Status_Code__c = veh.StatusPriorToTrade__c	// BLL6a
                    dealer__Status_Code__c = newsts);	// BLL14a
                if (newsts!=veh.dealer__Status_Code__c) uv.dealer__Status_Code_Assignment_Date__c = Date.today();	// BLL22a
                // BLL28a
                if (frloc!=null && frloc.ManufacturingLocation__c==true) uv.HomeLocation__c = toloc.Id;
                // BLL28a
                updVeh.put(veh.Id, uv);
                //System.debug(updVeh);
            }
        }
        if (updVeh.values().size()>0) {
            System.debug('Updating vehicles');
            try {	// BLL4a
            	update(updVeh.values());
	        } catch(Exception e) {	// BLL4a
	        	mon.log('Error updating vehicle status/location: ' + e.getMessage());	// BLL4a
	        	errors=true;	// BLL4a
	        }	// BLL4a
            System.debug('Updated vehicles');
        }
    }
 
    // getDealerTrades
    //-------------------------------------
    public List<dealer__Dealer_Trade__c> getDealerTrades() {
        //System.debug(DealerTrades);
        //System.debug(tradeIds);
        if (DealerTrades==null) DealerTrades = [
            select Id, Name, dealer__Outbound_Location__c, dealer__Store_Location__c, dealer__Stock_No__c,
				dealer__Trade_Completed__c, 
                dealer__Date__c, InboundGeneralManager__c, OutboundGeneralManager__c,
                OutboundSalesAdmin__c, InboundSalesAdmin__c, 
                dealer__Salesperson__c, dealer__Transfer_Status__c, Transport_Method__c, Carrier__c, Carrier__r.Name,  
                dealer__Dealer__c, dealer__Dealer_Address__c, dealer__Dealer_Phone__c,
                ChassisCost__c, ConversionCost__c, ContraValue__c, OutboundJournal__c, InboundJournal__c,
                OutboundInterCompanyJournal__c, InboundInterCompanyJournal__c
            from dealer__Dealer_Trade__c
            where Id in :tradeIds
        ];
        //System.debug(DealerTrades);
        return DealerTrades;
    }
    
    // getTradedVehiclesMap
    //-------------------------------------
    public Map<Id,dealer__Vehicle_Inventory__c> getTradedVehiclesMap() {
        getDealerTrades();
        Set<Id> vehIds = new Set<Id>();
        if (TradedVehiclesMap==null) {
            for(dealer__Dealer_Trade__c t : DealerTrades) {
                if (t.dealer__Stock_No__c!=null) vehIds.add(t.dealer__Stock_No__c);
            }
            TradedVehiclesMap = new Map<Id,dealer__Vehicle_Inventory__c>([
                select Id, Name, dealer__Stock_Number__c, dealer__Year__c, dealer__Make__c, dealer__Model__c,  
                    dealer__Vehicle_Cost__c, Conversion_Cost__c, dealer__Pack__c, New_Used_Other__c, 
                    dealer__Store_Location__c, dealer__Store_Location__r.Name, dealer__Store_Location__r.Financial_Force_Dimension_1__c, 
                    dealer__Status_Code__c, StatusPriorToTrade__c, Open_Service_Repair_Orders__c,
                    //BLL8a include list of open trades for this vehicle
                    (select Id, Name, dealer__Stock_No__c, dealer__Stock_No__r.Name, dealer__Transfer_Status__c,  
                    	dealer__Outbound_Location__c, dealer__Outbound_Location__r.Name,
                    	dealer__Store_Location__c, dealer__Store_Location__r.Name
                     from dealer__Dealer_Trades__r where dealer__Transfer_Status__c in ('Approved','In Transit')), 
                    (select Id, Name, dealer__Company_Number__c, dealer__Company__c 
                     from dealer__Service_Repair_Orders__r
                     where dealer__Status__c not in ('Posted', 'Void')),
                     (select Id, Name, dealer__Status__c	// BLL22a won proposals for veh 
                     from dealer__R00N70000002II35EAG__r
                     where dealer__Status__c!=null and dealer__Status__c like 'Won%')
                from dealer__Vehicle_Inventory__c
                where Id in :vehIds
            ]);
        }
        return TradedVehiclesMap;
    }
    
    // getOpenProposalsByVeh
    //-------------------------------------
    public Map<Id,List<dealer__Deal__c>> getOpenProposalsByVeh() {
        openProposals = new Map<Id,List<dealer__Deal__c>>();
        for(dealer__Deal__c d : [
                select Id, Name, dealer__Vehicle__c, dealer__Store_Location__c	// BLL12c rmv Location__c, 
                from dealer__Deal__c
                where dealer__Vehicle__c!=null 
                  and dealer__Vehicle__c in :tradedVehiclesMap.keySet() 
                  and dealer__Status__c not in ('Lost','Won - Posted')
                  and ( dealer__Status__c like 'Won%' 
                  	    or (dealer__Status__c='Pending' and Proposed_Delivery_Date__c!=null and Proposed_Delivery_Date__c>=TODAY)
                  	   )
            ]) {
            List<dealer__Deal__c> deals = openProposals.get(d.dealer__Vehicle__c);
            if (deals==null) deals = new List<dealer__Deal__c>();
            deals.add(d);
            openProposals.put(d.dealer__Vehicle__c, deals);
        }
        return openProposals;
    }

    // getVehProposalNamesForLocation
    //---------------------------------------
    public List<String> getVehProposalNamesForLocation(Id vehId, Id locId) {
        List<String> proposalnames = new List<String>();
        List<dealer__Deal__c> vehdeals = openProposals.get(vehId);
        if (vehdeals==null) vehdeals = new List<dealer__Deal__c>(); // In case it's null
        for(dealer__Deal__c d : vehdeals) { 
            if (d.dealer__Store_Location__c==locId) proposalnames.add(d.Name);
        }
        return proposalnames;
    }
    
    // getOpenQuotesByVeh
    //-------------------------------------
    public Map<Id,List<CommercialQuote__c>> getOpenQuotesByVeh() {
        openQuotes = new Map<Id,List<CommercialQuote__c>>();
        for(CommercialQuote__c q : [
                select Id, Name, VehicleInventory__c, Location__c
                from CommercialQuote__c
                where VehicleInventory__c!=null 
                  and VehicleInventory__c in :tradedVehiclesMap.keySet() 
                  and Status__c not in ('Lost','Won - Posted', 'Booked', 'Cloned', 'Ordered', 'Received')	// BLL adj list of statuses 2017-07-24
            ]) {
            List<CommercialQuote__c> quotes = openQuotes.get(q.VehicleInventory__c);
            if (quotes==null) quotes = new List<CommercialQuote__c>();
            quotes.add(q);
            openQuotes.put(q.VehicleInventory__c, quotes);
        }
        return openQuotes;
    }

    // getVehQuoteNamesForLocation
    //---------------------------------------
    public List<String> getVehQuoteNamesForLocation(Id vehId, Id locId) {
        List<String> quotenames = new List<String>();
        List<CommercialQuote__c> vehquotes = openQuotes.get(vehId);
        if (vehquotes==null) vehquotes = new List<CommercialQuote__c>();    // In case it's null
        for(CommercialQuote__c q : vehquotes) { 
            if (q.Location__c==locId) quotenames.add(q.Name);
        }
        return quotenames;
    }
    
    // getDealerLocationMap from list of trades
    //-------------------------------------
    public Map<Id,dealer__Dealer_Location__c> getDealerLocationsMap() {
        // BLL30
		//if (DealerLocationsMap==null) {
		// BLL30 end
            Set<Id> locIds = new Set<Id>();
            for(dealer__Dealer_Trade__c t : DealerTrades) {
                locIds.add(t.dealer__Outbound_Location__c);
                locIds.add(t.dealer__Store_Location__c);
            }
			// BLL30
            //DealerLocationsMap = new Map<Id,dealer__Dealer_Location__c>([
            //    select Id, Name, Company__c, dealer__Company_Number__c, Financial_Force_Dimension_1__c,
            //        dealer__Location_Account__c, dealer__Address__c, dealer__City__c, dealer__State__c, dealer__Postal_Code__c, dealer__Main_Phone__c,
            //        dealer__General_Manager__c, Sales_Admin__c, dealer__Service_Director__c,	// BLL4a
            //        ManufacturingLocation__c
            //    from dealer__Dealer_Location__c
            //    where Id in :locIds
            //]);
			// BLL30 end
		// BLL30
        //}
		LocationsSingleton ls = LocationsSingleton.getInstance();
		ls.addLocationIds(locIds);
		ls.retrieveLocations();
		DealerLocationsMap = ls.locationIdMap;
        return DealerLocationsMap;
		// BLL30 end
    }

    // getCompanyMap
    //-------------------------------------
    public Map<Id,c2g__codaCompany__c> getCompanyMap() {
        if (CompanyMap==null) CompanyMap = new Map<Id,c2g__codaCompany__c>([
            select Id, Name, DefaultPayableDimension1__c
            from c2g__codaCompany__c
        ]);
        return CompanyMap;
    }

    // getGeneralLedgerAccountMap for required gl accounts
    //-------------------------------------
    public Map<String,c2g__codaGeneralLedgerAccount__c> getVehicleTradeGLAcctMap() {
        Set<String> glaccts = new Set<String>{'1240', '1242', '1244', '1245', '1265', '2903'};
        if (VehicleTradeGLAcctMap==null) {
            VehicleTradeGLAcctMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
            for(c2g__codaGeneralLedgerAccount__c gla : [
                select Id, Name, c2g__ReportingCode__c
                from c2g__codaGeneralLedgerAccount__c
                where VehicleRequired__c=true or c2g__ReportingCode__c in :glaccts
                ]) {
                VehicleTradeGLAcctMap.put(gla.c2g__ReportingCode__c, gla);
            }
        }
        return VehicleTradeGLAcctMap;
    }

    // getCurrencyMap from list of locations
    //-------------------------------------
    public Map<Id,c2g__codaAccountingCurrency__c> getCurrencyMap() {
        if (CurrencyMap==null) {
            getDealerLocationsMap();
            CurrencyMap = new Map<Id,c2g__codaAccountingCurrency__c>();
            Set<Id> cmpIds = new Set<Id>();
            for(dealer__Dealer_Location__c l : DealerLocationsMap.values()) {
                cmpIds.add(l.Company__c);
            } 
            for (c2g__codaAccountingCurrency__c c : [
                select Id, c2g__OwnerCompany__c
                from c2g__codaAccountingCurrency__c 
                where Name='USD' and c2g__OwnerCompany__c in :cmpIds
            ]) {
                CurrencyMap.put(c.c2g__OwnerCompany__c, c);
            }
        }
        return CurrencyMap;
    }

    // createOutbounddTradeJournals from set of trade ids
    // Note: Normal process (approvals) submit one at a time. If a set is submitted for processing
    // all the trades must be for the same outbound company (not necessarily store)  
    //-------------------------------------
    public void createOutboundTradeJournals() {
        //MonitorExecution mon = new MonitorExecution('VehicleTransfer');
        //boolean errors = false;
        //List<dealer__Dealer_Trade__c> trades = getDealerTrades(tradeIds);
        getDealerTrades();
        getTradedVehiclesMap();
        getDealerLocationsMap();
        getVehicleTradeGLAcctMap();
        getCurrencyMap();

        Set<String> stocknbrs = new Set<String>();
        for (dealer__Vehicle_Inventory__c v : TradedVehiclesMap.values()) {
            if (v.dealer__Stock_Number__c!=null) stocknbrs.add(v.dealer__Stock_Number__c);
        }
        Map<String,List<c2g__codaTransactionLineItem__c>> vlines = getVehicleTransactions(stocknbrs);

        for(dealer__Dealer_Trade__c t : DealerTrades) {
	    	mon.log('createOutboundTradeJournals' + t.Name);
            System.debug(t);
            dealer__Vehicle_Inventory__c veh = TradedVehiclesMap.get(t.dealer__Stock_No__c);
            if (veh.dealer__Vehicle_Cost__c==null) veh.dealer__Vehicle_Cost__c = 0.00;
            if (veh.Conversion_Cost__c==null) veh.Conversion_Cost__c = 0.00;
            dealer__Dealer_Location__c frLoc = DealerLocationsMap.get(t.dealer__Outbound_Location__c);
            dealer__Dealer_Location__c toLoc = DealerLocationsMap.get(t.dealer__Store_Location__c);

            // Get current inventory summary by gl acct & dimension1
            Map<String,Decimal> vcamts = summarizeByVehicleComponentType(vlines.get(veh.dealer__Stock_Number__c));
            t.ChassisCost__c = vcamts.containsKey('Chassis') ? vcamts.get('Chassis') : 0;
            t.ConversionCost__c = vcamts.containsKey('Conversion') ? vcamts.get('Conversion') : 0;
            t.ContraValue__c = vcamts.containsKey('Contra') ? vcamts.get('Contra') : 0;

            boolean useGL = true;
            Map<Id,Decimal> glamts = summarizeByGLAccount(vlines.get(veh.dealer__Stock_Number__c));
            if (glamts.size()==0) useGL = false;
            if (t.ChassisCost__c==0 && t.ConversionCost__c==0) useGL = false;

            //BLL1d if (t.ChassisCost__c==null || t.ChassisCost__c==0) t.ChassisCost__c = veh.dealer__Vehicle_Cost__c;
            //BLL1d if (t.ConversionCost__c==null || t.ConversionCost__c==0) t.ConversionCost__c = veh.Conversion_Cost__c;
            //BLL1d if (t.ContraValue__c==null) t.ContraValue__c = 0.00;
            // BLL1a
            //BLL14d if (!useGL) {	// If not using GL, use the vehicle costs
            //BLL14d 	t.ChassisCost__c = veh.dealer__Vehicle_Cost__c;
            //BLL14d 	t.ConversionCost__c = veh.Conversion_Cost__c;
            //BLL14d 	t.ContraValue__c = 0.00;
            //BLL14d }
			if (t.ChassisCost__c==null) t.ChassisCost__c = 0;
			if (t.ConversionCost__c==null) t.ConversionCost__c = 0;
			if (t.ContraValue__c==null) t.ContraValue__c = 0;
			// BLL1a
            
            c2g__codaJournal__c outjournal = new c2g__codaJournal__c();
            outJournal.c2g__JournalStatus__c = 'In Progress';
            outJournal.c2g__Type__c = 'Manual Journal';
            outJournal.c2g__OwnerCompany__c = frLoc.Company__c;
            outJournal.c2g__JournalDate__c = Date.today();
            outJournal.c2g__Reference__c = veh.dealer__Stock_Number__c;
            outJournal.c2g__JournalDescription__c = t.Name + ': Move ' + veh.dealer__Stock_Number__c + ' from ' + frLoc.Name;	// BLL19c
            outJournal.Source__c = 'VEH'; // ???
            outJournal.Stock_Number__c = veh.dealer__Stock_Number__c;
            c2g__codaAccountingCurrency__c curr = CurrencyMap.get(frLoc.Company__c);
            if (curr!=null) outJournal.c2g__JournalCurrency__c = curr.Id;

            List<c2g__codaJournalLineItem__c> outlines = new List<c2g__codaJournalLineItem__c>();
            c2g__codaJournalLineItem__c jline;

            // If no existing GL entries, use defaults
            //if (glamts.size()==0) {
            if (!useGL) {
                glamts.clear();
                //BLL14d Id glid = newVeh.contains(veh.New_Used_Other__c) ? VehicleTradeGLAcctMap.get('1242').Id : VehicleTradeGLAcctMap.get('1244').Id;
                //BLL14d glamts.put(glid, t.ChassisCost__c);
                //BLL14d glid = newConv.contains(veh.New_Used_Other__c) ? VehicleTradeGLAcctMap.get('1240').Id : VehicleTradeGLAcctMap.get('1245').Id;
                //BLL14d glamts.put(glid, t.ConversionCost__c);
            }

			System.debug('[[[ Outbound Journal Lines]]]');
            // Use existing GL if it exists
            for(Id i : glamts.keySet()) {
                jline = new c2g__codaJournalLineItem__c(
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = i,
                    c2g__Dimension1__c = frLoc.Financial_Force_Dimension_1__c,
                    c2g__Value__c = - (Decimal) glamts.get(i),
                    Control__c = veh.dealer__Stock_Number__c,
                    Stock_Number__c = veh.dealer__Stock_Number__c,
                    Vehicle_Inventory__c = veh.Id
                );
				System.debug(jline);
                if (jline.c2g__Value__c!=0) outlines.add(jline);
            }
            
            jline = new c2g__codaJournalLineItem__c(
                c2g__LineType__c = 'General Ledger Account',
                c2g__GeneralLedgerAccount__c = VehicleTradeGLAcctMap.get('1265').Id,
                c2g__Dimension1__c = frLoc.Financial_Force_Dimension_1__c,
                c2g__Value__c = t.ChassisCost__c + t.ConversionCost__c + t.ContraValue__c,
                Control__c = veh.dealer__Stock_Number__c,
                Stock_Number__c = veh.dealer__Stock_Number__c,
                Vehicle_Inventory__c = veh.Id
            );
			System.debug(jline);
            if (jline.c2g__Value__c!=0) outlines.add(jline);
            
			System.debug(outlines);
            // BLL5a
            if (outlines.size()==0) {
            	mon.log('No lines in outbound journal for ' + t.Name);
            	//BLL20d errors = true;
            } else {	// BLL13c
            // BLL5a end
            
            	Id outJournalId = FinancialForce_MBW.createJournalApi(outJournal, outLines);
            	System.debug(outJournalId);
            
            	// Moved up from below the post option
            	t.OutboundJournal__c = outJournalId;
	        	try {
		    	    update(DealerTrades);
	        	} catch(Exception e) {	// BLL4a
	        		mon.log('Error updating trades: ' + e.getMessage());	// BLL4a
	        		errors=true;	// BLL4a
	        	}	// BLL4a
	        	// end moved up section
        
            	try {
            	    FFAccounting.postJournal(outJournalId);
            	    //t.OutboundJournal__c = outJournalId;
            	} catch(Exception e) {
            	    mon.log('Could not post journal: ' + e.getMessage());
            	    mon.log(JSON.serialize(outJournal));
            	    for(c2g__codaJournalLineItem__c l : outlines) mon.log(JSON.serialize(l));
            	    errors = true;
            	}
            }	// BLL13a
        }
        //try {
	    //    update(DealerTrades);
        //} catch(Exception e) {	// BLL4a
        // 	mon.log('Error updating trades: ' + e.getMessage());	// BLL4a
        //	errors=true;	// BLL4a
        //}	// BLL4a
        
        if (errors || mon.AlwaysNotify) mon.NotifyAdmin();
    }

    // createInboundTradeJournals from set of trade ids
    // Note: Normal process (approvals) submit one at a time. If a set is submitted for processing
    // all the trades must be for the same inbound company (not necessarily store)  
    //-------------------------------------
    public void createInboundTradeJournals() {
        //MonitorExecution mon = new MonitorExecution('VehicleTransfer');
        //boolean errors = false;
        List<dealer__Dealer_Trade__c> updTrades = new List<dealer__Dealer_Trade__c>();
        //List<dealer__Dealer_Trade__c> trades = getDealerTrades(tradeIds);
        getDealerTrades();
        getTradedVehiclesMap();
        getDealerLocationsMap();
        getVehicleTradeGLAcctMap();
        getCurrencyMap();

        Map<String,List<c2g__codaJournalLineItem__c>> jlines = getOutboundJournalLines();

        for(dealer__Dealer_Trade__c t : DealerTrades) {
	    	mon.log('createInboundTradeJournals' + t.Name);
            System.debug(t);
            dealer__Vehicle_Inventory__c veh = TradedVehiclesMap.get(t.dealer__Stock_No__c);
            if (veh.dealer__Vehicle_Cost__c==null) veh.dealer__Vehicle_Cost__c = 0.00;
            if (veh.Conversion_Cost__c==null) veh.Conversion_Cost__c = 0.00;
            dealer__Dealer_Location__c frLoc = DealerLocationsMap.get(t.dealer__Outbound_Location__c);
            dealer__Dealer_Location__c toLoc = DealerLocationsMap.get(t.dealer__Store_Location__c);
            if (t.ChassisCost__c==null) t.ChassisCost__c = 0;	// BLL13a
            if (t.ConversionCost__c==null) t.ConversionCost__c = 0;	// BLL13a
            if (t.ContraValue__c==null) t.ContraValue__c = 0;	// BLL13a

            c2g__codaJournal__c inJournal = new c2g__codaJournal__c();
            inJournal.c2g__JournalStatus__c = 'In Progress';
            inJournal.c2g__Type__c = 'Manual Journal';
            inJournal.c2g__OwnerCompany__c = toLoc.Company__c;
            inJournal.c2g__JournalDate__c = Date.today();
            inJournal.c2g__Reference__c = veh.dealer__Stock_Number__c;
            inJournal.c2g__JournalDescription__c = t.Name + ': Move ' + veh.dealer__Stock_Number__c + ' to ' + toLoc.Name;	// BLL19c
            inJournal.Source__c = 'VEH'; // ???
            inJournal.Stock_Number__c = veh.dealer__Stock_Number__c;
            c2g__codaAccountingCurrency__c curr = CurrencyMap.get(toLoc.Company__c);
            if (curr!=null) inJournal.c2g__JournalCurrency__c = curr.Id;

            List<c2g__codaJournalLineItem__c> inlines = new List<c2g__codaJournalLineItem__c>();
            List<c2g__codaJournalLineItem__c> outlines = jlines.get(t.OutboundJournal__c);
            if (outlines==null) {
                outlines = new List<c2g__codaJournalLineItem__c>();
                outlines.add(new c2g__codaJournalLineItem__c(
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = newVeh.contains(veh.New_Used_Other__c) ? VehicleTradeGLAcctMap.get('1242').Id : VehicleTradeGLAcctMap.get('1244').Id,
                    c2g__Dimension1__c = toLoc.Financial_Force_Dimension_1__c,
                    c2g__Value__c = t.ChassisCost__c!=null ? t.ChassisCost__c : 0,   //veh.dealer__Vehicle_Cost__c,	// BLL13c if not null
                    Control__c = veh.dealer__Stock_Number__c,
                    Stock_Number__c = veh.dealer__Stock_Number__c,
                    Vehicle_Inventory__c = veh.Id
                ));
                outlines.add(new c2g__codaJournalLineItem__c(
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = newConv.contains(veh.New_Used_Other__c) ? VehicleTradeGLAcctMap.get('1240').Id : VehicleTradeGLAcctMap.get('1245').Id,
                    c2g__Dimension1__c = toLoc.Financial_Force_Dimension_1__c,
                    c2g__Value__c = t.ConversionCost__c!=null ? t.ConversionCost__c : 0,    //veh.Conversion_Cost__c,	// BLL13 if not null
                    Control__c = veh.dealer__Stock_Number__c,
                    Stock_Number__c = veh.dealer__Stock_Number__c,
                    Vehicle_Inventory__c = veh.Id
                ));
            }
            
            // Duplicate outbound GL account structure on inbound journal           
            c2g__codaJournalLineItem__c jline;
            for(c2g__codaJournalLineItem__c jl : outlines) {
                jline = new c2g__codaJournalLineItem__c(
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = jl.c2g__GeneralLedgerAccount__c,
                    c2g__Dimension1__c = toLoc.Financial_Force_Dimension_1__c,
                    c2g__Value__c = -jl.c2g__Value__c,  //veh.dealer__Vehicle_Cost__c,
                    Control__c = veh.dealer__Stock_Number__c,
                    Stock_Number__c = veh.dealer__Stock_Number__c,
                    Vehicle_Inventory__c = veh.Id
                );
                if (jline.c2g__Value__c!=0) inlines.add(jline);
            }

            jline = new c2g__codaJournalLineItem__c(
                c2g__LineType__c = 'General Ledger Account',
                c2g__GeneralLedgerAccount__c = VehicleTradeGLAcctMap.get('1265').Id,
                c2g__Dimension1__c = frLoc.Financial_Force_Dimension_1__c,
                c2g__Value__c = -t.ChassisCost__c - t.ConversionCost__c - t.ContraValue__c, //-veh.dealer__Vehicle_Cost__c - veh.Conversion_Cost__c,
                Control__c = veh.dealer__Stock_Number__c,
                Stock_Number__c = veh.dealer__Stock_Number__c,
                Vehicle_Inventory__c = veh.Id
            );
            if (jline.c2g__Value__c!=0) inlines.add(jline);

            // BLL5a
            if (inlines.size()==0) {
            	mon.log('No lines in inbound journal for ' + t.Name);
            	//BLL20d errors = true;
            } 
            // BLL5a end
           	Id inJournalId = null;	// BLL13c
           	if(inLines.size()>0) inJournalId = FinancialForce_MBW.createJournalApi(inJournal, inLines);	// BLL13c
           	System.debug(inJournalId);
           	try {
           	    if (inJournalId!=null) FFAccounting.postJournal(inJournalId);	// BLL13c
           	    updTrades.add(new dealer__Dealer_Trade__c(Id=t.Id, dealer__Transfer_Status__c='Complete', dealer__Trade_Completed__c=true,
           	        InboundJournal__c=inJournalId));
           	} catch(Exception e) {
           	    mon.log('Could not post journal: ' + e.getMessage());
           	    mon.log(JSON.serialize(inJournal));
           	    for(c2g__codaJournalLineItem__c l : inlines) mon.log(JSON.serialize(l));
           	    errors = true;
           	}
        }
		try { // BLL4a
	        if (updTrades.size()>0) Database.update(updTrades);
        } catch(Exception e) {	// BLL4a
        	mon.log('Error updating trades: ' + e.getMessage());	// BLL4a
        	errors=true;	// BLL4a
        }	// BLL4a
        if (errors || mon.AlwaysNotify) mon.NotifyAdmin();
    }
    
    
    // Intercompany journals

    // createOutbounddIntercompanyJournals from set of trade ids
    // Note: Normal process (approvals) submit one at a time. If a set is submitted for processing
    // all the trades must be for the same outbound company (not necessarily store)  
    //-------------------------------------
    public void createOutboundIntercompanyJournals() {

        List<dealer__Dealer_Trade__c> updTrades = new List<dealer__Dealer_Trade__c>();
        //MonitorExecution mon = new MonitorExecution('VehicleTransfer');
        //boolean errors = false;
        //List<dealer__Dealer_Trade__c> trades = getDealerTrades(tradeIds);
        getDealerTrades();
        getTradedVehiclesMap();
        getDealerLocationsMap();
        getCompanyMap();
        getVehicleTradeGLAcctMap();
        getCurrencyMap();

        for(dealer__Dealer_Trade__c t : DealerTrades) {
	    	mon.log('createOutboundIntercompanyJournals' + t.Name);
            System.debug(t);
            dealer__Vehicle_Inventory__c veh = TradedVehiclesMap.get(t.dealer__Stock_No__c);
            if (veh.dealer__Vehicle_Cost__c==null) veh.dealer__Vehicle_Cost__c = 0.00;
            if (veh.Conversion_Cost__c==null) veh.Conversion_Cost__c = 0.00;
            dealer__Dealer_Location__c frLoc = DealerLocationsMap.get(t.dealer__Outbound_Location__c);
            dealer__Dealer_Location__c toLoc = DealerLocationsMap.get(t.dealer__Store_Location__c);
            c2g__codaCompany__c frCmp = frLoc!=null ? CompanyMap.get(frLoc.Company__c) : null;
            c2g__codaCompany__c toCmp = toLoc!=null ? CompanyMap.get(toLoc.Company__c) : null;

            c2g__codaJournal__c outjournal = new c2g__codaJournal__c();
            outJournal.c2g__JournalStatus__c = 'In Progress';
            outJournal.c2g__Type__c = 'Manual Journal';
            outJournal.c2g__OwnerCompany__c = frLoc.Company__c;
            outJournal.c2g__JournalDate__c = Date.today();
            outJournal.c2g__Reference__c = veh.dealer__Stock_Number__c;
            outJournal.c2g__JournalDescription__c = t.Name + ': Move ' + veh.dealer__Stock_Number__c + ' from ' + frLoc.Name;	// BLL19c
            outJournal.Source__c = 'VEH'; // ???
            outJournal.Stock_Number__c = veh.dealer__Stock_Number__c;
            c2g__codaAccountingCurrency__c curr = CurrencyMap.get(frLoc.Company__c);
            if (curr!=null) outJournal.c2g__JournalCurrency__c = curr.Id;

            if (t.ChassisCost__c==null) t.ChassisCost__c = 0.00;
            if (t.ConversionCost__c==null) t.ConversionCost__c = 0.00;
            if (t.ContraValue__c==null) t.ContraValue__c = 0.00;
			mon.log('Chassis cost=' + String.valueOf(t.ChassisCost__c));		// BLL9a
			mon.log('Conversion cost=' + String.valueOf(t.ConversionCost__c));	// BLL9a
			mon.log('Contra value=' + String.valueOf(t.ContraValue__c));		// BLL9a

            List<c2g__codaJournalLineItem__c> outlines = new List<c2g__codaJournalLineItem__c>();
            c2g__codaJournalLineItem__c jline;
            jline = new c2g__codaJournalLineItem__c(
                c2g__LineType__c = 'General Ledger Account',
                c2g__GeneralLedgerAccount__c = VehicleTradeGLAcctMap.get('1265').Id,
                c2g__Dimension1__c = frLoc.Financial_Force_Dimension_1__c,
                c2g__Value__c = -t.ChassisCost__c - t.ConversionCost__c - t.ContraValue__c, //-veh.dealer__Vehicle_Cost__c-veh.Conversion_Cost__c,
                Control__c = veh.dealer__Stock_Number__c,
                Stock_Number__c = veh.dealer__Stock_Number__c,
                Vehicle_Inventory__c = veh.Id
            );
            if (jline.c2g__Value__c!=0) outlines.add(jline);
            jline = new c2g__codaJournalLineItem__c(
                c2g__LineType__c = 'General Ledger Account',
                c2g__GeneralLedgerAccount__c = VehicleTradeGLAcctMap.get('2903').Id,
                c2g__Dimension1__c = frCmp.DefaultPayableDimension1__c,
                c2g__Value__c = t.ChassisCost__c + t.ConversionCost__c + t.ContraValue__c,  //veh.dealer__Vehicle_Cost__c+veh.Conversion_Cost__c,
                Control__c = veh.dealer__Stock_Number__c,
                Stock_Number__c = veh.dealer__Stock_Number__c,
                Vehicle_Inventory__c = veh.Id
            );
            if (jline.c2g__Value__c!=0) outlines.add(jline);
            
            // BLL5a
            if (outlines.size()==0) {
            	mon.log('No lines in outbound intercompany journal for ' + t.Name);
            	// BLL13d errors = true;
            }
            // BLL5a end
            if (outLines.size()>0) {
                Id outJournalId = FinancialForce_MBW.createJournalApi(outJournal, outLines);
                System.debug(outJournalId);
                try {
                    FFAccounting.postJournal(outJournalId);
                    updTrades.add(new dealer__Dealer_Trade__c(Id=t.Id, OutboundIntercompanyJournal__c=outJournalId));
                } catch(Exception e) {
                    mon.log('Could not post journal: ' + e.getMessage());
                    mon.log(JSON.serialize(outJournal));
                    for(c2g__codaJournalLineItem__c l : outlines) mon.log(JSON.serialize(l));
                    errors = true;
                }
            }
        }
		try { 	// BLL4a
	        if (updTrades.size()>0) update(updTrades);
        } catch(Exception e) {	// BLL4a
        	mon.log('Error updating trades: ' + e.getMessage());	// BLL4a
        	errors=true;	// BLL4a
        }	// BLL4a
        if (errors || mon.AlwaysNotify) mon.NotifyAdmin();

    }

    // createInboundIntercompanyJournals from set of trade ids
    // Note: Normal process (approvals) submit one at a time. If a set is submitted for processing
    // all the trades must be for the same inbound company (not necessarily store)  
    //-------------------------------------
    public void createInboundIntercompanyJournals() {

        List<dealer__Dealer_Trade__c> updTrades = new List<dealer__Dealer_Trade__c>();
        //MonitorExecution mon = new MonitorExecution('VehicleTransfer');
        //boolean errors = false;
        //List<dealer__Dealer_Trade__c> trades = getDealerTrades(tradeIds);
        getDealerTrades();
        getTradedVehiclesMap();
        getDealerLocationsMap();
        getCompanyMap();
        getVehicleTradeGLAcctMap();
        getCurrencyMap();

        Map<String,List<c2g__codaJournalLineItem__c>> jlines = getOutboundJournalLines();

        for(dealer__Dealer_Trade__c t : DealerTrades) {
	    	mon.log('createInboundIntercompanyJournals' + t.Name);
            System.debug(t);
            dealer__Vehicle_Inventory__c veh = TradedVehiclesMap.get(t.dealer__Stock_No__c);
            if (veh.dealer__Vehicle_Cost__c==null) veh.dealer__Vehicle_Cost__c = 0.00;
            if (veh.Conversion_Cost__c==null) veh.Conversion_Cost__c = 0.00;
            dealer__Dealer_Location__c frLoc = DealerLocationsMap.get(t.dealer__Outbound_Location__c);
            dealer__Dealer_Location__c toLoc = DealerLocationsMap.get(t.dealer__Store_Location__c);
            c2g__codaCompany__c frCmp = frLoc!=null ? CompanyMap.get(frLoc.Company__c) : null;
            c2g__codaCompany__c toCmp = toLoc!=null ? CompanyMap.get(toLoc.Company__c) : null;

            if (t.ChassisCost__c==null) t.ChassisCost__c = 0;	// BLL13a
            if (t.ConversionCost__c==null) t.ConversionCost__c = 0;	// BLL13a
            if (t.ContraValue__c==null) t.ContraValue__c = 0;	// BLL13a

            c2g__codaJournal__c inJournal = new c2g__codaJournal__c();
            inJournal.c2g__JournalStatus__c = 'In Progress';
            inJournal.c2g__Type__c = 'Manual Journal';
            inJournal.c2g__OwnerCompany__c = toLoc.Company__c;
            inJournal.c2g__JournalDate__c = Date.today();
            inJournal.c2g__Reference__c = veh.dealer__Stock_Number__c;
            inJournal.c2g__JournalDescription__c = t.Name + ': Move ' + veh.dealer__Stock_Number__c + ' to ' + toLoc.Name;	// BLL19c
            inJournal.Source__c = 'VEH'; // ???
            inJournal.Stock_Number__c = veh.dealer__Stock_Number__c;
            c2g__codaAccountingCurrency__c curr = CurrencyMap.get(toLoc.Company__c);
            if (curr!=null) inJournal.c2g__JournalCurrency__c = curr.Id;

            List<c2g__codaJournalLineItem__c> inlines = new List<c2g__codaJournalLineItem__c>();
            List<c2g__codaJournalLineItem__c> outlines = jlines.get(t.OutboundJournal__c);
            System.debug(outlines);
            mon.log('Outbound journal lines: \n' + JSON.serializePretty(outlines));		// BLL9a
            if (outlines==null) {
                outlines = new List<c2g__codaJournalLineItem__c>();
                outlines.add(new c2g__codaJournalLineItem__c(
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = newVeh.contains(veh.New_Used_Other__c) ? VehicleTradeGLAcctMap.get('1242').Id : VehicleTradeGLAcctMap.get('1244').Id,
                    c2g__Dimension1__c = toLoc.Financial_Force_Dimension_1__c,
                    c2g__Value__c = t.ChassisCost__c,   //veh.dealer__Vehicle_Cost__c,
                    Control__c = veh.dealer__Stock_Number__c,
                    Stock_Number__c = veh.dealer__Stock_Number__c,
                    Vehicle_Inventory__c = veh.Id
                ));
                outlines.add(new c2g__codaJournalLineItem__c(
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = newConv.contains(veh.New_Used_Other__c) ? VehicleTradeGLAcctMap.get('1240').Id : VehicleTradeGLAcctMap.get('1245').Id,
                    c2g__Dimension1__c = toLoc.Financial_Force_Dimension_1__c,
                    c2g__Value__c = t.ConversionCost__c,    //veh.Conversion_Cost__c,
                    Control__c = veh.dealer__Stock_Number__c,
                    Stock_Number__c = veh.dealer__Stock_Number__c,
                    Vehicle_Inventory__c = veh.Id
                ));
            }
            
            // Duplicate outbound GL account structure on inbound journal           
            c2g__codaJournalLineItem__c jline;
            for(c2g__codaJournalLineItem__c jl : outlines) {
                jline = new c2g__codaJournalLineItem__c(
                    c2g__LineType__c = 'General Ledger Account',
                    c2g__GeneralLedgerAccount__c = jl.c2g__GeneralLedgerAccount__c,
                    c2g__Dimension1__c = toLoc.Financial_Force_Dimension_1__c,
                    c2g__Value__c = -jl.c2g__Value__c,  //veh.dealer__Vehicle_Cost__c,
                    Control__c = veh.dealer__Stock_Number__c,
                    Stock_Number__c = veh.dealer__Stock_Number__c,
                    Vehicle_Inventory__c = veh.Id
                );
                if (jline.c2g__Value__c!=0) inlines.add(jline);
            }
            
            if (t.ChassisCost__c==null) t.ChassisCost__c = 0.00;
            if (t.ConversionCost__c==null) t.ConversionCost__c = 0.00;
            if (t.ContraValue__c==null) t.ContraValue__c = 0.00;
            
            jline = new c2g__codaJournalLineItem__c(
                c2g__LineType__c = 'General Ledger Account',
                c2g__GeneralLedgerAccount__c = VehicleTradeGLAcctMap.get('2903').Id,
                c2g__Dimension1__c = toCmp.DefaultPayableDimension1__c,
                c2g__Value__c = -t.ChassisCost__c-t.ConversionCost__c-t.ContraValue__c, //-veh.dealer__Vehicle_Cost__c-veh.Conversion_Cost__c,
                Control__c = veh.dealer__Stock_Number__c,
                Stock_Number__c = veh.dealer__Stock_Number__c,
                Vehicle_Inventory__c = veh.Id
            );
            if (jline.c2g__Value__c!=0) inlines.add(jline);

            // BLL5a
            if (outlines.size()==0) {
            	mon.log('No lines in inbound intercompany journal for ' + t.Name);
            	// BLL13d errors = true;
            }
            // BLL5a end
			Id inJournalId = null;	// BLL13c
			if (inLines.size()>0) inJournalId = FinancialForce_MBW.createJournalApi(inJournal, inLines);	// BLL13c
			System.debug(inJournalId);
			try {
				if (inJournalId!=null) FFAccounting.postJournal(inJournalId);	// BLL13c
				updTrades.add(new dealer__Dealer_Trade__c(
					Id=t.Id, dealer__Transfer_Status__c='Complete', dealer__Trade_Completed__c=true,
					InboundIntercompanyJournal__c=inJournalId));
			} catch(Exception e) {
				mon.log('Could not post journal: ' + e.getMessage());
				mon.log(JSON.serialize(inJournal));
				for(c2g__codaJournalLineItem__c l : inlines) mon.log(JSON.serialize(l));
				errors = true;
			}
        }
		try {	// BLL4a
	        if (updTrades.size()>0) update(updTrades);
        } catch(Exception e) {	// BLL4a
        	mon.log('Error updating trades: ' + e.getMessage());	// BLL4a
        	errors=true;	// BLL4a
        }	// BLL4a
        if (errors || mon.AlwaysNotify) mon.NotifyAdmin();

    }
    
    // Intercompany - end    
    
    
    // Trigger-invoked methods
    
    // DealerTradeStatusChange
    // update vehicle, generate journals as dealer trade moves through approval process
    //-------------------------------------
    public void DealerTradeStatusChange(Map<Id,dealer__Dealer_Trade__c> oldMap) {
        //Organization org = [select Id, Name, isSandbox from Organization];
        Set<String> AllowMissingTransport = new Set<string>{'Not submitted', 'Declined', 'In Transit', 'Received', 'Complete'};
        
        Map<Id,List<dealer__Service_Repair_Order__c>> smRoMap = new Map<Id,List<dealer__Service_Repair_Order__c>>();	// BLL4a
		Set<Id> roIds = new Set<Id>();	// BLL11a
        
        // Vehicle statuses to update
        Map<Id,dealer__Vehicle_Inventory__c> updVeh = new Map<Id,dealer__Vehicle_Inventory__c>();
        
        // message to inventory team
        //BLL25d String inventoryMsg = '';
        //String mbwtruckMsg = '';	// BLL24a

        // Messages to sending GMs to remind them to overnight paperwork/title
        //BLL25d List<Messaging.SingleEmailMessage> GMemails=new List<Messaging.SingleEmailMessage>();
        
        // Affected locations
        getDealerLocationsMap();
        // All referenced vehicles
        getTradedVehiclesMap();
     
        // List of GMs (sending locations)
        //BLL25d List<Id> SendingGMIds = new List<Id>();
        //BLL25d for(dealer__Dealer_Trade__c dt : DealerTrades) {
        //BLL25d     if (dt.OutboundGeneralManager__c!=null) SendingGMIds.add(dt.OutboundGeneralManager__c);
        //BLL25d     if (dt.InboundGeneralManager__c!=null) SendingGMIds.add(dt.InboundGeneralManager__c);
        //BLL25d     if (dt.OutboundSalesAdmin__c!=null) SendingGMIds.add(dt.OutboundSalesAdmin__c);
        //BLL25d     if (dt.InboundSalesAdmin__c!=null) SendingGMIds.add(dt.InboundSalesAdmin__c);
        //BLL25d }
        //BLL25d Map<Id,User> GMUsers = new Map<Id,User>([select Id, Name, FirstName, LastName, Email from User where Id in :SendingGMIds]);
     
        // Build list of dealer trades, both outbound (status = In Transit) and inbound (status = Received)
        Set<Id> OutboundTrades = new Set<Id>();
        Set<Id> InboundTrades = new Set<Id>();
        // BLL31
		// Set<Id> IntercompanyTrades = new Set<Id>();
		Set<Id> IntercompanyTradesOut = new Set<Id>();
		Set<Id> IntercompanyTradesIn = new Set<Id>();
		// BLL31 end
        for(dealer__Dealer_Trade__c dt : DealerTrades) {
            dealer__Dealer_Trade__c oldDt = null;
            if (oldMap!=null) oldDt = oldMap.get(dt.Id);
            System.debug(oldDt);

            System.debug(dt.dealer__Transfer_Status__c);
            if (olddt!=null) System.debug(olddt.dealer__Transfer_Status__c);

            // Referenced locations
            dealer__Dealer_Location__c frloc = DealerLocationsMap.get(dt.dealer__Outbound_Location__c);
            dealer__Dealer_Location__c toloc = DealerLocationsMap.get(dt.dealer__Store_Location__c);
            String frlocname = frloc!=null ? frloc.Name : '<unknown>';
            String tolocname = toloc!=null ? toloc.Name : '<unknown>'; 
            if (frloc!=null) System.debug(frloc.ManufacturingLocation__c);

            dealer__Vehicle_Inventory__c veh = TradedVehiclesMap.get(dt.dealer__Stock_No__c);
            System.debug(veh);
            String vehname = (veh!=null && veh.Name!=null) ? veh.Name : '<missing>';
            String vehlocname = (veh!=null && veh.dealer__Store_Location__c!=null && veh.dealer__Store_Location__r.Name!=null) ? veh.dealer__Store_Location__r.Name : '<missing>';
    
            if (dt!=null) System.debug(dt.dealer__Transfer_Status__c);
            if (oldDt!=null) System.debug(oldDt.dealer__Transfer_Status__c);

            // Validations upon submit
            if (dt.dealer__Transfer_Status__c=='Requested' && oldDt!=null && oldDt.dealer__Transfer_Status__c!=dt.dealer__Transfer_Status__c) {
                //ReqVehIds.add(dt.dealer__Stock_No__c);
                List<String> missingFields = new List<String>();
                if (String.isBlank(dt.dealer__Stock_No__c)) missingFields.add('Vehicle');
                if (String.isBlank(dt.dealer__Outbound_Location__c)) missingFields.add('Outbound location');
                if (String.isBLank(dt.dealer__Store_Location__c)) missingFields.add('Requesting location');
                if (frloc!=null && frloc.Company__c==null) missingFields.add('Outbound location Company');
                if (toloc!=null && toloc.Company__c==null) missingFields.add('Requesting location Company');
                if (missingFields.size()>0) {
                    dt.addError('The following information is required before submitting the transfer: ' + String.join(missingFields,', '));
                }
                if (dt.dealer__Trade_Completed__c==true) {
                    dt.addError('Cannot submit a Dealer Trade that has already been completed');
                }
                
                // BLL17d move & test when requested *or* approved
                // Ensure vehicle's store matches from-store
                //dealer__Vehicle_Inventory__c vehicle = TradedVehiclesMap.get(dt.dealer__Stock_No__c);
                //System.debug(vehicle.dealer__Store_Location__c);
                //System.debug(dt.dealer__Outbound_Location__c);
                //if (vehicle!=null && vehicle.dealer__Store_Location__c!=dt.dealer__Outbound_Location__c) {
				//	dt.addError('Vehicle ' + vehname + ' is in ' + vehlocname + ', NOT in ' + frloc.Name);
                //    //dt.addError('Cannot submit a Dealer Trade: vehicle is not in location ' + frloc.Name);
                //}
                // BLL17d end

                // Ensure there are no open proposals or quotes at the vehicle's current location
                getOpenProposalsByVeh();
                List<String> proposalNames = getVehProposalNamesForLocation(dt.dealer__Stock_No__c, frloc.Id);
                if (proposalNames.size()>0) dt.addError('Open proposals exist at the vehicle location: ' + String.join(proposalNames,',')); 
                getOpenQuotesByVeh();
                List<String> quoteNames = getVehQuoteNamesForLocation(dt.dealer__Stock_No__c, frloc.Id); 
                if (quoteNames.size()>0) dt.addError('Open quotes exist at the vehicle location: ' + String.join(quoteNames,',')); 

				// BLL17d duplicate error check
                // Vehicle must be in location requested from
				//if (veh!=null && dt.dealer__Outbound_Location__c!=veh.dealer__Store_Location__c) {
				//	dt.addError('Vehicle ' + vehname + ' is in ' + vehlocname);
				//}
				// BLL17d end

            }

			// BLL17a
            // Requested or Approved - vehicle must be in the transfer from location
            if (dt.dealer__Transfer_Status__c!=null && oldDt!=null && oldDt.dealer__Transfer_Status__c!=dt.dealer__Transfer_Status__c
            	&& (dt.dealer__Transfer_Status__c.startsWith('Requested') || dt.dealer__Transfer_Status__c.startsWith('Approved') || dt.dealer__Transfer_Status__c.startsWith('In Transit'))) {
                // Ensure vehicle's store matches from-store
                //BLL23d dealer__Vehicle_Inventory__c vehicle = TradedVehiclesMap.get(dt.dealer__Stock_No__c);
                System.debug(veh.dealer__Store_Location__c);
                System.debug(dt.dealer__Outbound_Location__c);
                if (veh!=null && veh.dealer__Store_Location__c!=dt.dealer__Outbound_Location__c) {
					dt.addError('Vehicle ' + vehname + ' is in ' + vehlocname + ', NOT in ' + frloc.Name);
                    //dt.addError('Cannot submit a Dealer Trade: vehicle is not in location ' + frloc.Name);
                }
            }
            // BLL17a end

            //BLL25d // Approved request - remind GM to send paperwork UPS overnight
            // Required fields: Transport method
            if (oldDt!=null) System.debug(oldDt.dealer__Transfer_Status__c);
            System.debug(dt.dealer__Transfer_Status__c);
            if (dt.dealer__Transfer_Status__c!=null && oldDt!=null && oldDt.dealer__Transfer_Status__c!=dt.dealer__Transfer_Status__c
            	&& !AllowMissingTransport.contains(dt.dealer__Transfer_Status__c)) {
            	//BLL25d && (dt.dealer__Transfer_Status__c.startsWith('Approved') || (dt.dealer__Transfer_Status__c=='In Transit' && frloc!=null && frloc.ManufacturingLocation__c))) {	// BLL21c
                // BLL8a Additional validations
				List<String> missingFields = new List<String>();	// BLL8a
                if (String.isBlank(dt.Transport_Method__c)) missingFields.add('Transport method');
                // if (dt.Transport_Method__c=='Carrier' && dt.Carrier__c==null) missingFields.add('Carrier');
				if (missingFields.size()>0) dt.addError('The following information is required before submitting or approving the transfer: ' + String.join(missingFields,', '));	// BLL25c
                // BLL8a end

/**
                // Email GM to remind them to overnight the paperwork
                Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();
                User outgm = GMUsers.get(dt.OutboundGeneralManager__c);
                User ingm = GMUsers.get(dt.InboundGeneralManager__c); 
                User outsa = null;
                if (dt!=null) outsa = GMUsers.get(dt.OutboundSalesAdmin__c);
                User insa = null;
                if (dt!=null) insa = GMUsers.get(dt.InboundSalesAdmin__c); 
                List<String> toAddresses = new List<String>();
                if (outgm!=null) toAddresses.add(outgm.Email);
                if (outsa!=null) toAddresses.add(outsa.Email);
                if (org!=null && org.isSandbox) toAddresses = new String[] {UserInfo.getUserEmail()};
                em.setToAddresses(toAddresses);
                em.setSubject('Approved transfer of ' + veh.Name + ' from Org : ' + UserInfo.getOrganizationName());
                String gmmsg = 'You have approved a transfer request. This is a reminder to package up the deal jacket and include it with the vehicle. '
                    + 'Please immediately UPS overnight the title (if applicable).\n';
                if (dt.Name!=null) gmmsg += dt.Name + ' request for ' + vehname + '.\n';
                String addressto = '';
                if (ingm!=null) addressto += ingm.Name;
                if (insa!=null) addressto += (String.isBlank(addressto) ? '' : ', ') + insa.Name;
                if (ingm!=null) gmmsg += 'To: ' + addressto + '\n';
                if (toloc!=null) gmmsg += toloc.dealer__Address__c + '\n' 
                    + toloc.dealer__City__c + ', ' + toloc.dealer__State__c + '  ' + toloc.dealer__Postal_Code__c + '\n'
                    + toloc.dealer__Main_Phone__c;  
                em.setPlainTextBody(gmmsg);
                if (toAddresses.size()>0) GMemails.add(em);
**/
/**
				// BLL7 moved here -- had been in the "In Transit" section below
                // Build message to inventory team
				String tfrMsg = tolocname + ' requested ' + vehname + ' from ' + vehlocname; 
                tfrMsg += ' via ' + dt.Transport_Method__c;
                if (dt.Carrier__c!=null) tfrMsg += ' ' + ((dt.Carrier__c==null) ? '' : dt.Carrier__r.Name);	// BLL3c
                if (dt.Name!=null) tfrMsg += ' (' + dt.Name + ')';
                // BLL16a
                if (!String.isBlank(dt.dealer__Trade_Notes__c)) tfrMsg += 'Notes: ' + dt.dealer__Trade_Notes__c; 
                if (!String.isBlank(dt.dealer__Trade_Notes_Inbound__c)) tfrMsg += 'Notes: ' + dt.dealer__Trade_Notes_Inbound__c;
				// BLL16a end
                inventoryMsg += tfrMsg + '\n\n'; 
				//if (dt.Transport_Method__c=='MBW Truck') mbwtruckMsg += tfrMsg + '\n\n';	// BLL24a
				tfrMsg = '';	// BLL24a
**/
            }

            // In-Transit processes, Inventory team notification (BLL2 changed)
            if (dt.dealer__Transfer_Status__c!=null && dt.dealer__Transfer_Status__c.startsWith('In Transit') && oldDt!=null && oldDt.dealer__Transfer_Status__c!=dt.dealer__Transfer_Status__c) {
                if (dt.OutboundJournal__c==null) OutboundTrades.add(dt.Id);
	
                // Additional validations
                List<String> missingFields = new List<String>();
                if (String.isBlank(dt.Transport_Method__c)) missingFields.add('Transport method');
                //BLL3d if (dt.Transport_Method__c=='Carrier' && dt.Carrier__c==null) missingFields.add('Carrier');
				if (missingFields.size()>0) dt.addError('The following information is required before approving the transfer: ' + String.join(missingFields,', '));

                // Vehicle must be in location requested from and have no open ROs
                //if (veh!=null && veh.Open_Service_Repair_Orders__c>0)
                //    dt.addError('Vehicle ' + veh.Name + ' has open repair orders.');
				List<String> RONameList = new List<String>();
				if (veh!=null) {
					for(dealer__Service_Repair_Order__c ro : veh.dealer__Service_Repair_Orders__r) {
						if (ro.dealer__Company__c!=dt.dealer__Store_Location__c) {
							RONameList.add(ro.Name);
						}
					}
					if (RONameList.size()>0) {
						dt.addError('Vehicle ' + veh.Name + ' has open repair orders: ' + String.join(RONameList, ', '));
					}
				}
                // Update vehicle cost on dealer trade
                if (veh!=null) {
                    dt.dealer__Invoice_Outbound__c=veh.dealer__Vehicle_Cost__c;
                    dt.dealer__Accessories_Ours__c = veh.Conversion_Cost__c;
                }
                if (!updVeh.containsKey(veh.Id)) { 
                    // BLL6d updVeh.put(veh.Id, new dealer__Vehicle_Inventory__c(Id=veh.Id, StatusPriorToTrade__c = veh.dealer__Status_Code__c, dealer__Status_Code__c = 'In Transit - Sold not Delivered'));
                    //if (frloc!=null && frloc.ManufacturingLocation__c!=true)	// BLL21a
                    dealer__Vehicle_Inventory__c uv = new dealer__Vehicle_Inventory__c(Id=veh.Id, StatusPriorToTrade__c = veh.dealer__Status_Code__c, dealer__Status_Code__c = 'In Transit - Transfer');
					if (veh.dealer__Status_Code__c!=uv.dealer__Status_Code__c) uv.dealer__Status_Code_Assignment_Date__c = Date.today();	// BLL22a                    
                    updVeh.put(veh.Id, uv);	// BLL6a
                    //else 
                    //	updVeh.put(veh.Id, new dealer__Vehicle_Inventory__c(Id=veh.Id, StatusPriorToTrade__c = veh.dealer__Status_Code__c));	// BLL21a
                }
            }
    
            // Transferred vehicle received
            if (dt.dealer__Transfer_Status__c == 'Received' && oldDt!=null && oldDt.dealer__Transfer_Status__c!=dt.dealer__Transfer_Status__c) {
                //InboundTrades.add(dt.Id);

				// BLL8a Do not allow if the outbound journal hasn't completed (or been given enough time to complete (10 min))
				Long elapsed_msec = DateTime.Now().getTime() - (dt.LastModifiedDate!=null ? dt.LastModifiedDate.getTime() : 0);	// LastModifiedDate can be null in test class
				Integer elapsed_min = Math.min(99999, (Integer) ((elapsed_msec / 1000) / 60));
				
				if (olddt!=null && dt.OutboundJournal__c==null && elapsed_min<10 ) dt.addError('Please allow the outbound request at least 10 minutes to process before receiving the vehicle.');
				// BLL8a end

                // Create GetReady RO - only on change from approval process
                if (DealerTrades.size()==1 && dt.GetReadyRepairOrder__c==null
                	&& veh.dealer__Status_Code__c!=null && !veh.dealer__Status_Code__c.contains('Rental')	// BLL18a
                	&& veh.StatusPriorToTrade__c!=null && !veh.StatusPriorToTrade__c.contains('Rental') // BLL18a
					&& frloc!=null && frloc.ManufacturingLocation__c!=true	// BLL21a - no RO for transfer from mfg
                	) {
                    dealer__Service_Repair_Order__c ro = CreateGetReadyROforVehicle(dt);	
                    // BLL4a
                    dealer__Dealer_Location__c inloc = DealerLocationsMap.get(dt.dealer__Store_Location__c);
                    Id servicedirectorid = inloc.dealer__Service_Director__c;
                    List<dealer__Service_Repair_Order__c> rolist = smRoMap.get(servicedirectorid);
                    if (rolist==null) rolist = new List<dealer__Service_Repair_Order__c>();
                    rolist.add(ro);
                    roIds.add(ro.Id);	// BLL11a
					if (servicedirectorid!=null) smRoMap.put(servicedirectorid, rolist);
                    // BLL4a
                    // BLLa Don't reset vehicle status if GetReady was created 
                }
                // Intercompany?
                if (frloc!=null && toloc!=null && frloc.Company__c!=toloc.Company__c) {
                    // BLL31 - only generate journal if it's not already been done
					// IntercompanyTrades.add(dt.Id);
					if (dt.OutboundIntercompanyJournal__c==null) IntercompanyTradesOut.add(dt.Id);
					if (dt.InboundIntercompanyJournal__c==null) IntercompanyTradesIn.add(dt.Id);
					// BLL31 end
                } else {
					// BLL31
                    //InboundTrades.add(dt.Id);
					if (dt.InboundJournal__c==null) InboundTrades.add(dt.Id);
					// BLL31 end
                }
                // Update inbound cost on trade document
                if (veh!=null) {
                    dt.dealer__Invoice_Inbound__c = veh.dealer__Vehicle_Cost__c;
                    dt.dealer__Accessories_Inbound__c = veh.Conversion_Cost__c;
                }
                
            }

			// BLL8a ensure there are no Other open trades
			if (veh!=null && (dt.dealer__Transfer_Status__c=='Approved' ||  dt.dealer__Transfer_Status__c=='In Transit')) {
				List<String> otherOpenTrades = new List<String>();
				for(dealer__Dealer_Trade__c ot : veh.dealer__Dealer_Trades__r) {
					if (ot.Id!=dt.Id) otherOpenTrades.add(ot.Name + ' Transfer ' + veh.Name + ' from ' + ot.dealer__Outbound_Location__r.Name + ' to ' + ot.dealer__Store_Location__r.Name);
				}
				if (otherOpenTrades.size()>0) {
					String otherTrades = String.join(otherOpenTrades, ', ');
					dt.addError('You cannot approve a transfer that has other active transfers: ' + otherTrades);
				}
			}
			// BLL8a end

        }

        // Only generate journals if there is 1 record to process (approval process or other single-record changed status)
        if (DealerTrades.size()==1) {
            if (OutboundTrades.size()>0) new VehicleTransfer(OutboundTrades).ProcessOutboundTrades();
            if (InboundTrades.size()>0) {
                VehicleTransfer tfr = new VehicleTransfer(InboundTrades);
                tfr.ProcessInboundTrades();
                tfr.UpdateVehicleLocations();
            }
            // BLL31
			// if (IntercompanyTrades.size()>0) {
			// BLL31 end
				// BLL31
                // VehicleTransfer tfr = new VehicleTransfer(IntercompanyTrades);
				if (IntercompanyTradesOut.size()>0) {
					VehicleTransfer tfr = new VehicleTransfer(IntercompanyTradesOut);
				// BLL31 end
                	tfr.ProcessOutboundIntercompany();
				// BLL31
				}
				if (IntercompanyTradesIn.size()>0) {
					VehicleTransfer tfr = new VehicleTransfer(IntercompanyTradesIn);
				// BLL31 end
                	tfr.ProcessInboundIntercompany();
                	tfr.UpdateVehicleLocations();
				// BLL31
				}
				// BLL31 end
			// BLL31
            // }
			// BLL31 end
        }

		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();	// BLL24a moved up
		
        //BLL25d // Send email to inventory team
        //BLL25d if (!String.isBlank(inventoryMsg)) {
        //BLL25d     String[] toAddresses = new String[] {'vehicle.inventory@mobilityworks.com'};
        //BLL25d     if ((org!=null && org.isSandbox) || toAddresses==null || toAddresses.size()==0) {
        //BLL25d     	inventoryMsg = 'Sandbox not sending email to: ' + String.join(toAddresses,', ') + '\n\n' + inventoryMsg;
        //BLL25d     	toAddresses = new String[] {UserInfo.getUserEmail()};
        //BLL25d     }
        //BLL25d     Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        //BLL25d     mail.setToAddresses(toAddresses);
        //BLL25d     mail.setSubject('Dealer Trade Request' + ' from Org : ' + UserInfo.getOrganizationName());
        //BLL25d     mail.setPlainTextBody(inventoryMsg);
        //BLL25d     //BLL24d Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        //BLL25d     emails.add(mail);	// BLL24a       
        //BLL25d }
        
        // BLL24a Message to MBW Truck group
        //if (!String.isBlank(mbwtruckMsg)) {
        //	List<String> toAddresses = new List<String>();
        //	toAddresses.addAll(Utility.getGroupMbrUserEmails('MBW_Truck'));
        //   if ((org!=null && org.isSandbox) || toAddresses==null || toAddresses.size()==0) {
        //    	mbwtruckMsg = 'Sandbox not sending email to: ' + String.join(toAddresses,', ') + '\n\n' + mbwtruckMsg;
        //    	toAddresses = new String[] {UserInfo.getUserEmail()};
        //    }
        //    Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        //    mail.setToAddresses(toAddresses);
        //    mail.setSubject('Dealer Trade Request' + ' from Org : ' + UserInfo.getOrganizationName());
        //    mail.setPlainTextBody(mbwtruckMsg);
        //    emails.add(mail);       
        //}               
        // BLL24a end

        // Send GM reminder emails
        //BLL25d if (GMemails.size()>0) emails.addAll(GMemails);	// BLL24c Messaging.sendEmail(GMemails);

		// BLL4a 
		// Send SM emails about ROs created
		//BLL24d List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		Map<Id,User> smusermap = new Map<Id,User>();
		if (smRoMap.size()>0) smusermap = new Map<Id,User>([
			select Id, Name, Email 
			from User 
			where Id in :smRoMap.keySet()
		]);
		Map<Id,dealer__Service_Repair_Order__c> sroMap = new Map<Id,dealer__Service_Repair_Order__c>();	// BLL11a
		if (roIds.size()>0) sroMap = new Map<Id,dealer__Service_Repair_Order__c>([
			select Id, Name, dealer__Vehicle__r.dealer__Stock_Number__c, DealerTrade__r.dealer__Outbound_Location__r.Name 
			from dealer__Service_Repair_Order__c 
			where Id in :roIds
		]);	// BLL11a, AMM1
		String body = 'GetReady repair orders have been created for received vehicle transfers:\n';
		for(Id smid : smRoMap.keySet()) {
			String ronames = '';
			List<dealer__Service_Repair_Order__c> rolist = smRoMap.get(smid);
			for(dealer__Service_Repair_Order__c ro : rolist) {
				// BLL11d ronames += ro.Name + '\n';
				dealer__Service_Repair_Order__c r = sroMap.get(ro.Id);	// BLL11a
				if (r!=null) ronames += r.name + ', Stock#: ' + r.dealer__Vehicle__r.dealer__Stock_Number__c + ', Outbound Location: ' + r.DealerTrade__r.dealer__Outbound_Location__r.Name + '\n';	// BLL11a, AMM1
			}
			Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {smusermap.get(smid).Email};
			if (org!=null && org.isSandbox) toAddresses = new String[] {UserInfo.getUserEmail()};
			mail.setToAddresses(toAddresses);
			mail.setSubject('GetReady RO created for received vehicle');
			mail.setPlainTextBody(body + ronames);
			emails.add(mail);
		}
		if (emails.size()>0) Messaging.sendEmail(emails);
		// BLL4a end
        
        // Update In-transit vehicle status
        if (updVeh.values().size()>0) update(updVeh.values());

        if (errors || mon.AlwaysNotify) mon.NotifyAdmin();	// BLL4a
        
    }
    

	// BLL23a - needs to be an "After" context trigger
	// no longer needed - idea was redesigned
	//BLL25d public void LockInGPSharing(Map<Id,dealer__Dealer_Trade__c> oldMap) {
	//BLL25d 	Set<String> GPSharingVehSource = new Set<String>{'Purchase','Trade'};	
	//BLL25d 	Map<Id,Id> GPSharingVehLocMap = new Map<Id,Id>();	
	//BLL25d 	Set<String> DealProtectedStatus = new Set<String>{'Lost', 'Won - Posted'};
	//BLL25d 
	//BLL25d 	// Affected locations
    //BLL25d     getDealerLocationsMap();
    //BLL25d     // All referenced vehicles
    //BLL25d     getTradedVehiclesMap();
    //BLL25d  
	//BLL25d 
	//BLL25d 	// Look through all vehicles for requested date being set or changed ...	
    //BLL25d     for(dealer__Dealer_Trade__c dt : DealerTrades) {
    //BLL25d         dealer__Dealer_Trade__c oldDt = null;
    //BLL25d         if (oldMap!=null) oldDt = oldMap.get(dt.Id);
    //BLL25d         System.debug(oldDt);
	//BLL25d 
    //BLL25d         // Referenced locations
    //BLL25d         dealer__Dealer_Location__c frloc = DealerLocationsMap.get(dt.dealer__Outbound_Location__c);
    //BLL25d         dealer__Dealer_Location__c toloc = DealerLocationsMap.get(dt.dealer__Store_Location__c);
    //BLL25d         if (frloc!=null) System.debug(frloc.ManufacturingLocation__c);
	//BLL25d 
    //BLL25d         dealer__Vehicle_Inventory__c veh = TradedVehiclesMap.get(dt.dealer__Stock_No__c);
    //BLL25d         System.debug(veh);
	//BLL25d 
	//BLL25d 		// requested date set - lock in GP sharing on proposals in destination store
	//BLL25d 		if (oldDt!=null && dt.RequestedDate__c!=oldDt.RequestedDate__c) {
	//BLL25d 			if (GPSharingVehSource.contains(veh.dealer__Status_Code__c)) 
	//BLL25d 				gpSharingVehLocMap.put(veh.Id, dt.dealer__Store_Location__c);
	//BLL25d 		}
	//BLL25d 
	//BLL25d 	}
	//BLL25d 
	//BLL25d 	// update related proposals for GP Sharing
	//BLL25d 	Set<Id> updDealIds = new Set<Id>();
	//BLL25d 	for (dealer__Deal__c d : [select Id, Name, dealer__Store_Location__c, dealer__Status__c from dealer__Deal__c where dealer__Vehicle__c in :gpSharingVehLocMap.keySet()]) {
	//BLL25d 		Id vid = d.dealer__Vehicle__c;
	//BLL25d 		Id lid = gpSharingVehLocMap.get(vid);
	//BLL25d 		if (d.dealer__Store_Location__c==lid && !DealProtectedStatus.contains(d.dealer__Status__c)) {
	//BLL25d 			updDealIds.add(d.Id);
	//BLL25d 		}
	//BLL25d 	}
	//BLL25d 
	//BLL25d 	// Update deals in a @future method
	//BLL25d 	if (updDealIds.size()>0) DealProcess.RecalcGPSharing(updDealIds);
	//BLL25d 
	//BLL25d }

    
    // DealerTradeIntegrity
    //-------------------------------------
    public void DealerTradeIntegrity(Map<Id,dealer__Dealer_Trade__c> oldMap) {
        getDealerTrades();
        
        // Map of referenced locations
        Set<Id> locIds = new Set<Id>();
        Map<Id,dealer__Dealer_Location__c> locMap = new Map<Id,dealer__Dealer_Location__c>();
        Set<Id> vehIds = new Set<Id>();

        // User location (default ship-to location)
        User u = CurrentUserSingleton.getInstance();
        List<dealer__Dealer_Location__c> usrloc = [select Id from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division];
        if (usrloc.size()>0) locIds.add(usrloc[0].Id);
     
        for(dealer__Dealer_Trade__c dt : DealerTrades) {
            // List of location Ids referenced
            if (dt.dealer__Outbound_Location__c!=null) locIds.add(dt.dealer__Outbound_Location__c);
            if (dt.dealer__Store_Location__c!=null) locIds.add(dt.dealer__Store_Location__c);
            if (dt.dealer__Stock_No__c!=null) vehIds.add(dt.dealer__Stock_No__c);
        }

        // Get info about vehicles referenced
        Map<Id,dealer__Vehicle_Inventory__c> vehMap = new Map<Id,dealer__Vehicle_Inventory__c>();
        if (vehIds.size()>0) {
            vehMap = new Map<Id,dealer__Vehicle_Inventory__c>([
                select Id, Name, dealer__Store_Location__c, dealer__Status_Code__c
                from dealer__Vehicle_Inventory__c
                where Id in :vehIds
            ]);
        }
        for(dealer__Vehicle_Inventory__c v : vehMap.values()) {
            if (v.dealer__Store_Location__c!=null) locIds.add(v.dealer__Store_Location__c);
        }

        // Get info about referenced locations
        if (locIds.size()>0) {
            locMap = new Map<Id,dealer__Dealer_Location__c>([
                select Id, Name, dealer__General_Manager__c, dealer__Location_Account__c, Sales_Admin__c, dealer__Service_Director__c	// BLL4c 
                from dealer__Dealer_Location__c 
                where Id in :locIds
            ]);
        }

        // Fill in missing information from defaults
        for(dealer__Dealer_Trade__c t : DealerTrades) {
            dealer__Dealer_Trade__c oldt = null;
            if (oldMap!=null) oldt = oldMap.get(t.Id);

            // Missing requesting location ...
            if (t.dealer__Store_Location__c==null && usrloc.size()>0) t.dealer__Store_Location__c = usrloc[0].Id;

            // Once dealer account reference is in production...
            // if (t.dealer__Dealer__c==null && t.dealer__Store_Location__c!=null) {
            //  if (locMap.containsKey(t.dealer__Store_Location__c)) {
            //      t.dealer__Dealer__c = locMap.get(t.dealer__Store_Location__c).dealer__Location_Account__c;
            //  }
            // }

            // Missing outbound location ...
            dealer__Vehicle_Inventory__c veh = vehMap.get(t.dealer__Stock_No__c);
            if (t.dealer__Outbound_Location__c==null && veh!=null) t.dealer__Outbound_Location__c = veh.dealer__Store_Location__c;

            // requesting location and outbound location cannot be the same
            if (t.dealer__Outbound_Location__c==t.dealer__Store_Location__c) {
                t.addError('Vehicle cannot already reside at the requesting location');
            }

            // Fill in location GMs         
            dealer__Dealer_Location__c outloc = locMap.get(t.dealer__Outbound_Location__c);
            dealer__Dealer_Location__c inloc = locMap.get(t.dealer__Store_Location__c);
            if (t.dealer__Trade_Completed__c==null || t.dealer__Trade_Completed__c!=true) {
                if (outloc!=null && t.OutboundGeneralManager__c==null) t.OutboundGeneralManager__c = outloc.dealer__General_Manager__c;
                if (inloc!=null && t.InboundGeneralManager__c==null) t.InboundGeneralManager__c = inloc.dealer__General_Manager__c;
                if (outloc!=null && t.OutboundSalesAdmin__c==null) t.OutboundSalesAdmin__c = outloc.Sales_Admin__c;
                if (inloc!=null && t.InboundSalesAdmin__c==null) t.InboundSalesAdmin__c = inloc.Sales_Admin__c;
            } 
            
            // Fill in dealer account and address
            if (t.dealer__Dealer__c==null || (oldt!=null && t.dealer__Store_Location__c!=oldt.dealer__Store_Location__c)) {
                if (inloc!=null) t.dealer__Dealer__c=inloc.dealer__Location_Account__c;
            }
        }

        if (errors || mon.AlwaysNotify) mon.NotifyAdmin();	// BLL4a
        
    }    
    
    // CreateGetReadyROforVehicle
    // Expected to be called from a trigger, passing in the new value of an individual trade
    //-------------------------------------
    public dealer__Service_Repair_Order__c CreateGetReadyROforVehicle(dealer__Dealer_Trade__c dt) {
        Set<String> newVehicle = new Set<String>{'New','Fleet'};

		dealer__Service_Repair_Order__c ro = null;	// BLL4a
        
        // Don't create anything if there's no vehicle
        if (dt.dealer__Stock_No__c==null || dt.GetReadyRepairOrder__c!=null) return ro; 

        // Get Associated Creating User
        String invoiceName = 'RO#';

        // Get location information
        dealer__Dealer_Location__c location = [Select Id, Name, dealer__Company_Number__c, dealer__Service_Director__c, Service_Reporting_User__c from dealer__Dealer_Location__c WHERE Id =:dt.dealer__Store_Location__c limit 1]; 

        // Get the vehicle record
        dealer__Vehicle_Inventory__c vi = [select Id, Name, New_Used_Other__c, Division__c from dealer__Vehicle_Inventory__c where Id=:dt.dealer__Stock_No__c limit 1];	// BLL14c division

        // Get service vehicle record for this inventory vehicle
        dealer__Service_Vehicle__c sv = null;
        if (sv==null && dt.dealer__Stock_No__c!=null) {
            try { 
                sv = [Select Id, dealer__Last_Odometer__c from dealer__Service_Vehicle__c where dealer__Sales_Inventory__c=:dt.dealer__Stock_No__c limit 1];
            } catch(Exception e) { /* No service vehicle attached to inventory vehicle */ } 
        }
        
        // Instantiate the RO  
        ro = new dealer__Service_Repair_Order__c();
        
        // BLL10d
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
        //} Catch(DmlException e) { dt.addError('Unable to create the GetReady repair order ' + e.getMessage()); }
        // BLL10d end 

        ro.Name = 'RO#' + location.dealer__Company_Number__c + '-';	// BLL10c  + ro.dealer__RO_Number__c;
        
        ro.dealer__Company_Number__c = location.dealer__Company_Number__c;
        ro.dealer__Company__c  = location.Id; 
        ro.dealer__Create_Date_Time__c = Datetime.now();
        ro.dealer__Service_Advisor__c = location.dealer__Service_Director__c;
        if (sv!=null) {
            ro.dealer__Vehicle__c = sv.Id;
        }
        ro.dealer__Vehicle_Inventory__c = dt.dealer__Stock_No__c;
        ro.dealer__Mileage_In__c = (sv!=null) ? sv.dealer__Last_Odometer__c : null;
        if (ro.dealer__Mileage_In__c==null) ro.dealer__Mileage_In__c = 0;
        ro.dealer__Customer__c = dt.dealer__Dealer__c;
        ro.DealerTrade__c = dt.Id; 
        if (location.Service_Reporting_User__c!=null) ro.OwnerId = location.Service_Reporting_User__c;  // BLL1a

        System.debug(ro);
        try {
            insert ro;

            // BLL15a - Need RO Name & Number
            dealer__Service_Repair_Order__c newro = [select Id, Name, dealer__RO_Number__c from dealer__Service_Repair_Order__c where id=:ro.Id];
            ro.Name = newro.Name;
            ro.dealer__RO_Number__c = newro.dealer__RO_Number__c;
            // BLL15a end

            // Create single get-ready line
            // Get Default Op Code
            //dealer__StandardOpCode__c[] sop = [select Id, Name from dealer__StandardOpCode__c where Name = '60CHECKIN' limit 1];
            //BLL29
			//dealer__StandardOpCode__c[] sop = [select Id, Name from dealer__StandardOpCode__c where Name = :StandardOpCode limit 1];
			dealer__StandardOpCode__c[] sop = [
				select Id, Name, dealer__Cause__c, dealer__Concern__c, dealer__Correction__c
				from dealer__StandardOpCode__c 
				where Name = :StandardOpCode 
				limit 1
			];
			// BLL29 end

            // Get NUO Payment Methods 
            Map<String,ServicePaymentType__c> sptMap = new Map<String,ServicePaymentType__c>();
            String sptName = newVehicle.contains(vi.New_Used_Other__c) ? 'GRNV' : 'GRUV';
            if (vi.Division__c=='Commercial') sptName = 'MCEO';	// BLL14a
            for(ServicePaymentType__c spt : [select Id, Name, Payment_Type__c from ServicePaymentType__c where Name=:sptName]) {
                sptMap.put(spt.Name, spt);
            }
            Integer i = 1;
            dealer__Service_Job__c newLine = new dealer__Service_Job__c();
            newLine.dealer__Service_Repair_Order__c = ro.Id;
            newLine.Name = ro.Name + '-' + i;
            newLine.dealer__Line_Number__c = i;
            newLine.dealer__Service_Type__c = 'MR';
            newLine.dealer__Labor_Type__c = sptMap.containsKey(sptName) ? sptMap.get(sptName).Payment_Type__c : 'I';
            newLine.dealer__CustomerConcern__c = 'Vehicle check-in';
            if(sop.size()>0) {
                newLine.dealer__Standard_Operation_Code__c = sop[0].Id;
                newLine.dealer__Op_Code__c = sop[0].Name;
				// BLL29
				//newLine.dealer__Concern__c = sop[0].dealer__Concern__c;
				newLine.dealer__CustomerConcern__c = sop[0].dealer__Concern__c;
				//newLine.dealer__Cause__c = sop[0].dealer__Cause__c;
				newLine.dealer__CauseExtended__c = sop[0].dealer__Cause__c;
				newLine.dealer__Correction__c = sop[0].dealer__Correction__c;
				// BLL29 end
            }
            newLine.Payment_Method__c = sptMap.containsKey(sptName) ? sptMap.get(sptName).Id : null;
            insert newLine;
            // Update the Dealer Trade
            dt.GetReadyRepairOrder__c = ro.Id;
            
        } catch(DmlException e) { dt.addError('Unable to create the delivery repair order ' + e.getMessage()); }   

		return ro;	// BLL4a

    }


    // getVehicleTransactions - for processing and for displaying on-screen
    //------------------------------------------
    public Map<String,List<c2g__codaTransactionLineItem__c>> getVehicleTransactions(Set<String> stocknbrs) {
        Map<String,List<c2g__codaTransactionLineItem__c>> vehTranLines = new Map<String,List<c2g__codaTransactionLineItem__c>>();
        
        Map<Id, c2g__codaGeneralLedgerAccount__c> vehGLAcctMap;
        Set<Id> vehGLAcctIds;
        vehGLAcctMap = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
            select Id, Name, c2g__ReportingCode__c, VehicleRequired__c, VehicleComponent__c 
            from c2g__codaGeneralLedgerAccount__c
            where VehicleRequired__c=true // and VehicleComponent__c!='Contra'
        ]);
        vehGLAcctIds = vehGLAcctMap.keySet();
        
        for (c2g__codaTransactionLineItem__c t : [
            select Id, Name, c2g__GeneralLedgerAccount__c, c2g__HomeValue__c, Control__c, Vehicle_Inventory__c,
                c2g__Transaction__r.Name, c2g__LineNumber__c
            from c2g__codaTransactionLineItem__c
            where c2g__GeneralLedgerAccount__c in :vehGLAcctIds and Control__c in :stocknbrs
        ]) {
            List<c2g__codaTransactionLineItem__c> lines = vehTranLines.get(t.Control__c);
            if (lines==null) lines = new List<c2g__codaTransactionLineItem__c>();
            lines.add(t);
            vehTranLines.put(t.Control__c,lines); 
        }
        return vehTranLines;
    }


    // getOutboundJournalLines - for processing inbound & intercompany
    //------------------------------------------
    public Map<String,List<c2g__codaJournalLineItem__c>> getOutboundJournalLines() {
        Map<String,List<c2g__codaJournalLineItem__c>> OutboundJrnLines = new Map<String,List<c2g__codaJournalLineItem__c>>();

        Set<Id> jrnids = new Set<Id>();
        for(dealer__Dealer_Trade__c t : DealerTrades) if (t.OutboundJournal__c!=null) jrnids.add(t.OutboundJournal__c);
                
        for (c2g__codaJournalLineItem__c l : [
            select Id, Name, c2g__GeneralLedgerAccount__c, c2g__Value__c, Control__c, Vehicle_Inventory__c,
                c2g__Journal__r.Name, c2g__LineNumber__c
            from c2g__codaJournalLineItem__c
            where c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c != '2903'
              and c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c != '1265' 
              and c2g__Journal__c in :jrnids
        ]) {
            List<c2g__codaJournalLineItem__c> lines = OutboundJrnLines.get((String) l.c2g__Journal__c);
            if (lines==null) lines = new List<c2g__codaJournalLineItem__c>();
            lines.add(l);
            OutboundJrnLines.put(l.c2g__Journal__c,lines); 
        }
        System.debug(OutboundJrnLines);
        return OutboundJrnLines;
    }


    // summarizeByGLAccount
    //------------------------------------------
    public Map<Id,Decimal> summarizeByGLAccount(List<c2g__codaTransactionLineItem__c> transactionlines) {
        Map<Id,Decimal> glMap = new Map<Id,Decimal>();
        if (transactionlines==null) transactionlines = new List<c2g__codaTransactionLineItem__c>();
        // Build summary by GL account  
        for(c2g__codaTransactionLineItem__c t : transactionlines) {
            Decimal value = glMap.get(t.c2g__GeneralLedgerAccount__c);
            if (value==null) value = 0;
            value += t.c2g__HomeValue__c;
            glMap.put(t.c2g__GeneralLedgerAccount__c, value); 
        }
        // Remove entries that netted to $0
        for(Id k : glMap.keySet()) {
            Decimal v = glMap.get(k);
            if (k!=null && v==0) glMap.remove(k);
        }
        return glMap;
    }

    // summarizeByVehicleComponentType
    //------------------------------------------
    public Map<String,Decimal> summarizeByVehicleComponentType(List<c2g__codaTransactionLineItem__c> transactionlines) {
        Map<String,Decimal> transMap = new Map<String,Decimal>();
        if (transactionlines==null) transactionlines = new List<c2g__codaTransactionLineItem__c>();
        
        // Map of GL accounts to veh cost type  
        Set<Id> GLAcctIds = new Set<Id>();  
        for(c2g__codaTransactionLineItem__c t : transactionlines) GLAcctIds.add(t.c2g__GeneralLedgerAccount__c);
        Map<Id,c2g__codaGeneralLedgerAccount__c> acctMap = new Map<Id,c2g__codaGeneralLedgerAccount__c>([
            select Id, VehicleComponent__c from c2g__codaGeneralLedgerAccount__c
            where id in :GLAcctIds
        ]);
        
        // Build summary by GL account and dimension1 
        for(c2g__codaTransactionLineItem__c t : transactionlines) {
            c2g__codaGeneralLedgerAccount__c gl = acctMap.get(t.c2g__GeneralLedgerAccount__c);
            String key = (gl!=null && gl.VehicleComponent__c!=null) ? gl.VehicleComponent__c : 'Chassis';
            Decimal amt = transMap.get(key);
            if (amt==null) amt = 0.00;
            amt += t.c2g__HomeValue__c;
            transMap.put(key,amt);
        }

        return transMap;
    }

	// prevent deletiong of dealer trades with journals
	public void DealerTradePreventDelete(Map<Id,dealer__Dealer_Trade__c> oldMap) {
		for(dealer__Dealer_Trade__c dt : oldMap.values()) {
			if (dt.InboundIntercompanyJournal__c!=null || dt.InboundJournal__c!=null 
				|| dt.OutboundIntercompanyJournal__c!=null || dt.OutboundJournal__c!=null) {
				dt.addError('You cannot delete dealer trades with journals.');
			}
		}
	}

}