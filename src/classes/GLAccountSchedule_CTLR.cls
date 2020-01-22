/**
 * GLAccountSchedule_CTLR
 * Used in: GLAccountSchedule, GLAccountScheduleXLS 
 * Tested by: GLAccountSchedule_TEST
 *
 * 	   Date   	Programmer	Comments
 * 	----------	----------	-------------------------------------------------------------------------------
 * 	2015-10-09 	B. Leaman   BLL1 - Support multiple locations at a time.
 *	2016-04-06	B. Leaman	BLL2 - change multi-select to select2 drop-downs.
 *	2016-05-02	B. Leaman	BLL3 IT#24272 - Limit results to 1000 rows and issue warning.
 *	2016-05-03	B. Leaman	BLL4 - Create xls (csv) in batch.
 *
 */
public with sharing class GLAccountSchedule_CTLR {
    
    // for lookup of GL account, Dimension 1 (location) 
    public c2g__codaJournal__c lookuph {get;set;}
    public c2g__codaJournalLineItem__c lookupd {get;set;}
    public boolean validInputs {get; private set;}
    public boolean showReport {get; private set;}
    public boolean includeZeroBal {get; set;}
    // Determine if running in a sandbox 
    public boolean isSandbox { 
        get { return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox; }
        private set;
    }
    public String organizationName {
        get { return UserInfo.getOrganizationName(); }
        private set;
    }

    // public String GLAcctName {get; private set;} // BLL1d
    public String GLAcctCodeStr {get; private set;} // BLL1a
    public List<SelectOption> allGLAcct {get;set;}  // BLL1a
    //BLL2d public List<SelectOption> selectedGLAcct {get;set;}  // BLL1a
    public List<Id> selectedGLAcctIds {get;set;} // BLL1a

    // public String Dim1Name {get; private set;} // BLL1d
    public String Dim1CodeStr {get; private set;} // BLL1a
    public List<SelectOption> allDim1 {get;set;}  // BLL1a
    //BLL2d public List<SelectOption> selectedDim1 {get;set;}  // BLL1a
    public List<Id> selectedDim1Ids {get;set;} // BLL1a

    public Decimal GrandTotal {get; private set;}
    public String quickLinkURL {get; private set;} // BLL1a
    
    // constructor
    public GLAccountSchedule_CTLR() {
        validInputs = false;
        showReport = false;
        includeZeroBal = false;
        lookuph = new c2g__codaJournal__c();
        lookupd = new c2g__codaJournalLineItem__c();
        lookuph.c2g__JournalDate__c = Date.today();
        selectedDim1Ids = new List<Id>();
        selectedGLAcctIds = new List<Id>();

        // Accept account & dimension1 from query parameters, if specified
        Map<String,String> URLParameters = ApexPages.currentPage().getParameters();

        allGLAcct = new List<SelectOption>();  // BLL1a
        //BLL2d selectedGLAcct = new List<SelectOption>();  // BLL1a
        if (URLParameters.containsKey('gla') && URLParameters.get('gla').length()>0) {
            // BLL1d
            // String likeacct = '%' + String.escapeSingleQuotes(URLParameters.get('gla')) + '%';
            // List<c2g__codaGeneralLedgerAccount__c> gla = [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where Name like :likeacct limit 1];
            // if (gla.size()>0) {
            //  lookupd.c2g__GeneralLedgerAccount__c = gla[0].Id;
            //}
            // BLL1d end
            // BLL1a
            List<String> GLAcctCodes = URLParameters.get('gla').split(',', 100);
            List<c2g__codaGeneralLedgerAccount__c> GLAcctSelList = [select Id, Name from c2g__codaGeneralLedgerAccount__c where c2g__ReportingCode__c in :GLAcctCodes];
            for(c2g__codaGeneralLedgerAccount__c glacct : GLAcctSelList) {
                //BLL2d selectedGLAcct.add(new SelectOption(glacct.Id, glacct.Name));
                selectedGLAcctIds.add(glacct.Id);
            }
            // BLL1a end
        }
        //if (URLParameters.containsKey('glaId')) {
        //  lookupd.c2g__GeneralLedgerAccount__c = (Id) URLParameters.get('glaId');
        //}
        // BLL1a - Get all GL Accts not already selected
        //BLL2d List<c2g__codaGeneralLedgerAccount__c> GLAcctList = [select Id, Name from c2g__codaGeneralLedgerAccount__c where Id not in :selectedGLAcctIds order by c2g__ReportingCode__c]; 
        List<c2g__codaGeneralLedgerAccount__c> GLAcctList = [select Id, Name from c2g__codaGeneralLedgerAccount__c order by c2g__ReportingCode__c]; // BLL2a 
        for(c2g__codaGeneralLedgerAccount__c glacct : GLAcctList) {
            allGLAcct.add(new SelectOption(glacct.Id, glacct.Name));
        }
        // BLL1a end

        allDim1 = new List<SelectOption>();  // BLL1a
        //BLL2d selectedDim1 = new List<SelectOption>();  // BLL1a
        if (URLParameters.containsKey('dim1') && URLParameters.get('dim1').length()>0) {
            // BLL1d
            //String likedim1 = '%' + String.escapeSingleQuotes(URLParameters.get('dim1')) + '%';
            //List<c2g__codaDimension1__c> dim1 = [select Id, Name from c2g__codaDimension1__c where Name like :likedim1 limit 1];
            //if (dim1.size()>0) {
            //  lookupd.c2g__Dimension1__c = dim1[0].Id;
            //}
            // BLL1d end
            // BLL1a
            List<String> dim1Codes = URLParameters.get('dim1').split(',', 200);
            List<c2g__codaDimension1__c> dim1SelList = [select Id, Name from c2g__codaDimension1__c where c2g__ReportingCode__c in :dim1Codes];
            for(c2g__codaDimension1__c dim1 : dim1SelList) {
                //BLL2d selectedDim1.add(new SelectOption(dim1.Id, dim1.Name));
                selectedDim1Ids.add(dim1.Id);
            }
            // BLL1a end
        }

        // BLL1a - Get all dim1s not already selected
        //BLL2d List<c2g__codaDimension1__c> dim1List = [select Id, Name from c2g__codaDimension1__c where Id not in :selectedDim1Ids order by c2g__ReportingCode__c]; 
        List<c2g__codaDimension1__c> dim1List = [select Id, Name from c2g__codaDimension1__c order by c2g__ReportingCode__c]; // BLL2a
        for(c2g__codaDimension1__c dim1 : dim1List) {
            allDim1.add(new SelectOption(dim1.Id, dim1.Name));
        }
        // BLL1a end
        //BLL2d sortOptions();

        // BLL1d - no longer used
        //if (URLParameters.containsKey('dim1Id')) {
        //  lookupd.c2g__Dimension1__c = (Id) URLParameters.get('dim1Id');
        //}
        // BLL1d end
        if (URLParameters.containsKey('enddate')) {
            try {
               lookuph.c2g__JournalDate__c = Date.valueOf(URLParameters.get('enddate'));
            } catch(Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'End date ' + URLParameters.get('enddate') + ' error ' + e.getMessage()));
                System.debug(URLParameters.get('enddate') + ' ' + e.getMessage());
            }
        }
        if (URLParameters.containsKey('zerobal')) {
            includeZeroBal = (URLParameters.get('zerobal').equals('1'));
        }

        // Auto-run report if all inputs are here!
        //if (lookupd.c2g__Dimension1__c!=null && lookupd.c2g__GeneralLedgerAccount__c!=null) {
        System.debug('GLs: ' + String.valueOf(selectedGLAcctIds.size()) + '; Dim1s: ' + String.valueOf(selectedDim1Ids.size()));
        if (selectedGLAcctIds.size()>0 /* && selectedDim1Ids.size()>0 */) {
            validateInputs();
        }
    }


    // BLL1a
    // Sort Options (on change)
    //BLL2d public void sortOptions() {
        //allDim1.sort();
        //selectedDim1.sort();
        //allGLAcct.sort();
        //selectedGLAcct.sort();
    //BLL2d }
    // BLL1a end

    // dummy action routine for button when no action is needed
    public void noAction() {
        //BLL2d sortOptions();
    }
    
    public Map<String,String> getReportParameters() {
        Map<String,String> parms = new Map<String, String>();
        //pgParameters.put('glaId', lookupd.c2g__GeneralLedgerAccount__c);
        // BLL1d c2g__codaGeneralLedgerAccount__c gl = [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where Id=:lookupd.c2g__GeneralLedgerAccount__c limit 1];  // BLL1a
        // BLL1d pgParameters.put('gla', gl.c2g__ReportingCode__c); // BLL1a
        // BLL1a
        //BLL2d List<c2g__codaGeneralLedgerAccount__c> glaccts = getGLAccountList(getGLAcctSelectedIds());
        List<c2g__codaGeneralLedgerAccount__c> glaccts = getGLAccountList(selectedGLAcctIds);	// BLL2a
        String glacctCodes = '';
        String sep = '';
        for(c2g__codaGeneralLedgerAccount__c g : glaccts) {
            GLAcctCodes += sep + g.c2g__ReportingCode__c;
            sep = ',';
        }
        parms.put('gla', GLAcctCodes);
        // BLL1a end
        
        //BLL1d pgParameters.put('dim1Id', lookupd.c2g__Dimension1__c);
        // BLL1a 
        //BLL2d List<c2g__codaDimension1__c> dim1s = getDimension1List(getDim1SelectedIds());
        List<c2g__codaDimension1__c> dim1s = getDimension1List(selectedDim1Ids);	// BLL2a
        String dim1Codes = '';
        sep = '';
        for(c2g__codaDimension1__c d : dim1s) {
            dim1Codes += sep + d.c2g__ReportingCode__c;
            sep = ',';
        }
        parms.put('dim1', dim1Codes);
        // BLL1a
        DateTime dt = DateTime.newInstance(lookuph.c2g__JournalDate__c, Time.newInstance(0,0,0,0));
        parms.put('enddate', dt.format('yyyy-MM-d'));
        parms.put('zerobal', includeZeroBal?'1':'0');
        return parms;
    }
    

    // Print (PDF)
    public String getPrintPdfUrl() {
        ApexPages.PageReference pg=null;
        //validateInputs();
        if (validInputs) {
            pg = Page.GLAccountSchedulePDF;
            Map<String,String> pgParameters = pg.getParameters();
            Map<String,String> parmmap = getReportParameters();
            for(String k : parmmap.keySet()) {
                pgParameters.put(k, parmmap.get(k));
            }
            System.debug(pg);
            //pg.setRedirect(true);
        //} else {
        //  pg = null;
            return pg.getUrl();
        } 
        return null;
    }



    // Download pdf
    public ApexPages.PageReference downloadPDF() {
        ApexPages.PageReference pg;
        validateInputs();
        if (validInputs) {
            pg = Page.GLAccountSchedulePDF;
            Map<String,String> pgParameters = pg.getParameters();
            Map<String,String> parmmap = getReportParameters();
            for(String k : parmmap.keySet()) {
                pgParameters.put(k, parmmap.get(k));
            }
            System.debug(pg);
            pg.setRedirect(true);
        } else {
            pg = null;
        }
        return pg;
    }


    // Download xls
    public ApexPages.PageReference downloadXLS() {
        //BLL4d ApexPages.PageReference pg;
        validateInputs();
        if (validInputs) {
        	// BLL4a
			GLAccountScheduleXLSBatch ba = new GLAccountScheduleXLSBatch('', lookuph.c2g__JournalDate__c, includeZeroBal, selectedGLAcctIds, selectedDim1Ids);
			Database.executeBatch(ba);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Account schedule export has been submitted'));
			// BLL4a end
            //BLL4d pg = Page.GLAccountScheduleXLS;
            //BLL4d Map<String,String> pgParameters = pg.getParameters();
            //BLL4d Map<String,String> parmmap = getReportParameters();
            //BLL4d for(String k : parmmap.keySet()) {
            //BLL4d     pgParameters.put(k, parmmap.get(k));
            //BLL4d }
            //BLL4d System.debug(pg);
            //BLL4d pg.setRedirect(true);
        } else {
            //BLL4d pg = null;
        }
        //BLL4d return pg;
        return null;	// BLL4a
    }	

    // BLL1a - return list of selected dim1 Ids

    // getGLAcctSelectedIds
    //BLL2d public List<Id> getGLAcctSelectedIds() {
    //BLL2d     //sortOptions();
    //BLL2d     List<Id> GLAcctIds = new List<Id>();
    //BLL2d     for(SelectOption o : selectedGLAcct) {
    //BLL2d         GLAcctIds.add(o.getValue());
    //BLL2d     }
    //BLL2d     return GLAcctIds;
    //BLL2d     //return selectedGLAcctIds;
    //BLL2d }
    
    // getGLAccountList
    public List<c2g__codaGeneralLedgerAccount__c> getGLAccountList(List<Id> GLAcctIds) {
        List<c2g__codaGeneralLedgerAccount__c> glaccts = new List<c2g__codaGeneralLedgerAccount__c>();
        if (GLAcctIds.size()>0) {
            glaccts = [select Id, Name, c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where Id in :GLAcctIds];
        }
        return glaccts;
    }

    // getDim1SelectedIds
    //BLL2d public List<Id> getDim1SelectedIds() {
    //BLL2d     //sortOptions();
    //BLL2d     List<Id> dim1Ids = new List<Id>();
    //BLL2d     for(SelectOption o : selectedDim1) {
    //BLL2d         dim1Ids.add(o.getValue());
    //BLL2d     }
    //BLL2d     return dim1Ids;
    //BLL2d     //return selectedDim1Ids;
    //BLL2d }
    
    // getDimension1List
    public List<c2g__codaDimension1__c> getDimension1List(List<Id> dim1Ids) {
        List<c2g__codaDimension1__c> dim1s = new List<c2g__codaDimension1__c>();
        if (dim1Ids.size()>0) {
            dim1s = [select Id, Name, c2g__ReportingCode__c from c2g__codaDimension1__c where Id in :dim1Ids];
        // } else {	// BLL8a
        // 	dim1s = [select Id, Name, c2g__ReportingCode__c from c2g__codaDimension1__c];	// BLL8a
        }
        return dim1s;
    }
    // BLL1a end
    
    // validInputs
    public void validateInputs() {
    	ApexPages.getMessages().clear();
        validInputs = lookuph.c2g__JournalDate__c != null;
            // BLL1d lookupd.c2g__GeneralLedgerAccount__c != null
            // BLL1d && lookupd.c2g__Dimension1__c != null
        try {
            // BLL1d
            //c2g__codaGeneralLedgerAccount__c gla = [
            //    select Id, Name 
            //    from c2g__codaGeneralLedgerAccount__c
            //    where Id=:lookupd.c2g__GeneralLedgerAccount__c
            //];
            //GLAcctName = gla.Name;
            // BLL1d end
            //BLL2d List<Id> GLAcctIds = getGLAcctSelectedIds();
            //BLL2d System.debug(GLAcctIds);
            //BLL2d if (GLAcctIds.size()<1) {
            if (selectedGLAcctIds.size()<1) {	// BLL2a
                validInputs = false;
                throw new ScheduleException('General Ledger Account selection is required');
            }
            //BLL2d List<c2g__codaGeneralLedgerAccount__c> glaccts = getGLAccountList(GLAcctIds);
            List<c2g__codaGeneralLedgerAccount__c> glaccts = getGLAccountList(selectedGLAcctIds);	// BLL2a
            System.debug(glaccts);
            //BLL2d if (glaccts.size()!=GLAcctIds.size()) {
            if (glaccts.size()!=selectedGLAcctIds.size()) {	// BLL2a
                validInputs = false;
                throw new ScheduleException('Invalid General Ledger Account selection');
            }
            GLAcctCodeStr = '';
            String sep = '';
            for(c2g__codaGeneralLedgerAccount__c acct : glaccts) {
                GLAcctCodeStr += sep + acct.c2g__ReportingCode__c;
                sep = ', '; 
            }

            // BLL1d - need support for multiple dimension 1's
            //c2g__codaDimension1__c dim1 = [
            //    select Id, Name 
            //    from c2g__codaDimension1__c
            //    where Id=:lookupd.c2g__Dimension1__c
            //];
            //Dim1Name = dim1.Name;
            // BLL1d end
            // BLL1a - support for list of dimension 1's
            //BLL2d List<Id> dim1Ids = getDim1SelectedIds();
            //BLL2d System.debug(dim1Ids);
            //BLL2d if (dim1Ids.size()<1) {
            //BLL8d if (selectedDim1Ids.size()<1) { 	// BLL2a
            //BLL8d    validInputs = false;
            //BLL8d    throw new ScheduleException('Dimension1 selection is required');
            //BLL8d }
            //BLL2d List<c2g__codaDimension1__c> dim1s = getDimension1List(dim1Ids);
            List<c2g__codaDimension1__c> dim1s = getDimension1List(selectedDim1Ids);	// BLL2a
            System.debug(dim1s);
            //BLL2d if(dim1s.size()!=dim1Ids.size()) {
            if(selectedDim1Ids.size()>0 && dim1s.size()!=selectedDim1Ids.size()) {	// BLL2a, BLL8c
                validInputs = false;
                throw new ScheduleException('Invalid dimension1 selection');
            }
            Dim1CodeStr = '';
            sep = '';
            for(c2g__codaDimension1__c d1 : dim1s) {
                Dim1CodeStr += sep + d1.c2g__ReportingCode__c;
                sep = ', '; 
            }
            // BLL1a end
        } catch(Exception e) {
            validInputs = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: '+e.getMessage()));
        }
        if (!validInputs) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Missing selection criteria--report not generated'));
        }
        showReport = validInputs;
        System.debug('Valid inputs=' + (validInputs?'true':'false'));
    }

    // getReport
    public List<ScheduleLine> getReport() {
    	boolean TooManyResults = false;	// BLL3a
        ApexPages.PageReference pg;
        pg = Page.GLAccountSchedule;
        Map<String,String> pgParameters = pg.getParameters();
        Map<String,String> parmmap = getReportParameters();
        for(String k : parmmap.keySet()) {
            if (k!='enddate') {  // Don't store end date in the bookmark url -- let it default to today
                pgParameters.put(k, parmmap.get(k));
            }
        }
        quickLinkURL = pg.getUrl();
        Datetime TransactionDT = Datetime.newInstance(lookuph.c2g__JournalDate__c, Time.newInstance(0,0,0,0));
        System.debug(TransactionDT);
        String lastControl = null;
        String lastDim1 = null;  // BLL1a
        String lastAcct = null;  // BLL1a
        boolean firstRecord = true;
        Integer groupcount = 0;
        GrandTotal = 0.00;
        //List<c2g__codaTransactionLineItem__c> controlTrns = new List<c2g__codaTransactionLineItem__c>();
        //List<c2g__codaTransactionLineItem__c> includedTrns = new List<c2g__codaTransactionLineItem__c>();
        List<ScheduleLine> controlTrns = new List<ScheduleLine>();
        List<ScheduleLine> includedTrns = new List<ScheduleLine>();
        Decimal controlTotal = 0.00;

        // BLL1a
        //BLL2d List<Id> glacctIds = getGLAcctSelectedIds(); 
        String GLIdString = '';  
        String sep = '';
        //BLL2d for(Id gli : glacctIds) {
        for(Id gli : selectedGLAcctIds) {	// BLL2a
            GLIdString += sep + '\''+gli+'\'';
            sep = ',';
        }
        Decimal acctTotal = 0.00; 

        //BLL2d List<Id> dim1Ids = getDim1SelectedIds();  
        String IdString = '';  
        sep = '';
        //BLL2d for(Id i : dim1Ids) {
        for(Id i : selectedDim1Ids) {	// BLL2a
            IdString += sep + '\''+i+'\'';
            sep = ',';
        }
        Decimal dim1Total = 0.00; 
        // BLL1a
            
        String qry = 'Select Id, Name, c2g__LineNumber__c, Transaction_Date__c, Control__c, '
                   +        'c2g__Transaction__r.Name, c2g__Transaction__r.Source__c, '
                   +        'c2g__LineReference__c, c2g__LineDescription__c, c2g__HomeValue__c, '  
                   +        'c2g__GeneralLedgerAccount__r.Name, c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c, '
                   +        'c2g__Dimension1__r.Name, c2g__Dimension1__r.c2g__ReportingCode__c, ' 
                   +        'c2g__Account__r.Name, CreatedDate ' 
                   + 'From c2g__codaTransactionLineItem__c ' 
                   + 'where Transaction_Date__c <= ' + TransactionDT.format('yyyy-MM-dd') + ' ' // selected date
                   +   'and c2g__GeneralLedgerAccount__c in (' + GLIdString + ') '; // BLL1a selected accounts
        if (!String.isBlank(IdString)) qry +=  'and c2g__Dimension1__c in (' + IdString + ') ';  // BLL1a, BLL8c   
        qry += 'order by c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c, c2g__Dimension1__r.c2g__ReportingCode__c, Control__c, CreatedDate desc ';    // BLL1a, BLL8c
                   //BLL1d +   'and c2g__GeneralLedgerAccount__c = \'' + String.escapeSingleQuotes(lookupd.c2g__GeneralLedgerAccount__c) + '\' ' // selected account
                   //BLL1d +   'and c2g__Dimension1__c = \'' + String.escapeSingleQuotes(lookupd.c2g__Dimension1__c) + '\' '// selected dimension 
                   //BLL1d + 'order by Control__c, CreatedDate desc ';
        System.debug('getReport query=' + qry);
        for(c2g__codaTransactionLineItem__c tli : Database.query(qry)) {
            if (firstRecord) {
                firstRecord = false;
                lastControl = tli.Control__c;
                lastAcct = tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c; // BLL1a
                lastDim1 = tli.c2g__Dimension1__r.c2g__ReportingCode__c;  // BLL1a
                System.debug('First control number='+tli.Control__c);
            }
            // BLL1d if (tli.Control__c != lastControl) {
            if (tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c!=lastAcct 
                || tli.c2g__Dimension1__r.c2g__ReportingCode__c!=lastDim1 
                || tli.Control__c != lastControl) {  // BLL1c
                System.debug('Control break: ' + tli.Control__c + ' '
                    + tli.c2g__Dimension1__r.c2g__ReportingCode__c + ' '
                    + tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c);  // BLL1c
                // include or not? depending on total !=0 for control#
                if (controlTrns.size()>0 && (includeZeroBal || controlTotal!=0.00)) {
                    controlTrns[controlTrns.size()-1].controlTotal = controlTotal;  // Set total on last item in list
                    controlTrns[controlTrns.size()-1].daysOld = controlTrns[0].trnDate.daysBetween(lookuph.c2g__JournalDate__c);
                    groupcount += 1;  // Used to zebra-stripe by control# rather than row-by-row
                    for(ScheduleLine l : controlTrns) {
                        l.groupCount = groupcount;
                    }
                    if (includedTrns.size() + controlTrns.size()<996) {	// BLL3a
	                   	includedTrns.addAll(controlTrns);
	                   	System.debug('Adding ' + String.valueOf(controlTrns.size()) + ' lines');
	                   	System.debug('Total trn ='+String.valueOf(includedTrns.size()));
					} else TooManyResults = true;	// BLL3a
                } else {
                    System.debug('Nbr trans=' + String.valueOf(controlTrns.size()) + '; total='+String.valueOf(controlTotal));
                }
                // BLL1a 
                // dim1 sub-total - add a single line to include with subtotal
                if (tli.c2g__Dimension1__r.c2g__ReportingCode__c!=lastDim1
                    || tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c!=lastAcct) {
                    if (!TooManyResults) includedTrns.add(new ScheduleLine(controlTrns[controlTrns.size()-1], dim1Total, null));
                    dim1Total = 0.00;
                    System.debug('Adding summary line');
                    System.debug('Total trn ='+String.valueOf(includedTrns.size()));
                }
                // Account sub-total - add a single line to include with subtotal
                if (tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c!=lastAcct) {
                    if (!TooManyResults) includedTrns.add(new ScheduleLine(controlTrns[controlTrns.size()-1], null, acctTotal));
                    acctTotal = 0.00;
                    dim1Total = 0.00;
                    System.debug('Adding summary line');
                    System.debug('Total trn ='+String.valueOf(includedTrns.size()));
                }
                // BLL1a end 
                controlTrns.clear();
                controlTotal = 0.00;
                lastControl = tli.Control__c;
                lastDim1 = tli.c2g__Dimension1__r.c2g__ReportingCode__c;  // BLL1a
                lastAcct = tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c; // BLL1a
            }
            controlTotal += tli.c2g__HomeValue__c;
            acctTotal += tli.c2g__HomeValue__c; // BLL1a
            dim1Total += tli.c2g__HomeValue__c; // BLL1a
            GrandTotal += tli.c2g__HomeValue__c;
            controlTrns.add(new ScheduleLine(tli));
        }
        
        // last record - run "break" logic
        System.debug('Last record logic');
        if (controlTrns.size()>0 && (includeZeroBal || controlTotal!=0.00)) {
            controlTrns[controlTrns.size()-1].controlTotal = controlTotal;  // Set total on last item in list
            controlTrns[controlTrns.size()-1].daysOld = controlTrns[0].trnDate.daysBetween(lookuph.c2g__JournalDate__c);
            groupcount += 1;  // Used to zebra-stripe by control# rather than row-by-row
            for(ScheduleLine l : controlTrns) {
                l.groupCount = groupcount;
            }
            includedTrns.addAll(controlTrns);
            System.debug('Adding ' + String.valueOf(controlTrns.size()) + ' lines');
            System.debug('Total trn ='+String.valueOf(includedTrns.size()));
        } else {
            System.debug('Nbr trans=' + String.valueOf(controlTrns.size()) + '; total='+String.valueOf(controlTotal));
        }
        
        // BLL1a
        // Final subtotals
        if (includedTrns.size()>0) {
            if (!TooManyResults) includedTrns.add(new ScheduleLine(includedTrns[includedTrns.size()-1], dim1Total, null));
            if (!TooManyResults) includedTrns.add(new ScheduleLine(includedTrns[includedTrns.size()-1], null, acctTotal));
        }
        // BLL1a end
        if (TooManyResults) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Too many results to display - use XLS download.'));	// BLL3a
        
        return includedTrns;
        
    }
    
    
    @testVisible public class ScheduleLine {
        public Id trnLineId {get; private set;}
        public Date trnDate {get; set;}
        public String trnControlNbr {get; set;}
        public String trnSource {get; set;}
        public String trnName {get; set;}
        public Decimal trnLineNo {get; set;}
        public String trnLineReference {get; set;}
        public String trnLineDescription {get; set;}
        public Decimal trnValue {get; set;}
        public String glaName {get; set;}
        public String glaReportingCode {get; set;}
        public String dim1Name {get; set;}
        public String dim1ReportingCode {get; set;}
        public Date crtDate {get; set;}
        public String accountName {get; set;}
        public Decimal controlTotal {get; set;}
        public Decimal daysOld {get; set;}
        public Integer groupcount {get; set;}
        public String subTotal {get; set;}
        public ScheduleLine(c2g__codaTransactionLineItem__c trnline) {
            trnLineId = trnline.Id;
            subTotal = null;
            controlTotal = null;
            daysOld = null;
            groupcount = 0;
            trnDate = trnline.Transaction_Date__c;
            trnControlNbr = trnline.Control__c;
            trnSource = trnline.c2g__Transaction__r.Source__c;
            trnName = trnline.c2g__Transaction__r.Name;
            trnLineNo = trnline.c2g__LineNumber__c;
            trnLineReference = trnline.c2g__LineReference__c;
            trnLineDescription = trnline.c2g__LineDescription__c;
            trnValue = trnline.c2g__HomeValue__c;
            if (trnline.c2g__GeneralLedgerAccount__c!=null) {
                glaName = trnline.c2g__GeneralLedgerAccount__r.Name;
                glaReportingCode = trnline.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c;
            }
            if (trnline.c2g__Dimension1__c!=null) {
                dim1Name = trnline.c2g__Dimension1__r.Name;
                dim1ReportingCode = trnline.c2g__Dimension1__r.c2g__ReportingCode__c;
            }
            if (trnline.c2g__Account__c!=null) {
                accountName = trnline.c2g__Account__r.Name;
            } 
        }
        
        // BLL1a
        public ScheduleLine(ScheduleLine tmplt, Decimal dim1subt, Decimal acctsubt) {
            trnControlNbr = null;
            trnSource = null;
            trnName = null;
            trnLineNo = null;
            trnLineReference = null;
            trnLineDescription = null;
            trnValue = null;
            crtDate = null;
            accountName = null;
            daysOld = null;
            groupcount = null;

            glaName = tmplt.glaName;
            glaReportingCode = tmplt.glaReportingCode;
            dim1Name = tmplt.dim1Name;
            dim1ReportingCode = tmplt.dim1ReportingCode;
            if (dim1subt!=null) {
                controlTotal = dim1subt;
                subTotal = tmplt.dim1Name;
            }
            if (acctsubt!=null) {
                controlTotal = acctsubt;
                subTotal = tmplt.glaName;
            }
        }
        // BLL1a end
    }

    // BLL1a
    class ScheduleException extends Exception {}
    // BLL1a end 
    
}