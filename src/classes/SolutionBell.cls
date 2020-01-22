/*
SolutionBell
Programmer: Bryan Leaman
Date: July 2, 2019

Modification log:

*/
global class SolutionBell {
    public Integer startyear {get;set;}
    public static Integer target;
    public static Integer yearnbr;
	public static Integer prior;

    public SolutionBell() {
        startyear = 2018;
    }

    @AuraEnabled
    public static SolutionCountWrapper countSolutionsForYear(Integer year) {
        Integer tot;
        yearnbr = year;
        
        String soql1 = 'select count(Id) nbr '
         + ' from dealer__Deal__c '
         + ' where dealer__Status__c in (\'Won - Delivered\', \'Won - Posted\') '
         + '   and CALENDAR_YEAR(Proposed_Delivery_Date__c) = :yearnbr '
         + '   and dealer__Deal_Type__c!=\'Wholesale\' '
         + '   and dealer__Deal_Type__c!=\'Financial Products\' ';
        
        String soql2 = 'select count(Id) nbr '
         + ' from dealer__Rental_Agreements__c '
         + ' where dealer__Agreement_Status__c = \'Paid\' '
         + ' and CALENDAR_YEAR(dealer__Return_Date__c) = :yearnbr ';
    
        AggregateResult ar1 = Database.query(soql1);
        AggregateResult ar2 = Database.query(soql2);
        Integer dc = (Integer) ar1.get('nbr');
        Integer rc = (Integer) ar2.get('nbr');
        SolutionCountWrapper scw = new SolutionCountWrapper(yearnbr, dc, rc); 
        System.debug(scw);
        return scw;
    }
    
    @AuraEnabled
    public static List<SolutionBell.SolutionWrapper> findSolutions(Integer year, Integer priorcnt, Integer targetnbr) {
        target = targetnbr;
        yearnbr = year;
		prior = priorcnt;
		System.debug(target);
		System.debug(yearnbr);
		System.debug(prior);
        //Integer currentyr = Date.today().year();
        //Integer tot = 0;
    
        // Now we need to sort the final year by solution and get the target item
        String soqldeals = 'select Id, Name, Proposed_Delivery_Date__c, dealer__Salesperson_1__c, dealer__Salesperson_1__r.Name, CreatedDate, TaxPostDT__c, Posted_DT__c, MarkDelivered_DT__c '
         + ' from dealer__Deal__c '
         + ' where dealer__Status__c in (\'Won - Delivered\', \'Won - Posted\') '
         + '   and CALENDAR_YEAR(Proposed_Delivery_Date__c) = :yearnbr '
         + '   and dealer__Deal_Type__c!=\'Wholesale\' '
         + '   and dealer__Deal_Type__c!=\'Financial Products\' ';
        
        String soqlrentals = 'select Id, Name, dealer__Return_Date__c, CreatedById, CreatedBy.Name, CreatedDate, TaxPostDT__c '
         + ' from dealer__Rental_Agreements__c '
         + ' where dealer__Agreement_Status__c = \'Paid\' '
         + ' and CALENDAR_YEAR(dealer__Return_Date__c) = :yearnbr ';
        
        
        List<SolutionBell.SolutionWrapper> sol = new List<SolutionBell.SolutionWrapper>();
    
        for (dealer__Deal__c d : Database.query(soqldeals)) {
            sol.add(new SolutionWrapper(
                d.Id, d.Name, d.Proposed_Delivery_Date__c, d.MarkDelivered_DT__c /*d.CreatedDate*/, d.dealer__Salesperson_1__c, d.dealer__Salesperson_1__r.Name
            ));
        }
        Integer nbrdeals = sol.size();
        System.debug(sol.size());
        for(dealer__Rental_Agreements__c r : Database.query(soqlrentals)) {
            sol.add(new SolutionWrapper(
                r.Id, r.Name, r.dealer__Return_Date__c, r.TaxPostDT__c /*r.CreatedDate*/, r.CreatedById, r.CreatedBy.Name
            ));
        }
        Integer nbrrentals = sol.size()-nbrdeals;
        System.debug(nbrrentals);
        System.debug(sol.size());
        sol.sort();
        
		System.debug(sol.size());
		Integer fromnbr = target-prior-5;
		Integer tonbr = target-prior+6;
		if (fromnbr>sol.size()) {
			fromnbr = sol.size()-5;
			if (fromnbr<1) fromnbr=1;
			tonbr = sol.size();
		}

		System.debug(prior);
		System.debug(fromnbr);
		System.debug(tonbr);
        List<SolutionBell.SolutionWrapper> rtnsol = new List<SolutionBell.SolutionWrapper>();
        for(Integer i=fromnbr; i<=tonbr && i<=sol.size(); i++) {
			System.debug(i);
			System.debug(i+prior);
            sol[i-1].SolutionNbr = i+prior;
			if ((i+prior)==target) sol[i-1].Winner = true;
            System.debug(String.valueOf(i+prior) + ' : ' + JSON.serialize(sol[i-1]));
            rtnsol.add(sol[i-1]);
        }
        return rtnsol;
    }

    global class SolutionCountWrapper  {
        @AuraEnabled public Integer yearnbr {get;set;}
        @AuraEnabled public Integer deals {get;set;}
        @AuraEnabled public Integer rentals {get;set;}
        @AuraEnabled public Integer total {get;set;}
        public SolutionCountWrapper(Integer yr, Integer dealcount, Integer rentalcount) {
            yearnbr = yr;
            deals = dealcount;
            rentals = rentalcount;
            total = deals+rentals;
        }
    }
    
    global class SolutionWrapper implements Comparable {
        @AuraEnabled public Integer SolutionNbr {get;set;}
        @AuraEnabled public Id SolutionId {get;set;}
        @AuraEnabled public String SolutionName {get;set;}
        @AuraEnabled public Date SolutionDate {get;set;}
        @AuraEnabled public DateTime SolutionDateTime {get;set;}
        @AuraEnabled public Id SalespersonId {get;set;}
        @AuraEnabled public String SalespersonName {get;set;}
		@AuraEnabled public boolean Winner {get;set;}
    
        public SolutionWrapper(Id solId, String solNm, Date solDt, DateTime crtDt, Id slsId, String slsNm) {
            SolutionNbr = 0;
			Winner = false;
            SolutionId = solId;
            SolutionName = solNm;
            SolutionDate = solDt;
            SolutionDateTime = crtDt;
            SalespersonId = slsId;
            SalespersonName = slsNm;
        }
    
        global Integer compareTo(Object compareto) {
            SolutionWrapper compareSol = (SolutionWrapper) compareto;
            Integer rtn = 0;
            if (SolutionDate > compareSol.SolutionDate) rtn = 1;
            else if (SolutionDate < compareSol.SolutionDate) rtn = -1;
            else if (SolutionDate==compareSol.SolutionDate && SolutionDateTime > compareSol.SolutionDateTime) rtn = 1;
            else if (SolutionDate==compareSol.SolutionDate && SolutionDateTime < compareSol.SolutionDateTime) rtn = -1;
            return rtn;
        }
    }
    
}