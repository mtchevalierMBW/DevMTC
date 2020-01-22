/**
 * VehicleAdvancedSearch
 * Used in VehicleSearchAdvanced.page
 * Tested by: VehicleAdvancedSearch_TC
 *
 *	Coverage:
 *	2018-04-18	90% (406/450)
 *	2018-06-01	87% (415/477)
 *	2018-08-17	83% (419/500)
 *
 *  Date        Programmer  Description
 *  2015-08-24  B. Leaman   BLL1 - fix status selection
 *  2015-08-27  B. Leaman   BLL2 - Allow search to work with no location on user
 *  2015-08-27  J. Kuljis   JVK1 - Year picklist to be current year +1 (Some vehicles model year may be greater than the current year) minus 15
 *  2015-09-08  B. Leaman   BLL3 - query was omiting ramp location and kneeling
 *  2015-09-21  J. Gordon   JG: adding New_Used_Other field (in progress, not complete)
 *  2015-09-23  B. Leaman   BLL4 - Change field used for suggested retail price
 *  2015-10-13  B. Leaman   BLL5 - Fix veh type query - change dealer__Vehicle_Type__c to Unit_Type__c.
 *  2016-02-02  B. Leaman   BLL6 IT#19480 - Set the "Makes" drop-down initially and retain. I think we should query the database rather than use an explicit list.
 *  2016-02-24  B. Leaman   BLL7 IT#20851 - Add Fleet to New/Used/Other drop-down selections. 
 *  2016-03-22  RedTeal     RT1  - Added logic to deal with an advanced search request from a commercial quote
 *  2016-03-23  B. Leaman   BLL8 - Handle incoming division selection default; add division, year range, multiple regions, multiple stores;
 *                          add floor type and floor cut selection options;
 *  2016-07-29  B. Leaman   BLL9 Use CurrentUserSingleton instead of SOQL.
 *  2016-08-23  B. Leaman   BLL10 IT#29752 add VIN to result table; IT#27819 add VIN to search criteria; 
 *  2016-09-06  Sneha       W-000525 Add Status Check button functionality
 *  2016-10-03  MarinerTek  Added logic to search by Featured Van, BLL11 remove rendertablebool, fix logic for sosl
 *  2017-02-07  B. Leaman   BLL11 - Return to default page for proposal rather than specifically the QuoteManager page.
 *  2017-07-19  B. Leaman   BLL12 - Handle missing lat/lng for user's location. 
 *  2017-09-14 T. Kauffman  1209 - Status Check Error Report Button
 *  2017-09-20  B. Leaman   BLL13 - No need to query commercial quotes anymore.
 *	2018-04-18	B. Leaman	BLL14 - Re-instate SOSL version of query when "Search All" text box is used; add tracking & base color fields to results;
 *	2018-06-01	B. Leaman	BLL15 - Re-instate status check error report functionality accidentally broke with BLL14.
 *	2018-08-17	B. Leaman	BLL16 - LEX: new select method to assign vehicle to sobject the lookup started from
 *  2019-04-19  A. Miller   AMM17 - W-000646 - Update to handle sorting oldest vehicles in inventory before showing results.
 *  2019-04-19  A. Miller   AMM14 - W-000657 - Update to let Featured Vans to be multiselect
 *	2019-10-10	B. Leaman	W-000766 BLL17 - New flag on location & formula on vehicle to restrict stores' vehicles to their own location.
 *							This is intended as a short-term intervention when new stores are onboarded.
 *	2019-10-29	B. Leaman	W-000772 BLL18 - handle incomplete "Make" so that Mercedes also matches Mercedes-Benz.
*/
 public with sharing class VehicleAdvancedSearch {


    public Boolean debugmode {get;set;}
    
    public String proposalId {get;set;}
    //public Boolean commercialQuote {get; set;}//RT1
    //public String commercialQuoteId {get; set;}//RT1

    public String stockNum { get; set; }
    //BLL8d public String vehType { get; set; }
    public List<String> vehType {get;set;}  // BLL8a
    //BLL8d public String year { get; set; }
    public List<String> year {get;set;} // BLL8a
    //BLL8d public String make { get; set; }
    public List<String> make {get;set;} // BLL8a
    public String searchAll {get; set;}
    public String model { get; set; }
    public String trim { get; set; }
    public String recordType { get; set; }
    public Integer minPrice { get; set; }
    public Integer maxPrice { get; set; }
    public Integer minOdometer { get; set; }
    public Integer maxOdometer { get; set; }
    public String convMfg { get; set; }
    public String convModel { get; set; }
    public String minConv { get; set; }
    public String maxConv { get; set; }
    public String minChassis { get; set; }
    public String maxChassis { get; set; }
    //BLL8d public String storeLocation { get; set; }
    public List<String> storeLocation {get;set;}    // BLL8a
    //BLL8d public String region { get; set; }
    public List<String> region {get;set;}   // BLL8a
    public String rampType { get; set; }
    public String rampOperation { get; set; }
    public String extColor { get; set; }
    public String intColor { get; set; }
    public String interior { get; set; }
    public String rampLoc { get; set; }
    public String kneel { get; set; }
    //BLL8d public String status { get; set; }
    public List<String> status {get;set;}   // BLL8a
    //BLL8d public String newUsedOther { get; set; }
    public List<String> newUsedOther {get;set;} // BLL8a
    public List<SelectOption> Makes {get;private set;} // BLL6a
    public String businessDivision {get;set;} // BLL8a 
    public List<SelectOption> DivisionOptions {get;private set;} // BLL8a
    private boolean lockDivision; // BLL8a
    public List<SelectOption> newUsedOtherOptions {get;private set;} // BLL8a
    private boolean lockNewUsedOther; // BLL8a
    public String floortype {get;set;}  // BLL8a
    public String floorcut {get;set;}   // BLL8a
    public String VIN {get;set;}    // BLL10a
	// AMM14
    //public String FeaturedVan {get; set;}
    public List<String> FeaturedVan {get; set;}
	// AMM14
    public List<SelectOption> FeatVanOptions {get; set;}
    private boolean lockFeatVan {get; set;}
    
    // BLL11d public boolean RenderTableBool {get; set;}
    public String filter {get;set;}
    public string todaysDate{get;set;}
    private List<User> user {get;set;}
    private String userLocKey {get;set;}
    private dealer__Dealer_Location__c userLoc {get;set;}
    private Double userLocLat {get;set;}
    private Double userLocLng {get;set;}
    public Boolean statusCheckBoolean{get;set;}
    public Boolean statusCheckErrorReportBoolean{get;set;} //1209

    private Boolean renderList1{get;set;}
    private Boolean renderList2{get;set;}
    
    //1223 start TK
    public List<dealer__Vehicle_Inventory__c> vehResult {get; set;}
   // public static integer maxRows { get; set; }
    //static string query = 'SELECT Id, Name, New_Used_Other__c, RecordType.Name, dealer__Year__c, dealer__Make__c, dealer__Model__c,dealer__Trim_Level__c, dealer__Mileage__c, dealer__Exterior_Color__c ,Conv_MFG__c, Conversion_Model__c, dealer__Store_Location__r.Name, '
    //+ 'dealer__Retail_Price__c, Conversion_Cost__c, dealer__Vehicle_Cost__c, Total_Vehicle_Cost__c, Suggested_Retail_Price__c, dealer__Status_Code__c, dealer__Stock_Number__c, location_region__c, dealer__Vehicle_Type__c, dealer__Interior_Color__c, '
    //+ 'Interior__c, Ramp_Location__c, MV_Ranp_Operation__c, MV_Ramp_Type__c, dealer__Coded_Cost__c, dealer__Days_in_Stock__c, SuggestedRetailPrice__c, AcquiredByQuote__c,AcquiredByQuote__r.Name,AcquiredByQuote__r.Customer__r.Name,AcquiredByQuote__r.Customer__c, AcquiredByQuote__r.Status__c, AcquiredByQuote__r.Delivery_Date__c,'
    //        + 'FloorType__c, FloorCut__c, Division__c, FeaturedVan__c, dealer__VIN__c, '   // BLL8a, BLL10c add VIN
    //        + '(select id,Name,dealer__Delivery_Date__c,dealer__Status__c,dealer__Buyer__c,dealer__Buyer__r.Name,Proposed_Delivery_Date__c from dealer__R00N70000002II35EAG__r WHERE dealer__Status__c != \'Pending\' AND dealer__Status__c != \'Lost\' order by createdDate desc limit 1) '
    //        + 'FROM dealer__Vehicle_Inventory__c';
    private String resultFields = 'Id, Name, New_Used_Other__c, RecordType.Name, dealer__Year__c, dealer__Make__c, dealer__Model__c,dealer__Trim_Level__c, dealer__Mileage__c, dealer__Exterior_Color__c ,Conv_MFG__c, Conversion_Model__c, dealer__Store_Location__r.Name, '
		+ 'dealer__Retail_Price__c, Conversion_Cost__c, dealer__Vehicle_Cost__c, Total_Vehicle_Cost__c, Suggested_Retail_Price__c, dealer__Status_Code__c, dealer__Stock_Number__c, location_region__c, dealer__Vehicle_Type__c, dealer__Interior_Color__c, '
		+ 'Interior__c, Ramp_Location__c, MV_Ranp_Operation__c, MV_Ramp_Type__c, dealer__Coded_Cost__c, dealer__Days_in_Stock__c, SuggestedRetailPrice__c, AcquiredByQuote__c,AcquiredByQuote__r.Name,AcquiredByQuote__r.Customer__r.Name,AcquiredByQuote__r.Customer__c, AcquiredByQuote__r.Status__c, AcquiredByQuote__r.Delivery_Date__c,'
		+ 'FloorType__c, FloorCut__c, Division__c, FeaturedVan__c, dealer__VIN__c, Tracking__c, Exterior_Base_Color__c, '	// BLL14a  
		+ ' (select id,Name,dealer__Delivery_Date__c,dealer__Status__c,dealer__Buyer__c,dealer__Buyer__r.Name,Proposed_Delivery_Date__c from dealer__R00N70000002II35EAG__r WHERE dealer__Status__c != \'Pending\' AND dealer__Status__c != \'Lost\' order by createdDate desc limit 1) ';	// BLL14a 
	public String finalQuery {get;private set;}
	public Set<Id> vehIds;	// BLL14a
	public String vehidstr {get;set;}	// BLL16a
		
            public VehicleAdvancedSearch() {

                vehResult = new List<dealer__Vehicle_Inventory__c>();
                renderList1 = false;
                renderList2 = false;
                todaysDate=DateTime.newInstance(
                    date.today().year(),  date.today().month(),  date.today().day()
                    ).format('MM/dd/YYYY');

                statusCheckBoolean = false;
        statusCheckErrorReportBoolean = false;//1209
        
        debugmode = false;
        //SOSLmode = false;

        //BLL8d if ( status == null || status == '') {
            // status = 'Ready for Sale';
        //BLL8d }
        status = new List<String>();    // BLL8a
        status.add('Ready For Sale');   // BLL8a
        vehType = new List<String>();   // BLL8a

        // Setup user location for filtering
        String userId = UserInfo.getUserId();
        //BLL9d userLocKey = [SELECT Division FROM User WHERE Id =: userId LIMIT 1].Division;

        User ur = [SELECT id, UserRole.Name FROM USER WHERE id =: userId ];
        String userRole = ur.UserRole.Name;
        system.debug(userRole);



        User u = CurrentUserSingleton.getInstance();    // BLL9a
        userLocKey = u.Division;    // BLL9a

        if(userLocKey==null) {
            userLocKey = 'AKR';
        }

        try { // BLL2a
            userLoc = [SELECT Id, Name, dealer__Physical_Location__Latitude__s, dealer__Physical_Location__Longitude__s, Region__c FROM dealer__Dealer_Location__c WHERE dealer__Company_Number__c =: userLocKey LIMIT 1];
        } catch(Exception e) {  // BLL2a
           userLoc = new dealer__Dealer_Location__c(Name='Richfield, OH', dealer__Physical_Location__Latitude__s=41.22319, dealer__Physical_Location__Longitude__s=-81.63699, Region__c='0');  // BLL2a
        }  // BLL2a

        userLocLat = userLoc.dealer__Physical_Location__Latitude__s;
        userLocLng = userLoc.dealer__Physical_Location__Longitude__s;

        // Set default region to logged in user
        region = new List<String>();    // BLL8a
        if ( userLoc.Region__c != null && userLoc.Region__c != '') {
            //BLL8d region = userLoc.Region__c;
            region.add(userLoc.Region__c);  // BLL8a
        }

        storeLocation = new List<String>(); // BLL8a
        //BLL8d if(storeLocation == null || storeLocation =='') {
        //BLL8d     storeLocation = userLoc.Name;
        //BLL8d }
        if (!String.isBlank(userLoc.Name)) storeLocation.add(userLoc.Name); // BLL8a

        System.debug('Lat: '+userLocLat+' - Lng: '+userLocLng);

        if(ApexPages.currentPage().getParameters().get('proposalId')!=null) {
            proposalId = ApexPages.currentPage().getParameters().get('proposalId');
        }

        ////RT1
        //if(ApexPages.currentPage().getParameters().get('cq') != null) {
        //    commercialQuote = true;
        //    if(ApexPages.currentPage().getParameters().get('quoteId') != null) {
        //        commercialQuoteId = ApexPages.currentPage().getParameters().get('quoteId');
        //    }
        //    else {
        //        commercialQuoteId = '';
        //    }
        //}
        //else {
        //    commercialQuote = false;
        //}
        //end RT1

        // BLL8a
        lockDivision=false;
        if (ApexPages.currentPage().getParameters().get('division')!=null) {
            businessDivision = ApexPages.currentPage().getParameters().get('division');
            lockDivision = !String.isBlank(businessDivision);
        } 
        newUsedOther = new List<String>();
        lockNewUsedOther=false;
        if (ApexPages.currentPage().getParameters().get('newusedother')!=null) {
            newUsedOther.add(ApexPages.currentPage().getParameters().get('newusedother'));
            lockNewUsedOther = true;
        }
        // BLL8a end  
        
        //*****************************************************************************
        lockFeatVan =false;
        if (ApexPages.currentPage().getParameters().get('featuredvan')!=null) {
            // AMM14
			//FeaturedVan = ApexPages.currentPage().getParameters().get('featuredvan');
            //lockFeatVan = !String.isBlank(FeaturedVan);
			FeaturedVan.addAll(ApexPages.currentPage().getParameters().get('featuredvan').split(','));
			lockFeatVan = FeaturedVan.size()>0;
			// AMM14
        } 
        newUsedOther = new List<String>();
        lockNewUsedOther=false;
        if (ApexPages.currentPage().getParameters().get('newusedother')!=null) {
            newUsedOther.add(ApexPages.currentPage().getParameters().get('newusedother'));
            lockNewUsedOther = true;
        }
        //*****************************************************************************

        year = new List<String>();  // BLL8a
        make = new List<String>();  // BLL8a
		FeaturedVan = new List<String>();	// AMM14
        // Auto populate search fields
        if(ApexPages.currentPage().getParameters().get('searchAll')!=null) {
            searchAll = ApexPages.currentPage().getParameters().get('searchAll');
        }
        if(ApexPages.currentPage().getParameters().get('year')!=null) {
            //BLL8d year = ApexPages.currentPage().getParameters().get('year');
            year.add(ApexPages.currentPage().getParameters().get('year'));  // BLL8a
        }
        if(ApexPages.currentPage().getParameters().get('make')!=null) {
            //BLL8d make = ApexPages.currentPage().getParameters().get('make');
            make.add(ApexPages.currentPage().getParameters().get('make'));  // BLL8a
        }
        if(ApexPages.currentPage().getParameters().get('model')!=null) {
            model = ApexPages.currentPage().getParameters().get('model');
        }

        if ( ApexPages.currentPage().getParameters().get('year')!='' || ApexPages.currentPage().getParameters().get('make')!='' || ApexPages.currentPage().getParameters().get('model')!='' ) {
            doSearch();

        }

        // Check to see if we are running in Debug mode (displays SQL Statement)
        if( ApexPages.currentPage().getParameters().get('debug')=='true') {
            debugmode=true;
        }

        Makes = MakesDropDown(); // BLL6a
        divisionOptions = DivisionDropDown(); // BLL8a
        FeatVanOptions = FeaturedVanDropDown(); 
    }

    public PageReference reset() {
        PageReference page = new PageReference(System.currentPageReference().getURL());
        page.setRedirect(true);
        return page;
    }

// BLL16a
	public PageReference selectVehicle() {
		System.debug('selectVehicle');
		for(String k : ApexPages.CurrentPage().getParameters().keySet()) {
			System.debug(k + '=' + ApexPages.CurrentPage().getParameters().get(k));
		}
		//Id docid = (Id) ApexPages.CurrentPage().getParameters().get('proposalId');
		//Id vehid = (Id) ApexPages.CurrentPage().getParameters().get('vehidstr');
		System.debug(proposalId);
		System.debug(vehidstr);
		Id docid = (Id) proposalId;
		Id vehid = (Id) vehidstr;
		System.debug(docid);
		System.debug(vehid);

		Map<String,String> objfldmap = new Map<String,String>{
			'dealer__Deal__c'=>'dealer__Vehicle__c',
			'CommercialQuote__c'=>'VehicleInventory__c'
		};
		Schema.SObjectType objType = docId.getSObjectType();
		Schema.DescribeSObjectResult dsr = objType.getDescribe();
		SObject obj = objType.newSObject();
		obj.Id = docid;
/**
		String fldname = objfldmap.get(dsr.getName());
		if (!String.isBlank(fldname)) obj.put(fldname, vehid);
		try {
			update(obj);
		} catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: ' + e.getMessage()));
			return null;
		}
**/
		ApexPages.StandardController ctl = new ApexPages.StandardController(obj);
		PageReference rtnTo = ctl.view();
		
		if (dsr.getName()=='dealer__Deal__c') rtnTo = Page.DealMBW2;
		rtnTo.getParameters().put('id',proposalId);
		rtnTo.getParameters().put('v',vehId);		
		rtnTo.setRedirect(true);
		System.debug('return from selectVehicle: ' + vehId);
		System.debug(rtnTo.getURL());
		return rtnTo;
	}
// BLL16a end

//    public String getQueryString() {
//   //     return buildQuery(false);   // BLL11c  
//   return null; 
//}

//public Boolean getRendered1() {
//    return renderList1;
//}

//public Boolean getRendered2() {
//    return renderList2;
//}

// BLL14a - modularize and re-instate SOSL option
public String buildSelection() {
	List<String> filterFields = new List<String>();

		// BLL17
		if (!Utility.hasCustompermission('Search_All_Inventory')) filterFields.add(' Restricted_from_View__c = false ');
		// BLL17 end

        filterFields.add(' RecordType.Name != \'Archived\' AND RecordType.Name != \'Vehicle Template\'');
        // Build Query Bits
        //BLL8d if(year != '' && year != null) { 
        //BLL8d     filterFields.add(' dealer__Year__c LIKE \'%' +year+ '%\'' );
        //BLL8d }
		if (year.size()>0) filterFields.add(' dealer__Year__c in (\'' + String.join(year, '\', \'') + '\') '); // BLL8a

        //BLL8d if(make != '' && make != null) { 
        //BLL8d     filterFields.add(' dealer__Make__c LIKE \'%' +make+ '%\'' );
        //BLL8d }   
		// BLL18
		//if (make.size()>0) filterFields.add(' dealer__Make__c in (\'' + String.join(make, '\', \'') + '\') '); // BLL8a
		if (make.size()>0) {
			String makeselector = '';
			String junction = ' (';
			for(String m : make) {
				makeselector += junction + ' dealer__Make__c LIKE \'%' + m + '%\' ';
				junction = ' or ';
			}
			makeselector += ' )';
			filterFields.add(makeselector);
		}
		// BLL18 end

		if(!String.isBlank(model)) filterFields.add(' dealer__Model__c LIKE  \'%' +model+ '%\'' );
		if(!String.isBlank(trim)) filterFields.add(' dealer__Trim_Level__c LIKE  \'%' +trim+ '%\'' );

        //BLL8d if(region != '' && region != null && region != 'All') { 
        //BLL8d     filterFields.add(' location_region__c = \'' +region+ '\'' );
        //BLL8d }
		if (region.size()>0) filterFields.add(' location_region__c in (\'' + String.join(region, '\', \'') + '\') ');  // BLL8a

        //BLL8d if(storeLocation != ''  && storeLocation != null && storeLocation != 'All') { 
        //BLL8d    filterFields.add(' dealer__Store_Location__r.Name LIKE  \'%' +storeLocation+ '%\'' );
        //BLL8d }  
		if (storeLocation.size()>0) filterFields.add(' dealer__Store_Location__r.Name in (\'' + String.join(storeLocation, '\', \'') + '\') ');    // BLL8a

        //BLL8d if(vehType != ''  && vehType != null && vehType != 'All') { 
            //BLL5d filterFields.add(' dealer__Vehicle_Type__c = \'' +vehType+ '\'' );
        //BLL8d     filterFields.add(' Unit_Type__c = \'' +vehType+ '\'' );  // BLL5a
        //BLL8d }
		if (vehType.size()>0) filterFields.add(' Unit_Type__c  in (\'' + String.join(vehType, '\', \'') + '\') '); // BLL8a

        // RecordType
		if(!String.isBlank(recordType) && recordType!='All') filterFields.add(' RecordType.Name = \''+recordType+'\' ');

        // New_Used_Other
        //BLL8d if(newUsedOther != '' && newUsedOther != null && newUsedOther != 'All') {
            // BLL8d commercial quote stuff - handle differently via parm coming in to page! 
            //if(commercialQuote) { //RT1 - only get commercial vehicles from commercial quote request
            //    filterFields.add(' New_Used_Other__c = \'Commercial\' ');
            //}
            //else {
        //BLL8d        filterFields.add(' New_Used_Other__c = \''+newUsedOther+'\' ');
            //}
        //BLL8d }
		if (newUsedOther.size()>0) filterFields.add(' New_Used_Other__c  in (\'' + String.join(newUsedOther, '\', \'') + '\') ');  // BLL8a
        
		// BLL8a
		if (!String.isBlank(businessDivision) && businessDivision!='All') filterFields.add(' Division__c = \'' + businessDivision + '\' ');
        
		// AMM14
		//if(!String.isBlank(FeaturedVan) && FeaturedVan != 'All') filterFields.add(' FeaturedVan__c = \'' + FeaturedVan + '\' ');
		if (FeaturedVan.size()>0) filterFields.add(' FeaturedVan__c in (\'' + String.join(FeaturedVan, '\', \'') + '\') '); 
		// AMM14
        
		// retail Price (numeric)
		if(minPrice != null && minPrice != 0) filterFields.add(' SuggestedRetailPrice__c >= '+ minPrice +' ' );  // BLL4c  
			// BLL4d filterFields.add(' dealer__Retail_Price__c >= '+ minPrice +' ' );

		if(maxPrice != null && maxPrice != 0) filterFields.add(' SuggestedRetailPrice__c <= '+ maxPrice +' ' );  // BLL4c 
			// BLL4d filterFields.add(' dealer__Retail_Price__c <= '+ maxPrice +' ' );

		/** Advanced Fields **/

		if(!String.isBlank(extColor)) filterFields.add(' (dealer__Exterior_Color__c LIKE  \'%' +extColor+ '%\' or Exterior_Base_Color__c LIKE \'%' + extColor + '%\')' );	// BLL14c add base color
		if(!String.isBlank(intColor)) filterFields.add(' dealer__Interior_Color__c LIKE  \'%' +intColor+ '%\'' );
		if(!String.isBlank(interior) && interior != 'All') filterFields.add(' Interior__c =  \'' +interior+ '\'' );

		// Mileage (numeric)
		if(minOdometer != null && minOdometer != 0) filterFields.add(' dealer__Mileage__c >= '+ minOdometer +' ' );
		if(maxOdometer != null && maxOdometer != 0) filterFields.add(' dealer__Mileage__c <= '+ maxOdometer +' ' );

		// Conversion
		if(!String.isBlank(convMfg) && convMfg != 'All') filterFields.add(' Conv_MFG__c LIKE \'%' +convMfg+ '%\'' );
		if(!String.isBlank(convModel) && convModel != 'All') filterFields.add(' Conversion_Model__c LIKE  \'%' +convModel+ '%\'' );
		if(!String.isBlank(rampType) && rampType != 'All') filterFields.add(' MV_Ramp_Type__c =  \'' +rampType+ '\'' );
		if(!String.isBlank(rampOperation) && rampOperation != 'All') filterFields.add(' MV_Ranp_Operation__c =  \'' +rampOperation+ '\'' );
		// BLL3a don't forget ramp location & kneeling
		if(!String.isBlank(rampLoc) && rampLoc!='All') filterFields.add(' Ramp_Location__c = \'' + rampLoc + '\'');
		if (!String.isBlank(kneel) && kneel=='Yes') filterFields.add(' (Kneeling__c = \'' + kneel + '\' or Kneeling__c = \'1\')');
		if (!String.isBlank(kneel) && kneel=='No')  filterFields.add(' (Kneeling__c = \'' + kneel + '\' or Kneeling__c = \'0\')');

        // Conversion COST (numeric)
        if(minConv != '' && minConv != null) filterFields.add(' Conversion_Cost__c >= '+ minConv +' ' );
        if(maxConv != '' && maxConv != null) filterFields.add(' Conversion_Cost__c <= '+ maxConv +' ' );

        // Chassis COST (numeric)
        if(minChassis != '' && minChassis != null) filterFields.add(' dealer__Vehicle_Cost__c >= '+ minChassis +' ' );
        if(maxChassis != '' && maxChassis != null) filterFields.add(' dealer__Vehicle_Cost__c <= '+ maxChassis +' ' );

        if (status.size()>0) filterFields.add(' dealer__Status_Code__c in (\'' + String.join(status, '\', \'') + '\') ');  // BLL8a     

        if (status.size()==0) filterFields.add(' dealer__Status_Code__c != \'Delivered\'' );   // BLL8a

        if (!String.isBlank(floortype) && floortype!='All') filterFields.add(' FloorType__c = \'' + floortype + '\' ');
        if (!String.isBlank(floorcut) && floorcut!='All') filterFields.add(' FloorCut__c = \'' + floorcut + '\' ');

        if (!String.isBlank(VIN)) filterFields.add(' dealer__VIN__c like \'%' + VIN + '%\'');
        
        // StockNumber Trumps All
        if(stockNum != '' && stockNum != null) { 
            filterFields.clear();
            filterFields.add(' dealer__Stock_Number__c LIKE \'%' +stockNum+ '%\'' );
        }  
	return String.join(filterFields, ' AND ');
}

public String resultSequence() {
	system.debug('userLoc '+userLoc+' userLong '+userLocLng + ' userLat '+userLocLat);
	string sequence = '';
	if(userLoc!=null && userLocLat!=null && userLocLng!=null  && !statusCheckBoolean && !statusCheckErrorReportBoolean) {  // BLL12c check userLocLat & userLocLng
		// AMM17
        //sequence = ' ORDER BY DISTANCE(dealer__Store_Location__r.dealer__Physical_Location__c, GEOLOCATION('+userLocLat+','+userLocLng+'), \'mi\') ASC  ';    // BLL sort ascending, not descending! Doh!
        sequence = ' ORDER BY DISTANCE(dealer__Store_Location__r.dealer__Physical_Location__c, GEOLOCATION('+userLocLat+','+userLocLng+'), \'mi\') ASC, dealer__Days_in_Stock__c DESC NULLS LAST ';    // BLL sort ascending, not descending! Doh!
        // AMM17
    } 

	if (statusCheckBoolean || statusCheckErrorReportBoolean){
        // AMM17
		//sequence = ' ORDER BY dealer__Status_Code__c asc LIMIT 5000 ';
        sequence = ' ORDER BY dealer__Days_in_Stock__c DESC, dealer__Status_Code__c ASC NULLS LAST LIMIT 5000 ';  
        // AMM17
	} else {
        sequence += ' LIMIT 1000 ';
	}
	return sequence;
}      

public String buildSOSL() {
	String findtext = searchAll.replace( '\'', '\\\'' );
	return 'FIND \'' + findtext + '\' IN ALL FIELDS RETURNING dealer__Vehicle_Inventory__c (Id '
		+ (String.isBlank(filter) ? ' ' : ' Where ') + filter + ' ' + resultSequence() + ') ';	
}

public String buildSOQL() {
	return 'Select ' + resultFields + ' from dealer__Vehicle_Inventory__c '
		+ (String.isBlank(filter) ? '' : 'Where ') + filter + ' ' + resultSequence();	
}
// BLL14a end

public void vehicleSearch(/*boolean usesosl*/) {

        // BLL11d renderTableBool = true;
        //BLL14d List<String> filterFields = new List<String>();

/** BLL14d 
        filterFields.add(' RecordType.Name != \'Archived\' AND RecordType.Name != \'Vehicle Template\'');
        // Build Query Bits
        //BLL8d if(year != '' && year != null) { 
        //BLL8d     filterFields.add(' dealer__Year__c LIKE \'%' +year+ '%\'' );
        //BLL8d }
        if (year.size()>0) filterFields.add(' dealer__Year__c in (\'' + String.join(year, '\', \'') + '\') '); // BLL8a

        //BLL8d if(make != '' && make != null) { 
        //BLL8d     filterFields.add(' dealer__Make__c LIKE \'%' +make+ '%\'' );
        //BLL8d }   
        if (make.size()>0) filterFields.add(' dealer__Make__c in (\'' + String.join(make, '\', \'') + '\') '); // BLL8a

        if(model != '' && model != null) { 
            filterFields.add(' dealer__Model__c LIKE  \'%' +model+ '%\'' );
        }

        if(trim != '' && trim != null) { 
            filterFields.add(' dealer__Trim_Level__c LIKE  \'%' +trim+ '%\'' );
        }

        //BLL8d if(region != '' && region != null && region != 'All') { 
        //BLL8d     filterFields.add(' location_region__c = \'' +region+ '\'' );
        //BLL8d }
        if (region.size()>0) filterFields.add(' location_region__c in (\'' + String.join(region, '\', \'') + '\') ');  // BLL8a

        //BLL8d if(storeLocation != ''  && storeLocation != null && storeLocation != 'All') { 
        //BLL8d    filterFields.add(' dealer__Store_Location__r.Name LIKE  \'%' +storeLocation+ '%\'' );
        //BLL8d }  
        if (storeLocation.size()>0) filterFields.add(' dealer__Store_Location__r.Name in (\'' + String.join(storeLocation, '\', \'') + '\') ');    // BLL8a

        //BLL8d if(vehType != ''  && vehType != null && vehType != 'All') { 
            //BLL5d filterFields.add(' dealer__Vehicle_Type__c = \'' +vehType+ '\'' );
        //BLL8d     filterFields.add(' Unit_Type__c = \'' +vehType+ '\'' );  // BLL5a
        //BLL8d }
        if (vehType.size()>0) filterFields.add(' Unit_Type__c  in (\'' + String.join(vehType, '\', \'') + '\') '); // BLL8a

        // RecordType
        if(recordType != '' && recordType != 'All'  && recordType != null) { 
            filterFields.add(' RecordType.Name = \''+recordType+'\' ');
        }

        // New_Used_Other
        //BLL8d if(newUsedOther != '' && newUsedOther != null && newUsedOther != 'All') {
            // BLL8d commercial quote stuff - handle differently via parm coming in to page! 
            //if(commercialQuote) { //RT1 - only get commercial vehicles from commercial quote request
            //    filterFields.add(' New_Used_Other__c = \'Commercial\' ');
            //}
            //else {
        //BLL8d        filterFields.add(' New_Used_Other__c = \''+newUsedOther+'\' ');
            //}
        //BLL8d }
        if (newUsedOther.size()>0) filterFields.add(' New_Used_Other__c  in (\'' + String.join(newUsedOther, '\', \'') + '\') ');  // BLL8a
        
        // BLL8a
        if (!String.isBlank(businessDivision) && businessDivision!='All') {
            filterFields.add(' Division__c = \'' + businessDivision + '\' ');
        }
        // BLL8a end 
        
        if(!String.isBlank(FeaturedVan) && FeaturedVan != 'All'){
            filterFields.add(' FeaturedVan__c = \'' + FeaturedVan + '\' ');
        }
        
        // retail Price (numeric)
        if(minPrice != null && minPrice != 0) { 
            // BLL4d filterFields.add(' dealer__Retail_Price__c >= '+ minPrice +' ' );
            filterFields.add(' SuggestedRetailPrice__c >= '+ minPrice +' ' );  // BLL4a
        }

        if(maxPrice != null && maxPrice != 0) { 
            // BLL4d filterFields.add(' dealer__Retail_Price__c <= '+ maxPrice +' ' );
            filterFields.add(' SuggestedRetailPrice__c <= '+ maxPrice +' ' );  // BLL4a
        }

        //** Advanced Fields 

        if(extColor != ''  && extColor != null) { 
            filterFields.add(' dealer__Exterior_Color__c LIKE  \'%' +extColor+ '%\'' );
        }
        if(intColor != ''  && intColor != null) { 
            filterFields.add(' dealer__Interior_Color__c LIKE  \'%' +intColor+ '%\'' );
        }
        if(interior != ''  && interior != null && interior != 'All') { 
            filterFields.add(' Interior__c =  \'' +interior+ '\'' );
        }

        // Mileage (numeric)
        if(minOdometer != null && minOdometer != 0) { 
            filterFields.add(' dealer__Mileage__c >= '+ minOdometer +' ' );
        }

        if(maxOdometer != null && maxOdometer != 0) { 
            filterFields.add(' dealer__Mileage__c <= '+ maxOdometer +' ' );
        }

        // Conversion
        if(convMfg != '' && convMfg != null && convMfg != 'All') { 
            filterFields.add(' Conv_MFG__c LIKE \'%' +convMfg+ '%\'' );
        }

        if(convModel != '' && convModel != null && convModel != 'All') { 
            filterFields.add(' Conversion_Model__c LIKE  \'%' +convModel+ '%\'' );
        }

        if(rampType != ''  && rampType != null && rampType != 'All') { 
            filterFields.add(' MV_Ramp_Type__c =  \'' +rampType+ '\'' );
        }
        if(rampOperation != ''  && rampOperation != null && rampOperation != 'All') { 
            filterFields.add(' MV_Ranp_Operation__c =  \'' +rampOperation+ '\'' );
        }
        // BLL3a don't forget ramp location & kneeling
        if(!String.isBlank(rampLoc) && rampLoc!='All') {
            filterFields.add(' Ramp_Location__c = \'' + rampLoc + '\'');
        }
        if(!String.isBlank(kneel) && kneel!='All') {
            if (kneel=='Yes') {
                filterFields.add(' (Kneeling__c = \'' + kneel + '\' or Kneeling__c = \'1\')');
            }
            if (kneel=='No') {
                filterFields.add(' (Kneeling__c = \'' + kneel + '\' or Kneeling__c = \'0\')');
            }
        }

        // Conversion COST (numeric)
        if(minConv != '' && minConv != null) { 
            filterFields.add(' Conversion_Cost__c >= '+ minConv +' ' );
        }

        if(maxConv != '' && maxConv != null) { 
            filterFields.add(' Conversion_Cost__c <= '+ maxConv +' ' );
        }

        // Chassis COST (numeric)
        if(minChassis != '' && minChassis != null) { 
            filterFields.add(' dealer__Vehicle_Cost__c >= '+ minChassis +' ' );
        }

        if(maxChassis != '' && maxChassis != null) { 
            filterFields.add(' dealer__Vehicle_Cost__c <= '+ maxChassis +' ' );
        }

        if (status.size()>0) filterFields.add(' dealer__Status_Code__c in (\'' + String.join(status, '\', \'') + '\') ');  // BLL8a     

        if (status.size()==0) filterFields.add(' dealer__Status_Code__c != \'Delivered\'' );   // BLL8a

        if (!String.isBlank(floortype) && floortype!='All') filterFields.add(' FloorType__c = \'' + floortype + '\' ');
        if (!String.isBlank(floorcut) && floorcut!='All') filterFields.add(' FloorCut__c = \'' + floorcut + '\' ');

        if (!String.isBlank(VIN)) filterFields.add(' dealer__VIN__c like \'%' + VIN + '%\'');
        
        // StockNumber Trumps All
        if(stockNum != '' && stockNum != null) { 
            filterFields.clear();
            filterFields.add(' dealer__Stock_Number__c LIKE \'%' +stockNum+ '%\'' );
        }  

**/
        
        // Start building Query
        //query = queryStart;
        //1223 TK
        //BLL11d String finalQuery = query;
        
        //BLL11d if(filterFields.size() > 0){
            //BLL11d finalQuery += ' WHERE ' + String.join (filterFields, ' AND ');
            //BLL11d filter = String.join(filterFields, ' AND ');
        //BLL11d }

		/** moved to buildsoql & buildsosl routines
            system.debug('userLoc '+userLoc+' userLong '+userLocLng + ' userLat '+userLocLat);
            if(userLoc!=null && userLocLat!=null && userLocLng!=null  && !statusCheckBoolean && !statusCheckErrorReportBoolean) {  // BLL12c check userLocLat & userLocLng
                finalQuery += ' ORDER BY DISTANCE(dealer__Store_Location__r.dealer__Physical_Location__c, GEOLOCATION('+userLocLat+','+userLocLng+'), \'mi\') ASC  ';    // BLL sort ascending, not descending! Doh!
            } 

            if (statusCheckBoolean || statusCheckErrorReportBoolean){
                finalQuery+=' order by dealer__Status_Code__c asc LIMIT 5000 ';  
            }
            else{
                 finalQuery += 'LIMIT 1000';
                }
		**/
		
		filter = buildSelection();
		vehIds = new Set<Id>();
		if (!String.isBlank(searchAll)) {
        	String soslQuery = buildSOSL();
	        System.debug(soslQuery);
			List<List<SObject>> soslResult = Search.query(soslQuery);
			for(dealer__Vehicle_Inventory__c veh : (List<dealer__Vehicle_Inventory__c>) soslResult[0]) vehIds.add(veh.Id);
			// run SOQL over sosl results only
			filter = ' Id in :vehIds ';
		} 
        String finalQuery = buildSOQL();
        System.debug(finalQuery);
        vehResult = Database.query(finalQuery);

		//BLL15a - last change caused status check error report to stop working
		List<dealer__Vehicle_Inventory__c> statusCheckResult = new List<dealer__Vehicle_Inventory__c>();
		List<dealer__Vehicle_Inventory__c> statusCheckWholesaleResult = new List<dealer__Vehicle_Inventory__c>();
		Date today = date.today(); //1209
		Date cutoffDate = today.toStartOfMonth();//1209
		if(statusCheckErrorReportBoolean){
            for(dealer__Vehicle_Inventory__c v : vehResult) {
                // 1209 return any vehicle marked as 'not delivered' that have a proposed delivery date before today
                if(v.New_Used_Other__c != 'Wholesale'){  
                    if(v.dealer__Status_Code__c == 'Sold - Not Delivered' || v.dealer__Status_Code__c == 'Order - Sold Not Delivered' || v.dealer__Status_Code__c == 'In Transit - Sold Not Delivered'){
                        if(v.dealer__R00N70000002II35EAG__r.size()==0 ){ // BLL13d && v.Commercial_Quotes__r.size()==0 
                            statusCheckResult.add(v);
                        }
                        for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {    
                            if(d.Proposed_Delivery_Date__c != null && d.Proposed_Delivery_Date__c < cutoffDate)statusCheckResult.add(v);
                        }
                    }
                    //return any vehicle in a 'not sold' status that has a quote number
                    if(v.dealer__Status_Code__c == 'Not For Sale' || v.dealer__Status_Code__c == 'Order' || v.dealer__Status_Code__c == 'Ready for Sale'){
                     for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {
                         if (d.Name != Null) statusCheckResult.add(v);
                     }
                 }
             }
                //same features as above but to separate any type 'wholesale'
                if(v.New_Used_Other__c == 'Wholesale'){  
                    if(v.dealer__Status_Code__c == 'Sold - Not Delivered' || v.dealer__Status_Code__c == 'Order - Sold Not Delivered' || v.dealer__Status_Code__c == 'In Transit - Sold Not Delivered'){
                        if(v.dealer__R00N70000002II35EAG__r.size()==0 ){	// BLL13d && v.Commercial_Quotes__r.size()==0 
                            statusCheckWholesaleResult.add(v);
                        }
                        for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {    
                            if(d.Proposed_Delivery_Date__c != null && d.Proposed_Delivery_Date__c < cutoffDate)statusCheckWholesaleResult.add(v);
                        }
                    }
                    if(v.dealer__Status_Code__c == 'Not For Sale' || v.dealer__Status_Code__c == 'Order' || v.dealer__Status_Code__c == 'Ready for Sale'){
                        for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {
                            if (d.Name != Null) statusCheckWholesaleResult.add(v);
                        }
                    }
                }
            }
            // 1209 adding warranty results to end of statusCheckResult
            statusCheckResult.addAll(statusCheckWholesaleResult); 
            vehResult = statusCheckResult;

            //for(dealer__Vehicle_Inventory__c veh : vehResult) {
            //    myResults.add(new vehWrapper(veh));
            //}
            //return myResults;
		}
        //end 1209
		//BLL15a end

    }

    public String GetJSON
    {

        get {

            JsonResponse response = new JsonResponse();

            //BLl14d response.vehResult = getResults();
			vehicleSearch();	// BLl14a
			List<vehWrapper> resultList = new List<vehWrapper>();
			for(dealer__Vehicle_Inventory__c veh : vehResult) {
				resultList.add(new vehWrapper(veh));
			}

			response.vehResult = resultList;	// BLL14a
            response.total = vehResult.size();

            system.debug('response.vehresults: '+response);

            return JSON.Serialize(response);
        }
    }

    public class JsonResponse
    {
        Integer total;
        List<vehWrapper> vehResult;
    }
    
//1223 gwet
public class vehWrapper
{
    public dealer__Vehicle_Inventory__c vehicle {get;set;}
    public String Quote {get;set;}
    public String ProposedDeliveryDate {get;set;}
    public String CustomerName {get;set;}
    public String ProposalQuoteStatus {get;set;}
    public String QuoteId {get;set;}
    public Boolean errorCheckBool {get;set;}

    public vehWrapper(dealer__Vehicle_Inventory__c v)
    {

        // Iterate the nested values of the vehicle sub query into a String

        Quote = '';
        QuoteId='';
        ProposedDeliveryDate = '';
        CustomerName = '';
        ProposalQuoteStatus = '';
        vehicle=v;

        if(v.dealer__R00N70000002II35EAG__r != null){
            for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {

                Quote += d.Name; 
                QuoteId += d.Id;
                if(d.Proposed_Delivery_Date__c != null)
                ProposedDeliveryDate += String.valueOf(parseDate(d.Proposed_Delivery_Date__c));
                CustomerName += d.dealer__Buyer__r.Name ;
                ProposalQuoteStatus += d.dealer__Status__c;

            }
        }
    }
    public string parseDate(date d) {
     return DateTime.newInstance(
        d.year(), d.month(), d.day()
        ).format('MM/dd/YYYY');
 	}

}   



	public PageReference doSearch() {

        statusCheckBoolean = false;
        statusCheckErrorReportBoolean = false;//1209
        
        vehicleSearch();
        return null;
    }

/** BLL14d obsolete code
    public List<vehWrapper> getResults(){

        //W-000525 end
        List<List<SObject>> soslResult = new List<List<SObject>>();
        //vehResult = Database.query( buildQuery(false) );    // BLL11
        
        // Tyler K. 1209 to acquire correct result lines
        List<dealer__Vehicle_Inventory__c> statusCheckResult = new List<dealer__Vehicle_Inventory__c>();
        List<dealer__Vehicle_Inventory__c> statusCheckWholesaleResult = new List<dealer__Vehicle_Inventory__c>();
        List<vehWrapper> myResults = new List<vehWrapper>();

        //123
         date today = date.today(); //1209
         date cutoffDate = today.toStartOfMonth();//1209

         if(statusCheckErrorReportBoolean){
            for(dealer__Vehicle_Inventory__c v : vehResult) {
                // 1209 return any vehicle marked as 'not delivered' that have a proposed delivery date before today
                if(v.New_Used_Other__c != 'Wholesale'){  
                    if(v.dealer__Status_Code__c == 'Sold - Not Delivered' || v.dealer__Status_Code__c == 'Order - Sold Not Delivered' || v.dealer__Status_Code__c == 'In Transit - Sold Not Delivered'){
                        if(v.dealer__R00N70000002II35EAG__r.size()==0 ){ // BLL13d && v.Commercial_Quotes__r.size()==0 
                            statusCheckResult.add(v);
                        }
                        for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {    
                            if(d.Proposed_Delivery_Date__c != null && d.Proposed_Delivery_Date__c < cutoffDate)statusCheckResult.add(v);
                        }
                    }
                    //return any vehicle in a 'not sold' status that has a quote number
                    if(v.dealer__Status_Code__c == 'Not For Sale' || v.dealer__Status_Code__c == 'Order' || v.dealer__Status_Code__c == 'Ready for Sale'){
                     for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {
                         if (d.Name != Null) statusCheckResult.add(v);
                     }
                 }
             }
                //same features as above but to separate any type 'wholesale'
                if(v.New_Used_Other__c == 'Wholesale'){  
                    if(v.dealer__Status_Code__c == 'Sold - Not Delivered' || v.dealer__Status_Code__c == 'Order - Sold Not Delivered' || v.dealer__Status_Code__c == 'In Transit - Sold Not Delivered'){
                        if(v.dealer__R00N70000002II35EAG__r.size()==0 ){	// BLL13d && v.Commercial_Quotes__r.size()==0 
                            statusCheckWholesaleResult.add(v);
                        }
                        for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {    
                            if(d.Proposed_Delivery_Date__c != null && d.Proposed_Delivery_Date__c < cutoffDate)statusCheckWholesaleResult.add(v);
                        }
                    }
                    if(v.dealer__Status_Code__c == 'Not For Sale' || v.dealer__Status_Code__c == 'Order' || v.dealer__Status_Code__c == 'Ready for Sale'){
                        for(dealer__Deal__c d : v.dealer__R00N70000002II35EAG__r) {
                            if (d.Name != Null) statusCheckWholesaleResult.add(v);
                        }
                    }
                }
            }
            // 1209 adding warranty results to end of statusCheckResult
            statusCheckResult.addAll(statusCheckWholesaleResult); 
            vehResult = statusCheckResult;

            for(dealer__Vehicle_Inventory__c veh : vehResult) {
                myResults.add(new vehWrapper(veh));
            }
            return myResults;
        }
        //end 1209
        //if(v.dealer__Status_Code__c == 'Order - Sold Not Delivered' && v.Proposed_Delivery_Date__c < TODAY ){
        //                statusCheckResult.add(v);
        //            }else{
        //                statusCheckResult.add(v);
        //                }

        //BLL11d if(query!='' ){
            if(!String.isBlank(searchAll)) {
                // soslResult = Search.query( buildQuery(true) );
                // BLL11d vehResult = List<dealer__Vehicle_Inventory__c>)soslResult[0];
                soslResult = Search.query( buildSOSL() );	// BLL14a
                Map<Id,dealer__Vehicle_Inventory__c> tmpsoslResult = new Map<Id,dealer__Vehicle_Inventory__c>((List<dealer__Vehicle_Inventory__c>) soslResult[0]);   // BLL11c
                system.debug('SOSLresult: ' + soslResult);
                system.debug('vehResult after sosl: ' + tmpsoslResult); // BLL11c
                // BLL11a 
                // Filter SOQL results with SOSL results
                List<dealer__Vehicle_Inventory__c> filterResult = new List<dealer__Vehicle_Inventory__c>();
                for(dealer__Vehicle_Inventory__c v : vehResult) {
                    if (tmpsoslResult.containsKey(v.Id)) filterResult.add(v);
                } 
                vehResult = filterResult;
                for(dealer__Vehicle_Inventory__c veh : vehResult) {
                    myResults.add(new vehWrapper(veh));
                }
                return myResults;
                // BLL11a
            //}else{
            //    vehResult = Database.query( buildQuery() );
        }

        if (vehResult.size() == 0) {
            ApexPages.Message noResults = new ApexPages.Message(ApexPages.Severity.INFO, 'No results Found!');
            ApexPages.addMessage(noResults);
            return myResults;

        }
        for(dealer__Vehicle_Inventory__c veh : vehResult) {
            myResults.add(new vehWrapper(veh));
        }
        return myResults;

    }
BLL14d end **/

    public PageReference returnToDeal() {
        //BLL11d PageReference p = new PageReference('/apex/QuoteManager?id='+proposalId+'#sec_chassis');
        //BLL16d PageReference p = new PageReference('/' + proposalId+'#sec_chassis');   // BLL11a
        Id did = (Id) proposalId;

		Schema.SObjectType objType = did.getSObjectType();
		Schema.DescribeSObjectResult dsr = objType.getDescribe();
		SObject obj = objType.newSObject();
		obj.Id = did;
		ApexPages.StandardController ctl = new ApexPages.StandardController(obj);
		System.debug('return from selectVehicle');
		return ctl.view();

        //BLL16d p.setRedirect(true);
        //BLL16d return p;
    }

    public List<dealer__Vehicle_Inventory__c> getVehResult(){
        return vehResult;
    }

    /** PICKLIST VALUES */

    public List<SelectOption> getYears() {
        List<SelectOption> options = new List<SelectOption>();
        //BLL8d options.add(new SelectOption('', 'All'));

        // JVK1
        Date d = Date.today();
        Integer current_year = d.year() + 1; 
        Integer current_back = current_year - 20;

        for(Integer y = current_year; y>=current_back; y--) {
            options.add(new SelectOption(String.valueOf(y), String.valueOf(y)));
        }
        // JVK1 End

        return options;  
    }

    //public List<SelectOption> getMakes() {    // BLL6d
    public List<SelectOption> MakesDropDown() { // BLL6a
        List<SelectOption> options = new List<SelectOption>();
        //BLL8d options.add(new SelectOption('', 'All'));
        options.add(new SelectOption('Ford', 'Ford'));
        options.add(new SelectOption('Dodge', 'Dodge'));
        options.add(new SelectOption('Ram', 'Ram'));
        options.add(new SelectOption('Chevrolet', 'Chevrolet'));    // BLL6a
        options.add(new SelectOption('Chevy', 'Chevy'));    // BLL6a
        options.add(new SelectOption('Chrysler', 'Chrysler'));
        options.add(new SelectOption('GMC', 'GMC'));    // BLL6a
        options.add(new SelectOption('Honda', 'Honda'));
        options.add(new SelectOption('Mercedes', 'Mercedes'));
        options.add(new SelectOption('Nissan', 'Nissan'));
        options.add(new SelectOption('Toyota', 'Toyota'));

        /*
        List<AggregateResult> makes = [Select dealer__Make__c from dealer__Vehicle_Inventory__c 
                                                        Where dealer__Status_Code__c != 'Delivered' 
                                                        and dealer__Status_Code__c != 'Sold - Not Delivered'
                                                        and dealer__Make__c != null
                                                        and dealer__Status_Code__c != 'Delivered' 
                                                        and dealer__Status_Code__c != 'Sold - Not Delivered'
                                                        Group By dealer__Make__c
                                                        Order By dealer__Make__c ASC
                                                        LIMIT 5000];
        for( AggregateResult m : makes) {
            if((String)m.get('dealer__Make__c') != null) {
                options.add( new SelectOption( (String)m.get('dealer__Make__c') ,(String)m.get('dealer__Make__c') ) );
            }
        } 
        */


        return options;  
    }

    // BLL8a
    public List<SelectOption> divisionDropDown() { // BLL6a
        List<SelectOption> options = new List<SelectOption>();
        if(lockDivision) options.add(new SelectOption(businessDivision, businessDivision));
        else {
            options.add(new SelectOption('', 'All'));
            Schema.DescribeFieldResult dfr = dealer__Vehicle_Inventory__c.Division__c.getDescribe();
            List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
            for(Schema.PicklistEntry p : plvs) options.add(new SelectOption(p.getLabel(), p.getValue()));
        }
        return options;
    }
    
    public List<SelectOption> FeaturedVanDropDown(){
        List<SelectOption> options = new List<SelectOption>();
        if(lockFeatVan) {
			// AMM14
			//options.add(new SelectOption(FeaturedVan, FeaturedVan));
			for(String f : FeaturedVan) options.add(new SelectOption(f, f));
			// AMM14
        } else {
            options.add(new SelectOption('', 'All'));
            Schema.DescribeFieldResult dfr = dealer__Vehicle_Inventory__c.FeaturedVan__c.getDescribe();
            List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
            for(Schema.PicklistEntry p : plvs) options.add(new SelectOption(p.getLabel(), p.getValue()));
        }
        return options;
    }

    public List<SelectOption> getFloorTypes() { 
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'All'));
        Schema.DescribeFieldResult dfr = dealer__Vehicle_Inventory__c.FloorType__c.getDescribe();
        List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
        for(Schema.PicklistEntry p : plvs) options.add(new SelectOption(p.getLabel(), p.getValue()));
        return options;
    }
    
    public List<SelectOption> getFloorCuts() { 
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'All'));
        Schema.DescribeFieldResult dfr = dealer__Vehicle_Inventory__c.FloorCut__c.getDescribe();
        List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
        for(Schema.PicklistEntry p : plvs) options.add(new SelectOption(p.getLabel(), p.getValue()));
        return options;
    }
    // BLL8a end
    public List<SelectOption> getModels() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'All'));
        /*
        List<AggregateResult> models = [Select dealer__Model__c from dealer__Vehicle_Inventory__c 
                                                        Where dealer__Status_Code__c != 'Delivered' 
                                                        and dealer__Status_Code__c != 'Sold - Not Delivered'
                                                        and dealer__Model__c != null
                                                        and dealer__Status_Code__c != 'Delivered' 
                                                        and dealer__Status_Code__c != 'Sold - Not Delivered'
                                                        Group By dealer__Model__c
                                                        Order By dealer__Model__c ASC
                                                        LIMIT 5000];
        for( AggregateResult m : models) {
            if((String)m.get('dealer__Model__c') != null) {
                options.add( new SelectOption( (String)m.get('dealer__Model__c') ,(String)m.get('dealer__Model__c') ) );
            }
        } 
        */
        return options;  
    }

    public List<SelectOption> getTrims() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', 'All'));
        /*
        List<AggregateResult> trims = [Select dealer__Trim_Level__c from dealer__Vehicle_Inventory__c 
                                                        Where dealer__Status_Code__c != 'Delivered' 
                                                        and dealer__Status_Code__c != 'Sold - Not Delivered'
                                                        and dealer__Trim_Level__c != null
                                                        and dealer__Status_Code__c != 'Delivered' 
                                                        and dealer__Status_Code__c != 'Sold - Not Delivered'
                                                        Group By dealer__Trim_Level__c
                                                        Order by dealer__Trim_Level__c ASC
                                                        LIMIT 5000];
        for( AggregateResult m : trims) {
            if((String)m.get('dealer__Trim_Level__c') != null) {
                options.add( new SelectOption( (String)m.get('dealer__Trim_Level__c') ,(String)m.get('dealer__Trim_Level__c') ) );
            }
        } 
        */
        return options;  
    }   

    public List<SelectOption> getRecordTypes() {
        List<SelectOption> recordTypes = new List<SelectOption>();
        recordTypes.add(new SelectOption('All','All'));
        recordTypes.add(new SelectOption('Demo','Demo'));
        recordTypes.add(new SelectOption('New','New'));
        recordTypes.add(new SelectOption('Rental','Rental'));
        recordTypes.add(new SelectOption('Used','Used'));
        return recordTypes;
    }

    public List<SelectOption> getnewUsedOthers() {
        // BLL8a
        List<SelectOption> options = new List<SelectOption>();
        if(lockNewUsedOther && newUsedOther.size()>0) options.add(new SelectOption(newUsedOther.get(0), newUsedOther.get(0)));
        else {
            //options.add(new SelectOption('', 'All'));
            Schema.DescribeFieldResult dfr = dealer__Vehicle_Inventory__c.New_Used_Other__c.getDescribe();
            List<Schema.PicklistEntry> plvs = dfr.getPicklistValues();
            for(Schema.PicklistEntry p : plvs) options.add(new SelectOption(p.getLabel(), p.getValue()));
        }
        // BLL8a end
        // BLL8d remove old fixed values
        //        List<SelectOption> newUsedOthers = new List<SelectOption>();
        //        newUsedOthers.add(new SelectOption('All','All'));
        //        newUsedOthers.add(new SelectOption('Commercial','Commercial'));
        //        newUsedOthers.add(new SelectOption('Company Vehicle','Company Vehicle'));
        //        newUsedOthers.add(new SelectOption('Demo','Demo'));
        //        newUsedOthers.add(new SelectOption('Demo - Not For Sale','Demo - Not For Sale'));
        //        newUsedOthers.add(new SelectOption('Fixed Asset','Fixed Asset'));
        //        newUsedOthers.add(new SelectOption('Fleet','Fleet')); // BLL7a
        //        newUsedOthers.add(new SelectOption('New','New'));
        //        newUsedOthers.add(new SelectOption('New/Used','New/Used'));
        //        newUsedOthers.add(new SelectOption('Other','Other'));
        //        newUsedOthers.add(new SelectOption('Rental','Rental'));
        //        newUsedOthers.add(new SelectOption('Rental - Not For Sale','Rental - Not For Sale'));
        //        newUsedOthers.add(new SelectOption('Used','Used'));
        //        newUsedOthers.add(new SelectOption('Wholesale','Wholesale'));
        //        return newUsedOthers;
        return options; // BLL8a    
    }

    public List<SelectOption> getInteriors() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.Interior__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }

    public List<SelectOption> getVehTypes() {
        List<SelectOption> options = new List<SelectOption>();
        //BLL8d options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.Unit_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }  

        return options;     
    }

    public List<SelectOption> getRegions() {
        List<SelectOption> options = new List<SelectOption>();
        //BLL8d
        // Get the Users Current Region
        //User u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
        //try {  // BLL2a
        //  dealer__Dealer_Location__c loc = [Select Id, Name, Region__c from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division limit 1];
        //  options.add(new SelectOption(loc.Region__c, loc.Region__c));  // BLL2a
        //} catch(Exception e) {} // BLL2a
        // BLL8d end
        // BLL2d block
        //if(loc!=null && loc.Region__c==null) {
            //throw new AdvancedSearchErrorException('The Location ('+loc.Name+') you are currently set to use has no Region Assigned.  Please Contact Tech Support');
        //}

        //options.add(new SelectOption(loc.Region__c, loc.Region__c));
        // BLL2d end block
        //BLL8d options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Dealer_Location__c.Region__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }             
        return options; 
    }

    public List<SelectOption> getBranchLocations() {
        List<SelectOption> options = new List<SelectOption>();
        // BLL8d
        // Get the Users Current Region
        //User u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
        //try { // BLL2a
        //dealer__Dealer_Location__c loc = [Select Id, Name, Region__c from dealer__Dealer_Location__c where dealer__Company_Number__c=:u.Division limit 1];

        //if(storeLocation==null || storeLocation=='') {
        //    storeLocation=loc.Name;
        //}

        //options.add(new SelectOption(loc.Name, loc.Name));
        //} catch(Exception e) {} // BLL2a
        // BLL8d end
        
        //BLL8d options.add(new SelectOption('All','All'));
        //filter for where user has access 
        List<AggregateResult> vehs = [SELECT Name From dealer__Dealer_Location__c group by Name limit 5000];
        
        for( AggregateResult v : vehs) {
            if((String)v.get('Name') != null) {
                options.add( new SelectOption( (String)v.get('Name') ,(String)v.get('Name') ) );
            }
        }       
        return options;     
    }

    public List<SelectOption> getStatusCodes() {

        List<SelectOption> options = new List<SelectOption>();
        //BLL8d options.add(new SelectOption('Ready For Sale', 'Ready For Sale'));
        //BLL8d options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.dealer__Status_Code__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            //if(f.getLabel() != 'Delivered') {  // BLL1d Should be able to search specifically for these!
                options.add(new SelectOption(f.getLabel(), f.getValue()));
            //} // BLL1d
        }            

        return options;         
    }

    public List<SelectOption> getRampTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.MV_Ramp_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }

    public List<SelectOption> getRampOperationItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.MV_Ranp_Operation__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }

    /** Conversion Fields */
    public List<SelectOption> getConversions() { 
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.Conv_MFG__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }

    public List<SelectOption> getConversionModels() { 
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.Conversion_Model__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }

    public List<SelectOption> getRampLocations() { 
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All','All'));

        Schema.DescribeFieldResult fieldResult =
        dealer__Vehicle_Inventory__c.Ramp_Location__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
        return options;
    }
    
    //BLL11d public Boolean getRenderTableBool(){
    //BLL11d     return RenderTableBool;
    //BLL11d }
    
    //W-000525 begin
    public PageReference statusCheckSearch(){
        statusCheckErrorReportBoolean = false;//1209
        statusCheckBoolean = true;
        status.clear();
        searchAll = '';	// BLL14a
        vehicleSearch(); 
        return null;             
    }
    //W-000525 end
    
    //Work 1209
    public pageReference statusCheckErrorReportSearch(){  
        statusCheckBoolean = false;
        statusCheckErrorReportBoolean = true;
        setErrorReportSearchFields();

        status.add('Sold - Not Delivered'); 
        status.add('Order - Sold Not Delivered');
        status.add('In Transit - Sold Not Delivered'); 
        status.add('Not For Sale');
        status.add('Order');
        status.add('Ready for Sale');
        system.debug('statusCheckErrorReportSearch');
        searchAll = '';	// BLL14a
        vehicleSearch();      
        return null;       
    }
    public pageReference setErrorReportSearchFields(){
        
       year.clear();
       make.clear();
       status.clear();

       //region.clear();
       //storeLocation.clear();

       vehType.clear();
       newUsedOther.clear();

       model = null;
       trim = null;
       stockNum = null;
       businessDivision = null;
       minPrice = null;
       maxPrice = null;
       extColor = null;
       intColor = null;
       interior = null;
       VIN = null;
       minOdometer = null;
       maxOdometer = null;
       convMfg = null;
       minConv = null;
       maxConv = null;
       minChassis = null;
       maxChassis = null;
       convModel = null;
       rampType = null;
       rampOperation = null;
       rampLoc = null;
       kneel = null;
       FloorType = null;
       floorcut = null;
	   // AMM14
       //FeaturedVan = null;
	   FeaturedVan.clear();
	   // AMM14

       return null;

    }

    public class AdvancedSearchErrorException extends Exception{}

}