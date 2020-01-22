/**
 * WMK, LLC (c) - 2018 
 *
 * InventoryItemZPL
 * 
 * Created By:   Alexander Miller
 * Created Date: 05/14/2019 
 * Tested By:    InventoryItemZPLTest
 * Work Item:    W-000676
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */

public class InventoryItemZPL {

    public String barcode {get;set;}

    public InventoryItemZPL()
    {
        Id itemId = ApexPages.currentpage().getparameters().get('id');

        rstk__icitem__c tempItem = ([SELECT Id, 
                                        Name, 
                                        rstk__externalId__c,
                                        rstk__icitem_div__c, 
                                        rstk__icitem_div__r.Name, 
                                     	rstk__icitem_div__r.rstk__sydiv_descr__c,
                                        rstk__icitem_invuom__c, 
                                        rstk__icitem_invuom__r.Name,
                                        rstk__icitem_descr__c
                                    FROM rstk__icitem__c
                                    WHERE Id = :itemId]);

        barcode = buildInventoryURL(tempItem);
		//barcode = 'http://api.labelary.com/v1/printers/24dpmm/labels/2x3/0/%5EXA%5EFXQRCodeItemNumber%5EFO650,50%5EBQ,2,8%5EFDQA,%3Citem_number%3E%5EFS%5EFX%5ECF0,27,27%5EFO40,40%5EFB370,2,,,%5EFD%3Cdivision_name%3E%5EFS%5EFO380,40%5EFB250,2,,R,%5EFD%3Cuom_name%3E%5EFS%5EFX%5ECF0,36,36%5EFO40,80%5EFD%3Citem_number%3E%5EFS%5ECF0,27,27%5EFO40,120%5EFB600,4,,,%5EFD%3Citem_description%3E%5EFS%5EFX%5EFO40,170%5EBQ,2,4%5EFDQA,%3Citem_serial_number%3E%5EFS%5EFX%5ECF0,27,27%5EFO170,190%5EFDSrl:%3Citem_serial_number%3E%5EFS%5EFO170,230%5EFDLot:%3Citem_lot_number%3E%5EFS%5EFO170,260%5EFDExp:%3Citem_lot_expiration%3E%5EFS%5EXZ';
        
        System.debug(barcode);
    }

    public String buildInventoryURL(rstk__icitem__c item)
    {
        System.debug(item); 

        String URL = 'http://api.labelary.com/v1/printers/8dpmm/labels/5x6/0/';

        String inventoryItemName = item.rstk__externalId__c;
        
        inventoryItemName = inventoryItemName.substring(3, inventoryItemName.length());
        
        URL += EncodingUtil.urlEncode('^XA^FXQRCodeItemNumber^FO650,50^BQ,2,8^FDQA,', 'UTF-8') + inventoryItemName.replace(' ', '%20') + EncodingUtil.urlEncode('^FS', 'UTF-8');
        
        URL += EncodingUtil.urlEncode('^FX^CF0,27,27^FO40,40^FB370,2,,,^FD', 'UTF-8') + item.rstk__icitem_div__r.rstk__sydiv_descr__c.replace(' ', '%20') + EncodingUtil.urlEncode('^FS^FO380,40^FB250,2,,R,^FD', 'UTF-8') + item.rstk__icitem_invuom__r.Name.replace(' ', '%20') + EncodingUtil.urlEncode('^FS', 'UTF-8');
        
        URL += EncodingUtil.urlEncode('^FX^CF0,36,36^FO40,80^FD', 'UTF-8') + inventoryItemName.replace(' ', '%20') + EncodingUtil.urlEncode('^FS^CF0,27,27^FO40,120^FB600,4,,,^FD', 'UTF-8') + item.rstk__icitem_descr__c.replace(' ', '%20') + EncodingUtil.urlEncode('^FS', 'UTF-8');

        // Serial, Lot, and Lot Expiration
        //URL += EncodingUtil.urlEncode('^FX^FO40,170^BQ,2,4^FDQA,<item_serial_number>^FS', 'UTF-8');
        //URL += EncodingUtil.urlEncode('^FX^CF0,27,27^FO170,190^FDSrl:<item_serial_number>^FS^FO170,230^FDLot:<item_lot_number>^FS^FO170,260^FDExp:<item_lot_expiration>^FS', 'UTF-8');
        
        URL += EncodingUtil.urlEncode('^XZ', 'UTF-8');

        return URL;
    }
}