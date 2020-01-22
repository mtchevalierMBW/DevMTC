public class BudgetUpsert_Ctrl {
    public static String currency(String i) {
        String s = ( Decimal.valueOf(i==null||i.trim()==''?'0':i).setScale(2) + 0.001 ).format();
        return s.substring(0,s.length()-1);
    }
    public class Budget {
            public string month {get; set;}
            public string dollars {get; set;}
        	public string store {get; set;}
    }
    public string uploadType = 'Retail';
    public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public String[] csvFileLines{get;set;}
	public List<Budget> budgetlist{get;set;}
    public List<String> errorLists{get; set;}
    public BudgetUpsert_Ctrl(){
        csvFileLines = new String[]{};
        budgetlist = New List<Budget>(); 
      }
    
    public List<SelectOption> getradioTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Retail', 'Retail'));
        options.add(new SelectOption('Commercial', 'Commercial'));
        options.add(new SelectOption('Division', 'Division'));
        return options;
    }
    
    public String getUploadType() {
        return uploadType;
    }
    
    public void setUploadType(String uploadType) { this.uploadType = uploadType; }

    public Static String getMonth(Integer i){
        String str = '';
        if(i == 1){
            str = 'January';
        }
        if(i == 2){
            str = 'February';
        }
        if(i == 3){
            str = 'March';
        }
        if(i == 4){
            str = 'April';
        }
        if(i == 5){
            str = 'May';
        }
        if(i == 6){
            str = 'June';
        }
        if(i == 7){
            str = 'July';
        }
        if(i == 8){
            str = 'August';
        }
        if(i == 9){
            str = 'September';
        }
        if(i == 10){
            str = 'October';
        }
        if(i == 11){
            str = 'November';
        }
        if(i == 12){
            str = 'December';
        }
        return str;
    }
    public void updateRecords(){
        List<Budget__c> buds = [Select Id, Budget_Id__c, Budget_Type__c From Budget__c];
        for(Integer x = 0; x< buds.size(); x++){
            if(buds[x].Budget_Type__c == 'Retail'){
                if(buds[x].Budget_Id__c.right(2) != '_r'){
                	buds[x].Budget_Id__c = buds[x].Budget_Id__c + '_r';
            	}
            }
			if(buds[x].Budget_Type__c == 'Consumer'){
                buds[x].Budget_Type__c = 'Commercial';
                if(buds[x].Budget_Id__c.right(2) != '_c'){
                	buds[x].Budget_Id__c = buds[x].Budget_Id__c + '_c';
            	}
            }
            if(buds[x].Budget_Type__c == 'Commercial'){
                if(buds[x].Budget_Id__c.right(2) != '_c'){
                	buds[x].Budget_Id__c = buds[x].Budget_Id__c + '_c';
            	}
            }
        }
        try{
            update buds;
        }catch(Exception e){
            	ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage());
                ApexPages.addMessage(errorMessage);
        }
    }    
    
	public void importCSVFile(){
           List<Budget__c> Budgets = new List<Budget__c>();
        errorLists = new List<String>();
           csvAsString = '';
		   
		   List<dealer__Dealer_Location__c> Locations = [Select Id, Name__c, dealer__Company_Number__c FROM dealer__Dealer_Location__c];
               csvAsString = csvFileBody.toString();
               csvFileLines = csvAsString.split('\n'); 
                
               for(Integer i=2;i<csvFileLines.size();i++){
                   String currentLoc = '';
			   		string[] csvRecordData = csvFileLines[i].split(',');
					for(Integer m=1; m<13; m++){
                        Budget newBud = new Budget();
                        newBud.store = csvRecordData[0];
                        newBud.month = getMonth(m);
                        newBud.dollars = csvRecordData[m];
					   Budget__c budObj = new Budget__c();
					   //budObj.Budget_Id__c = csvRecordData[];   
                       String x = csvRecordData[m].replace('.','').trim();
                       String s = currency(x);
                       s = s.replace(',','');
                        system.debug(s);
                       budObj.Dollars__c = Decimal.valueOf(s);
                        if(csvRecordData[15].trim() != ''){
					   for(Integer y=0;y<Locations.size();y++){
							if(String.valueOf(Locations[y].dealer__Company_Number__c).trim() == csvRecordData[15].trim()){
								currentLoc = Locations[y].Id;
                                budObj.Location__c = currentLoc;
                       		if(uploadType == 'Retail'){
                                    budObj.Budget_Type__c = 'Retail';
                       				budObj.Name = csvRecordData[0] + ' ' + getMonth(m) + ' 2017';
                            }else if(uploadType == 'Commercial'){
                                budObj.Budget_Type__c = 'Commercial';
                       			budObj.Name = csvRecordData[0] + ' ' + getMonth(m) + ' 2017 Commercial';
                            }
					   budObj.Month__c = m;
					   budObj.Year__c = Decimal.valueOf('2017');
                       			budgetlist.add(newBud);
                                Budgets.add(budObj);
							}
					   }
                            }
					}
               }    
        		System.Debug(errorLists);
               System.Debug(Budgets);
 
        try{
            	upsert Budgets;
            }
            catch (Exception e)
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage());
                ApexPages.addMessage(errorMessage);
            }  

      }
    
    
    public void divisionUpdate(){
        	   List<dealer__Dealer_Location__c> Locations = [Select Id, Name__c, dealer__Company_Number__c, Division__c, Region__c FROM dealer__Dealer_Location__c];
               csvAsString = csvFileBody.toString();
               csvFileLines = csvAsString.split('\n'); 
                
               for(Integer i=1;i<csvFileLines.size();i++){ //foreach csv row
			   		string[] csvRecordData = csvFileLines[i].split(',');
                   for(Integer x=0; x<Locations.size();x++){//find location that matches
                       if(csvRecordData[0] == Locations[x].dealer__Company_Number__c){
                           //Locations[x].Region__c = csvRecordData[1];
                           Locations[x].Division__c = csvRecordData[2];
                       }
                   }
               }
        try{
            update Locations;
        }catch(Exception e){
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage());
                ApexPages.addMessage(errorMessage);
        }
    }
    
    
}