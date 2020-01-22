/**
 * CashMatchingProcess
 * Tested by: CashMatchingProcess_TEST
 * Date: Jul 23, 2018
 * Programmer: Bryan Leaman
 * 
 * Coverage:
 *  2018-07-24  89% (25/28)
 *  2018-10-30  91% (31/34)
 *  2018-11-30  91% (32/35)
 *
 *  2018-07-23  B. Leaman   IR-0012718  Written.
 *  2018-10-30  B. Leaman   W-000474    BLL1 - Update to ignore payment process.
 *  2018-11-30  B. Leaman   W-000507    BLL2 - Only enforce cross-Dim protection for "Matching" (not unmatching);
 *                                      don't run SOQLs if no data to query;
 *  2019-01-03  B. Leaman   W-000536    BLL3 - Added debug statements; fix to allow undo matching;
 */
public with sharing class CashMatchingProcess {

    // CashMatchingProcess
    //---------------------------------------
    public CashMatchingProcess() {
    }

    // PreventMatchingAcrossDimension1s
    // CashMatchingHistory (CMH) points to -> MathingReference (MR)
    // so MR must exist first; when CMHs are inserted (or updated) with a MR and a TransactionLineItem (TLI),
    // create map of any existing TLI Dim1's tied to the given MR and then add any TLI Dim1's being associated to a MR
    // in this insert (or update);
    // Finally, iterate through the CMHs being inserted/updated, find the related TLI Dim1 already set (or being set in this update)
    // and if an inserted/updated record references a DIFFERENT TLI Dim1, flag the record as an error.   
    public static void PreventMatchingAcrossDimension1s(List<c2g__codaCashMatchingHistory__c> newlist) {

        MW_TriggerControls__c CashMatchCrossDimExcludePmts = MW_TriggerControls__c.getInstance('CashMatchCrossDimExcludePmts');

        //Set<Id> cmrIds = new Set<Id>();
        Set<Id> cmrIds = new Set<Id>();
        Set<Id> cmrTrnLinIds = new Set<Id>();
        for(c2g__codaCashMatchingHistory__c cmh : newlist) {
            // BLL2
            //if (cmh.c2g__MatchingReference__c!=null) cmrIds.add(cmh.c2g__MatchingReference__c);
            //if (cmh.c2g__TransactionLineItem__c!=null) cmrTrnLinIds.add(cmh.c2g__TransactionLineItem__c); 
			// BLL3
            //if (cmh.c2g__Action__c=='Match' && cmh.c2g__MatchingReference__c!=null) cmrIds.add(cmh.c2g__MatchingReference__c);
            //if (cmh.c2g__Action__c=='Match' && cmh.c2g__TransactionLineItem__c!=null) cmrTrnLinIds.add(cmh.c2g__TransactionLineItem__c); 
            if (cmh.c2g__Action__c=='Match' && cmh.c2g__MatchingReference__c!=null && cmh.c2g__UndoMatchingReference__c==null) cmrIds.add(cmh.c2g__MatchingReference__c);
            if (cmh.c2g__Action__c=='Match' && cmh.c2g__TransactionLineItem__c!=null && cmh.c2g__UndoMatchingReference__c==null) cmrTrnLinIds.add(cmh.c2g__TransactionLineItem__c); 
            System.debug(cmh.Id);
            System.debug(cmh.c2g__MatchingReference__c);
            System.debug(cmh.c2g__TransactionLineItem__c);
            System.debug(cmh.c2g__Action__c);
            // BLL3 end
            // BLL2 end
        }
        System.debug(cmrIds);
        System.debug(cmrTrnLinIds);

        // Get Dim1 from Transaction Line Items & Cash Entry Type (if applicable)
        // BLL2
        //Map<Id,c2g__codaTransactionLineItem__c> trnLinMap = new Map<Id,c2g__codaTransactionLineItem__c>([
        //  select Id, Name, c2g__Dimension1__c, Control__c,
        //      c2g__LineReference__c, c2g__LineDescription__c, DocumentReference__c,
        //      c2g__Transaction__r.c2g__CashEntry__c, c2g__Transaction__r.c2g__CashEntry__r.c2g__Type__c
        //  from c2g__codaTransactionLineItem__c
        //  where Id in :cmrTrnLinIds
        //]);
        Map<Id,c2g__codaTransactionLineItem__c> trnLinMap = new Map<Id,c2g__codaTransactionLineItem__c>();
        if (cmrTrnLinIds.size()>0) trnLinMap = new Map<Id,c2g__codaTransactionLineItem__c>([
            select Id, Name, c2g__Dimension1__c, Control__c,
                c2g__LineReference__c, c2g__LineDescription__c, DocumentReference__c,
                c2g__Transaction__r.c2g__CashEntry__c, c2g__Transaction__r.c2g__CashEntry__r.c2g__Type__c
            from c2g__codaTransactionLineItem__c
            where Id in :cmrTrnLinIds
        ]);
        // BLL3
        System.debug(trnLinMap);
        // BLL3 end
        // BLL2 end
        //for(c2g__codaTransactionLineItem__c tli : trnLinMap.values()) {
        //  System.debug(tli);
        //}
        //System.debug(trnLinMap);

        // Map of cmrs referenced in this update to dim1
        Map<Id,Id> cmrDim1Map = new Map<Id,Id>();

        // List of matching references with attached matching histories (may not occur in real life)
        // not sure if these exist before the relationship becomes invalid (mis-matched dim1s) or not
        //BLL1d Set<Id> mrNotPmt = new Set<Id>(); // matching references NOT from payments 
        for(c2g__codaMatchingReference__c cmr : [
            select Id, Name, c2g__Operation__c, c2g__PaymentNumber__c, 
                (select Id, Name, c2g__TransactionLineItem__r.c2g__Dimension1__c,
                    c2g__TransactionLineItem__r.c2g__Dimension1__r.Name
                 from c2g__MatchingHistories__r)
            from c2g__codaMatchingReference__c
            where Id in :cmrIds 
            ]) {
            // BLL3
            System.debug(cmr);
            // BLL3 end
            //BLL1d from SOQL - wasn't working anyway: and c2g__PaymentNumber__c=null
            // BLL1d mrNotPmt.add(cmr.Id);  // matching reference is NOT from the payment process
            for(c2g__codaCashMatchingHistory__c cmh : cmr.c2g__MatchingHistories__r) {
                Id dim1Id = cmh.c2g__TransactionLineItem__r.c2g__Dimension1__c;
                if (dim1Id!=null && !cmrDim1Map.containsKey(cmr.Id)) cmrDim1Map.put(cmr.Id, dim1Id);
            }
        }
        // BLL3
        System.debug(cmrDim1Map);
        // BLL3 end

        // Now add any CMRs referenced that do not already have an assigned Dim1 from existing records
        for(c2g__codaCashMatchingHistory__c cmh : newlist) {
            c2g__codaTransactionLineItem__c trnlin = trnLinMap.get(cmh.c2g__TransactionLineItem__c);
            // BLL2
            //boolean isPayment = trnlin.c2g__Transaction__r.c2g__CashEntry__c!=null && String.valueOf(trnlin.c2g__Transaction__r.c2g__CashEntry__r.c2g__Type__c).startsWith('Payment');
            boolean isPayment = trnlin==null ? false : trnlin.c2g__Transaction__r.c2g__CashEntry__c!=null && String.valueOf(trnlin.c2g__Transaction__r.c2g__CashEntry__r.c2g__Type__c).startsWith('Payment');
            // BLL2 end
            Id dim1Id = (trnlin==null) ? null : trnlin.c2g__Dimension1__c;
            //BLL1d if (dim1Id!=null && cmh.c2g__MatchingReference__c!=null && mrNotPmt.contains(cmh.c2g__MatchingReference__c) 
            // BLL2
            //if (dim1Id!=null && cmh.c2g__MatchingReference__c!=null  
            //  && !cmrDim1Map.containsKey(cmh.c2g__MatchingReference__c)) {
            // BLL3
            System.debug(cmh);
            System.debug(isPayment);
            System.debug(trnlin);
            System.debug(dim1Id);
            // BLL3 end
            if (cmh.c2g__Action__c=='Match' && dim1Id!=null && cmh.c2g__MatchingReference__c!=null  
 				&& cmh.c2g__UndoMatchingReference__c==null	// BLL3a
                && !cmrDim1Map.containsKey(cmh.c2g__MatchingReference__c)) {
            // BLL2 end
                if (CashMatchCrossDimExcludePmts==null || CashMatchCrossDimExcludePmts.Enabled__c!=true || !isPayment) {
                    cmrDim1Map.put(cmh.c2g__MatchingReference__c, dim1Id);
                }
            }
        }
        // BLL3
        System.debug(cmrdim1Map);
        // BLL3 end

        // Now iterate over insert/update records and set error on any records with a different dim1
        for(c2g__codaCashMatchingHistory__c cmh : newlist) {
            c2g__codaTransactionLineItem__c trnlin = trnLinMap.get(cmh.c2g__TransactionLineItem__c);
            // BLL2
            // boolean isPayment = trnlin.c2g__Transaction__r.c2g__CashEntry__c!=null && String.valueOf(trnlin.c2g__Transaction__r.c2g__CashEntry__r.c2g__Type__c).startsWith('Payment');
            boolean isPayment = trnlin==null ? false : trnlin.c2g__Transaction__r.c2g__CashEntry__c!=null && String.valueOf(trnlin.c2g__Transaction__r.c2g__CashEntry__r.c2g__Type__c).startsWith('Payment');
            // BLL2 end
            Id dim1Id = (trnlin==null) ? null : trnlin.c2g__Dimension1__c;
            // Current Dim1 for the CMH ...
            Id mappedDim1 = cmrDim1Map.get(cmh.c2g__MatchingReference__c);
            //BLL1d if (cmh.c2g__MatchingReference__c!=null && mrNotPmt.contains(cmh.c2g__MatchingReference__c)
            // BLL2
            // BLL3
            System.debug(cmh);
            System.debug(isPayment);
            System.debug(trnlin);
            System.debug(dim1Id);
            System.debug(mappedDim1);
            // BLL3 end
            //if (cmh.c2g__MatchingReference__c!=null 
            //  && mappedDim1!=null && dim1Id!=null && mappedDim1!=dim1Id) {
            if (cmh.c2g__Action__c=='Match' && cmh.c2g__MatchingReference__c!=null 
 				&& cmh.c2g__UndoMatchingReference__c==null	// BLL3a
                && mappedDim1!=null && dim1Id!=null && mappedDim1!=dim1Id) {
            // BLL2 end
                if (CashMatchCrossDimExcludePmts==null || CashMatchCrossDimExcludePmts.Enabled__c!=true || !isPayment) {
                    cmh.addError('Cash matching reference crosses multiple Dimension1s: ' + mappedDim1 + ' & ' + dim1Id);
                }
            }
        }

    }

}