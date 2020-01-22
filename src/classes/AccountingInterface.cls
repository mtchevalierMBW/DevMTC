/**
AccountingInterface
Tested by: FFAccounting_TEST
Developed by: Jarrett Kuljis (DealerTeam)
Project: W-000575

Coverage:
2019-04-16	98% (73/74)

Modifications:

**/
public class AccountingInterface { 

 	/**
    * createReceipt - Signature includes the entry Id
	* stop-gap interface from FFCA_AccountReceivable globl rest operation
    */
    public static void createReceipt(Id cashierEntryId, dealer__Dealer_Location__c location, String paymentMethod, Account customer, Decimal transAmount) {
		createReceiptFromCashierRecord(cashierEntryId);
	}

    /**
     * create cashreceipt from cashier entry
     * 
     */
    public static void createReceiptFromCashierRecord(Id cRecord) {
        
        dealer__Cashering__c cashReceipt = [
			SELECT Id, Name, dealer__Location__c, dealer__Location__r.dealer__Company_Number__c, 
				dealer__Location__r.Company__r.Name, dealer__Location__r.Financial_Force_Dimension_1__c,
				dealer__Amount__c, dealer__Customer__c, dealer__Payment_Method__c,
				dealer__Deal__c, dealer__Deal__r.Name, dtmob__MobilityDeal__c, dtmob__MobilityDeal__r.Name,
				dealer__Rental_Agreement__c, dealer__Rental_Agreement__r.Name, dealer__Service_Repair_Order__c, dealer__Service_Repair_Order__r.Name
			FROM dealer__Cashering__c 
			WHERE Id =:cRecord 
			LIMIT 1
		];
		String paymentMethod = cashReceipt.dealer__Payment_Method__c;

        dealer__Dealer_Location__c loc = AccountingInterface.getLocation(cashReceipt.dealer__Location__c);

        // Preflight reqs
        Id ownerCompany =  FFAccounting.getFFCompany(cashReceipt.dealer__Location__c);
        Id currencyId   =  FFAccounting.currency(ownerCompany);
        Id openPeriod 	=  FFAccounting.getCurrentPeriod(ownerCompany);

        // Get Payment Method Settings
        String depositAccount;
		String ffPaymentMethod;
        List<PaymentMethodsByLocation__c> pms = [
			SELECT Name, Method__c, Location__c, Deposit_Account__c, FF_Payment_Method__c 
			FROM PaymentMethodsByLocation__c
			WHERE Location__c =:loc.dealer__Company_Number__c
			  AND Method__c=:paymentMethod
		];
        if (pms.size()>0) {
			System.debug(pms[0]);
		    System.debug('Found payment method '+paymentMethod);
            depositAccount= pms[0].Deposit_Account__c;
			ffPaymentMethod = pms[0].FF_Payment_Method__c;
        }
        
        c2g__codaBankAccount__c bankAccount;
        List<c2g__codaBankAccount__c> banks = [
				SELECT Id 
				FROM c2g__codaBankAccount__c 
				WHERE c2g__ReportingCode__c = :depositAccount
		];
		if (banks.size()>0) bankAccount = banks[0];
        System.assert(bankAccount!=null && bankAccount.Id!=null, 
			'Bank account must be supplied to create Cash Entry');
        
        c2g.CODAAPICommon_7_0.Context ct7 = new c2g.CODAAPICommon_7_0.Context(); 
        ct7.CompanyName = cashReceipt.dealer__Location__r.Company__r.Name;
        
        // Does an entry exist?
        // You need to check to see if the Entry is "Open" posted.
        //c2g__codaCashEntry__c existingEntry = AccountingInterface.getCurrentCashEntry(new dealer__Dealer_Location__c(Id=cashReceipt.dealer__Location__c), cashReceipt.dealer__Payment_Method__c, Date.today());
		c2g__codaCashEntry__c existingEntry = AccountingInterface.getCurrentCashEntry(new dealer__Dealer_Location__c(Id=cashReceipt.dealer__Location__c), ffPaymentMethod, Date.today());
 		
        /* Generate Entry */
		c2g.CODAAPICashEntryTypes_7_0.CashEntry ce = new c2g.CODAAPICashEntryTypes_7_0.CashEntry();
		DateTime dt = DateTime.now();
		ce.DateValue = dt.Date();
        ce.BankAccountCurrency = 'USD'; 
		ce.BankAccount = c2g.CODAAPICommon.getRef(bankAccount.Id, null);
        ce.CashEntryCurrency = c2g.CODAAPICommon.getRef(currencyId, null);
		//ce.PaymentMethod = cashReceipt.dealer__Payment_Method__c;
		ce.PaymentMethod = ffPaymentMethod;
        ce.Period = c2g.CODAAPICommon.getRef(openPeriod, null);
		ce.Status = c2g.CODAAPICashEntryTypes_7_0.enumStatus.InProgress;
		ce.TypeRef = c2g.CODAAPICashEntryTypes_7_0.enumType.Receipt;
		ce.Value = cashReceipt.dealer__Amount__c;
		ce.Reference = dt.format('yyyyMMdd') + '/' + loc.Financial_Force_Dimension_1__r.c2g__ReportingCode__c + '/' + paymentMethod;
        
        System.debug(existingEntry);
        
        if(existingEntry!=null && existingEntry.Id!=null) {
            ce.Id=existingEntry.Id;
        }

        /* Generate Line Items */
        c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItems celines = new c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItems();
        c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItem celine = new c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItem();
        celine.Account = c2g.CODAAPICommon.getRef(cashReceipt.dealer__Customer__c, null);
        celine.AccountDimension1 = c2g.CODAAPICommon.getRef(cashReceipt.dealer__Location__r.Financial_Force_Dimension_1__c, null);
        celine.CashEntryValue = cashReceipt.dealer__Amount__c;
        celine.PaymentValue = cashReceipt.dealer__Amount__c;
		celine.BankAccountValue = cashReceipt.dealer__Amount__c;
		celine.AccountReference = cashReceipt.Name;
		//celine.LineDescription = cashReceipt.Name;
        celines.LineItemList = new List<c2g.CODAAPICashEntryLineItemTypes_7_0.CashEntryLineItem>(); 
        celines.LineItemList.add(celine);
        ce.LineItems = celines;
            
		c2g.CODAAPICommon.Reference ceref = c2g.CODAAPICashEntry_7_0.CreateCashEntry(ct7, ce);

		// set custom data
		// header
		if (existingEntry==null && ceref.Id!=null) {
			update(new c2g__codaCashEntry__c(
				Id=ceref.Id,
				Automated_Entry__c = true, AutoMatchCash__c = true
			));
		}
		// line is handled via trigger because updating it here
		// results in error:
		// Update failed. First exception on row 0 with id a3j540000004mdoAAA; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Object validation has failed. Cash Entry: Object validation has failed. The Net Value field is automatically updated. You cannot edit it directly.
		c2g__codaCashEntryLineItem__c cel = [
			select Id, Control__c, Cashier__c 
			from c2g__codaCashEntryLineItem__c
			where c2g__CashEntry__c=:ceref.Id 
			  and c2g__AccountReference__c=:cashReceipt.Name
			LIMIT 1
		];
		String controlNbr = '';
		//if (!String.isBlank(cashReceipt.dealer__MobilityDeal__r.Name)) controlNbr = cashReceipt.dealer__MobilityDeal__r.Name;
		if (!String.isBlank(cashReceipt.dealer__Rental_Agreement__r.Name)) controlNbr = cashReceipt.dealer__Rental_Agreement__r.Name;
		if (!String.isBlank(cashReceipt.dealer__Service_Repair_Order__r.Name)) controlNbr = cashReceipt.dealer__Service_Repair_Order__r.Name;
		if (!String.isBlank(cashReceipt.dealer__Deal__r.Name)) controlNbr =cashReceipt.dealer__Deal__r.Name;
		update(new c2g__codaCashEntryLineItem__c(Id=cel.Id, Cashier__c=cashReceipt.Id, Control__c=controlNbr));

		// link cashiering record to cash entry line item
		update(new dealer__Cashering__c(Id=cashReceipt.Id, Cash_Entry_Line_Item__c=cel.Id));

    }
    

    /**
    * Get Current Cash Entry
    */
    private static c2g__codaCashEntry__c getCurrentCashEntry(dealer__Dealer_Location__c location, String paymentMethod, Date entryDate) {
		c2g__codaCashEntry__c rtnCashEntry;

        dealer__Dealer_Location__c loc = AccountingInterface.getLocation(location.Id);
        System.assert(loc.Financial_Force_Dimension_1__c!=null, 'Location must have a Dimension 1 set.');

        List<c2g__codaCashEntry__c> entries = [SELECT Id, Name, c2g__ChargesGLADimension1__c 
                FROM c2g__codaCashEntry__c 
                WHERE c2g__PaymentMethod__c =:paymentMethod
                AND c2g__Date__c =:entryDate 
                AND c2g__ChargesGLADimension1__c=:loc.Financial_Force_Dimension_1__c
                AND c2g__Status__c ='In Progress'
				AND Automated_Entry__c = true
                LIMIT 1];
        
        if(entries.size()==1) rtnCashEntry = entries[0];

        return rtnCashEntry;
    }
    
    private static dealer__Dealer_Location__c getLocation(Id locationId)
    {
        return [
			SELECT Id, dealer__Company_Number__c, 
				Financial_Force_Dimension_1__c, Financial_Force_Dimension_1__r.c2g__ReportingCode__c,
				Company__c, Company__r.Name 
			FROM dealer__Dealer_Location__c 
			WHERE Id=:locationId];
    }

    public class AccountingInterfaceException extends Exception{}
}