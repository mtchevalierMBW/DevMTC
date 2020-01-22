//Developer Alexander Miller. Quick Fix for Chuck MAS -> RS needs 
public class ConfigSearcher{

    public list<rstk__confdsel__c> accs {get;set;}
    public String sessionIdName {get;set;}

    public ConfigSearcher(){}

    public void search(){
        accs = ([SELECT Id, Name, rstk__confdsel_confsess__r.Name, rstk__confdsel_confsel__r.rstk__confsel_helptext__c FROM rstk__confdsel__c WHERE rstk__confdsel_confsess__r.Name Like :sessionIdName+'%' LIMIT 1000]);
    }   
}