/**
 * PartsProcess
 * Tested by: PartsProcess_TEST
 * Date: Mar 2, 2018
 * Programmer: Bryan Leaman
 *
 * Code Coverage:
 *  2018-03-05  98% (74/75)
 *  2018-05-18  98% (83/84)
 *	2019-07-30	99%	(127/128)
 *
 * Modification log:
 *  2018-05-18  B. Leaman   BLL1-Round the parts pricing results!
 *  2019-03-28  A. Miller   AMM2/BLL2 - W-000554 Update to handle ensuring the name and Raw Part Number is always uppercase
 *	2019-07-26	B. Leaman	W-000703 BLL3 - replicate static price changes down to parts inventory records
 */
public with sharing class PartsProcess {

    public static List<dealer__Parts_Master__c> newList;
    public static Map<Id, dealer__Parts_Master__c> oldMap;

    public static Set<Id> MasterIds;
    public static Map<Id, String> NewPartNameMap;
    public static Map<Id, String> NewPartNbrMap;
    public static Map<Id, String> OldPartNameMap;
    public static Map<Id,dealer__PartSupersession__c> superSessions;


    // doPartMasterSuppressions
    // Kick of part suppression by updating the parts master record(s)
    public static void doPartMasterSupersessions(List<dealer__Parts_Master__c> nlist, Map<Id, dealer__Parts_Master__c> omap) {
        newList = nlist;
        oldMap = omap;
        
        MasterIds = new Set<Id>();
        NewPartNameMap = new Map<Id, String>();
        NewPartNbrMap = new Map<Id, String>();
        OldPartNameMap = new Map<Id, String>();
        superSessions = new Map<Id,dealer__PartSupersession__c>();

        Map<String, dealer__Parts_Master__c> DupPartMap = new Map<String, dealer__Parts_Master__c>();

        for(dealer__Parts_Master__c pm : newList) {
            if (!String.isBlank(pm.CreateSupersession__c)) {
                // don't force uppercase at this time: pm.CreateSupersession__c = pm.CreateSupersession__c.toUpperCase();
                if (pm.dealer__Manufacturer__c==null) pm.addError('Manufacturer is required to perform a part supersession.');
                else if (pm.CreateSupersession__c.startsWith(pm.dealer__Manufacturer__c+':')) pm.addError('New part number cannot already start with the manufacturer prefix.');
                else {
                    MasterIds.add(pm.Id);
                    String newPartName = pm.dealer__Manufacturer__c + ':' + pm.CreateSupersession__c;
                    if (pm.Name!=newPartName) NewPartNameMap.put(pm.Id, newPartName);
                    if (pm.Name!=newPartName) NewPartNbrMap.put(pm.Id, pm.CreateSupersession__c);
                    if (pm.Name!=newPartName) OldPartNameMap.put(pm.Id, pm.Name);
                }
            }
        }

        for(dealer__Parts_Master__c pm : [select Id, Name, dealer__Part_No__c, dealer__Manufacturer__c from dealer__Parts_Master__c where dealer__Part_No__c in :NewPartNameMap.values()]) {
            if (pm.dealer__Part_No__c.startsWith(pm.dealer__Manufacturer__c+':')) DupPartMap.put(pm.dealer__part_No__c, pm);
        }

        for(dealer__Parts_Master__c pm : newList) {
            String newname = NewPartNameMap.get(pm.Id);
            String newpnbr = NewPartNbrMap.get(pm.Id);
            String oldname = pm.Name;
            System.debug(pm.Name);
            System.debug(newname);
            System.debug(newpnbr);
            System.debug(oldname);
            if (DupPartMap.containsKey(newname)) pm.addError('New part number ' + newname + ' already exists.');
            else if (!String.isBlank(newname)) {
                pm.dealer__Part_No__c = newname;
                pm.Name = newpnbr;
                pm.dealer__Raw_Part_Number__c = newpnbr.replaceAll('[^a-zA-Z0-9]', '');
                pm.Supersedes__c = PartsProcess.prepend(oldname, pm.Supersedes__c, 128);
                superSessions.put(pm.Id, new dealer__PartSupersession__c(
                    dealer__Parts_Master__c = pm.Id,
                    dealer__Old_Part__c=oldName
                ));     
            }           
            pm.CreateSupersession__c = null;
        }

        // Supersessions
        insert(superSessions.values());
    }   


    // doPartsInventorySupersession
    // runs in "after" context, relying on having filled in the part supersession maps from the before context
    public static void doPartsInventorySupersession(List<dealer__Parts_Master__c> nlist, Map<Id, dealer__Parts_Master__c> omap) {
        newList = nlist;
        oldMap = omap;
        if (MasterIds == null) MasterIds = new Set<Id>();
        
        // Parts Inventory updates
        List<dealer__Parts_Inventory__c> invUpdate = new List<dealer__Parts_Inventory__c>();
        for(dealer__Parts_Inventory__c p : [
            select Id, Name, dealer__Part_No__c, dealer__Parts_Master__c, dealer__MFG__c, dealer__Location__r.dealer__Company_Number__c, dealer__Supersedes__c 
            from dealer__Parts_Inventory__c
            where dealer__Parts_Master__c in :MasterIds
        ]) {
            String newname = NewPartNameMap.get(p.dealer__Parts_Master__c);
            String newpnbr = NewPartNbrMap.get(p.dealer__Parts_Master__c);
            String oldname = OldPartNameMap.get(p.dealer__Parts_Master__c);
            String supersedetext = PartsProcess.prepend(oldname, p.dealer__Supersedes__c, 128);
            System.debug('Update parts inventory ' + p.Name);
            if (superSessions.containsKey(p.dealer__Parts_Master__c)) { 
                invUpdate.add(new dealer__Parts_Inventory__c(
                    Id = p.Id,
                    Name = p.dealer__MFG__c + ':' + newpnbr,
                    dealer__Part_No__c = p.dealer__Location__r.dealer__Company_Number__c + ':' + p.dealer__MFG__c + ':' + newpnbr,
                    dealer__Company_Number__c = p.dealer__Location__r.dealer__Company_Number__c,
                    dealer__Supersedes__c = supersedetext 
                ));
            }
        }
        System.debug(invUpdate.size());
        if (invUpdate.size()>0) System.debug(invUpdate[0]);
        update(invUpdate);
        if (invUpdate.size()>0) System.debug(invUpdate[0]);
        
    }


    public static String prepend(String prefix, String oldstr, Integer maxlen) {
        if (oldstr==null) oldstr = '';
        String newstr = oldstr;
        if (!oldstr.contains(prefix)) { // don't pre-pend if it's already in there somewhere anyway
            if (!String.isBlank(oldstr)) prefix += ', ';
            if (oldstr==null) oldstr = '';
            newstr = prefix + oldstr;
            Integer endidx = newstr.length();
            while (endidx > maxlen) {
                endidx = newstr.lastIndexOf(',', endidx-1);
            }
            newstr = newstr.substring(0,endidx);
        }
        return newstr.trim();
    }

    public static Decimal RetailPriceMarkUpFromCost(Decimal partcost) {
        Decimal newRetailPrice = partcost * 1.00;
        if (partcost <= 1.00)         { newRetailPrice = (partcost * 5.00); }
        else if (partcost <=    2.50) { newRetailPrice = (partcost * 4.50); }
        else if (partcost <=    5.00) { newRetailPrice = (partcost * 4.00); }
        else if (partcost <=   25.00) { newRetailPrice = (partcost * 3.75); }
        else if (partcost <=   33.00) { newRetailPrice = (partcost * 3.50); }  
        else if (partcost <=   49.00) { newRetailPrice = (partcost * 3.20); }  
        else if (partcost <=   65.00) { newRetailPrice = (partcost * 2.80); }  
        else if (partcost <=   81.00) { newRetailPrice = (partcost * 2.30); }  
        else if (partcost <= 2000.00) { newRetailPrice = (partcost * 2.00); }  
        else if (partcost <= 4000.00) { newRetailPrice = (partcost * 1.66); }  
        else if (partcost >  4000.00) { newRetailPrice = (partcost * 1.40); }  
        newRetailPrice = newRetailPrice.setScale(2, System.RoundingMode.HALF_UP);   // BLL1a
        return newRetailPrice;      
    }

    // AMM2
    public static void ensureUppercase(List<dealer__Parts_Master__c> listOfPartMasters)
    {
        for(dealer__Parts_Master__c tempPartMaster : listOfPartMasters)
        {
            if(!tempPartMaster.Name.equals(tempPartMaster.Name.replaceAll('[a-z]',''))) 
            {
                tempPartMaster.Name = tempPartMaster.Name.toUpperCase();
            }

            if(!tempPartMaster.dealer__Raw_Part_Number__c.equals(tempPartMaster.dealer__Raw_Part_Number__c.replaceAll('[a-z]',''))) 
            {
                tempPartMaster.dealer__Raw_Part_Number__c = tempPartMaster.dealer__Raw_Part_Number__c.toUpperCase();
            }

			// BLL6
            if(!tempPartMaster.dealer__Part_No__c.equals(tempPartMaster.dealer__Part_No__c.replaceAll('[a-z]',''))) 
            {
                tempPartMaster.dealer__Part_No__c = tempPartMaster.dealer__Part_No__c.toUpperCase();
            }
			// BLL6 end
        }
    }
    // AMM2

    // BLL2
    public static void ensureUppercasePart(List<dealer__Parts_Inventory__c> listOfParts)
    {
        for(dealer__Parts_Inventory__c tempPart : listOfParts)
        {
            if(!tempPart.Name.equals(tempPart.Name.replaceAll('[a-z]',''))) 
            {
                tempPart.Name = tempPart.Name.toUpperCase();
            }

            if(!tempPart.dealer__Part_No__c.equals(tempPart.dealer__Part_No__c.replaceAll('[a-z]',''))) 
            {
                tempPart.dealer__Part_No__c = tempPart.dealer__Part_No__c.toUpperCase();
            }
        }
    }
    // BLL2

	// BLL3
	// MasterStaticPriceUpdate - after update!
    public static void MasterStaticPriceUpdate(List<dealer__Parts_Master__c> nlist, Map<Id, dealer__Parts_Master__c> omap) {
		Map<Id, Decimal> pmStaticMap = new Map<Id, Decimal>();
		for(dealer__Parts_Master__c pm : nlist) {
			dealer__Parts_Master__c oldpm = omap.get(pm.Id);
			if (oldpm!=null && pm.Static_price__c!=oldpm.Static_price__c) {
				pmStaticMap.put(pm.Id, pm.Static_price__c);
			}
		}
		System.debug(pmStaticMap);
		List<dealer__Parts_Inventory__c> pinvs = new List<dealer__Parts_Inventory__c>();
		for(dealer__Parts_Inventory__c pi : [
				select Id, dealer__Cost__c, dealer__Static_Price__c, dealer__Parts_Master__c  
				from dealer__Parts_Inventory__c
				where dealer__Parts_Master__c in :pmStaticMap.keySet()
			]) {
			System.debug(pi);
			Decimal staticprice = pmStaticMap.get(pi.dealer__Parts_Master__c);
			dealer__Parts_Inventory__c updpi = new dealer__Parts_Inventory__c(
				Id = pi.Id, 
				dealer__Cost__c=pi.dealer__Cost__c, 
				dealer__Static_Price__c = staticprice
			);
			System.debug(updpi);
			if (pi.dealer__Static_Price__c!=staticprice) pinvs.add(updpi);
		}
		System.debug(pinvs);
		update(pinvs);
	}

	// NewPartStaticPrice - before insert only!
	// (need to allow part inventory static price override up until parts master is updated again)
	public static void NewPartStaticPrice(List<dealer__Parts_Inventory__c> nlist) {
		Set<Id> pmIds = new Set<Id>();
		for(dealer__Parts_Inventory__c pi : nlist) {
			if (pi.dealer__Parts_Master__c!=null) pmIds.add(pi.dealer__Parts_Master__c);
		}
		Map<Id, dealer__Parts_Master__c> pmMap = new Map<Id, dealer__Parts_Master__c>([
			select Id, Static_Price__c 
			from dealer__Parts_Master__c 
			where Id in :pmIds
		]);
		System.debug(pmMap);
		// Update parts inventory record
		for(dealer__Parts_Inventory__c pi : nlist) {
			dealer__Parts_Master__c pm = pmMap.get(pi.dealer__Parts_Master__c);
			Decimal staticprice = pm!=null ? pm.Static_price__c : null;
			System.debug(pm);
			System.debug(pi.dealer__Static_Price__c);
			if ( pm!=null && (pi.dealer__Static_Price__c==null || pi.dealer__Static_Price__c==0.00)) {
				pi.dealer__Static_Price__c = staticprice;
				System.debug(pi.dealer__Static_Price__c);
			}
		}
	}
	// BLL3

}