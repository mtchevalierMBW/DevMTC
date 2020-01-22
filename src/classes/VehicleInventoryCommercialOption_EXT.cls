/**
 * VehicleInventoryCommercialOption_EXT
 * Tested by: VehicleInventoryCommercialOption_TEST
 * Programmer: Bryan Leaman
 * Date: Feb 11, 2016
 *
 *	2016-06-10	B. Leaman	BLL1 - add ability to pull options from a commercial quote 
 */
 public with sharing class VehicleInventoryCommercialOption_EXT {
    private ApexPages.StandardController ctlr;
    public dealer__Vehicle_Inventory__c veh {get;private set;}
    public List<VehicleInventory_CommercialOption__c> vehicleOptions {get; set;}
    public VehicleInventory_CommercialOption__c vico {get;private set;}

    // Selection for option list
    public String optionType {get;set;}
    public String chassisMfg {get;set;}
    public String wheelbase {get;set;}
    public String keywords {get;set;}
    public String keywords2 {get;set;}
    public String keywords3 {get;set;}
    
    public List<SelectOption> optionTypeOpts {get; private set;}
    public List<SelectOption> chassisMfgOpts {get; private set;}
    public List<SelectOption> wheelbaseOpts {get; private set;} 

    public VehicleInventory_CommercialOption__c chassisOption {get;private set;}
    public Commercial_Quote_Options__c chassisOptionCq {get;private set;}
    public Set<Id> vehQuoteOptionIds;
    
    public Id optionToAdd {get;set;}
    public Id optionToRmv {get;set;}
    
    // BLL1a
    public String unitNumber {get;set;}
    public String VIN {get;set;}
    public Id quoteToUse {get;set;}
    public String selectBy {get;set;}
    // BLL1a end
    
    // pagination variables
    Integer cqoOffset {get;set;}
    Integer cqoLimit {get;set;}
    public Boolean changeQuantities {get;private set;}
 
    // constructor
    //-----------------------------------------
    public VehicleInventoryCommercialOption_EXT(ApexPages.StandardController controller) {
        ctlr = controller;
        List<String> addFields = new List<String>();
        addFields.add('Name');
        addFields.add('ChassisMfg__c');
        addFields.add('Wheelbase__c');
        addFields.add('dealer__Status_Code__c');
        addFields.add('dealer__Store_Location__c');
        addFields.add('dealer__VIN__c');
        addFields.add('New_Used_Other__c');
        addFields.add('Conv_MFG__c');
        addFields.add('Conversion_Model__c');
        addFields.add('Division__c');
        addFields.add('dealer__Stock_Number__c');	// BLL1a
        addFields.add('OptionsExtendedPrice__c');   	//MarinerTek
        addFields.add('ChassisOptionsExtendedPrice__c'); //MarinerTek
        // Get all the custom field for use in the VF UI
        //Map<String, Schema.SObjectField> objFieldMap = Schema.SObjectType.SObject.fields.getMap();
        //Set<String> fieldnames = M.keySet(); 
        //addFields.addAll(fieldnames);
        if(!Test.isRunningTest() && addFields.size()>0) ctlr.addFields(addFields);

        veh = (dealer__Vehicle_Inventory__c) ctlr.getRecord();
        wheelbase = veh!=null ? veh.Wheelbase__c : null;
        chassisMfg = veh!=null ? veh.ChassisMfg__c : null;
        vico = new VehicleInventory_CommercialOption__c(VehicleInventory__c=veh.Id);
        try {unitNumber = veh.dealer__Stock_Number__c; } catch(Exception e) {}	// BLL1a
        VIN = veh.dealer__VIN__c;	// BLL1a
        refreshVehicleOptions();

        // default limits until pagination is added (if it's addd)
        cqoOffset = 0;
        cqoLimit = 500; 

        generateSelectOptions();    

        if (chassisOption==null) optionType='Chassis Options';
        changeQuantities = false;
        // BLL1a
        selectBy='none';
        if (chassisOption==null) selectBy='quote';
        // BLL1a end
    }

    // returnToVehicle
    //-----------------------------------------
    public ApexPages.PageReference returnToVehicle() {
        return ctlr.view();
    }
 
    
    // refreshVehicleOptions
    //-----------------------------------------
    public void refreshVehicleOptions() {
        List<VehicleInventory_CommercialOption__c> options = new List<VehicleInventory_CommercialOption__c>();
        List<VehicleInventory_CommercialOption__c> chassis = new List<VehicleInventory_CommercialOption__c>();
        List<VehicleInventory_CommercialOption__c> nonchassis = new List<VehicleInventory_CommercialOption__c>();
        vehQuoteOptionIds = new Set<Id>();
        chassisOption = null;
        chassisMfg = null;
        wheelbase = null;
        
        options = [
            select Id, Name, OptionType__c, CommercialQuoteOption__c, Description__c, SellingPrice__c, Cost__c,
                    Quantity__c, ExtendedCost__c, ExtendedPrice__c, Notes__c
            from VehicleInventory_CommercialOption__c
            where VehicleInventory__c=:veh.Id
        ];
        for(VehicleInventory_CommercialOption__c o : options) {
            if (o.OptionType__c=='Chassis Options') chassis.add(o);
            if (o.OptionType__c!='Chassis Options') nonchassis.add(o);
            if (chassisOption==null && o.OptionType__c=='Chassis Options') setChassisOption(o);
            vehQuoteOptionIds.add(o.CommercialQuoteOption__c);
        }
        System.debug(vehQuoteOptionIds);

        vehicleOptions = new List<VehicleInventory_CommercialOption__c>();
        vehicleOptions.addAll(nonchassis);
        System.debug('Number of options on vehicle ' + String.valueOf(vehicleOptions.size()));
        generalValidations();
    }
    
    // getVehicleOptions
    //----------------------------------------
    public List<VehicleInventory_CommercialOption__c> getVehicleOptions() {
        refreshVehicleOptions();
        System.debug('Vehicle options size='+String.valueOf(vehicleOptions.size()));
        return vehicleOptions;
    }
 
	// generalValidations
    //----------------------------------------
	public void generalValidations() {
        if (chassisOption==null && vehicleOptions.size()>0) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'This vehicle does not have a chassis assigned yet'));
        }
	}

    // getCommercialOptions
    //-----------------------------------------
    public List<CommercialOptionWrapper> getCommercialOptions() {
        List<Commercial_Quote_Options__c> opts = new List<Commercial_Quote_Options__c>();
        //refreshVehicleOptions();

        String fieldlist = 'Id, Name, Active__c, Vehicle_Manufacturer__c, Wheelbase__c, Description__c, '
            + 'Cost__c, Freight__c, Internal_Note__c, Selling_Price__c, Supplier_URL__c ';
        String fromobj = 'Commercial_Quote_Options__c ';
        String selection = 'where Active__c=true ';

        // add variable selection criteria
        if (!String.isBlank(optionType)) selection += ' and RecordType.Name=\'' + optionType.escapeJava() + '\' ';
        if (!String.isBlank(chassisMfg)) selection += ' and (Vehicle_Manufacturer__c=null or Vehicle_Manufacturer__c=\'' + chassisMfg.escapeJava() + '\') ';
        if (!String.isBlank(wheelbase))  selection += ' and (Wheelbase__c=null or Wheelbase__c=\'' + wheelbase.escapeJava() + '\') ';

        String orderby = 'order by Name';
        String limits = 'limit ' + String.valueOf(cqoLimit) + ' ' 
            + 'offset ' + String.valueOf(cqoOffset) + ' ';

        String keywordString = '';
        if (!String.isBlank(keywords)) keywordString += '"' + keywords.trim() + '" ';
        if (!String.isBlank(keywords2)) keywordString += '"' + keywords2.trim() + '" ';
        if (!String.isBlank(keywords3)) keywordString += '"' + keywords3.trim() + '" ';
        if (String.isBlank(keywordString)) {
            // SOQL 
            String soql = 'select ' + fieldlist + ' from ' + fromobj + ' ' + selection + ' ' + orderby + ' ' + limits;
            System.debug(soql);
            try {
            	opts = Database.query(soql);
            } catch(Exception e) {
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        } else {
            // SOSL
            String sosl = 'FIND \'' + String.escapeSingleQuotes(keywordString.trim()) + '\' IN ALL FIELDS '
                + 'RETURNING ' + fromobj + '(' + fieldlist + ' '
                + selection + ' ' + orderby + ' ' + limits + ') ';
            System.debug(sosl);
            try {
    	        List<List<SObject>> soslrs = search.query(sosl);
	            if (soslrs.size()>0) opts = (List<Commercial_Quote_Options__c>) soslrs[0];
            } catch(Exception e) {
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
        
        return wrapCommercialOptions(opts);
    }


    // wrapCommercialOptions
    //-----------------------------------------
    public List<CommercialOptionWrapper> wrapCommercialOptions(List<Commercial_Quote_Options__c> opts) {
        List<CommercialOptionWrapper> wrapped = new List<CommercialOptionWrapper>();
        System.debug(vehQuoteOptionIds);
        for(Commercial_Quote_Options__c o : opts) {
            System.debug('Id=' + o.Id + '; onvehicle=' + (vehQuoteOptionIds.contains(o.Id)?'true':'false'));
            wrapped.add(new CommercialOptionWrapper(o, vehQuoteOptionIds.contains(o.Id)));
        }
        return wrapped;
    }
    

    // generateSelectOptions
    //-----------------------------------------
    public void generateSelectOptions() {

        optionTypeOpts = new List<SelectOption>();
        chassisMfgOpts = new List<SelectOption>();
        wheelbaseOpts = new List<SelectOption>(); 

        // commercial quote option record types
        optionTypeOpts = new List<SelectOption>();
        Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Commercial_Quote_Options__c.getRecordTypeInfosByName();
        for(String k : RcdTypes.keySet()) {
            if (!RcdTypes.get(k).isMaster()) {
                String n = RcdTypes.get(k).getName();
                optionTypeOpts.add(new SelectOption(n, n));
                if (optionType==null) optionType = n;
            } 
        }
        
        // chassis manufacturer
        Schema.DescribeFieldResult cm_dfr = Commercial_Quote_Options__c.Vehicle_Manufacturer__c.getDescribe();
        List<Schema.PicklistEntry> cm_plvs = cm_dfr.getPicklistValues();
        chassisMfgOpts.add(new SelectOption('','--'));
        for(Schema.PicklistEntry p : cm_plvs) chassisMfgOpts.add(new SelectOption(p.getLabel(), p.getValue()));     
        
        // wheelbase options
        Schema.DescribeFieldResult wo_dfr = Commercial_Quote_Options__c.Wheelbase__c.getDescribe();
        List<Schema.PicklistEntry> wo_plvs = wo_dfr.getPicklistValues();
        wheelbaseOpts.add(new SelectOption('','--'));
        for(Schema.PicklistEntry p : wo_plvs) wheelbaseOpts.add(new SelectOption(p.getLabel(), p.getValue()));      
        
    }
 

    // newVehicleCommercialOption
    //-------------------------------------
    public VehicleInventory_CommercialOption__c newVehicleCommercialOption(Id cqoId) {
        VehicleInventory_CommercialOption__c addvico;
        Commercial_Quote_Options__c cqo;
        try {
            cqo = [ 
                select  Id, Name, RecordType.Name, Active__c, Vehicle_Manufacturer__c, Wheelbase__c, Description__c, 
                        Cost__c, Freight__c, Internal_Note__c, Selling_Price__c, Supplier_URL__c 
                from Commercial_Quote_Options__c 
                where Id=:optionToAdd
            ];
        } catch(Exception e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid option selected'));}
        if (cqo!=null) {
            addvico = new VehicleInventory_CommercialOption__c(
                VehicleInventory__c=veh.Id, CommercialQuoteOption__c=cqo.Id,
                Name=cqo.Name, Cost__c=cqo.Cost__c, SellingPrice__c=cqo.Selling_Price__c,
                Description__c=cqo.Description__c, Notes__c=cqo.Internal_Note__c,
                Quantity__c=1, OptionType__c=cqo.RecordType.Name
            );
        }
        return addvico;
    }
 
    // addOption
    //---------------------------------------
    public void addOption() {
        System.debug('Adding option id=' + String.valueOf(optionToAdd));
        try {
            VehicleInventory_CommercialOption__c vico = newVehicleCommercialOption(optionToAdd);
            insert(vico);
            vehQuoteOptionIds.add(vico.CommercialQuoteOption__c);
            if (vico.OptionType__c=='Chassis Options') updateVehicleChassisOption(vico);
            refreshVehicleOptions();
        } catch(Exception e) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Unable to add selected option: ' + e.getMessage()));}
    }
    
    
    // rmvOption
    //---------------------------------------
    public void rmvOption() {
        System.debug('Removing option id=' + String.valueOf(optionToRmv));
        try {
            VehicleInventory_CommercialOption__c vico = new VehicleInventory_CommercialOption__c(Id=optionToRmv);
            delete(vico);
            if (vico.OptionType__c=='Chassis Options') updateVehicleChassisOption(vico);
            refreshVehicleOptions();
        } catch(Exception e) {ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Unable to add selected option: ' + e.getMessage()));}
    }
    
    
    // updateVehicleChassisOption
    //---------------------------------------
    public void updateVehicleChassisOption(VehicleInventory_CommercialOption__c chassisOpt) {
        // remove all old chassis
        List<VehicleInventory_CommercialOption__c> co = [
            select Id, OptionType__c
            from VehicleInventory_CommercialOption__c
            where VehicleInventory__c=:veh.Id and Id<>:chassisOpt.Id and OptionType__c='Chassis Options'
        ];
        if (co.size()>0) delete(co); 
        // set chassis mfg & wheelbase
        setChassisOption(chassisOpt);
        dealer__Vehicle_Inventory__c updVeh = new dealer__Vehicle_Inventory__c(
            Id=veh.Id,
            ChassisMfg__c=chassisMfg, Wheelbase__c=wheelbase
        );
        if (updVeh.Id!=null) update(updVeh);
        refreshVehicleOptions();
    }

    // setChassisOption
    //---------------------------------------
    public void setChassisOption(VehicleInventory_CommercialOption__c o) {
        chassisOption = o;
        // need mfg and wheelbase for additional option selections
        Commercial_Quote_Options__c cqo = [
            select Id, Name, Vehicle_Manufacturer__c, Wheelbase__c
            from Commercial_Quote_Options__c
            where Id=:o.CommercialQuoteOption__c
        ];
        chassisMfg = cqo.Vehicle_Manufacturer__c;
        wheelbase = cqo.Wheelbase__c;
        veh.ChassisMfg__c = chassisMfg;
        veh.Wheelbase__c = wheelbase;
    }

    
    // removeChassis
    //---------------------------------------
    public void removeChassis() {
        List<VehicleInventory_CommercialOption__c> co = [
            select Id, OptionType__c 
            from VehicleInventory_CommercialOption__c
            where VehicleInventory__c=:veh.Id and OptionType__c='Chassis Options'
        ];
        if (co.size()>0) delete(co);
        dealer__Vehicle_Inventory__c vehInv = new dealer__Vehicle_Inventory__c(
            Id=veh.Id, ChassisMfg__c=null, Wheelbase__c=null
        ); 
        veh.ChassisMfg__c=null;
        veh.Wheelbase__c=null;
        chassisMfg = null;
        wheelbase = null;
        update(vehInv);
        refreshVehicleOptions();
    }
    
    // removeNonChassisOptions
    //---------------------------------------
    public void removeNonChassisOptions() {
        List<VehicleInventory_CommercialOption__c> co = [
            select Id, OptionType__c 
            from VehicleInventory_CommercialOption__c
            where VehicleInventory__c=:veh.Id and OptionType__c<>'Chassis Options'
        ];
        if (co.size()>0) delete(co); 
        refreshVehicleOptions();
    }


    public void editQuantities() {
        changeQuantities = true;
    }
    
    public void saveChanges() {
        changeQuantities = false;
        List<VehicleInventory_CommercialOption__c> updVico = new List<VehicleInventory_CommercialOption__c>();
        for(VehicleInventory_CommercialOption__c c : vehicleOptions) {
            System.debug('Id=' + c.Id + ', new qty=' + String.valueOf(c.Quantity__c));
            updVico.add(new VehicleInventory_CommercialOption__c(Id=c.Id, Quantity__c=c.Quantity__c));
        }
        if (updVico.size()>0) {
            System.debug(String.valueOf(updVico.size()));
            update(updVico);
        }
    }
    
    public void cancelChanges() {
        changeQuantities = false;
        refreshVehicleOptions();
    }
    

    // noaction
    //---------------------------------------
    public void noaction() {}


	// BLL1a
    // getCommercialQuotes
    //-----------------------------------------
    public List<CommercialQuote__c> getCommercialQuotes() {
        List<CommercialQuote__c> opts = new List<CommercialQuote__c>();
        Integer cqLimit = 10;
        Integer cqOffset = 0;

        String fieldlist = 'Id, Name, UnitNumber__c, Customer__c, QuoteType__c, TypeOfSale__c, Delivery_Date__c, Salesperson__c, VIN__c ';
        String fromobj = 'CommercialQuote__c ';
        String selection = '';
        String junct = 'where ';
        
        if (!String.isBlank(unitnumber)) {
        	selection += junct + 'UnitNumber__c=:unitNumber ';
        	junct = ' and ';
        }
        if (!String.isBlank(VIN)) {
        	selection += junct + 'VIN__c=:VIN ';
        	junct = ' and ';
        }

        String orderby = 'order by Delivery_Date__c desc';
        String limits = 'limit ' + String.valueOf(cqLimit) + ' ' 
            + 'offset ' + String.valueOf(cqOffset) + ' ';

        // SOQL 
        String soql = 'select ' + fieldlist + ' from ' + fromobj + ' ' + selection + ' ' + orderby + ' ' + limits;
        System.debug(soql);
        try {
        	opts = Database.query(soql);
        } catch(Exception e) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        
        return opts;
    }

	// addQuoteOptions
	//-----------------------------
	public void addQuoteOptions() { 
		System.debug(quoteToUse);
		List<CommercialQuote__c> cqlist = [select Id, Name,  Chassis_MFG__c, Chassis_Wheelbase__c,  
			Chassis__c, Chassis__r.Name, Chassis_Cost__c, Chassis_Description__c, Chassis_Price__c, Chassis_QTY__c, 
				( select Id, Commercial_Quote_Options__c, Commercial_Quote_Options__r.Name, RecordTypeName__c, Quantity__c, Cost__c, Selling_Price__c, Description__c, Line_Type__c
				  from Commercial_Quote_Lines__r
				)
			from  CommercialQuote__c
			where Id=:quoteToUse
		];
		if (cqlist.size()<1) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Could not retrieve commercial quote'));
			return;
		}
		CommercialQuote__c cq = cqlist[0];
		
		// set of options on the quote (used to match up with options already on the vehicle)
		List<VehicleInventory_CommercialOption__c> addOptions = new List<VehicleInventory_CommercialOption__c>(); 
		Set<Id> quoteoptions = new Set<Id>();
		if (cq.Chassis__c!=null) { 
			quoteoptions.add(cq.Chassis__c);
			System.debug(cq.Id);
			System.debug(cq.Chassis__c);
			addOptions.add(new VehicleInventory_CommercialOption__c(
				VehicleInventory__c=veh.Id, CommercialQuoteOption__c=cq.Chassis__c,
				Name=cq.Chassis__r.Name, 
				Quantity__c=cq.Chassis_QTY__c, Cost__c=cq.Chassis_Cost__c, SellingPrice__c=cq.Chassis_Price__c,
				OptionType__c='Chassis Options', Description__c=cq.Chassis_Description__c
			));
		}
		for(CommercialQuoteLine__c l : cq.Commercial_Quote_Lines__r) {
			if (l.Commercial_Quote_Options__c!=null) {
				quoteoptions.add(l.Commercial_Quote_Options__c);
				System.debug(l.Id);
				System.debug(l.Commercial_Quote_Options__c);
				addOptions.add(new VehicleInventory_CommercialOption__c(
					VehicleInventory__c=veh.Id, CommercialQuoteOption__c=l.Commercial_Quote_Options__c,
					Name=l.Commercial_Quote_Options__r.Name, 
					Quantity__c=l.Quantity__c, Cost__c=l.Cost__c, SellingPrice__c=l.Selling_Price__c,
					OptionType__c=l.Line_Type__c, Description__c=l.Description__c
				));
			}
		}
		
		List<VehicleInventory_CommercialOption__c> dltOptions = new List<VehicleInventory_CommercialOption__c>();
		for (VehicleInventory_CommercialOption__c vico : vehicleOptions) {
			if (quoteoptions.contains(vico.CommercialQuoteOption__c)) {
				dltOptions.add(new VehicleInventory_CommercialOption__c(Id=vico.Id));
			}
		}
		if (dltOptions.size()>0) delete(dltOptions);
		
		// Now add all the options from the vehicle
		if (addOptions.size()>0) {
			insert(addOptions);
			dealer__Vehicle_Inventory__c updVeh = new dealer__Vehicle_Inventory__c(Id=veh.Id, AcquiredByQuote__c=cq.Id);
			update(updVeh);
			veh.AcquiredByQuote__c = cq.Id;
		} 
	}
    // BLL1a end
    
    // CommercialOptionWrapper
    public class CommercialOptionWrapper {
        public boolean onVehicle {get;set;}
        public Id Id {get;set;}
        public String Name {get;set;}
        public String Description {get;set;}
        public Decimal Cost {get;set;}
        public Decimal Price {get;set;}
        public String ChassisMfg {get;set;}
        public String Wheelbase {get;set;}
        public String Note {get;set;}
        public CommercialOptionWrapper(Commercial_Quote_Options__c o, boolean onVeh) {
            this.Id = o.Id;
            this.Name = o.Name;
            this.Description = o.Description__c;
            this.Cost = o.Cost__c;
            this.Price = o.Selling_Price__c;
            this.Note = o.Internal_Note__c;
            this.onVehicle = onVeh; 
            this.ChassisMfg = o.Vehicle_Manufacturer__c;
            this.Wheelbase = o.Wheelbase__c;
        }
    }
    
 }