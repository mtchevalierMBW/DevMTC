/*
* 2016-06-07 RedTeal    RT1 - given a template, vin, and stock number, creates a new vehicle inventory record
* 2018-07-16	B. Leaman	BLL1 - Only set fields from vin decode map if they are in the vin decode map.
* 2018-09-10 Alexander Miller - AMILLER1 - Bryan Leaman generated code to handle duplicate stock numbers, just pasting it in
*/
global class VehicleInventoryTemplateClone {
    
    webservice static String createVehicleFromTemplate(String templateId, String vin, String stockNumber) { 
        Map<String, Schema.SObjectField> fieldMap = dealer__Vehicle_Inventory__c.SObjectType.getDescribe().fields.getMap();
        Map<String,Schema.RecordTypeInfo> recordTypeMap = dealer__Vehicle_Inventory__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        List<String> fields = new List<String>(fieldMap.keySet());
        Set<String> excludedFields = new Set<String>();
        excludedFields.add('dealer__store_location__c');
        excludedFields.add('branch_location__c');
        excludedFields.add('dealer__company_number__c');
        
        String soql = 'SELECT ' + String.join(fields, ',') + ', (SELECT Id, Title, Body FROM Notes) FROM dealer__Vehicle_Inventory__c' + ' WHERE Id = \'' + templateId + '\'';
        System.debug(soql);


        dealer__Vehicle_Inventory__c template = Database.query(soql); 
        dealer__Vehicle_Inventory__c vehicle  = new dealer__Vehicle_Inventory__c();

        Map<String, Object> vinDecodeMap = new Map<String, Object>();
        if(vin != null && vin.length() == 17) {
            vinDecodeMap = dealer.VinDecodeRemote.decodedVin(vin);
        }
        
        for(String field : fields) {
            System.debug(field);
            System.debug(excludedFields.contains(field));
            if(fieldMap.get(field).getDescribe().isUpdateable() && !excludedFields.contains(field)) {
                vehicle.put(field, template.get(field));
            }
        }

        vehicle.RecordTypeId = recordTypeMap.get('New').getRecordTypeId();
        vehicle.dealer__VIN__c = vin;
        // BLL1c only set fields if the vinDecodeMap contains them
        if (vinDecodeMap.containsKey('dealer__Carline__c')) vehicle.dealer__Model__c = (String)vinDecodeMap.get('dealer__Carline__c');
        if (vinDecodeMap.containsKey('dealer__Make__c')) vehicle.dealer__Make__c  = (String)vinDecodeMap.get('dealer__Make__c');
        if (vinDecodeMap.containsKey('dealer__Year__c')) vehicle.dealer__Year__c  = (String)vinDecodeMap.get('dealer__Year__c');
        // AMILLER1
        //vehicle.dealer__Stock_Number__c = stockNumber == '' ? vin.right(8) : stockNumber;
        vehicle.dealer__Stock_Number__c = stockNumber == '' ? getApprovedStockNumber(vin) : stockNumber;
        // AMILLER1
        
        vehicle.dealer__Status_Code_Assignment_Date__c = Date.today();
        
        System.debug(vehicle.dealer__Store_Location__c);
        insert vehicle;
        System.debug(vehicle.dealer__Store_Location__c);

        List<Note> newNotes = new List<Note>();
        if(!template.Notes.isEmpty()) {
            for(Note templateNote : template.Notes) {
                Note note = new Note();
                note.Title = templateNote.Title;
                note.Body = templateNote.Body;
                note.ParentId = vehicle.Id;
                newNotes.add(note);
            }
        }       
        insert newNotes;
        return vehicle.Id;
    }

    //AMMILER1
    /**
    * getApprovedStockNumber
    * 
    * Function which looks out into the system and systematically assigns an extending letter to the stock #
    *
    * @param vin - VIN of the vehicle. Take last 8 to be stock
    *
    * @return String - either last 8 of the VIN or (A,B,C,D...Z) added onto the end
    */
    public static String getApprovedStockNumber(String vin)
    {
        //String vin = '1A4GP45R66B583125'; // the input vin value
        String last8 = vin.right(8);   // what we’re searching for in stock numbers
        String nextStock = last8;     // this will be adjusted by the logic below, if necessary
        
        String likepattern = last8 + '%';
        List<String> alphabet = new List<String>{'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','W','X','Y','Z'};
        
        AggregateResult ar = [
        select max(dealer__Stock_Number__c) stock
        from dealer__Vehicle_Inventory__c
        where dealer__Stock_Number__c like :likepattern
        ];
        
        if (ar!=null && ar.get('stock')!=null) {
                        System.debug(ar);
                        String laststock = (String) ar.get('stock');
                        System.debug(laststock);
                    
                        String suffix = laststock.removeStart(last8);
                        System.debug(suffix);
                    
                        if (suffix.length()==0) {
                                        nextStock = last8 + alphabet[0];
                        }
                        if (suffix.length()==1) {
                                        Integer sfxidx = alphabet.indexOf(suffix);
                                        System.debug(sfxidx);
                                        System.debug('Next suffix: ' + alphabet[sfxidx+1]);
                                        nextStock = last8 + alphabet[sfxidx+1];
                        }
        }
        System.debug('New stock#: ' + nextStock);

        return nextStock;
    }
    //AMILLER1
}