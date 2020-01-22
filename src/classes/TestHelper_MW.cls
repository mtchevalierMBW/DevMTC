/**
 * General tools to assist with test classes and reduce need for seealldata=true
 * Note: FinancialForce company still requires seealldata=true for the time being
 * 2015-08-07   B. Leaman   Start developing this in earnest
 * 2015-10-15   B. Leaman   BLL1 - add rental manager to test locations.
 * 2015-11-05   B. Leaman   BLL2 - add influencer account support.
 * 2015-11-17   B. Leaman   BLL3 - Add FF support routines.
 * 2016-01-04	B. Leaman	BLL4 - Place vehicle inventory into a location (for testing trades).
 * 2016-08-08	B. Leaman	BLL5 - set current user as the test user's manager.
 * 2016-09-13	B. Leaman	BLL6 - Make dealer locations more unique so they don't cause dupe errors during tests.
 * 2016-12-19	B. Leaman	BLL7 - Authorize user to dealer location
 * 2017-02-22	B. Leaman	Add GLAMap to FFAData refresh method.
 * 2017-05-04	B. Leaman	BLL8 - Remove custom object Dealer_Location_Users__c.
 * 2017-9-29    A. Miller   AMILLER - updated the alias to not have more than 8 characters. Salesforce validation
 * 2017-11-15	B. Leaman	BLL9 - introduce salt into the account names so duplicate matching rules don't cause trouble.
 * 2018-03-13	B. Leaman	BLL10 - service reporting test user on locations;
 * 2018-08-13	B. Leaman	BLL11 - new routines to help create test data;
 * 2019-03-20   A. Miller   AMM12 - W-000580 - Update to handle TransitWorks Accounts
 * 2019-04-22	B. Leaman	BLL12 - W-000575 - updates to reduce soql queries; remove dupecatcher; add GL Account external Ids;
 */
@isTest
public class TestHelper_MW {
    // singleton
    private static TestHelper_MW instance=null;

    protected Map<String, Profile> profileMAD = new Map<String, Profile>();
    protected Map<String, dealer__Dealer_Location__c> dealerLocation = new Map<String, dealer__Dealer_Location__c>();
    protected c2g__codaCompany__c ffCompany = null;
    protected Map<String, dealer__Parts_Master__c> partsMaster = new Map<String, dealer__Parts_Master__c>();
    protected Map<String, dealer__Parts_Inventory__c> partsInventory = new Map<String, dealer__Parts_Inventory__c>();
    protected Map<String, dealer__Vehicle_Inventory__c> vehicleInventory = new Map<String, dealer__Vehicle_Inventory__c>();
    protected RecordType DealerSaleRecordType;
    protected dealer__Chart_of_Accounts__c DealerSalesAccount;
    protected dealer__Parts_Stocking_Group__c PartsStockingGroup;

    public Map<String, Account> vendors = new Map<String, Account>();
    public Map<String, Account> thirdparties = new Map<String, Account>();
    public Map<String, Account> businesses = new Map<String, Account>();
    public Map<String, Account> commercialaccts = new Map<String, Account>();
    public Map<String, Account> persons = new Map<String, Account>();
    public Map<String, Account> influencers = new Map<String, Account>();  // BLL2a
    public Map<String, Account> transitworks = new Map<String, Account>(); // AMM12
    public Map<String, Account> transitworksLeads = new Map<String, Account>(); // AMM12

    //protected List<SFSSDupeCatcher__Scenario__c> dc_on;
    //protected List<SFSSDupeCatcher__Scenario__c> dc_off;
	private Map<String, RecordType> AccountRecordTypeMap;
	private Map<String, RecordType> LeadRecordTypeMap;

	public Map<String,String> AccountSalt = new Map<String,String>{'1'=>'One', '2'=>'Twain', '3'=>'Thrice', '4'=>'Fourth',
			'A'=>'Alpha', 'B'=>'Bravo', 'C'=>'Charlie', 'D'=>'Delta'};

    class TestHelperException extends Exception {}
    
    // singleton
    //----------------------------------------------------
    public static TestHelper_MW getInstance() {
        if (!Test.isRunningTest()) {
            throw new TestHelperException('TestHelper_MW can only be used in Apex TEST classes!');
        }
        if(instance==null) instance = new TestHelper_MW();
        return instance;
    }

    // constructor
    // Get current state of dupecatcher rules
    //----------------------------------------------------
    public TestHelper_MW() {    
/**        dc_on = [
           select Id, Name, SFSSDupeCatcher__Deployed__c
           from SFSSDupeCatcher__Scenario__c 
           where SFSSDupeCatcher__Deployed__c=true
        ];
        // For testing *this* class if no filters in place...
        if (dc_on != null && dc_on.size()==0) {
            dc_on = [select Id, Name, SFSSDupeCatcher__Deployed__c
                     from SFSSDupeCatcher__Scenario__c
                     limit 1 
           ];
        }
        dc_off = new List<SFSSDupeCatcher__Scenario__c>();
**/
		vendors = new Map<String, Account>();
		commercialaccts = new Map<String, Account>();
		businesses = new Map<String, Account>();
		persons = new Map<String, Account>();
		influencers = new Map<String, Account>();
		thirdparties = new Map<String, Account>();
		transitworks = new Map<String, Account>();
			for(Account a : [select Id, Name, dealer__External_ID__c, isPersonAccount, PersonContactId, BillingPostalCode, RecordType.Name from Account where dealer__External_ID__c!=null limit 500]) {
			if (a.dealer__External_ID__c!=null) {
				if (a.dealer__External_ID__c.startsWith('Vendor')) vendors.put(a.dealer__External_ID__c.substringAfterLast(':'), a);
				if (a.dealer__External_ID__c.startsWith('Commercial')) commercialaccts.put(a.dealer__External_ID__c.substringAfterLast(':'), a);
				if (a.dealer__External_ID__c.startsWith('Business')) businesses.put(a.dealer__External_ID__c.substringAfterLast(':'), a);
				if (a.dealer__External_ID__c.startsWith('Person')) persons.put(a.dealer__External_ID__c.substringAfterLast(':'), a);
				if (a.dealer__External_ID__c.startsWith('Influencer')) influencers.put(a.dealer__External_ID__c.substringAfterLast(':'), a);
				if (a.dealer__External_ID__c.startsWith('ThirdParty')) thirdparties.put(a.dealer__External_ID__c.substringAfterLast(':'), a);
				if (a.dealer__External_ID__c.startsWith('Driverge')) transitworks.put(a.dealer__External_ID__c.substringAfterLast(':'), a);
			}
		}

		AccountRecordTypeMap = new Map<String,RecordType>();
		for(RecordType rt : [select Id, Name from RecordType where SObjectType='Account' and isActive=true]) AccountRecordTypeMap.put(rt.Name,rt);

		LeadRecordTypeMap = new Map<String,RecordType>();
		for(RecordType rt : [select Id, Name from RecordType where SObjectType='Lead' and isActive=true]) LeadRecordTypeMap.put(rt.Name,rt);
    }
    
    // suspendDupeCatcher
    // Mark all active filters as inactive
    //----------------------------------------------------
    public void suspendDupeCatcher() {
/**        if (dc_on != null && dc_on.size()>0) {
            for(SFSSDupeCatcher__Scenario__c s : dc_on) {
                dc_off.add(s);
            }
            for(SFSSDupeCatcher__Scenario__c d : dc_off) {
               d.SFSSDupeCatcher__Deployed__c=false;
            }
        }
        if (dc_off != null && dc_off.size()>0) {
            try {
               update(dc_off);
            } catch(Exception e) { }
        }
**/
    }

    // resumeDupeCatcher
    // Re-activate all filters initially marked active
    //----------------------------------------------------
    public void resumeDupeCatcher() {
/**
        if (dc_on != null && dc_on.size()>0) {
            try {
                update(dc_on);
            } catch(Exception e) { }
        }
**/
    }

	// salt
	public String salt(String id) {
		String s = AccountSalt.get(id);
		if (s==null) {
			s = id+id+id;
		}
		return s;
	}

    // Record types for various objects
    //-------------------------------------------
    
    // Business account record type    
    public RecordType getBusinessAccountRt() {
        //return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and Name like 'Bus%' limit 1];
		return AccountRecordTypeMap.get('Business Account');
    }
    // Commercial account record type    
    public RecordType getCommercialAccountRt() {
        //return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and Name like 'Commercial%' limit 1];
		return AccountRecordTypeMap.get('Commercial');
    }
    // Vendor account record type    
    public RecordType getVendorAccountRt() {
        //return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and Name like 'Vendor%' limit 1];
		return AccountRecordTypeMap.get('Vendor');
    }
    // Person account record type    
    public RecordType getPersonAccountRt() {
        //return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and isPersonType=true limit 1];
		return AccountRecordTypeMap.get('PersonAccount');
    }
    // Third party payor account record type    
    public RecordType getThirdPartyAccountRt() {
        //return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and Name like 'Third%' limit 1];
		return AccountRecordTypeMap.get('Third Party Payor');
    }
    // Influencer account record type - BLL2a    
    public RecordType getInfluencerAccountRt() {
        //return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and Name like 'Influencer%' limit 1];
		return AccountRecordTypeMap.get('Influencer');
    }
    // TransitWorks account record type - AMM12 
    public RecordType getTransitWorksAccountRt() {
        //BLL12 return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and Name like 'TransitWorks' limit 1];
		return AccountRecordTypeMap.get('TransitWorks');
    }
    // TransitWorks Lead account record type - AMM12 
    public RecordType getTransitWorksLeadAccountRt() {
        //BLL12 return [select Id, Name from RecordType where SObjectType='Account' and isActive=true and Name like 'TransitWorks Lead' limit 1];
		return LeadRecordTypeMap.get('TransitWorks Lead');
    }

    // Retail lead record type    
    public RecordType getRetailLeadRt() {
        //return [select Id, Name from RecordType where SObjectType='Lead' and isActive=true and Name like 'Retail%' limit 1];
		return LeadRecordTypeMap.get('Retail');
    }
    // Commercial lead record type    
    public RecordType getCommercialLeadRt() {
        //return [select Id, Name from RecordType where SObjectType='Lead' and isActive=true and Name like 'Commerc%' limit 1];
		return LeadRecordTypeMap.get('Commercial');
    }
    // TransitWorks lead record type    
    public RecordType getTransitWorksLeadRt() {
        //return [select Id, Name from RecordType where SObjectType='Lead' and isActive=true and Name like 'Transit%' limit 1];
		return LeadRecordTypeMap.get('Transit Works');
    }

    // Accounts
    //---------------------------------------------
    
    // Vendor
    public Account getVendorAccount(String vid) {
		System.debug('getVendorAccount');
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
		System.debug(vid);
		System.debug(vendors);
        if (vendors.get(vid)==null) {
        	String s = salt(vid);
            Account v = new Account(
                RecordTypeId=getVendorAccountRt().Id, 
                Name=s+'Test'+vid+' Vendor'+s, BillingStreet=vid+'12'+vid+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='446'+vid+vid,
                dealer__Vendor__c=true, Parts_Prefix__c='PFX', dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active',
				dealer__External_ID__c = 'Vendor:' + vid
            );
            Database.insert(v,dml);
			System.debug('Inserted new vendor');
			System.debug(v.Id);
            vendors.put(vid, v);
			System.debug(v);
			System.debug(vendors);
        } else {System.debug('Re-using vendor'); System.debug(vendors);}
        return vendors.get(vid);
    }
    
    // Business account
    public Account getBusinessAccount(String id) {
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        if (businesses.get(id)==null) {
        	String s = salt(id);
            Account a = new Account(
                RecordTypeId=getBusinessAccountRt().Id, 
                Name=s+'Test'+id+' Company'+s, BillingStreet=id+'12'+id+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='446'+id+id,
                dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active',
				dealer__External_ID__c = 'Business:' + id
            );
            Database.insert(a,dml);
            businesses.put(id, a);
        }
        return businesses.get(id);
    }
    
    // Commercial account
    public Account getCommercialAccount(String id) {
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        if (commercialaccts.get(id)==null) {
        	String s = salt(id);
            Account a = new Account(
                RecordTypeId=getCommercialAccountRt().Id, 
                Name=s+'Commercial Test'+id+' Company'+s, BillingStreet=id+'12'+id+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='446'+id+id,
                dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active',
				dealer__External_ID__c = 'Commercial:' + id
            );
            Database.insert(a,dml);
            commercialaccts.put(id, a);
        }
        return commercialaccts.get(id);
    }

    // ThirdPartyPayor account
    public Account getThirdPartyAccount(String id) {
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        if (thirdparties.get(id)==null) {
        	String s = salt(id);
            Account a = new Account(
                RecordTypeId=getThirdPartyAccountRt().Id, 
                Name=s+'Test'+id+' Payor'+s, BillingStreet=id+'12'+id+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='446'+id+id,
                dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active',
				dealer__External_ID__c = 'ThirdParty:' + id
            );
            Database.insert(a,dml);
            thirdparties.put(id, a);
        }
        return thirdparties.get(id);
    }
    
    // Person account
    public Account getPersonAccount(String id) {
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        if (persons.get(id)==null) {
        	String s = salt(id);
            Account a = new Account(
                RecordTypeId=getPersonAccountRt().Id, 
                FirstName=s+'Test'+id, LastName=s+'Ln', BillingStreet=id+'12'+id+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='446'+id+id,
                PersonMailingStreet=id+'12'+id+' '+s+' Ave', PersonMailingCity=s+'field', PersonMailingState='OH', PersonMailingPostalCode='446'+id+id,
                PersonBirthdate=Date.parse('01/02/1970'),
                PersonEmail=s+'Test'+'.'+s+'@example.com',
                Phone='(330) 555-12'+id+id,
                dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active',
				dealer__External_ID__c = 'Person:' + id
            );
            System.debug(a);
            Database.insert(a,dml);
            persons.put(id, a);
        }
        return persons.get(id);
    }

    
    // Influencer account - BLL2a
    public Account getInfluencerAccount(String id) {
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        if (influencers.get(id)==null) {
        	String s = salt(id);
            Account a = new Account(
                RecordTypeId=getInfluencerAccountRt().Id, 
                Name='TestInf '+s, BillingStreet=id+'12'+id+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='441'+id+id,
                dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active',
				dealer__External_ID__c = 'Influencer:' + id
            );
            Database.insert(a,dml);
            influencers.put(id, a);
        }
        return influencers.get(id);
    }
    
    // TransitWorks account - AMM12
    public Account getTransitWorksAccount(String id) {
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        if (transitworks.get(id)==null) {
        	String s = salt(id);
            Account a = new Account(
                RecordTypeId=getTransitWorksAccountRt().Id, 
                Name='TestTW '+s, BillingStreet=id+'12'+id+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='441'+id+id,
                dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active',
				dealer__External_ID__c='Driverge:'+id
            );
            Database.insert(a,dml);
            transitworks.put(id, a);
        }
        return transitworks.get(id);
    }

    // TransitWorks Lead account - AMM12
    public Account getTransitWorksLeadAccount(String id) {
		Database.DMLOptions dml = new Database.DMLOptions();
		dml.DuplicateRuleHeader.AllowSave = true; 
        if (transitworksLeads.get(id)==null) {
        	String s = salt(id);
            Account a = new Account(
                RecordTypeId=getTransitWorksLeadAccountRt().Id, 
                Name='TestTWLead '+s, BillingStreet=id+'12'+id+' '+s+' Ave', BillingCity=s+'field', BillingState='OH', BillingPostalCode='441'+id+id,
                dealer__Active__c='YES', Active__c=true,
				Account_Status__c='Active'
            );
            Database.insert(a,dml);
            transitworksLeads.put(id, a);
        }
        return transitworksLeads.get(id);
    }


    // getProfile
    //----------------------------------------------------
    public Profile getProfile(String id) {
        if (profileMAD.get(id)==null) {
            Profile p = [ Select Id, PermissionsModifyAllData, Name from Profile where PermissionsModifyAllData=true limit 1];
            profileMAD.put(id, p);
        }
        return profileMAD.get(id);
    }

    // getFFCompany
    //----------------------------------------------------
    public c2g__codaCompany__c getFFCompany(Id uid) {
        if (ffCompany==null) {
            // FF Companies user could have selected
	        System.debug('COMPANY_GROUPMEMBER');
            List<Id> compGroupIds = new List<Id>();
            for(c2g__codaCompany__c c : [select Id, OwnerId, Name from c2g__codaCompany__c]) {
                compGroupIds.add(c.OwnerId);
                System.debug(c.OwnerId);
            }
            
            // Currently selected company/companies
            List<Id> groupIds = new List<Id>();
            for(GroupMember member : [
                  select GroupId from GroupMember 
                  where Group.Type = 'Queue' and GroupId in :compGroupIds and UserOrGroupId = :uid]
               ) {
                groupIds.add(member.GroupId);               
            } 
            c2g__codaCompany__c[] companies = 
                [select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c from c2g__codaCompany__c where OwnerId in :groupIds];

            // if none, create company as owned by the first queue found!
            // todo: create a test queue to own the company or is it automatically created?
            // todo: add user as authorized to new company & select only that company for the user
            if (companies.size()==0 && compGroupIds.size()>0) {
                c2g__codaCompany__c comp = new c2g__codaCompany__c(
                    Name='TestCompany1', OwnerId=compGroupIds[0]
                );
                insert(comp);
                companies = [
                    select RecordType.Name, Id, Name, c2g__TaxCode__c, c2g__CODABaseDate1__c, c2g__CODADaysOffset1__c, OwnerId 
                    from c2g__codaCompany__c 
                    where Id=:comp.Id
                ]; 
                System.debug(companies);
            }
            
            // save & return FF company
            if (companies.size()>0) {               
                ffCompany = companies[0];
            }
        }
        return ffCompany;       
    }

    // getDealerLocation
    //----------------------------------------------------
    public dealer__Dealer_Location__c getDealerLocation(String id) {
    	System.debug(UserInfo.getUserId());
        if (dealerLocation.get(id)==null) {
            dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c();
            loc.Name = 'Test' + id + ' Location x' + id;
            loc.dealer__Company_Number__c = 'X#' + id;
            loc.Region__c = '1';
            loc.dealer__General_Manager__c = UserInfo.getUserId();
            loc.Rental_Manager__c = UserInfo.getUserId();  // BLL1a
            loc.dealer__City__c = 'Richfield'+id;
            loc.dealer__State__c = 'OH';
            loc.dealer__Postal_Code__c = '4428'+id.substring(0,1);
            c2g__codaCompany__c comp = getFFCompany(UserInfo.getUserId());
            loc.dealer__Main_Phone__c = '(440) 555-111' +  id.substring(0,1);
			loc.Manual_Cash_Entry__c = true; // allow any cash entries
            if (comp!=null) {
                loc.Company__c = comp.Id;
            }
            insert(loc);
            dealerLocation.put(id, loc);
        }
        return dealerLocation.get(id);
    }
    
    // Create test user
    // Copied & adjusted from Milestone1
    //----------------------------------------------------
    public User getTestUser(String id) {
    
        Profile p = getProfile(id.substring(0,1));
        
        String name = 'mbw_' + id + '_' + math.rint(math.random() * 100000);

        dealer__Dealer_Location__c loc = getDealerLocation(id.substring(0,1));    
    
        User testUser = new User();
        testUser.Email = name + '.test.sf.user@example.com';
        testUser.Username = name + '@example.com';
        testUser.LastName = 'mbwtest';
        testUser.FirstName = name;
        testUser.Alias = 'mbw_'+id;
        testUser.ProfileId = p.Id;
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.TimeZoneSidKey = 'America/New_York';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.ManagerId = UserInfo.getUserId();	// BLL5a
        // MBW Custom requirements
        dealer__Dealer_Location__c dl = getDealerLocation(id.substring(0,1));
        testUser.Division = dl.dealer__Company_Number__c;
        insert testUser;
        //BLL8d Dealer_Location_Users__c dlu = new Dealer_Location_Users__c(
        //BLL8d    User__c = testUser.Id,
        //BLL8d    Dealer_Location__c = dl.Id 
        //BLL8d );
        //BLL8d insert(dlu);
        insert(new dealer__Dealer_Location_User__c(dealer__User__c=testUser.Id, dealer__Dealer_Location__c=dl.Id));	// BLL8a
         
        return testUser;
    } 
 
    
    // PartsMaster
    //----------------------------------------------------
    public dealer__Parts_Master__c getPartsMaster(String id) {
        if (partsMaster.get(id)==null) {
            dealer__Parts_Master__c p = new dealer__Parts_Master__c(
                Name='TESTPART_' + id,
                dealer__Manufacturer__c='TST',
                dealer__Raw_Part_Number__c = 'TESTPART_' + id,
                dealer__Part_No__c='TST:TESTPART_' + id,
                dealer__Retail_Price__c=3.00,
                dealer__Cost__c=1.00
            );
            insert(p);
            partsMaster.put(id, p);
        }
        return partsMaster.get(id);
    }
      
    // PartsInventory
    //----------------------------------------------------
    public dealer__Parts_Inventory__c getPartsInventory(String id) {
        if (partsInventory.get(id)==null) {
            dealer__Parts_Master__c pm = getPartsMaster(id);
            dealer__Parts_Inventory__c pi = new dealer__Parts_Inventory__c();
            pi.dealer__Company_Number__c = getDealerLocation(id.substring(0,1)).dealer__Company_Number__c;
            pi.dealer__MFG__c = pm.dealer__Manufacturer__c;
            pi.dealer__Parts_Master__c = pm.Id;
            pi.dealer__Cost__c = 1.00;
            pi.dealer__List__c = 2.00;
            pi.Name = pi.dealer__MFG__c + ':' + pm.dealer__Raw_Part_Number__c;
            pi.dealer__Part_No__c = pi.dealer__Company_Number__c + ':' + pm.dealer__Part_No__c;
            pi.dealer__On_Hand__c=1;
            insert(pi);
            partsInventory.put(id, pi);
        }
        return partsInventory.get(id);
    }
      
    // Vehicle_Inventory
    //------------------------------------------------------
    public dealer__Vehicle_Inventory__c getVehicleInventory(String id) {     
        if (vehicleInventory.get(id)==null) { 
        	dealer__Dealer_Location__c loc = getDealerLocation(id); // BLL4a
            dealer__Vehicle_Inventory__c vi = new dealer__Vehicle_Inventory__c(
                Name='(test' + id + ') Test van in stock', dealer__Stock_Number__c='test' + id,
                dealer__Make__c='Toyota', dealer__Model__c='Sienna', dealer__VIN__c=(id+'12345678901234567').substring(0,17), 
                dealer__Year__c='2000',
                dealer__Vehicle_Cost__c = 100.00, Conversion_Cost__c = 50.00,  // BLL4a
                dealer__Store_Location__c=loc.Id  // BLL4a
            );       
            insert(vi); 
            vehicleInventory.put(id, vi);
        }
        return vehicleInventory.get(id);
    }      

    // getDealerSalesAccount
    //------------------------------------------------------
    public dealer__Chart_of_Accounts__c getDealerSalesAccount() {
        if (DealerSalesAccount==null) {
            RecordType saleRt = getDealerSaleRecordType();
            DealerSalesAccount = new dealer__Chart_of_Accounts__c(
                RecordTypeId=saleRt.Id, Name='Test Sales CoA', dealer__Description__c='Test Sales CoA'
            );
            insert(DealerSalesAccount);
        }
        return DealerSalesAccount;
    }

    // getDealerSaleRecordType
    //------------------------------------------------------
    public RecordType getDealerSaleRecordType() {
        if (DealerSaleRecordType==null) {
            DealerSaleRecordType = [
                select Id, Name 
                from RecordType 
                where SObjectType='dealer__Chart_of_Accounts__c' and Name like 'Sale%'
                  and isActive=true
                limit 1
            ];
        }
        return DealerSaleRecordType;
    }

    // getDefaultPartsStockingGroup
    //------------------------------------------------------
    public dealer__Parts_Stocking_Group__c getDefaultPartsStockingGroup() {
        if (PartsStockingGroup==null) {
            getDealerSalesAccount();
             PartsStockingGroup = new dealer__Parts_Stocking_Group__c(
                Name = 'Test Part Stocking Group', dealer__Active__c=TRUE, dealer__Default__c = TRUE,
                dealer__Description__c='Test Part Stocking Group', 
                dealer__Internal_Sales__c = DealerSalesAccount.Id, 
                dealer__Retail_Non_Taxable__c = DealerSalesAccount.Id, 
                dealer__Retail_Taxable__c = DealerSalesAccount.Id, 
                dealer__Wholesale_Non_Taxable__c = DealerSalesAccount.Id, 
                dealer__Wholesale_Taxable__c = DealerSalesAccount.Id
            );
            insert(PartsStockingGroup);
        }
        return PartsStockingGroup;
    }

    // BLL3a FF routines
    // Usage:
    //    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); // BLL1
    //    @testSetup
    //    static void setupFFA() {
    //      TestHelper_MW.createBaseFFAData(FFAdata);
    //    }
    // FFAdata.refresh();
    // System.runAs(FFAdata.TestUser) {
    // }
    
    public class FFATestData {
        public Account Account {get;set;}
        public c2g__codaCompany__c CurrentCompany {get;set;}
        public c2g__codaPeriod__c CurrentPeriod {get;set;}
        public c2g__codaDimension1__c Dimension1 {get;set;}
        public c2g__codaDimension1__c Dimension1b {get;set;}
        public c2g__codaAccountingCurrency__c HomeCurrency {get;set;}
        public Product2 Product {get;set;}
        public Map<String,c2g__codaGeneralLedgerAccount__c> GLAMap {get;set;}
        public User TestUser {get;set;}
        public dealer__Dealer_Location__c DealerLocation {get;set;}
        public void refresh() {
            this.TestUser = [Select Id From User Where Username = 'ffdeveloper@nowhere.com'];
            this.Account = [Select Id, PersonContactId From Account where Name='Tony Stark Enterprises' limit 1];
            this.CurrentCompany = [Select Id, Name From c2g__codaCompany__c where Name='FinancialForce' limit 1];
            this.HomeCurrency = [Select Id, Name From c2g__codaAccountingCurrency__c where c2g__OwnerCompany__c=:this.CurrentCompany.Id order by createddate desc limit 1];
            this.Product = [Select Id, Name From Product2 order by createddate desc limit 1];
            this.DealerLocation = [select Id, Name, dealer__Company_Number__c, Financial_Force_Dimension_1__c from dealer__Dealer_Location__c order by createddate desc limit 1];  
            this.CurrentPeriod = [Select Id, Name From c2g__codaPeriod__c Where c2g__Description__c = 'Trading Period' And c2g__StartDate__c <= :System.today() And c2g__EndDate__c >= :System.today() and c2g__OwnerCompany__c=:this.CurrentCompany.Id order by createddate desc limit 1];
            this.Dimension1 = [select Id, Name, c2g__ReportingCode__c From c2g__codaDimension1__c where c2g__ReportingCode__c='FFA1' limit 1];
            this.Dimension1b = [select Id, Name, c2g__ReportingCode__c from c2g__codaDimension1__c where c2g__ReportingCode__c='FFA1B' limit 1];
            this.GLAMap = new Map<String,c2g__codaGeneralLedgerAccount__c>();
            for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c, c2g__ExternalId__c from c2g__codaGeneralLedgerAccount__c]) this.GLAMap.put(g.c2g__ReportingCode__c, g);
            //for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c]) this.GLAMap.put(g.c2g__ReportingCode__c, g);
            //for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c]) this.GLAMap.put(g.c2g__ReportingCode__c, g);
            //for(c2g__codaGeneralLedgerAccount__c g : [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c]) this.GLAMap.put(g.c2g__ReportingCode__c, g);
        }
    }

    //@testSetup
    public static void createBaseFFAData(FFATestData testData)
    {
        testData.TestUser = createUser();
        testData.DealerLocation = createLocation(testData.TestUser);
        // Authorize user to location - BLL7a
        dealer__Dealer_Location_User__c dlu = new dealer__Dealer_Location_User__c(
        	dealer__User__c = testData.TestUser.Id,
        	dealer__Dealer_Location__c = testData.DealerLocation.Id
        );
        try { insert(dlu); } catch(Exception e) {}
        // BLL7a end

        System.runAs(testData.TestUser)
        {
            Test.startTest();                        
            // GLA's, Accounts and Products are not company aware, create them first
            testData.GLAMap = createGLAccounts();
            testData.Account = createAccount('Tony Stark Enterprises', testData.GLAMap.get('accountsReceivableControl').Id, testData.GLAMap.get('accountsPayableControl').Id);
            testData.Product = createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id);
     
            testData.Dimension1 = createDimension1();
            testData.Dimension1b = createDimension1b();
            
            // create all 'Company' aware data objects
            // Create the Queue and simulate activating the company
            testData.CurrentCompany = createFFACompany('FinancialForce', createFFAQueue(testData.TestUser.Id).Id);
            // Add a user Company
            createUserCompany(testData.CurrentCompany.Id, testData.TestUser.Id);
            // create other base data types...
            testData.HomeCurrency = createHomeCurrency('USD');        
            testData.CurrentPeriod = createYearPeriods();
            testData.DealerLocation.Company__c = testData.CurrentCompany.Id;
            testData.DealerLocation.Financial_Force_Dimension_1__c = testData.Dimension1.Id;
            update(testData.DealerLocation);
            Test.stopTest();
        }
    }

    static dealer__Dealer_Location__c createLocation(User u) {
            dealer__Dealer_Location__c loc = new dealer__Dealer_Location__c();
            loc.Name = 'Test FFA Location xyz';
            loc.dealer__Company_Number__c = 'FFA';
            loc.Region__c = '1';
            loc.dealer__General_Manager__c = u.Id;
            loc.Rental_Manager__c = u.Id; 
            loc.dealer__City__c = 'Richfield';
            loc.dealer__State__c = 'OH';
            loc.dealer__Postal_Code__c = '44286';
            loc.Service_Reporting_User__c = u.Id;	// BLL10a
            //c2g__codaCompany__c comp = getFFCompany(UserInfo.getUserId()); 
            //if (comp!=null) {
            //    loc.Company__c = comp.Id;
            //}
            insert(loc);

	        // Authorize user to location - BLL7a
    	    dealer__Dealer_Location_User__c dlu = new dealer__Dealer_Location_User__c(
        		dealer__User__c = UserInfo.getUserId(),
        		dealer__Dealer_Location__c = loc.Id
	        );
	        try { insert(dlu); } catch(Exception e) {}
	        // BLL7a end

            return loc;
    }

    static c2g__codaDimension1__c createDimension1() {
            c2g__codaDimension1__c dim1 = new c2g__codaDimension1__c();
            dim1.Name = 'Test FFA Dimension1';
            dim1.c2g__ReportingCode__c = 'FFA1';
            insert(dim1);
            return dim1;
    }

    static c2g__codaDimension1__c createDimension1b() {
            c2g__codaDimension1__c dim1b = new c2g__codaDimension1__c();
            dim1b.Name = 'Test FFA Dimension1b';
            dim1b.c2g__ReportingCode__c = 'FFA1B';
            insert(dim1b);
            return dim1b;
    }
    
    static User createUser()
    {
        Profile p = [select id from profile where name='System Administrator'];

        User u = new User();
        u.FirstName = 'FFA';
        u.LastName = 'User';
        u.Alias = 'FFAUSER';
        u.Username = 'ffdeveloper@nowhere.com';
        u.Email = 'ffdeveloper@nowhere.com';
        u.CommunityNickname = 'ffd';
        u.Phone = '555.555.5555';
        u.IsActive = true;
        u.ProfileId = p.Id;
        u.TimeZoneSidKey = 'America/New_York';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.LanguageLocaleKey = 'en_US';
        u.Title = 'The enlightened one';
        u.CompanyName = 'FF Test Company';
        u.Division = 'FFA';

        insert u;

        return u;
    }

    

    /**
        *   Create FFA Queue (FinancialForce)
        *   No @Parms required
    **/
    public static Group createFFAQueue(Id userId) 
    {
        //Create queue
        Group grp = new Group(Type = 'Queue', Name = 'FF FinancialForce');
        insert grp;

        //Create list of all FinancialForce Objctes
        List<String> queueObjectNames =  getQueueObjectNames();

        //Assign Objects to Queue
        List<QueueSObject> newQueueObjects = new List<QueueSObject>();
        for (String queueObjectName : queueObjectNames) 
        {
            newQueueObjects.add(new QueueSObject(QueueId = grp.id, SobjectType = queueObjectName));
        }
        insert newQueueObjects;

        //Assign group to a current user
        insert new GroupMember(GroupId = grp.id, UserOrGroupId = userId); 
        System.debug('COMPANY_GROUPMEMBER');
        System.debug(grp.id);
        System.debug(userId);

        return grp;   
    }
    /**
        *   Create FFA Company (FinancialForce Test Company)
        *   No @Parms required
    **/
    public static c2g__codaCompany__c createFFACompany(String name, Id queueMemberId) 
    {        
        c2g__codaCompany__c testCompany = new c2g__codaCompany__c();
        testCompany.put('Name', name);
        testCompany.put('OwnerId', queueMemberId);
        testCompany.put('c2g__Street__c', 'Cardale Park');
        testCompany.put('c2g__StateProvince__c', 'Beckwith Head Road');
        testCompany.put('c2g__City__c', 'Harrogate');
        testCompany.put('c2g__ZipPostCode__c', 'HG3 1RY');
        testCompany.put('c2g__Country__c', 'United Kingdom');
        testCompany.put('c2g__Phone__c', '+44 (0)1423 537728)');      
             
        insert  testCompany;  

        return testCompany;    

    }
    public static void createUserCompany(Id companyId, Id userId)
    {
        insert new c2g__codaUserCompany__c(c2g__Company__c = companyId, c2g__User__c = userId);        
    }
    /**
        *   Create FFA Currency (USD)
        *   No @Parms required
    **/
    public static c2g__codaAccountingCurrency__c createHomeCurrency(String name) 
    {
        c2g__codaAccountingCurrency__c testCurrency = new c2g__codaAccountingCurrency__c();
        testCurrency.put('Name', name);
        //testCurrency.put('c2g__UnitOfWork__c', 1);
        testCurrency.put('c2g__DecimalPlaces__c', 2);
        testCurrency.put('c2g__Home__c', true);
        testCurrency.put('c2g__Dual__c', true);

        insert testCurrency;

        return testCurrency;
    }

    public static c2g__codaPeriod__c createYearPeriods() 
    {
        String currentYear = String.valueOf(Date.today().year());  

        c2g__codaYear__c yr = new c2g__codaYear__c();
        yr.put('Name', currentYear);
        yr.put('c2g__NumberOfPeriods__c', 12);
        yr.put('c2g__AutomaticPeriodList__c', true);
        yr.put('c2g__StartDate__c', Date.valueOf(currentYear + '-01-01 00:00:00'));
        yr.put('c2g__EndDate__c', Date.valueOf(currentYear + '-12-31 00:00:00'));
        yr.put('c2g__PeriodCalculationBasis__c', 'Month End');

        insert yr;

        String currentMth = String.valueOf(Date.today().month());
        if(currentMth.length() == 1) 
            currentMth = '0' + currentMth;

        List<c2g__codaPeriod__c> periods = new List<c2g__codaPeriod__c>();        

        c2g__codaPeriod__c currentTestPeriod;
        List<String> monthNumbers = new List<String>{'01','02','03','04','05','06','07','08','09','10','11','12','01','12','12'};
        for (String monthNumber : monthNumbers) 
        {
            c2g__codaPeriod__c period = new c2g__codaPeriod__c();
            period.put('Name', currentYear + '/' + '0' + monthNumber);
            period.put('c2g__YearName__c', yr.id);
            period.put('c2g__PeriodNumber__c', '0' + monthNumber);
            period.put('c2g__Description__c', 'Trading Period');                   
            period.put('c2g__StartDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00'));
            period.put('c2g__EndDate__c', Date.valueOf(currentYear + '-' + monthNumber + '-01 00:00:00').addMonths(1).addDays(-1));
            periods.add(period);

            //returns current period
            if (monthNumber == currentMth) 
                currentTestPeriod = period; 
        }
        // fix the opening period
        periods[12].put('Name', currentYear + '/000');
        periods[12].put('c2g__PeriodNumber__c', '000');
        periods[12].put('c2g__Description__c', 'Opening (B/fwd)');
        periods[12].put('c2g__EndDate__c', periods[12].c2g__StartDate__c); 

        // fix the closing period
        periods[13].put('Name' , currentYear + '/101');
        periods[13].put('c2g__PeriodNumber__c', '101');
        periods[13].put('c2g__Description__c', 'Closing (C/fwd)');
        periods[13].put('c2g__StartDate__c', periods[13].c2g__EndDate__c);

        // fix the adjustment period
        periods[14].put('Name' , currentYear + '/100');
        periods[14].put('c2g__PeriodNumber__c', '100');
        periods[14].put('c2g__Description__c', 'Adjustment Period');
        periods[14].put('c2g__StartDate__c', periods[14].c2g__EndDate__c);
                    
        insert periods;
        
        return currentTestPeriod;
    }
    /**
    *   Create GLA Accounts
    *   No @Parms required
    **/
    public static Map<String,c2g__codaGeneralLedgerAccount__c> createGLAccounts()
    {    
        c2g__codaGeneralLedgerAccount__c accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs;
        
        List<c2g__codaGeneralLedgerAccount__c> glaList;

        deferredIncome = new c2g__codaGeneralLedgerAccount__c();
        deferredIncome.put('Name' , '2200t - Deferred Income');
        deferredIncome.put('c2g__ReportingCode__c' , '2200t');
        deferredIncome.put('c2g__ExternalId__c' , '2200t');
        deferredIncome.put('c2g__Type__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__TrialBalance3__c' , 'Accruals and Deferred Income');
        deferredIncome.put('c2g__TrialBalance4__c' , '-');
        deferredIncome.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        deferredIncome.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        deferredIncome.put('c2g__BalanceSheet3__c' , 'Accruals and Deferred Income');

        accountsPayableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsPayableControl.put('Name' , '2000t - Accounts Payable Control');
        accountsPayableControl.put('c2g__ReportingCode__c' , '2000t');
        accountsPayableControl.put('c2g__ExternalId__c' , '2000t');
        accountsPayableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__TrialBalance3__c' , 'Creditors');
        accountsPayableControl.put('c2g__TrialBalance4__c' , '-');
        accountsPayableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsPayableControl.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        accountsPayableControl.put('c2g__BalanceSheet3__c' , 'Creditors');

        accountsReceivableControl = new c2g__codaGeneralLedgerAccount__c();
        accountsReceivableControl.put('Name' , '1200t - Accounts Receivable Control');
        accountsReceivableControl.put('c2g__ReportingCode__c' , '1200t');
        accountsReceivableControl.put('c2g__ExternalId__c' , '1200t');
        accountsReceivableControl.put('c2g__Type__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__TrialBalance2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__TrialBalance3__c' , 'Debtors');
        accountsReceivableControl.put('c2g__TrialBalance4__c' , '-');
        accountsReceivableControl.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        accountsReceivableControl.put('c2g__BalanceSheet2__c' , 'Current Assets');
        accountsReceivableControl.put('c2g__BalanceSheet3__c' , 'Debtors');

        grossRevenue = new c2g__codaGeneralLedgerAccount__c();
        grossRevenue.put('Name' , '4000t - Gross revenue');
        grossRevenue.put('c2g__ReportingCode__c' , '4000t');
        grossRevenue.put('c2g__ExternalId__c' , '4000t');
        grossRevenue.put('c2g__Type__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        grossRevenue.put('c2g__TrialBalance2__c' , 'Gross Profit');
        grossRevenue.put('c2g__TrialBalance3__c' , 'Sales Revenue');
        grossRevenue.put('c2g__TrialBalance4__c' , 'Sales - Direct');
        grossRevenue.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        grossRevenue.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        grossRevenue.put('c2g__BalanceSheet3__c' , '-');

        //Bank Account - Current UK
        bankAccCurUK = new c2g__codaGeneralLedgerAccount__c();
        bankAccCurUK.put('Name' , 'BNK001 UKt 24000 - Customer Prepaids (MPS)');
        bankAccCurUK.put('c2g__ReportingCode__c' , 'BNK001 UKt');
        bankAccCurUK.put('c2g__ExternalId__c' , 'BNK001 UKt');
        bankAccCurUK.put('c2g__Type__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__TrialBalance2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__TrialBalance3__c' , 'Bank and Cash');
        bankAccCurUK.put('c2g__TrialBalance4__c' , '');
        bankAccCurUK.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankAccCurUK.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankAccCurUK.put('c2g__BalanceSheet3__c' , 'Bank and Cash');

        //Bank Charges
        bankCharges = new c2g__codaGeneralLedgerAccount__c();
        bankCharges.put('Name' , '61620 - Bank Charges');
        bankCharges.put('c2g__ReportingCode__c' , '61620');
        bankCharges.put('c2g__ExternalId__c' , '61620');
        bankCharges.put('c2g__Type__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankCharges.put('c2g__TrialBalance2__c' , 'Operating Expenses');
        bankCharges.put('c2g__TrialBalance3__c' , 'Administration Costs');
        bankCharges.put('c2g__TrialBalance4__c' , '');
        bankCharges.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankCharges.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankCharges.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Bank Charges
        bankInterest = new c2g__codaGeneralLedgerAccount__c();
        bankInterest.put('Name' , '64740 - Bank Interest');
        bankInterest.put('c2g__ReportingCode__c' , '64740');
        bankInterest.put('c2g__ExternalId__c' , '64740');
        bankInterest.put('c2g__Type__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        bankInterest.put('c2g__TrialBalance2__c' , 'Interest and Taxation');
        bankInterest.put('c2g__TrialBalance3__c' , 'Finance Costs');
        bankInterest.put('c2g__TrialBalance4__c' , '');
        bankInterest.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        bankInterest.put('c2g__BalanceSheet2__c' , 'Current Assets');
        bankInterest.put('c2g__BalanceSheet3__c' , 'Profit and Loss');

        //Tax Code
        salesTaxA = new c2g__codaGeneralLedgerAccount__c();
        salesTaxA.put('Name' , '2160t - Sales Tax A');
        salesTaxA.put('c2g__ReportingCode__c' , '2160t');
        salesTaxA.put('c2g__ExternalId__c' , '2160t');
        salesTaxA.put('c2g__Type__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__TrialBalance2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__TrialBalance3__c' , 'Tax Liability');
        salesTaxA.put('c2g__TrialBalance4__c' , '');
        salesTaxA.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        salesTaxA.put('c2g__BalanceSheet2__c' , 'Current Liabilities');
        salesTaxA.put('c2g__BalanceSheet3__c' , 'Tax Liability');

        cogs = new c2g__codaGeneralLedgerAccount__c();
        cogs.put('Name' , '5100t - COGS - Materials');
        cogs.put('c2g__ReportingCode__c' , '5100t');
        cogs.put('c2g__ExternalId__c' , '5100t');
        cogs.put('c2g__Type__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance1__c' , 'Profit and Loss');
        cogs.put('c2g__TrialBalance2__c' , 'Gross Profit');
        cogs.put('c2g__TrialBalance3__c' , 'Cost of Sales');
        cogs.put('c2g__TrialBalance4__c' , 'Cost of Sales - Direct');
        cogs.put('c2g__BalanceSheet1__c' , 'Balance Sheet');
        cogs.put('c2g__BalanceSheet2__c' , 'Profit and Loss');
        cogs.put('c2g__BalanceSheet3__c' , '');
        
        glaList = new List<c2g__codaGeneralLedgerAccount__c>{accountsPayableControl, accountsReceivableControl, grossRevenue, bankAccCurUK, bankCharges, bankInterest, deferredIncome, salesTaxA, cogs};
        insert glaList;
        
        return new Map<String,c2g__codaGeneralLedgerAccount__c>{
            'accountsPayableControl'=>accountsPayableControl,
            'accountsReceivableControl'=>accountsReceivableControl,
            'grossRevenue'=>grossRevenue,
            'bankAccCurUK'=>bankAccCurUK,
            'bankCharges'=>bankCharges,
            'bankInterest'=>bankInterest,
            'deferredIncome'=>deferredIncome,
            'salesTaxA'=>salesTaxA,
            'cogs'=>cogs
        };
        
    }

    /**
    *   Create or Insert Account
    *   No @Parms required
    **/
    public static Account createAccount(String name, Id accountsReceivableControlId, Id accountsPayableControlId)
    {
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();
		Schema.RecordTypeInfo rtInfo = RcdTypes.get('Business Account');

        Account productServices = new Account();
		productServices.put('RecordTypeId', rtInfo.getRecordTypeId());
        productServices.put('Name', name);
        //productServices.put('CurrencyIsoCode', 'USD');
        productServices.put('Type', 'Customer - Direct');
        productServices.put('Industry', 'Apparel');
        productServices.put('AnnualRevenue', 350000000);
        productServices.put('Ownership', 'Public');
        productServices.put('Rating', 'Warm');
        productServices.put('Phone', '(336) 222-7000');
        productServices.put('Fax', '(336) 222-8000');
        productServices.put('Website', 'http://www.financialforce.com');
        productServices.put('TickerSymbol', 'BTXT');
        productServices.put('NumberOfEmployees', 9000);
        productServices.put('SIC', '546732');
        productServices.put('c2g__CODAReportingCode__c', 'ABC123t');
        productServices.put('c2g__CODAAccountsReceivableControl__c', accountsReceivableControlId);
        productServices.put('c2g__CODAAccountsPayableControl__c', accountsPayableControlId);
        productServices.put('c2g__CODASalesTaxStatus__c', 'Exempt');
        productServices.put('c2g__CODAVATStatus__c', 'EC Registered');
        productServices.put('c2g__CODAECCountryCode__c', 'FR');
        productServices.put('c2g__CODAVATRegistrationNumber__c', '123 43223 3');
        productServices.put('c2g__CODATaxCalculationMethod__c', 'Gross');
        productServices.put('c2g__CODAInvoiceEmail__c', 'productservices@financialforce.com');
        productServices.put('c2g__CODADescription1__c', 'Standard Terms');
        productServices.put('c2g__CODADaysOffset1__c', 30);
        productServices.put('c2g__CODABaseDate1__c', 'Invoice Date');
        productServices.put('c2g__CODADiscount1__c', 0);
        productServices.put('c2g__CODAAccountTradingCurrency__c', 'USD');

        insert productServices;

        return productServices;
    }   
    /**
        *   Create Product
        *   No @Parms required
    **/
    public static Product2 createProduct(Id cogsId, Id grossRevenueId)
    {
        Product2 prod = new Product2();
        prod.put('Name' , 'Titanium');
        prod.put('ProductCode' , 'TIT101');
        prod.put('IsActive' , true);
        prod.put('c2g__CODAPurchaseAnalysisAccount__c' , cogsId);
        prod.put('c2g__CODASalesRevenueAccount__c' , grossRevenueId);
        prod.put('c2g__CODASalesTaxStatus__c' , 'Taxable');

        insert prod;
        return prod;
    }
    /**
        *   Create PricebookEntry
        *   One Param required 
        *       - Id prodId - Product2 Id
    **/
    public static PricebookEntry createPriceBook(Id prodId)
    {
        // Get Pricebook
        Pricebook2 priceBook = Database.query('select id from Pricebook2 where IsStandard = true');
        priceBook.put('IsActive' , true);
        update priceBook;  

        PricebookEntry priceBookEntry = new PricebookEntry();
        priceBookEntry.put('Pricebook2Id' , priceBook.Id);
        priceBookEntry.put('Product2Id' , prodId); 
        priceBookEntry.put('UnitPrice' , 5000);
        priceBookEntry.put('IsActive' , true);
        priceBookEntry.put('UseStandardPrice' , false);

        insert priceBookEntry;

        return priceBookEntry;
    }
    /**
    *   Create Sales Invoice Header
    *   One Param required 
    *       - Id accId - Account Id
    **/
    //public static c2g__codaInvoice__c createSalesInvoice(Id accId, Id currencyId, Id periodId)
    //{
    //   c2g__codaInvoice__c invoice = new c2g__codaInvoice__c();
    //    invoice.put('c2g__Account__c' , accId);
    //    invoice.put('c2g__InvoiceDate__c' , System.today());
    //    invoice.put('c2g__InvoiceCurrency__c' , currencyId);
    //    invoice.put('c2g__Period__c' , periodId);
    //
    //    insert invoice;
    //    return invoice;
    //}
    /**
    *   Create Sales Invoice Line
    *   Two Param required 
    *       - Id prodId - Product2 Id
    *       - Id headerId - Sales Invoice Header Id
    **/
    //public static c2g__codaInvoiceLineItem__c createSalesInvoiceLine(Id headerId, Id prodId)
    //{
    //    c2g__codaInvoiceLineItem__c invoiceLine = new c2g__codaInvoiceLineItem__c();
    //    invoiceLine.put('c2g__Quantity__c' ,500);
    //    invoiceLine.put('c2g__LineDescription__c' , 'Testing123CoolDude123Income');
    //    invoiceLine.put('c2g__UnitPrice__c' , 1);
    //    invoiceLine.put('c2g__Product__c' , prodId);
    //    invoiceLine.put('c2g__DeriveUnitPriceFromProduct__c' , false);
    //    invoiceLine.put('c2g__Invoice__c' , headerId);
    //
    //    insert invoiceLine;
    //    return invoiceLine;
    //}
    
    /**
        *   Create List of Object Queue Names
        *   No @Parms required
    **/
    public static List<String> getQueueObjectNames()
    {
        List<String> objectNames = new List<String>();

        //Financial Objects
        objectNames.add('c2g__codaCompany__c');
        objectNames.add('c2g__codaYear__c');
        objectNames.add('c2g__codaCurrencyRevaluation__c');
        objectNames.add('c2g__ReportingBalance__c');
        objectNames.add('c2g__codaBudget__c');
        objectNames.add('c2g__codaBankAccount__c');
        objectNames.add('c2g__codaBankStatement__c');
        objectNames.add('c2g__codaPaymentMediaControl__c');
        objectNames.add('c2g__codaBankReconciliation__c');
        objectNames.add('c2g__codaPaymentMediaSummary__c');
        objectNames.add('c2g__codaMatchingReference__c');
        objectNames.add('c2g__codaAccountingCurrency__c');
        objectNames.add('c2g__codaGroupingReference__c');
        objectNames.add('c2g__codaPaymentTemplate__c');

        //Document Objects
        objectNames.add('c2g__codaTransaction__c');
        objectNames.add('c2g__codaInvoice__c');
        objectNames.add('c2g__codaJournal__c');
        objectNames.add('c2g__codaCreditNote__c');
        objectNames.add('c2g__codaCashEntry__c');
        objectNames.add('c2g__codaPurchaseInvoice__c');
        objectNames.add('c2g__codaPurchaseCreditNote__c');
        objectNames.add('c2g__codaPayment__c');
        //objectNames.add('c2g__CancelPayment__c');
        objectNames.add('c2g__codaCashMatchingHistory__c');

        //Random Objects
        objectNames.add('c2g__codaTextDefinition__c');
        objectNames.add('c2g__codaIntercompanyDefinition__c');
        //objectNames.add('c2g__AsOfAging__c');
        objectNames.add('c2g__codaIntercompanyTransfer__c');
        objectNames.add('c2g__codaYear__c');

        return objectNames;     
    }

    
    // BLL3a end
    
    // JVK - Adding back methods previously overwritten.
    // 
    public PostingTemplate__c getPostingTemplate() {
        // Return generic posting template
        PostingTemplate__c pt = new PostingTemplate__c();
        insert pt;

        return pt;
    }

    public dealer__Deal__c getDealBasic(Id sup, Id loc, Id a) {
        dealer__Deal__c Deal = new dealer__Deal__c();
        Deal.dealer__Deal_ID__c = '000000000000001';
        Deal.dealer__Buyer__c = a;
        Deal.dealer__Sales_Lead__c = sup;
        Deal.dealer__Store_Location__c = loc;
        Deal.dealer__Licence__c = '100';
        Deal.Name = '12342';
        
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

    //public dealer__Vehicle_Inventory__c getVehicleInventory(String v) {

    //    dealer__Vehicle_Inventory__c VI = new dealer__Vehicle_Inventory__c();
    //    VI.Name = 'Test Vehicle Inventory';
    //    VI.dealer__Model__c = 'Civic';
    //    VI.dealer__Stock_Number__c = v;
    //    VI.dealer__VIN__c = v;
    //    VI.dealer__Company_Number__c = 'Location 1';
    //    VI.dealer__Year__c = '2014';
    //    VI.dealer__Make__c = 'Honda';
        
    //    insert VI;   
    //    return VI;     
    //}    


	// BLL11a
	// createGeneralLedgerAccounts
	public void createGeneralLedgerAccounts(List<String> glcodes) {
		List<c2g__codaGeneralLedgerAccount__c> newglas = new List<c2g__codaGeneralLedgerAccount__c>();
		for(String c : glcodes) {
			newglas.add(new c2g__codaGeneralLedgerAccount__c(
			Name=c+' Acct',
			c2g__ReportingCode__c=c,
			c2g__ExternalId__c=c,
			c2g__Type__c='Balance Sheet',
			c2g__TrialBalance1__c='Balance Sheet',
			c2g__BalanceSheet1__c='Balance Sheet'
		));			
		}
		insert(newglas);
	}


	// create sample PO
	// requires testhelper_mw.ffadata be set to the structure that was built using createBaseFFAdata
    public dealer__Purchase_Order__c CreateTestPOData(String rcdtype, dealer__Dealer_Location__c loc, Account vendor, Decimal invoiceamt){
        dealer__Purchase_Order__c p = CreateTestPurchaseOrder(rcdtype, loc, vendor);
        p.dealer__Invoice_Amount__c = invoiceamt;
        insert p;
        list<dealer__Purchase_Order_Line__c> poLines = CreateTestPurchaseOrderLines(p,
        	new List<String>{'2115','2115'});
        return p;
    }

    public dealer__Purchase_Order__c CreateTestPurchaseOrder(String rcdtype, dealer__Dealer_Location__c loc, Account vendor){
		Map<String, Schema.RecordTypeInfo> RcdTypes = Schema.SObjectType.dealer__Purchase_Order__c.getRecordTypeInfosByName();
		Schema.RecordTypeInfo rcdtypeInfo = RcdTypes.get(rcdtype);
		Id rcdtypeId = rcdtypeInfo.getRecordTypeId();
			
        dealer__Purchase_Order__c po =  new dealer__Purchase_Order__c(
        RecordTypeId=rcdtypeId,
        dealer__Invoice_Amount__c = 90000, 
        dealer__Invoice_Date__c = date.today(), 
        dealer__Invoice_Number__c = '12345', 
        dealer__PO_Key__c = '112233',
        dealer__Status__c = 'Open', 
        //dealer__Post_Date_Time__c = datetime.now(), 
        dealer__Requested_By__c = 'test person', 
        dealer__Type__c= rcdtype, 
        dealer__Vendor_City__c = 'Test City' , 
        dealer__Vendor_Country__c = 'USA', 
        dealer__Vendor_Email__c='test@test1.com', 
        dealer__Vendor_Name__c = 'Test Vendor', 
        dealer__Vendor_Phone__c = '12121223', 
        dealer__Vendor_Postal_Code__c='343434', 
        dealer__Vendor_State__c='GA', 
        dealer__Vendor_Street__c = 'Main St', 
        dealer__Comments__c = 'test comm', 
        dealer__Freight__c = 500, 
        NMEDA_Fee__c = 300, 
        Invoice_Adjustment__c = 40, 
        dealer__Company__c = loc.Id, 
        dealer__Vendor__c = vendor.Id, 
        Parts_Amount__c = 1000 
        );
        return po;
    }
    public List<dealer__Purchase_Order_Line__c>  CreateTestPurchaseOrderLines(dealer__Purchase_Order__c po, List<String> glacodes){
		List<dealer__Purchase_Order_Line__c> lines = new List<dealer__Purchase_Order_Line__c>();
		
		Map<String, c2g__codaGeneralLedgerAccount__c> glamap = new Map<String, c2g__codaGeneralLedgerAccount__c>();
		for(c2g__codaGeneralLedgerAccount__c gla : [select Id, Name, c2g__ReportingCode__c, c2g__ExternalId__c from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c in :glacodes]) {
			glamap.put(gla.c2g__ReportingCode__c, gla);
		}
					
        for(String code : glacodes){
            lines.add(new dealer__Purchase_Order_Line__c(
				dealer__Purchase_Order__c = po.Id,
				dealer__Amount__c = 995,
				Add_to_Chassis__c = false,
				Add_to_Conversion__c = false,
				General_Ledger_Account__c = glamap.get(code).Id
            ));
        }
        insert lines;
        return lines;
    }


}