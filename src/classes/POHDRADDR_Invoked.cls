/**
* MobilityWorks (c) - 2017
*
* Programmer: Alexander Miller
* Created 1/1/2018
* Description: A class used by a Process Builder
*   to be invoked and loaded with data on 
*   Purchase Order edits. 
*
* Tested By: POHDRADDR_InvokedTest
*
* Modified:
* Alexander Miller 1/9/2018 - AMILLER1 - Changed override name to customer name since it was pulling a record id
*/
public with sharing class POHDRADDR_Invoked {

    static String comma = ', ';

    /**
    * refreshQuery
    *
    * A function which takes all of the Purchase Order
    * record IDs and queries the system for the desired
    * fields
    *
    * @param poIdValues - list of Purchase Order record IDs found to be modified in the transaction
    * @return List<rstk__pohdraddr__c> - list of records containing the desired lookup data
    */
    public static List<rstk__pohdraddr__c> refreshQuery(List<Id> poIdValues)
    {
        return ([SELECT Id,
                    // Address Fields
                    rstk__pohdraddr_city__c,
                    rstk__pohdraddr_country__c,
                    rstk__pohdraddr_phone__c,
                    rstk__pohdraddr_street__c,
                    rstk__pohdraddr_stateprov__c,
                    rstk__pohdraddr_zippostalcode__c,
                    // PO Header Addresses
                    rstk__pohdraddr_ordno__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__c,
                    // AMILLER1
                    // used if override address is made
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_custno__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_custno__r.name,
                    // / AMILLER1
                    // Standard Ship Address
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_defaultshipto__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address1__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address2__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address3__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_city__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_country__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_name__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_state__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_phone__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_zip__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_useasshipto__c,
                    // Override Ship Address
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address1__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address2__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address3__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_city__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_country__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_name__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_phone__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_state__c,
                    rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_zip__c
                FROM rstk__pohdraddr__c 
                WHERE rstk__pohdraddr_ordno__c IN :poIdValues]);
    }

    /**
    * combineStreetAddresses
    *
    * function which takes the address lines of the address object
    * and dynamically assigns it to one large string depending
    * if the address fields are null or not.
    *
    * @param line1 - address line 1
    * @param line2 - address line 2
    * @param line3 - address line 3
    *
    * @return string - cleaned address line string
    */
    public static String combineStreetAddresses(String line1, String line2, String line3)
    {
        String returningString = '';
        
        if(line1 != null && !String.isEmpty(line1))
        {
            returningString += line1;
        }
        
        if(line2 != null && !String.isEmpty(line2))
        {
            returningString += comma + line2;
        }
        
        if(line3 != null && !String.isEmpty(line3))
        {
            returningString += comma + line3;
        }

        return returningString;
    }

    /**
    * invocablePurchaseOrderAddressUpdate
    *
    * - Invoked by a Process Builder found in the list below,
    * this method takes the IDs of the Purchase Orders
    * and updates the Ship To Address to the Customer 
    * record found on the connected Sales Order Header.
    * - - TW Purchase Order Header
    *
    * - The address is updated to the overridden address 
    * on the Sales Order Header if one is found, else it
    * is the standard one.
    *
    * @param poIds - List of all the Purchase Orders record IDs modified in this transaction
    */
    @InvocableMethod
    public static void invocablePurchaseOrderAddressUpdate(List<Id> poIds) 
    {
        // 1. Get queried data to look at SO Customer Address
        List<rstk__pohdraddr__c> cleanedList = refreshQuery(poIds);

        // 2. Cycle through each address and assign new addresses based on override flag
        for(rstk__pohdraddr__c tempAddress : cleanedList)
        {
            // Override Ship Address
            if(tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__c != null)
            {
                tempAddress.Name =  tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_custno__r.name; // AMILLER1
                tempAddress.rstk__pohdraddr_street__c = combineStreetAddresses(tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address1__c,
                                                        tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address2__c, 
                                                        tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address3__c);
                tempAddress.rstk__pohdraddr_city__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_city__c;
                tempAddress.rstk__pohdraddr_stateprov__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_state__c;
                tempAddress.rstk__pohdraddr_country__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_country__c;
                tempAddress.rstk__pohdraddr_phone__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_phone__c;
                tempAddress.rstk__pohdraddr_zippostalcode__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_shiptoaddr__r.rstk__socaddr_zip__c;
            }
            // Standard Ship Address
            else
            {
                tempAddress.Name = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_name__c;
                tempAddress.rstk__pohdraddr_street__c = combineStreetAddresses(tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address1__c,
                                                        tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address2__c, 
                                                        tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address3__c);
                tempAddress.rstk__pohdraddr_city__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_city__c;
                tempAddress.rstk__pohdraddr_stateprov__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_state__c;
                tempAddress.rstk__pohdraddr_country__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_country__c;
                tempAddress.rstk__pohdraddr_phone__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_phone__c;
                tempAddress.rstk__pohdraddr_zippostalcode__c = tempAddress.rstk__pohdraddr_ordno__r.Sales_Order_Header__r.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_zip__c;
            }
        }

        // 3. Update all the records
        update cleanedList;
    }   
}