/**	DO NOT DEPLOY UNTIL FIXED
* JournalLineItemProcessTest
*
* Test class for JournalLineItemProcess
* Developer: Alexander Miller
*   
* Modifications:
*	2019-07-10	B. Beaman	Fix company selection and try to select an unprocessed journal
*
* Fixes needed:
* - Need to select a record in a project in the user's current division (?)
	rstk__syusr__c.rstk__syusr_lastdiv__c = rstk__sytxncst__c.rstk__sytxncst_div__c
	where rstk__syusr__c.rstk__syusr_employee__c = current user id
* - JournalLineItemProcess selects recently-created records, which can fail in an old sandbox.
*/
@isTest(seeAllData=true) 
public class JournalLineItemProcessTest {
    
    private static TestHelper_MW.FFATestData FFAdata = new TestHelper_MW.FFATestData(); 

    public static testMethod void testTransitWorksDefaultInvoiceCogsDimension()
    {      
        //TestHelper_MW.createBaseFFAData(FFAdata);
        //FFAdata.refresh();
        //System.runAs(FFAdata.TestUser) 
        //{
            // BLL1
			//FinancialForce_MBW.selectCompany([SELECT Id FROM c2g__codaCompany__c WHERE Name = 'TransitWorks' LIMIT 1].Id);
			//FinancialForce_MBW.selectCompany([SELECT Id FROM c2g__codaCompany__c WHERE c2g__ExternalId__c ='TWK' LIMIT 1].Id);
			// Run as a user with TWK company selected *and* has FF license
			Set<Id> FFTWKUserIds = new Set<Id>();
			for(GroupMember m : [select UserOrGroupId from GroupMember where Group.Name in ('FF TransitWorks','FF Driverge')]) FFTWKUserIds.add(m.UserOrGroupId);
			// rstk__syusr__c rstkUser = [select Id, rstk__syusr_lastdiv__c from rstk__syusr__c where rstk__syusr_employee__c=:UserInfo.getUserId() limit 1];	
			rstk__syusr__c rstkUser = [
				select Id, rstk__syusr_lastdiv__c 
				from rstk__syusr__c
				where rstk__syusr_obsolete__c=false and rstk__syusr_superauth__c=true
				  and rstk__syusr_employee__c in :FFTWKUserIds
				limit 1
			];
			// BLL1 end
			
			// BLL1d Test.startTest();

            // 1. Get a cost transaction with Sales Order Issue in the transaction ID 
            //BLL1 
			//rstk__sytxncst__c costTransaction = [SELECT Id,
            //                                        rstk__sytxncst_dim1__c,
            //                                        rstk__sytxncst_journalentryno__c,
            //                                        rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c 
            //                                    FROM rstk__sytxncst__c 
            //                                    WHERE rstk__sytxncst_txnid__c = 'SOISS' AND
            //                                        rstk__sytxncst_journalentryno__c != null //AND
            //                                        //rstk__sytxncst_journalentryno__c IN (SELECT Id FROM c2g__codaJournal__c WHERE c2g__JournalStatus__c IN ('Complete', 'Discarded'))
            //                                    ORDER BY CreatedDate desc
            //                                    LIMIT 1];
			// Try to find a cost transaction with an unposted journal
			List<rstk__sytxncst__c> v1 = [SELECT Id,
				    rstk__sytxncst_dim1__c,
				    rstk__sytxncst_journalentryno__c,
				    rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c 
				FROM rstk__sytxncst__c 
				WHERE rstk__sytxncst_txnid__c = 'SOISS' 
				    AND rstk__sytxncst_journalentryno__c != null 
					AND rstk__sytxncst_div__c = :rstkUser.rstk__syusr_lastdiv__c
					AND rstk__sytxncst_proj__r.Name!=null
				ORDER BY CreatedDate desc
				LIMIT 50];
			List<rstk__sytxncst__c> costTrans = v1;
			rstk__sytxncst__c costTransaction = costTrans[0];
			Set<Id> jrnids = new Set<Id>();
			for(rstk__sytxncst__c ct : costTrans) jrnids.add(ct.rstk__sytxncst_journalentryno__c);
			Map<Id,c2g__codaJournal__c> jrnMap = new Map<Id,c2g__codaJournal__c>([
				select Id, c2g__JournalStatus__c
				from c2g__codaJournal__c
				where Id in :jrnids and c2g__JournalStatus__c in ('In Progress')
			]);
			for(rstk__sytxncst__c ct : costTrans) {
				if (!jrnMap.containsKey(costTransaction.rstk__sytxncst_journalentryno__c)) costTransaction = ct;
			}
			// BLL1 end

            c2g__codaDimension1__c tempDimensionCost = [SELECT Id,
                                                        c2g__ReportingCode__c
                                                    FROM c2g__codaDimension1__c 
                                                    WHERE c2g__ReportingCode__c = :costTransaction.rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c 
                                                    LIMIT 1];

            c2g__codaDimension1__c tempDimensionSale = [SELECT Id,
                                                        c2g__ReportingCode__c 
                                                    FROM c2g__codaDimension1__c 
                                                    WHERE c2g__ReportingCode__c = :costTransaction.rstk__sytxncst_dim1__c 
                                                    LIMIT 1];

            Id tempJournalId = Id.valueOf(costTransaction.rstk__sytxncst_journalentryno__c);

            // 2. Get the journal which stemmed from it
            c2g__codaJournal__c tempHeader = [SELECT Id
                                            FROM c2g__codaJournal__c 
                                            WHERE Id = :tempJournalId
                                            LIMIT 1];       

            System.debug(costTransaction);     
            System.debug(tempDimensionCost); 
            System.debug(tempDimensionSale);     
            System.debug(tempHeader);     

            // 3. Set up a fake Journal Line matching the entry criteria for the class
            List<c2g__codaGeneralLedgerAccount__c> glas = new List<c2g__codaGeneralLedgerAccount__c>();
            glas.add(new c2g__codaGeneralLedgerAccount__c(
                c2g__ReportingCode__c ='12',
                c2g__Type__c='Balance Sheet',
                Name='Test'
            ));
            insert glas;
            
            List<c2g__codaJournalLineItem__c> jllist = new List<c2g__codaJournalLineItem__c>();
            jllist.add(new c2g__codaJournalLineItem__c(
                c2g__Journal__c = tempJournalId,
                c2g__LineType__c = 'General Ledger Account',
                c2g__GeneralLedgerAccount__c = glas[0].Id,
                Control__c = null,
                c2g__Value__c = -1000,
                c2g__LineDescription__c = 'SOISS',
                c2g__DebitCredit__c = 'Credit',
                c2g__Dimension1__c = tempDimensionSale.Id
            )); 

			Test.startTest();
			try {	// BLL1a
            	insert(jllist);
	            c2g__codaJournalLineItem__c tempLine = [
					SELECT Id, c2g__Dimension1__r.c2g__ReportingCode__c
					FROM c2g__codaJournalLineItem__c 
					WHERE Id = :jllist.get(0).Id
					LIMIT 1
				];
	            // 4. Make sure the cost transaction dimension doesn't equal the Journal Line's dimension
	            System.debug(costTransaction.rstk__sytxncst_div__r.rstk__sydiv_dimval__r.rstk__sydim_dimval__c);
	            System.debug(tempLine.c2g__Dimension1__r.c2g__ReportingCode__c);
	            System.assertEquals(tempDimensionCost.c2g__ReportingCode__c, tempLine.c2g__Dimension1__r.c2g__ReportingCode__c);
			// BLL1a
			} catch(Exception e) {
				if (jrnMap.containsKey(costTransaction.rstk__sytxncst_journalentryno__c))
					System.assert(e==null, 'Received an error adding a line to an existing journal: ' + e.getMessage());
			}
			// BLL1a end

			Test.stopTest();
        //}
    }
}