public without sharing class partRegister_EXT {

	public String register {get;set;}
	public dealer__Parts_Inventory__c inventory;

	public partRegister_EXT(ApexPages.standardController c) {
		inventory = (dealer__Parts_Inventory__c)c.getRecord();
		register = JSON.serializePretty(partRegister_EXT.register(inventory.Id));
	}
 
	public static List<partRegister> register(Id partId) {

        // List<partRegister> register = new List<partRegister>();
        List<PartLedgerReporting__c> ledger = getLedger(partId);
        List<dealer__Part_Inventory_History__c> dataloadhistory = getdataload(partId);
        // Map<String, partRegister> purchases = new Map<String, partRegister>();
        // Map<String, partRegister> partSales = new Map<String, partRegister>();
        // Map<String, partRegister> manualEntries = new Map<String, partRegister>();

        // Map<Date, Map<String, partRegister>> entryByDate = new Map<Date, Map<String, partRegister>>();

        // Iterate the ledger chronologically
        // Decimal totalValue=0;
        // Decimal runningOnHand=0;

        // Map by Transaction Note
        Map<String, partRegister> registerByName = new Map<String, partRegister>();
        String mapKey = ''; // entry.Transaction_Note__c; 

        // Process Data Loads at inception
        for(dealer__Part_Inventory_History__c pih : dataloadhistory) {
            // We could have more than a single part load
            partRegister dlRegister = registerByName.get('Data Load');
            if(dlRegister==null) {
                dlRegister=new partRegister(
                    pih.dealer__Transaction_Time__c,
                    Date.valueOf(pih.dealer__Transaction_Time__c),
                    pih.dealer__EventId__c,
                    'Data Load',
                    '',
                    (pih.dealer__Quantity_Adjustment__c), //TRansaction Quantity
                    0, //PostTransaction OnHand
                    (pih.dealer__Cost__c * pih.dealer__Quantity_Adjustment__c), //Transaction Value
                    0, //PostTransaction Value
                    null,
                    'ASC' 
                );
            } else {
                dlRegister.adjusted = (dlRegister.adjusted + pih.dealer__Quantity_Adjustment__c);
                //dlRegister.postAdjustOnHand = (dlRegister.postAdjustOnHand + pih.dealer__Quantity_Adjustment__c);
                dlRegister.transactionValue = (dlRegister.totalValue + (pih.dealer__Cost__c * pih.dealer__Quantity_Adjustment__c));
                //dlRegister.totalValue = (dlRegister.totalValue + (pih.dealer__Cost__c * pih.dealer__Quantity_Adjustment__c));
            }
            registerByName.put('Data Load', dlRegister);
        } 

        for(PartLedgerReporting__c entry : ledger) {

            if(entry.Parts_Sale_Line__c!=null) {
                mapKey=entry.Parts_Sale_Line__c;
                partRegister tempRegister = setRegister(mapKey, registerByName, entry);
                if(tempRegister!=null) {
                    registerByName.put(mapKey, tempRegister);                
                }
            }

            if(entry.Purchase_Order__c!=null) {
                mapKey=entry.Purchase_Order__c;
                partRegister tempRegister = setRegister(mapKey, registerByName, entry);
                if(tempRegister!=null) {
                    registerByName.put(mapKey, tempRegister);
                }
            }            

            if(entry.Parts_Sale_Line__c==null && entry.Purchase_Order__c==null) { 
                mapKey=entry.Transaction_Note__c;
                partRegister tempRegister = setRegister(mapKey, registerByName, entry);
                if(tempRegister!=null) {
                    registerByName.put(mapKey, tempRegister);                
                }
            }            

        }

        // Sort and iterate values by TransactionDatetime
        List<partRegister> sortedRegister = registerByName.values(); 
        System.debug(sortedRegister);
        
        sortedRegister.sort();  
        sortedRegister = partRegister_EXT.runningTotals(sortedRegister);

        // Sort the other way
        List<partRegister> sortedRegisterDesc = new List<partRegister>();
        for(partRegister pr : sortedRegister) {
            pr.order = 'DESC';
            sortedRegisterDesc.add(pr);
        }

        System.debug(sortedRegister);

        sortedRegisterDesc.sort();

        return sortedRegisterDesc;
	}

    public static List<partRegister> runningTotals(List<partRegister> reg) {
        
        List<partRegister> postReg = new List<partRegister>();
        Decimal postOnHand = 0;
        Decimal postValue = 0;    

        for(partRegister pr : reg) {

            System.debug(pr.TransactionDatetime);

            partRegister inRegister = pr;
            
            // Integer multiplier = 1;
            // if(inRegister.adjusted < 1) {
            //     multiplier = -1;
            // }
            postOnHand = (postOnHand + inRegister.adjusted);
            postValue = (postValue + inRegister.transactionValue);

            inRegister.postAdjustOnHand = postOnHand;
            inRegister.totalValue = postValue;

            postReg.add(inRegister);
        }

        return postReg;
    }

    public static partRegister setRegister(String mapKey, Map<String, partRegister> register, PartLedgerReporting__c ledgerEntry) {

            // Counters
            Decimal onHand =0;
            Decimal postOnHand =0;
            Decimal transactionValue=0;
            Decimal postTransactionValue=0;
            Decimal qty=0;
            Decimal runningTotal=0;

            // If we have a existing matched register 
            Boolean registerExists = false;
            Boolean runEvent = false;

            if(register.get(mapKey)!=null) {
                registerExists=true;
                onHand=register.get(mapKey).adjusted;
                
                transactionValue=register.get(mapKey).transactionValue;
                postTransactionValue=register.get(mapKey).totalValue;

                // Get the running Total
                // for(String s : register.keyset()) {
                //     System.debug(register.get(s).totalValue);
                //     runningTotal+=register.get(s).totalValue;
                //     postOnHand=register.get(s).postAdjustOnHand;

                // }
            } 

            // Transaction Number 
            String transactionNumber = '';
            Id transactionId;
            String transactionEvent = '';
            DateTime transactionDateTime;

            // Purchase Events
            if(ledgerEntry.Purchase_Order__c!=null && ledgerEntry.Purchase_Order__c==mapKey) {
                    runEvent = true;
                    transactionNumber=ledgerEntry.Purchase_Order__r.Name; 
                    transactionId=ledgerEntry.Purchase_Order__c;
                    transactionDateTime=ledgerEntry.Purchase_Order__r.dealer__Accepted_DateTime__c; // to be the AcceptedDateTime
                    transactionEvent='Part Purchased';
                    qty=1;
            }

            // Sales Events
            if(ledgerEntry.Parts_Sale_Line__c!=null && ledgerEntry.Parts_Sale_Line__c==mapKey) { 
                    runEvent = true;
                    transactionNumber=ledgerEntry.Parts_Sale_Line__r.Name; 
                    transactionId=ledgerEntry.Parts_Sale_Line__c;
                    transactionDateTime=ledgerEntry.Parts_Sale_Line__r.CreatedDate;
                    transactionEvent='Part Sold';
                    qty=-1;
            }

            // Incriment running total.
            if(runEvent==true) {

                Integer m = 1;
                if(qty<1)
                    m=-1;

                partRegister pr = new partRegister(
                    //datetime.newInstance(ledgerEntry.Entry_Date__c.year(), ledgerEntry.Entry_Date__c.month(), ledgerEntry.Entry_Date__c.day()),
                    //Date.valueOf(ledgerEntry.Entry_Date__c),
                    transactionDateTime,
                    Date.valueOf(transactionDateTime),
                    transactionNumber,
                    transactionEvent,
                    ledgerEntry.Transaction_Note__c,
                    (qty + onHand), //TRansaction Quantity
                    0, //PostTransaction OnHand
                    ((ledgerEntry.Item_Value__c + transactionValue) * m), //Transaction Value
                    0, //PostTransaction Value
                    transactionId,
                    'ASC'    
                );
                return pr;

                // System.debug('STATS : on-hand: '+onHand);
                // System.debug('STATS : post-on-hand: '+postOnHand);
                // System.debug('STATS : transaction value: '+transactionValue);
                // System.debug('STATS : post-transaction value: '+postTransactionValue);
                // System.debug('STATS : qty: '+qty);
                // System.debug('STATS : running-total: '+runningTotal);  
                // System.debug('~-------------------------------------;');

            }           

        return null;
    }    

	public static List<PartLedgerReporting__c> getLedger(Id partId) {
		return [SELECT Part__c, Parts_Sale_Line__c, Quantity__c, Purchased_By__c, Sold_By__c, 
                        Item_Value__c, Current_Value__c, Purchase_Order__c, Transaction_Note__c,
                         Purchase_Order__r.Name,  Repair_Order_Line__r.Name, 
                         Parts_Sale_Line__r.Name,
                         Entry_Date__c,  Repair_Order_Line__c, Name, Id,
                         Parts_Sale_Line__r.CreatedDate,
                         Purchase_Order__r.CreatedDate,
                         Repair_Order_Line__r.CreatedDate,
                         Purchase_Order__r.dealer__Accepted_DateTime__c
                    FROM PartLedgerReporting__c 
                        WHERE Part__c=:partId 
                    ORDER BY Entry_Date__c ASC LIMIT 10000];

	}
 
	public static List<dealer__Part_Inventory_History__c> getdataload(Id partId) {
        return [SELECT Id, Name, dealer__Part__c, dealer__Cost__c, dealer__EventId__c, dealer__Quantity_Adjustment__c, dealer__Transaction_Event__c, dealer__Transaction_Time__c FROM dealer__Part_Inventory_History__c WHERE dealer__Part__c=:partId AND dealer__Transaction_Event__c = 'Data Load'];
    } 
     
    public static List<dealer__Part_Inventory_History__c> getmanualAdjustments(Id partId) {
        return [SELECT Id, Name, dealer__Part__c, dealer__Cost__c, dealer__Quantity_Adjustment__c, dealer__Transaction_Event__c, dealer__Transaction_Time__c FROM dealer__Part_Inventory_History__c WHERE dealer__Part__c=:partId AND dealer__Transaction_Event__c = 'Manual On Hand Adjustment'];
    }
    

	/**
    *  wrapper class defining the partRegister value
    *
    */
    public class partRegister implements Comparable {

        public DateTime transactionDateTime {get;set;}
        public Date transactionDate {get;set;}
        public String transactionNumber {get;set;}
        public String transactionEvent {get;set;}
        public String transactionNotes {get;set;}
        public Decimal adjusted {get;set;}
        public Decimal postAdjustOnHand {get;set;}
        public Decimal transactionValue {get;set;}
        public Decimal totalValue {get;set;}
        public Id transactionId {get;set;}
        public String order {get;set;}

        public partRegister(DateTime dt, Date d, String tn, String te, String note, Decimal aon, Decimal padj, Decimal tv, Decimal totalVal, Id transactionId, String order) {
            transactionDateTime=dt;
            transactionDate=d;
            transactionNumber=tn;
            transactionEvent=te;
            transactionNotes=note;
            adjusted=aon;
            postAdjustOnHand=padj;
            transactionValue=tv;
            totalValue=totalVal;
            transactionId=transactionId;
            order=order;
        }

        public Integer compareASC(Object compareTo) {
            System.debug('Compare ASC');
            partRegister compareRegister = (partRegister)compareTo;
            if(transactionDateTime == compareRegister.transactionDateTime) return 0;
            if(transactionDateTime > compareRegister.transactionDateTime) return 1;
            return -1;            
        }

        public Integer compareDESC(Object compareTo) {
            System.debug('Compare DESC');
            partRegister compareRegister = (partRegister)compareTo;
            if(transactionDateTime == compareRegister.transactionDateTime) return 0;
            if(transactionDateTime < compareRegister.transactionDateTime) return 1;
            return -1;            
        }        

        public Integer compareTo(Object compareTo) {
            System.debug(order);
            if(order==null || order=='ASC'){
                return compareASC(compareTo);
            }
            return compareDESC(compareTo);
        }        

    }
    

}