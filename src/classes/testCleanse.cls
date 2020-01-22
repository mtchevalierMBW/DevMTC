public class testCleanse {
	public static void run()
    {
        System.debug('Start');

List<Chassis_Master__c> listOfChassis = ([SELECT Id, 
                                                Make__c, 
                                                Model__c, 
                                                Model_Ext__c 
                                        FROM Chassis_Master__c
                                        WHERE Model_Ext__c != 'Other']);

for(Chassis_Master__c tempChassis : listOfChassis)
{
    if(tempChassis.Model_Ext__c != null)
    {
        if(tempChassis.Model_Ext__c.equalsIgnoreCase('Caravan SE 29E'))
        {
            tempChassis.Make__c = 'Dodge';
            tempChassis.Model__c = 'Caravan';
            tempChassis.Model_Ext__c = 'SE 29E';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Caravan SE 29Q'))
        {
            tempChassis.Make__c = 'Dodge';
            tempChassis.Model__c = 'Caravan';
            tempChassis.Model_Ext__c = 'SE 29Q';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Caravan SE 29S'))
        {
            tempChassis.Make__c = 'Dodge';
            tempChassis.Model__c = 'Caravan';
            tempChassis.Model_Ext__c = '29S';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Odyssey'))
        {
            tempChassis.Make__c = 'Honda';
            tempChassis.Model__c = 'Odyssey';
            tempChassis.Model_Ext__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('PROMASTER 1500 LR 136WB'))
        {
            tempChassis.Make__c = 'Dodge';
            tempChassis.Model__c = 'Promaster';
            tempChassis.Model_Ext__c = '1500';
            tempChassis.Roof_Option__c = 'Low';
            tempChassis.Wheelbase__c = '136';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('PROMASTER 2500 WV HR 159WB'))
        {
            tempChassis.Make__c = 'Dodge';
            tempChassis.Model__c = 'Promaster';
            tempChassis.Model_Ext__c = '2500';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '159';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Savana'))
        {
            tempChassis.Make__c = 'GMC';
            tempChassis.Model__c = 'Savana';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Savana Express'))
        {
            tempChassis.Make__c = 'Chevrolet';
            tempChassis.Model__c = 'Express';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Sienna'))
        {
            tempChassis.Make__c = 'Toyota';
            tempChassis.Model__c = 'Sienna';
            tempChassis.Model_Ext__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Sienna LE'))
        {
            tempChassis.Make__c = 'Toyota';
            tempChassis.Model__c = 'Sienna';
            tempChassis.Model_Ext__c = 'LE';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Sienna Limited'))
        {
            tempChassis.Make__c = 'Toyota';
            tempChassis.Model__c = 'Sienna';
            tempChassis.Model_Ext__c = 'Limited';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Sienna SE'))
        {
            tempChassis.Make__c = 'Toyota';
            tempChassis.Model__c = 'Sienna';
            tempChassis.Model_Ext__c = 'SE';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Sienna XLE'))
        {
            tempChassis.Make__c = 'Toyota';
            tempChassis.Model__c = 'Sienna';
            tempChassis.Model_Ext__c = 'XLE';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Town and country'))
        {
            tempChassis.Make__c = 'Chrysler';
            tempChassis.Model__c = 'Town and Country';
            tempChassis.Model_Ext__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 150 MR 130WB'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-150';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '130';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 150 MR 148WB VAN'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-150';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 250 MR 148WB VAN'))        
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-250';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 MR 148WB'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 MR 148WB EL Diesel'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
            tempChassis.Diesel__c = true;
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 MR 148WB EL SRW VAN'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL SRW';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 MR 148WB VAN'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 MR Cargo'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Cargo';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit Connect XLT Wagon'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'Transit Connect';
            tempChassis.Model_Ext__c = 'XLT';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Wagon';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit Connect XL Wagon'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'Transit Connect';
            tempChassis.Model_Ext__c = 'XL';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Wagon';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR Cargo'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'Transit Connect';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Cargo';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR Wagon'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'Transit Connect';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Wagon';
        }
        // Go-live additions
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL XLT'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL XLT';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 250 MR 148WB VAN DIESEL'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-250';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
            tempChassis.Diesel__c = true;
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 150 MR CARGO'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-150';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Cargo';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 MR 148WB XLT'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'XLT';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL SRW VAN'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL SRW VAN';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL DIESEL'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
            tempChassis.Diesel__c = true;
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR EL CARGO'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Cargo';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL DRW VAN DIESEL'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL DRW';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Cargo';
            tempChassis.Diesel__c = true;
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 MR WAGON'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL DRW';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Wagon';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 150 LR 130WB XLT'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-150';
            tempChassis.Model_Ext__c = 'XLT';
            tempChassis.Roof_Option__c = 'Low';
            tempChassis.Wheelbase__c = '130';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL 3.5L'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
            tempChassis.Engine_Size__c = '3.5';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL 3.5L XLT'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL XLT';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
            tempChassis.Engine_Size__c = '3.5';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 350 HR 148WB EL DRW VAN'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL DRW';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        // Go-live additions
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('350 HR 148WB EL SRW VAn'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL SRW';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('350 HR 148WB VAn'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = 'Windowed Van';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('4X4'))
        {
            tempChassis.Make__c = 'Mercedes';
            tempChassis.Model__c = 'Sprinter';
            tempChassis.Model_Ext__c = '4X4';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('4X4'))
        {
            tempChassis.Make__c = 'Mercedes';
            tempChassis.Model__c = 'Sprinter';
            tempChassis.Model_Ext__c = '4X4';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('350 HR 148WB'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('350 HR 148WB Diesel'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
            tempChassis.Diesel__c = true;
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('350 HR 148WB EL Diesel'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
            tempChassis.Diesel__c = true;
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 150 MR Wagon'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-150';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '150';
            tempChassis.Frame__c = 'Wagon';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Transit 250 MR Cargo'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-250';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = 'Medium';
            tempChassis.Wheelbase__c = '150';
            tempChassis.Frame__c = 'Cargo';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Metris'))
        {
            tempChassis.Make__c = 'Mercedes';
            tempChassis.Model__c = 'Metris';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('350 HR 148WB EL'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'T-350';
            tempChassis.Model_Ext__c = 'EL';
            tempChassis.Roof_Option__c = 'High';
            tempChassis.Wheelbase__c = '148';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('4X4 Sprinter'))
        {
            tempChassis.Make__c = 'Mercedes';
            tempChassis.Model__c = 'Sprinter';
            tempChassis.Model_Ext__c = '4X4';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Smartliner'))
        {
            tempChassis.Make__c = 'Mercedes';
            tempChassis.Model__c = 'Smartliner';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('3500 Sprinter'))
        {
            tempChassis.Make__c = 'Mercedes';
            tempChassis.Model__c = 'Sprinter';
            tempChassis.Model_Ext__c = '3500';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Sprinter - prototype'))
        {
            tempChassis.Make__c = 'Mercedes';
            tempChassis.Model__c = 'Sprinter';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Grand caravan'))
        {
            tempChassis.Make__c = 'Dodge';
            tempChassis.Model__c = 'Caravan';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('Pacifica'))
        {
            tempChassis.Make__c = 'Chrysler';
            tempChassis.Model__c = 'Pacifica';
            tempChassis.Model_Ext__c = '';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = '';
        }
        else if(tempChassis.Model_Ext__c.equalsIgnoreCase('XL Wagon LWB'))
        {
            tempChassis.Make__c = 'Ford';
            tempChassis.Model__c = 'Transit Connect';
            tempChassis.Model_Ext__c = 'LWB';
            tempChassis.Roof_Option__c = '';
            tempChassis.Wheelbase__c = '';
            tempChassis.Frame__c = 'Wagon';
        }
    }
}

System.debug('Done');

update listOfChassis;
	}
}