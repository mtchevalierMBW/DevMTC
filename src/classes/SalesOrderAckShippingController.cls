/**
 * WMK, LLC (c) - 2018 
 *
 * SalesOrderAckShippingController
 * 
 * Created By:   Alexander Miller
 * Created Date: 12/18/2018 
 * Tested By:    
 * Work Item:    W-000500
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public class SalesOrderAckShippingController {
    
    Id orderId {get;set;}
    
    public rstk__sohdr__c orderHeader {get;set;}

    public Boolean isShipThru {get;set;}

    public String customerName {get;set;}

    public String address1 {get;set;}

    public String address2 {get;set;}

    public String address3 {get;set;}

    public String city {get;set;}

    public String state {get;set;}
    
    public String zipcode {get;set;}
    
    public String country {get;set;}

    public String phone {get;set;}
    
    public String fax {get;set;}

    public String email {get;set;}

    public SalesOrderAckShippingController() { 
        
        orderId = ApexPages.currentPage().getParameters().get('id');
        
        orderHeader = [SELECT Id, 
                        Is_Ship_Thru_Order__c,
                        rstk__sohdr_shiptoaddr__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_name__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_address1__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_address2__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_address3__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_city__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_state__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_zip__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_country__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_phone__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_fax__c,
                        rstk__sohdr_shiptoaddr__r.rstk__socaddr_email__c,
                        rstk__sohdr_oshiptoaddr__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_name__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address1__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address2__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address3__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_city__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_state__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_zip__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_country__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_phone__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_fax__c,
                        rstk__sohdr_oshiptoaddr__r.rstk__soaddr_email__c
                    FROM rstk__sohdr__c 
                    WHERE Id = :orderId];
        
        isShipThru = orderHeader.Is_Ship_Thru_Order__c;
        
        // override
        if(orderHeader.rstk__sohdr_oshiptoaddr__c != null)
        {
            customerName = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_name__c;
            address1 = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address1__c;
            address2 = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address2__c;
            address3 = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_address3__c;
            city = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_city__c;
            state = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_state__c;
            zipcode = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_zip__c;
            country = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_country__c;
            phone = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_phone__c;
            fax = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_fax__c;
            email = orderHeader.rstk__sohdr_oshiptoaddr__r.rstk__soaddr_email__c;
        }
        // regular
        else 
        {
            customerName = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_name__c;
            address1 = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address1__c;
            address2 = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address2__c;
            address3 = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_address3__c;
            city = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_city__c;
            state = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_state__c;
            zipcode = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_zip__c;
            country = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_country__c;
            phone = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_phone__c;
            fax = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_fax__c;
            email = orderHeader.rstk__sohdr_shiptoaddr__r.rstk__socaddr_email__c;
        }
    }
}