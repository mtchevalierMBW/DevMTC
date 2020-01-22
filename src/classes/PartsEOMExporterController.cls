public without sharing class PartsEOMExporterController {

    public List<PartsEOM.eomData> end_of_month = new List< PartsEOM.eomData>();
    
    public PartsEOMExporterController() {
        PartsEom p = new PartsEom();
        p.locationName ='';
        p.end_of_month.clear();
        p.geteomdata_json();
        end_of_month = p.end_of_month;
    }

    public List<PartsEOM.eomData> geteom(){
        return end_of_month;
    }
}