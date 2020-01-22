/**
 * GLAccountScheduleXLSBatch
 * Tested by: GLAccountSchedule_TEST
 * Date: May 2, 2016
 * Programmer: Bryan Leaman
 * 
 */
global class GLAccountScheduleXLSBatch implements Database.Batchable<sObject>, Database.Stateful {
    
	global final String query;
    global String errmsgs;
    global String csv;
	global String csvHeaders;
	    
	global String lastControl = null;
	global String lastDim1 = null;  
	global String lastAcct = null;  
	global boolean firstRecord = true;
	global Integer groupcount;
	global Decimal controlTotal;   
	global Decimal dim1Total;
	global Decimal acctTotal;
	global Decimal GrandTotal;
	global List<ScheduleLine> controlTrns;
	global List<ScheduleLine> includedTrns;
	global Date tranDate;
	global boolean includeZeroBal;
	global List<Id> glIdList;
	global List<Id> dim1IdList;
    
	global GLAccountScheduleXLSBatch(String rcdlimit, Date TransactionDate, boolean ZeroBal, List<Id> glIds, List<Id> dim1Ids) {
		firstRecord = true;
		tranDate = TransactionDate;
		includeZeroBal = ZeroBal;
		glIdList = glIds;
		dim1IdList = dim1Ids;
		groupcount = 0;
		controlTotal = 0.00;
		dim1Total = 0.00;
		acctTotal = 0.00;
		GrandTotal = 0.00;
		controlTrns = new List<ScheduleLine>();
		includedTrns = new List<ScheduleLine>();
		DateTime tranDateTime = DateTime.newInstance(tranDate, Time.newInstance(0, 0, 0, 0));

		csvHeaders = 'Date,Source,Control#,GL Acct-Dim1,Transaction Id-Line,Line reference,Value,Balance,Customer Acct,Days old';

        String GLIdString = '';  
        String sep = '';
        for(Id gli : glIds) {
            GLIdString += sep + '\''+gli+'\'';
            sep = ',';
        }
        String IdString = '';  
        sep = '';
        for(Id i : dim1Ids) {	
            IdString += sep + '\''+i+'\'';
            sep = ',';
        }

		String soql = 
			'Select Id, Name, c2g__LineNumber__c, Transaction_Date__c, Control__c, '
                   +        'c2g__Transaction__r.Name, c2g__Transaction__r.Source__c, '
                   +        'c2g__LineReference__c, c2g__LineDescription__c, c2g__HomeValue__c, '  
                   +        'c2g__GeneralLedgerAccount__r.Name, c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c, '
                   +        'c2g__Dimension1__r.Name, c2g__Dimension1__r.c2g__ReportingCode__c, ' 
                   +        'c2g__Account__r.Name, CreatedDate ' 
                   + 'From c2g__codaTransactionLineItem__c ' 
                   + 'where Transaction_Date__c <= ' + tranDateTime.format('yyyy-MM-dd') + ' ' 
                   +   'and c2g__GeneralLedgerAccount__c in (' + GLIdString + ') '; 
        if (dim1IdList.size()>0) soql +=  'and c2g__Dimension1__c in (' + IdString + ') ';  
        soql += 'order by c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c, c2g__Dimension1__r.c2g__ReportingCode__c, Control__c, CreatedDate desc ';   
		//if (!Test.isRunningTest()) soql += 'and (condition) ';
		if (!String.isBlank(rcdlimit)) soql += ' Limit ' + rcdlimit + ' ';
		query = soql;
		errmsgs = '';
		csv = '';
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext bc, List<sObject> scope) {
		List<c2g__codaTransactionLineItem__c> objs = (List<c2g__codaTransactionLineItem__c>) scope;
		System.debug('Record count: ' + String.valueOf(objs.size()));

        for(c2g__codaTransactionLineItem__c tli : objs) {
            if (firstRecord) {
                firstRecord = false;
                lastControl = tli.Control__c;
                lastAcct = tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c; 
                lastDim1 = tli.c2g__Dimension1__r.c2g__ReportingCode__c;  
                System.debug('First control number='+tli.Control__c);
            }
            if (tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c!=lastAcct 
                || tli.c2g__Dimension1__r.c2g__ReportingCode__c!=lastDim1 
                || tli.Control__c != lastControl) {  
                System.debug('Control break: ' + tli.Control__c + ' '
                    + tli.c2g__Dimension1__r.c2g__ReportingCode__c + ' '
                    + tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c); 
                // include or not? depending on total !=0 for control#
                if (controlTrns.size()>0 && (includeZeroBal || controlTotal!=0.00)) {
                    controlTrns[controlTrns.size()-1].controlTotal = controlTotal;  // Set total on last item in list
                    controlTrns[controlTrns.size()-1].daysOld = controlTrns[0].trnDate.daysBetween(tranDate);
                    groupcount += 1;  // Used to zebra-stripe by control# rather than row-by-row
                    for(ScheduleLine l : controlTrns) {
                        l.groupCount = groupcount;
                    }
                    //if (includedTrns.size() + controlTrns.size()<996) {	
	                   	includedTrns.addAll(controlTrns);
	                   	System.debug('Adding ' + String.valueOf(controlTrns.size()) + ' lines');
	                   	System.debug('Total trn ='+String.valueOf(includedTrns.size()));
					//} 
                } else {
                    System.debug('Nbr trans=' + String.valueOf(controlTrns.size()) + '; total='+String.valueOf(controlTotal));
                }

                // dim1 sub-total - add a single line to include with subtotal
                if (tli.c2g__Dimension1__r.c2g__ReportingCode__c!=lastDim1
                    || tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c!=lastAcct) {
                    includedTrns.add(new ScheduleLine(controlTrns[controlTrns.size()-1], dim1Total, null));
                    dim1Total = 0.00;
                    System.debug('Adding summary line');
                    System.debug('Total trn ='+String.valueOf(includedTrns.size()));
                }
                // Account sub-total - add a single line to include with subtotal
                if (tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c!=lastAcct) {
                    includedTrns.add(new ScheduleLine(controlTrns[controlTrns.size()-1], null, acctTotal));
                    acctTotal = 0.00;
                    dim1Total = 0.00;
                    System.debug('Adding summary line');
                    System.debug('Total trn ='+String.valueOf(includedTrns.size()));
                }

                controlTrns.clear();
                controlTotal = 0.00;
                lastControl = tli.Control__c;
                lastDim1 = tli.c2g__Dimension1__r.c2g__ReportingCode__c;  
                lastAcct = tli.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c; 
            }
            controlTotal += tli.c2g__HomeValue__c;
            acctTotal += tli.c2g__HomeValue__c; 
            dim1Total += tli.c2g__HomeValue__c; 
            GrandTotal += tli.c2g__HomeValue__c;
            controlTrns.add(new ScheduleLine(tli));
        }
        
	}
	
	
	global void finish(Database.BatchableContext bc) {

		Profile p = [
            select Id, Name, PermissionsModifyAllData 
            from Profile 
            where Id=:UserInfo.getProfileID() 
            limit 1
        ];
		boolean isAdmin = (p!=null && (p.Name.contains('Admin') || p.PermissionsModifyAllData==true));
		
        // last record - run "break" logic
        System.debug('Last record logic');
        if (controlTrns.size()>0 && (includeZeroBal || controlTotal!=0.00)) {
            controlTrns[controlTrns.size()-1].controlTotal = controlTotal;  // Set total on last item in list
            controlTrns[controlTrns.size()-1].daysOld = controlTrns[0].trnDate.daysBetween(tranDate);
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

        // Final subtotals
        if (includedTrns.size()>0) {
            includedTrns.add(new ScheduleLine(includedTrns[includedTrns.size()-1], dim1Total, null));
            includedTrns.add(new ScheduleLine(includedTrns[includedTrns.size()-1], null, acctTotal));
        }
        // BLL1a end
		
		List<Messaging.SingleEmailMessage> emailMsgs = new List<Messaging.SingleEmailMessage>();
		List<Messaging.EmailFileAttachment> listOfAttachments = new List<Messaging.EmailFileAttachment>();
		
		// Build csv attachment

		csv = 'General Ledger Account Schedule\n';
		List<String> gls = new List<String>();
		for(c2g__codaGeneralLedgerAccount__c g : [select c2g__ReportingCode__c from c2g__codaGeneralLedgerAccount__c where Id in :glIdList]) {
			gls.add(g.c2g__ReportingCode__c);
		}
		csv += '"Accounts: ' + String.join(gls,', ') + '"\n';
		List<String> dim1s = new List<String>();
		for(c2g__codaDimension1__c d : [select Name from c2g__codaDimension1__c where Id in :dim1IdList]) {
			dim1s.add(d.Name);
		}
		csv += '"Dimensions: ' + String.join(dim1s,', ') + '"\n';
		csv += csvHeaders + '\n';
		for(ScheduleLine l : includedTrns) {
			csv += (l.trnName!=null ? csvLine(l) : csvSubTotal(l)) + '\n';
		}
		csv += csvGrandtotal() + '\n';
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(new String[] { UserInfo.getUserEmail() }); 
		mail.setSubject('GL Account Schedule');
		String body = 'Account Schedule export has completed.\n\n';
		if (isAdmin) body += 'query=' + query + '\n\n';
		mail.setPlainTextBody(body);
		
		Messaging.EmailFileAttachment results = new Messaging.EmailFileAttachment();
			results.setContentType('text/csv');
			results.setFileName('schedule.csv');
			results.setInline(false);
			results.Body = Blob.valueOf(csv);
			if (!String.isBlank(csv)) listOfAttachments.add(results);
		//Messaging.EmailFileAttachment upderrors = new Messaging.EmailFileAttachment();
		//	upderrors.setContentType('text/plain');
		//	upderrors.setFileName('UpdateErrors.txt');
		//	upderrors.setInline(false);
		//	upderrors.Body = Blob.valueOf(errmsgs);
		//	if (!String.isBlank(errmsgs)) listOfAttachments.add(upderrors);
		mail.setFileAttachments(listOfAttachments);
		emailMsgs.add(mail);

		Messaging.sendEmail(emailMsgs);
	}
	
	public String csvLine(ScheduleLine l) {
		String q = '"';
		String csvl = '';
		csvl += l.trnDate!=null ? l.trnDate.format() : '';
		csvl += ',' + q + (l.trnSource==null?'':l.trnSource) + q; 
		csvl += ',' + q + (l.trnControlNbr==null?'':l.trnControlNbr) + q;
		csvl += ',' + q + (l.glaReportingCode==null?'':l.glaReportingCode) + '-' + (l.dim1ReportingCode==null?'':l.dim1ReportingCode) + q;
		csvl += ',' + q + (l.trnName==null?'':(l.trnName + '-' + String.valueOf(l.trnLineNo.round(System.RoundingMode.FLOOR)))) + q;
		csvl += ',' + q + (l.trnLineReference==null?'':l.trnLineReference) + q;
		csvl += ',' + (l.trnValue==null?'':String.valueOf(l.trnValue));
		csvl += ',' + (l.controlTotal==null?'':String.valueOf(l.controlTotal));
		csvl += ',' + q + (l.accountName==null?'':l.accountName) + q;
		csvl += ',' + (l.daysOld==null?'':String.valueOf(l.daysOld));
		return csvl;
	}
	
	public String csvSubTotal(ScheduleLine l) {
		String q = '"';
		String csvl = '';
		csvl += ''; // date
		csvl += ',';  // source
		csvl += ','; // control
		csvl += ',' + q + (l.subTotal==null?'':l.subTotal) + q;
		csvl += ','; // transaction
		csvl += ','; // line reference
		csvl += ','; // value
		csvl += ',' + (l.controlTotal==null?'':String.valueOf(l.controlTotal));
		csvl += ','; // customer
		csvl += ','; // days old
		return csvl;
	}
	
	public String csvGrandtotal() {
		String q = '"';
		String csvl = '';
		csvl += ',' + ',' + ',' + ','
			+ ','
			+ 'Grand total' + ',' + ',' + String.valueOf(GrandTotal) + ','
			+ ',';
		return csvl;
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
            glaName = '';
            glaReportingCode = '';
            if (trnline.c2g__GeneralLedgerAccount__c!=null) {
                glaName = trnline.c2g__GeneralLedgerAccount__r.Name;
                glaReportingCode = trnline.c2g__GeneralLedgerAccount__r.c2g__ReportingCode__c;
            }
            dim1Name = '';
            dim1ReportingCode = '';
            if (trnline.c2g__Dimension1__c!=null) {
                dim1Name = trnline.c2g__Dimension1__r.Name;
                dim1ReportingCode = trnline.c2g__Dimension1__r.c2g__ReportingCode__c;
            }
            accountName = '';
            if (trnline.c2g__Account__c!=null) {
                accountName = trnline.c2g__Account__r.Name;
            } 
        }
        

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
    }


    class ScheduleException extends Exception {}

}