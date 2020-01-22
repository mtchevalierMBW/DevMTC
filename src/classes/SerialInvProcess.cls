/**
*	SerialInvProcess
*	Tested by: SerialInvProcess_TEST
*	
*	Date		Programmer		Description
*	2017-07-05	B. Leaman		Set received date and status on chassis master when PO receipt is processed.
*	
**/

public with sharing class SerialInvProcess {

    public void copyChassisDataToReceipt(List<rstk__icitemsrl__c> newList) {
        Set<String> VINs = getSerialNbrs(newList);
        Map<String,chassis_master__c> chassismap = getchassisMap(VINs);
        copyChassisDataToReceipt(newList, chassismap);
    }


    public Set<String> getSerialNbrs(List<rstk__icitemsrl__c> newList) {
         Set<String> VINs = new Set<String>();   
         for(rstk__icitemsrl__c s: newList) {
            String ref = s.rstk__icitemsrl_serial__c;
            if (!String.isblank(ref)) {
               VINs.add(ref);
            }                   
         }  
         return VINs;
    }
	 
	public Map<String,chassis_master__c> getChassisMap(Set<String> VINs) {

           Map<String,chassis_master__c> chassismap = new Map<string,chassis_master__c>();
            for(chassis_master__c c:[select vin__c, id  from chassis_master__c  where  vin__c in :VINs]) {
              chassismap.put(c.VIN__c,c);
            } 
			return chassismap;
	}

    public void copyChassisDataToReceipt(List<rstk__icitemsrl__c> newList, Map<String,chassis_master__c> chassismap) {
            for(rstk__icitemsrl__c srl: newList) {
                if (!String.isblank(srl.rstk__icitemsrl_Serial__c)) { 
                    if (chassismap.containsKey(srl.rstk__icitemsrl_serial__c)) {
                       chassis_master__c  cm = chassismap.get(srl.rstk__icitemsrl_serial__c);
                        if (cm != Null)  {
                           srl.chassis__c=cm.Id;      
                        } 
                    }  
                }   
            } 
    }
    

public void LinkChassisToFirstInvRec(List<rstk__icitemsrl__c> newList) {

  Set<id> ChassisMasterIDs = new set<id>();
  for(rstk__icitemsrl__c srl: newList) {
     if (srl.chassis__c != NULL) ChassisMasterIDs.add(srl.chassis__c);
  }

  Map<Id,chassis_master__c> CMaplist = New Map<Id,chassis_master__c>();
  If (ChassisMasterIDs.size() > 0) CMaplist = New Map<Id,chassis_master__c>(
     [select Id, Name, Serial_Inventory_Record__c, Date_Received__c, Status__c 
      from Chassis_Master__c 
      where Id in :ChassisMasterIDs and Serial_Inventory_Record__c = NULL]
  );

  List<Chassis_Master__c> UpdateLink = New List <Chassis_Master__c>();

  for(rstk__icitemsrl__c srl: newList) {
  	 if (srl.chassis__c != NULL) {  
     	Chassis_Master__c CM = CMapList.get(srl.chassis__c);
     	if (CM!=Null && CM.Serial_Inventory_Record__c == NULL) {
			String newStatus = CM.Status__c;
			if (String.isBlank(newStatus) || newStatus=='On Order') newStatus='Received';
     		UpdateLink.add(New Chassis_Master__c(Id=CM.Id,
     			Serial_Inventory_Record__c=Srl.Id,
     			Date_Received__c=Date.Today(),
     			Status__c=newStatus
     		));
     	} 
     }
  }
  If (UpdateLink.size()>0) Update(UpdateLink);

}



}