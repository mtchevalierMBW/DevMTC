/**
 * SOInvoiceExtension
 * 
 * Created 12/20/2017
 * Programmer: Alexander Miller
 * Tested By: SOInvoiceExtensionTest
 * 
 * A class which allows for Sales Order Invoice Header Email Templates
 * for invoicing can gain dynamic data
 */
public class SOInvoiceExtension {
    
    Id invoiceId {get;set;}

    /** address - Primary Shipping Address of the Division */
    public String address {get;set;}
    
    /** phone - Primary Phone of the Division */
    public String phone {get;set;}

    public SOInvoiceExtension() { 
        
        invoiceId = ApexPages.currentPage().getParameters().get('id');
        
        // load initial data
        rstk__soinv__c temp = ([SELECT Id, 
                            rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_street__c,         // Street 
                            rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_city__c,           // City 
                            rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_stateprov__c,      // State 
                            rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_zippostalcode__c,  // ZIP 
                            rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_phone__c           // Phone
                            FROM rstk__soinv__c 
                            WHERE Id = :invoiceId LIMIT 1]);
        
        // set address
        address = temp.rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_street__c + ', ' +
                 temp.rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_city__c + ', ' + 
                 temp.rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_stateprov__c + ', ' + 
                 temp.rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_zippostalcode__c;

        // set phone
        phone = temp.rstk__soinv_div__r.rstk__sydiv_primeshipaddr__r.rstk__sydivaddr_phone__c;
    }
}