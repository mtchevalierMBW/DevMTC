/**
 * PartLabelPrint_CTLR
 * Tested by: PartLabelPrint_TEST
 * -- Receives and Id of type PurchaseOrder for printing during receipt of parts, or
 *    of type PartMaster or PurchaseOrderLine for re-printing.
 * -- Gathers list of parts and related information and shows on-screen with checkbox
 *    to select which ones to print.
 * -- Printer name or IP stored in dealer__Dealer_Location__c.Part_Label_Printer__c
 * -- Prints using Javascript post to printer (runs on client, so printer can use local DNS or internal IP)
 *
 *	2015-07-24	B. Leaman	BLL1 Use received qty from PO if not tied to a service job line.
 *	                        Also adjust by pack qty from part master & adjust printer IP in sandbox.
 *	2015-10-06	B. Leaman	BLL2 Add dynamic title to page block
 *	2015-11-03	B. Leaman	BLL3 IT#16039 Attempt to determine which parts were just received and select those only.
 *	2015-12-01	B. Leaman	BLL4 IT#15478 Add barcode to labels.
 *	2016-07-29	B. Leaman	BLL5 - user CurrentUserSingleton
 *	2016-10-27	B. Leaman	BLL6 - don't show extra lines for labels unallocated to an RO if there was no RO for any of them.
 */
public with sharing class PartLabelPrint_CTLR {

    public List<PartLabelInfo> LabelInfos {get; set;}
    public List<PartLabelInfo> labels {get; private set;}
    public List<String> zpls {get; private set;}
    
    public String printerip {get; set;}
    public boolean canChangePrinter {get; private set;}
    public String title {get; set;}  // BLL2a
    
    // to be removed... in favor of PartLabelInfo class
    //public String rawPartNumber {get; private set;}
    //public String mfgPartNumber {get; private set;}
    //public String partNumber {get; private set;}
    //public String manufacturer {get; private set;}
    //public String partDescription {get; private set;}
    //public Integer copies {get; set;}
    //public String poNumber {get; set;}
    //public String roNumber {get; set;}
    //public String customerName {get; set;}
    public Date   rcvDate {get; set;}
    public String rcvDateString {get; set;} 

    private Decimal DftMfgPartCharWidth = 62;
    private Decimal MfgPartCharWidth = 62;
    private Id refid=null;
    private boolean fromPartMaster=false;
    private boolean fromPO=false;
    private boolean fromPOLine=false;

    // Zebra label template with replacement variables {}
    String PartLabelZPLTemplate = ''  // BLL4a
         + '~CT~~CD,~CC^~CT~'
         + '^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR5,5~SD15^JUS^LRN^CI0^XZ'
         + '^XA'
         + '^MMT'
         + '^PW609'
         + '^LL0406'
         + '^LS0'
         + '^FO34,24^GB575,78,78^FS'
         + '^FT34,86^A0N,62,{MFGPARTCHARWIDTH}^FR^FH\\^FD{MFG_PART_NUMBER}^FS'
         + '^FT34,146^A0N,34,33^FH\\^FD{PART_DESCRIPTION}^FS'
         + '^FT34,194^A0N,34,33^FH\\^FDRCV: {RCV_DATE}^FS'
         + '^FT34,242^A0N,34,33^FH\\^FDPO: {PO_NUMBER}^FS'
         + '^FT312,242^A0N,34,33^FH\\^FDRO: {RO_NUMBER}^FS'
         + '^FT34,290^A0N,34,33^FH\\^FDCUSTOMER: {CUSTOMER_NAME}^FS'
         + '^BY{BC_DENSITY},3,61^FT42,371^BCN,,Y,N'
         + '^FD>:{MFG_PART_NUMBER}^FS'	// >: means use subset B with start character!
         + '^FT568,391^A0N,14,14^FH\\^FDv1.2^FS'
         + '^PQ{QTY},0,1,Y^XZ'
         + '\\n';
/* BLL4d    String PartLabelZPLTemplate = ''
         + '~CT~~CD,~CC^~CT~'
         + '^XA~TA000~JSN^LT0^MNW^MTD^PON^PMN^LH0,0^JMA^PR5,5~SD15^JUS^LRN^CI0^XZ'
         + '^XA'
         + '^MMT'
         + '^PW609'
         + '^LL0406'
         + '^LS0'
         + '^FO34,37^GB575,78,78^FS'
         + '^FT34,99^A0N,62,{MFGPARTCHARWIDTH}^FR^FH\\^FD{MFG_PART_NUMBER}^FS'
         + '^FT34,159^A0N,34,33^FH\\^FD{PART_DESCRIPTION}^FS'
         + '^FT34,210^A0N,34,33^FH\\^FDRCV: {RCV_DATE}^FS'
         + '^FT34,260^A0N,34,33^FH\\^FDPO: {PO_NUMBER}^FS'
         + '^FT34,311^A0N,34,33^FH\\^FDRO: {RO_NUMBER}^FS'
         + '^FT34,362^A0N,34,33^FH\\^FDCUSTOMER: {CUSTOMER_NAME}^FS'
         + '^FT492,390^A0N,14,14^FH\\^FDv1.1^FS'
         + '^PQ{QTY},0,1,Y^XZ'
         + '\\n';
*/

    // constructor
    // Obtain Id, determine object type and load up list of possible labels to print
    //-------------------------------------------------------------------------------
    public PartLabelPrint_CTLR() {
        refid = null;
        printerip = 'Zebra_GK420d';
        
        // Determine if user is authorized to key in a printer name (only admins)
        Profile p = [
            select Id, Name, PermissionsModifyAllData 
            from Profile 
            where Id=:UserInfo.getProfileID() 
            limit 1
        ];
        canChangePrinter = (p!=null && (p.Name.contains('Admin') || p.PermissionsModifyAllData==true));
        
        LabelInfos = new List<PartLabelInfo>();
        labels = new List<PartLabelInfo>();
        zpls = new List<String>();
        rcvDate = Date.today();
        rcvDateString = '';
        //copies = 1;
        //mfgPartNumber = '';
        //rawPartNumber = '';
        //partNumber = '';
        //manufacturer = '';
        //partDescription = '';
        //copies = 1;
        //poNumber = '';
        //roNumber = '';
        //customerName = '';
        title = '';  // BLL2a

        // Get SObject Id from url
        Map<String,String> URLParameters = ApexPages.currentPage().getParameters();
        if (URLParameters.containsKey('id')) {
            refid = (Id) URLParameters.get('id');
        }    

        // Determine type of object (R.O., Part Master, Part Inventory, etc)
        if (refid!=null && Schema.dealer__Parts_Master__c.SObjectType == refid.getSObjectType()) {
            labelsFromPartsMaster(refid);
            fromPartMaster = true;
            title = 'Part Master Labels';  // BLL2a
        }
        if (refid!=null && Schema.dealer__Purchase_Order_Line__c.SObjectType == refid.getSObjectType()) {
        	labelsFromPurchaseOrderLine(refid);
        	fromPOLine = true;
            title = 'Purchase Order Line Labels';  // BLL2a
        }
        if (refid!=null && Schema.dealer__Purchase_Order__c.SObjectType == refid.getSObjectType()) {
        	labelsFromPurchaseOrder(refid);
        	fromPO = true;
            title = 'Purchase Order Labels';  // BLL2a
        }
        
        // If not able to print any labels, give info message
        if (labelInfos.size()==0) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.INFO, 'Nothing to print')
            );
        }
        
        // Get printer name/ip from dealer__Dealer_Location__c.Part_Label_Printer__c
	    Id defaultLocId = null;
	    //BLL5d User u = [Select Id, Division from User where Id=:UserInfo.getUserId() limit 1];
	    User u = CurrentUserSingleton.getInstance();	// BLL5a
	    System.debug('user id='+u.Id+', division='+u.Division);
	    if (u != null && u.Division != null) {
	       List<dealer__Dealer_Location__c> loc = [
	           select Id, Part_Label_Printer__c 
	           from dealer__Dealer_Location__c 
	           where dealer__Company_Number__c=:u.Division
	       ];
	       if (loc.size()>0) {
	       	  //System.debug('location id=' + loc[0].Id);
	          defaultLocId = loc[0].Id;
	          if (loc[0].Part_Label_Printer__c!=null) {
	          	  printerip = loc[0].Part_Label_Printer__c;
	          }
	       }
	    } 
	    
	    // Sandbox: prefix printer IP to prevent accidental print! BLL1a
	    Organization org = [select Id, IsSandbox from Organization limit 1];
        if (org.isSandbox) {
        	printerip = 'Sandbox.' + printerip;
        }
        // BLL1a end
	    

    }


    // getLabelZPL
    // Perform replacements on ZPL template & return result
    //------------------------------------------------------
    public String getLabelZPL(PartLabelInfo pi) {
        String zpl = PartLabelZPLTemplate;
        // Perform replacements
        String part = replaceNull(pi.mfgPartNumber);
        MfgPartCharWidth = DftMfgPartCharWidth;
        if (part.length()>16) {
            System.debug('Part number length='+String.valueOf(part.length()));
        	MfgPartCharWidth = (16.0 / part.length()) * DftMfgPartCharWidth;
        	MfgPartCharWidth = MfgPartCharWidth.setScale(0, System.RoundingMode.FLOOR);
        	System.debug('MfgPartCharWidth = ' + String.valueOf(MfgPartCharWidth));
        }
        Integer density = 3;
        if (part.length()>15) density=2;
        if (part.length()>21) density=1;
		zpl = zpl.replace('{BC_DENSITY}', String.valueOf(density));
        zpl = zpl.replace('{MFGPARTCHARWIDTH}', String.valueOf(mfgPartCharWidth));
        zpl = zpl.replace('{MFG_PART_NUMBER}', part);
        zpl = zpl.replace('{RAW_PART_NUMBER}', replaceNull(pi.rawPartNumber));
        zpl = zpl.replace('{PART_NUMBER}', replaceNull(pi.partNumber));
        zpl = zpl.replace('{MANUFACTURER}', replaceNull(pi.manufacturer));
        zpl = zpl.replace('{PART_DESCRIPTION}', replaceNull(pi.partDescription));
        zpl = zpl.replace('{PO_NUMBER}', replaceNull(pi.poNumber));
        zpl = zpl.replace('{RO_NUMBER}', replaceNull(pi.roNumber));
        zpl = zpl.replace('{CUSTOMER_NAME}', replaceNull(pi.customerName));
        zpl = zpl.replace('{RCV_DATE}', replaceNull(pi.rcvDateString));
        zpl = zpl.replace('{QTY}', String.valueOf(pi.copies));
        zpl = zpl.replace('"', '\\"');
        return zpl;        
    }

    // replaceNull
    // Replace null with empty string
    //-------------------------------------
    public String replaceNull(String s) {
    	return (s==null) ? '' : s;
    }

    // labelsFromPartsMaster
    //------------------------------------------------
    public void labelsFromPartsMaster(Id refid) {
    	System.debug('labelsFromPartsMaster ' + refid);
        dealer__Parts_Master__c PartMaster = null;
        labelinfos.clear();
        try {
            PartMaster = [
                select Id, Name, dealer__Part_No__c, dealer__Part_No_Display__c,
                       dealer__Manufacturer__c, dealer__Raw_Part_Number__c,    
                       dealer__Pack_QTY__c, dealer__Part_Description__c
                from dealer__Parts_Master__c
                where Id=:refid
                limit 1
            ];
        } catch(Exception e) {
        }
        rcvDateString = DateTime.newInstance(rcvDate, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yy');
        if (PartMaster!=null) {
            PartLabelInfo pli = new PartLabelInfo();
            pli.rcvDateString = (rcvDateString!=null) ? rcvDateString : '';
            pli.mfgPartNumber = PartMaster.dealer__Part_No__c;
            pli.rawPartNumber = PartMaster.dealer__Raw_Part_Number__c;
            pli.partNumber = PartMaster.Name;
            pli.manufacturer = PartMaster.dealer__Manufacturer__c;
            pli.partDescription = PartMaster.dealer__Part_Description__c;
            pli.copies = 1;
            pli.poNumber = '';
            pli.roNumber = '';
            pli.customerName = '';
            pli.selected = true;
            labelinfos.add(pli);
        }
    }

    // labelsFromPurchaseOrder
    //------------------------------------------------------
    public void labelsFromPurchaseOrder(Id refid) {
    	System.debug('labelsFromPurchaseOrder ' + refid);
	    dealer__Purchase_Order__c PurchaseOrder;
        List<dealer__Parts_Master__c> PartMasters;
        dealer__Parts_Master__c PartMaster;
	    List<dealer__Parts_Inventory__c> PartInventorys;
	    dealer__Parts_Inventory__c PartInventory;
	    List<dealer__Service_Repair_Order__c> RepairOrders;
	    dealer__Service_Repair_Order__c RepairOrder;
	    List<dealer__Service_Job__c> ServiceJobLines;    
	    dealer__Service_Job__c ServiceJobLine;    
	    List<dealer__Parts_Invoice_Line__c> PartsLines;
	    dealer__Parts_Invoice_Line__c PartsLine;
        
    	try {
            // Get Purchase Order
    		PurchaseOrder = [
    		    select Id, Name, dealer__PO_Number__c
    		    from dealer__Purchase_Order__c
    		    where id=:refid
    		    limit 1
    		];
            // PO Lines
    		for(dealer__Purchase_Order_Line__c line : [ 
    		    select Id, Name, dealer__Purchase_Order__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c , 
    		           dealer__Part__c, dealer__Part_Quantity__c, dealer__Service_Job_Line__c,
    		           dealer__Parts_Master__c, dealer__Part_Quantity_Received__c,
    		           LabelPrintRcvQty__c // BLL3a
    		    from dealer__Purchase_Order_Line__c
    		    where dealer__Purchase_Order__c=:PurchaseOrder.Id]) {
                System.debug('PO Line ' + line.Id);

                loadUpFromPO(PurchaseOrder, line);
                
	        }


    	} catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    		System.debug(e.getTypeName() + ': ' + e.getMessage());
    	}
    	
    }

    // labelsFromPurchaseOrderLine
    //------------------------------------------------------
    public void labelsFromPurchaseOrderLine(Id refid) {
    	System.debug('labelsFromPurchaseOrderLine ' + refid);
	    dealer__Purchase_Order__c PurchaseOrder;
	    dealer__Purchase_Order_Line__c line;
        
    	try {
            // PO Lines
    		line = [ 
    		    select Id, Name, dealer__Purchase_Order__c, dealer__Parts_Invoice__c, dealer__Parts_Line__c , 
    		           dealer__Part__c, dealer__Part_Quantity__c, dealer__Service_Job_Line__c,
    		           dealer__Parts_Master__c, dealer__Part_Quantity_Received__c,
    		           LabelPrintRcvQty__c // BLL3a
    		    from dealer__Purchase_Order_Line__c
    		    where Id=:refid];
            System.debug('PO Line ' + line.Id);

            // Get Purchase Order
    		PurchaseOrder = [
    		    select Id, Name, dealer__PO_Number__c
    		    from dealer__Purchase_Order__c
    		    where id=:line.dealer__Purchase_Order__c
    		    limit 1
    		];
                
            loadUpFromPO(PurchaseOrder, line);
                
    	} catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    		System.debug(e.getTypeName() + ': ' + e.getMessage());
    	}
    	
    }

    // loadUpFromPO
    // Common code when loading info from a PO or a single PO line
    //-------------------------------------------------------------
    public void loadUpFromPO(dealer__Purchase_Order__c PurchaseOrder, dealer__Purchase_Order_Line__c line) {
        List<dealer__Parts_Master__c> PartMasters;
        dealer__Parts_Master__c PartMaster;
	    List<dealer__Parts_Inventory__c> PartInventorys;
	    dealer__Parts_Inventory__c PartInventory;
	    List<dealer__Service_Repair_Order__c> RepairOrders;
	    dealer__Service_Repair_Order__c RepairOrder;
	    List<dealer__Service_Job__c> ServiceJobLines;    
	    dealer__Service_Job__c ServiceJobLine;    
	    List<dealer__Parts_Invoice_Line__c> PartsLines;
	    dealer__Parts_Invoice_Line__c PartsLine;

        // Get service job line (if available)
        ServiceJobLine = null;
	    ServiceJobLines = [ 
	        select Id, Name, dealer__Service_Repair_Order__c, dealer__Repair_Order__c, dealer__Parts_Line__c
	        from dealer__Service_Job__c
	        where id=:line.dealer__Service_Job_Line__c
	    ];
	    if (ServiceJobLines.size()>0) {
	    	ServiceJobLine = ServiceJobLines[0];
	    	System.debug('Service job line ' + ServiceJobLine.Id + ' ' + ServiceJobLine.Name);
	    }
		
		// Get repair order from service job line (if available)    
	    RepairOrder = null;
	    if (ServiceJobLine!=null && ServiceJobLine.dealer__Service_Repair_Order__c!=null) {
	    	RepairOrders = [
	    	    select id, Name, dealer__Customer__r.Name, dealer__Customer_Contact__r.Name,
	    	           dealer__Company__c
	    	    from dealer__Service_Repair_Order__c
	    	    where id=:ServiceJobLine.dealer__Service_Repair_Order__c 
	    	];
	    	if (RepairOrders.size()>0) {
	    		RepairOrder = RepairOrders[0];
	    		System.debug('RepairOrder from ServiceJobLine ' + RepairOrder.Id + ' ' + RepairOrder.Name);
	    	}
	    } 
	    
	    // Get parts line (invoice line) from Service job line or PO line
	    PartsLine = null;
	    if (ServiceJobLine!=null && ServiceJobLine.dealer__Parts_Line__c!=null) {
	    	PartsLines = [
	    	    select Id, Name, dealer__MFG__c, dealer__Part_Number__c, dealer__Part__c,
	    	           dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Currently_Available__c
	    	    from dealer__Parts_Invoice_Line__c
	    	    where Id=:ServiceJobLine.dealer__Parts_Line__c
	    	];
	    	if (PartsLines.size()>0) {
	    		PartsLine = PartsLines[0];
	    		System.debug('PartsLine from ServiceJobLine ' + PartsLine.Id + ' ' + PartsLine.Name);
	    	}
	    } 
	    if (PartsLine==null && line.dealer__Parts_Line__c!=null) {
	    	PartsLines = [
	    	    select Id, Name, dealer__MFG__c, dealer__Part_Number__c, dealer__Part__c,
	    	           dealer__Quantity_Ordered__c, dealer__Quantity_Sold__c, dealer__Currently_Available__c
	    	    from dealer__Parts_Invoice_Line__c
	    	    where Id=:line.dealer__Parts_Line__c
	    	];
	    	if (PartsLines.size()>0) {
	    		PartsLine = PartsLines[0];
	    		System.debug('PartsLine from PO line ' + PartsLine.Id + ' ' + PartsLine.Name);
	    	}
	    }
		     
		// Warn if no receipt found
	    if (PartsLine==null && !fromPartMaster) {
	        // disable warning for now...apparently this is normal
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Could not find receipt for part '));
	    }
		    
        // Get Part Inventory from PartsLine (invoice line)
	    PartInventory = null;
	    if (PartsLine!=null && PartsLine.dealer__Part__c!=null) {
	        PartInventorys = [
	            select Id, Name, dealer__Parts_Master__c
	            from dealer__Parts_Inventory__c
	            where id=:PartsLine.dealer__Part__c
	        ]; 
            if (PartInventorys.size()>0) {
            	PartInventory = PartInventorys[0];
	    		System.debug('PartInventory ' + PartInventory.Id + ' ' + PartInventory.Name);
            }
	    }
	    
	    // Get Part Master from Part Line or PO line 
        PartMaster = null;
        Id pmId = null;
	    if (PartInventory!=null) {
	    	pmId = PartInventory.dealer__Parts_Master__c;
	    } else if (line.dealer__Parts_Master__c!=null) {
	    	pmId = line.dealer__Parts_Master__c;
	    }
	    if (pmId!=null) {
	    	PartMasters = [
                select Id, Name, dealer__Part_No__c, dealer__Part_No_Display__c,
                       dealer__Manufacturer__c, dealer__Raw_Part_Number__c,    
                       dealer__Pack_QTY__c, dealer__Part_Description__c
                from dealer__Parts_Master__c
                where Id=:pmId
	    	];
	    	if (PartMasters.size()>0) {
	    		PartMaster = PartMasters[0];
	    		System.debug('PartMaster ' + PartMaster.Id + ' ' + PartMaster.Name);
	    	}
	    }

        // Generate wrapper class of gathered information         
        PartLabelInfo pli = new PartLabelInfo();
        pli.rcvDateString = DateTime.newInstance(rcvDate, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yy');
        if (PartMaster!=null) {
            pli.mfgPartNumber = PartMaster.dealer__Part_No__c;
            pli.rawPartNumber = PartMaster.dealer__Raw_Part_Number__c;
            pli.partNumber = PartMaster.Name;
            pli.manufacturer = PartMaster.dealer__Manufacturer__c;
            pli.partDescription = PartMaster.dealer__Part_Description__c;
        }
        pli.copies = 1;
        // BLL1a
        if (line!=null) { // && line.dealer__Part_Quantity_Received__c!=null) {
        	// BLL3d pli.copies = Integer.valueOf(line.dealer__Part_Quantity_Received__c);
        	// BLL3a
        	Decimal qty = (line.dealer__Part_Quantity_Received__c==null) ? 0 : line.dealer__Part_Quantity_Received__c;
        	Decimal pntqty = (line.LabelPrintRcvQty__c==null) ? 0 : line.LabelPrintRcvQty__c;
        	pli.copies = qty>pntqty ? Integer.valueOf(qty-pntqty) : 0;
        	pli.PoLine = line;
        	// BLL3a end
        }
        // BLL1a end
        if (PartsLine!=null) {
        	pli.copies = Integer.valueOf(PartsLine.dealer__Quantity_Sold__c);
        }
        if (PurchaseOrder!=null && PurchaseOrder.dealer__PO_Number__c!=null) {
        	pli.poNumber = PurchaseOrder.dealer__PO_Number__c;
        }
        if (ServiceJobLine!=null) {
        	pli.roNumber = ServiceJobLine.dealer__Repair_Order__c;
        	if (RepairOrder.dealer__Customer__r.Name!=null) {
        	    pli.customerName = RepairOrder.dealer__Customer__r.Name;
        	} 
        }
        pli.selected = pli.copies>0;

        // We only print labels if there is a related part master!
        if (PartMaster!=null) {

            // Adjust by pack size (if even multiple of pack size) BLL1a
            if (pli.copies>1 && PartMaster.dealer__Pack_QTY__c>0 
                && Math.mod(pli.copies, Integer.valueOf(PartMaster.dealer__Pack_QTY__c))==0) {
            	pli.copies = Integer.valueOf(pli.copies / PartMaster.dealer__Pack_QTY__c);
            }
            // BLL1a end

	        LabelInfos.add(pli);
	        System.debug('Added line info: ' + pli.toString());
	        
	        // Extra label(s) for un-accounted-for lines (received 10 but only sold 2 of them)
	        // The extra 8 will not contain RO or customer information
	        if (ServiceJobLine!=null && PartsLine!=null && (PartsLine.dealer__Currently_Available__c>0 || Test.isRunningTest())) {	// BLL6c check for servicejobline
	        	pli = new PartLabelInfo();
	            pli.rcvDateString = DateTime.newInstance(rcvDate, Time.newInstance(0, 0, 0, 0)).format('MM/dd/yy');
	        	pli.copies = Integer.valueOf(PartsLine.dealer__Currently_Available__c);
		        if (PartMaster!=null) {
		            pli.mfgPartNumber = PartMaster.dealer__Part_No__c;
		            pli.rawPartNumber = PartMaster.dealer__Raw_Part_Number__c;
		            pli.partNumber = PartMaster.Name;
		            pli.manufacturer = PartMaster.dealer__Manufacturer__c;
		            pli.partDescription = PartMaster.dealer__Part_Description__c;
		        }
	            if (PurchaseOrder!=null && PurchaseOrder.dealer__PO_Number__c!=null) {
	                pli.poNumber = PurchaseOrder.dealer__PO_Number__c;
	            }
	            pli.selected = pli.copies>0;
	            LabelInfos.add(pli);
	            System.debug('Added line info: ' + pli.toString());
	        }
        } else {
        	ApexPages.addMessage(
        	   new ApexPages.Message(ApexPages.Severity.INFO, 'No part on line '+line.Name)
        	);
        }
    }

    
    // print 
    // generate code to print labels 
    // (re-render section of page with label info & script to send to printer)
    //-------------------------------------------------------------------------
    public void print() {
    	List<dealer__Purchase_Order_Line__c> updlines = new List<dealer__Purchase_Order_Line__c>();  // BLL3a
    	labels = new List<PartLabelInfo>();
    	zpls = new List<String>();
    	String zpl;
    	for(PartLabelInfo pi : LabelInfos) {
    		if (pi.selected) {
    			System.debug('Print: ' + pi.toString());
    			labels.add(pi);
                zpl = getLabelZPL(pi);
                System.debug('ZPL: ' + zpl);
    			zpls.add(zpl);
    			// BLL3a - update lines
    			if (pi.PoLine!=null) {
    				updlines.add(new dealer__Purchase_Order_Line__c(
    					Id=pi.PoLine.Id, LabelPrintRcvQty__c=pi.PoLine.dealer__Part_Quantity_Received__c
    		        ));
    			}
    			// BLL3a end
    		}
    	}
    	if (zpls.size()==0) {
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.ERROR, 'Nothing to print')
            );
    	}
    	// BLL3a do update of po lines
    	if (updlines.size()>0) {
    		try {
    			update(updlines);
    		} catch(Exception e) {}
    	}
    	// BLL3a end
    }


    // Return to source (PartMaster, PO, PO Line)
    //------------------------------------------------------
    public PageReference back() {
    	PageReference p = new PageReference('/' + refid);
    	p.setRedirect(true);
    	return p;
    }


    // PartLabelInfo: Wrapper class
    // List of parts and label information for printing
    //------------------------------------------------------
    public class PartLabelInfo {
    	public dealer__Purchase_Order_Line__c PoLine {get; set;}  // BLL3a
    	public boolean selected {get; set;}
    	public String mfgPartNumber {get; set;}
    	public String rawPartNumber {get; set;}
    	public String partNumber {get; set;}
    	public String manufacturer {get; set;}
    	public String partDescription {get; set;}
    	public Integer copies {get; set;}
    	public String poNumber {get; set;}
    	public String roNumber {get; set;}
    	public String customerName {get; set;}
    	public String rcvDateString {get; set;}
    	public PartLabelInfo() {
    		mfgPartNumber = '';
    		rawPartNumber = '';
    		partNumber = '';
    		manufacturer = '';
    		partDescription = '';
    		copies = 1;
    		poNumber = '';
    		roNumber = '';
    		customerName = '';
    		rcvDateString = '';
    		selected = false;
    		PoLine = null; // BLL3a
    	}
    	public override String toString() {
    		return (selected?'x':' ') + copies + ' ' + mfgPartNumber + ' ' + partDescription
    		       + ' ' + poNumber + ' ' + roNumber + ' ' + customerName + ' ' + rcvDateString;
    	}
    }

}