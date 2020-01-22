/**
 * WMK, LLC (c) - 2018 
 *
 * ContentObjectFieldTriggerHandler 
 * 
 * Created By:   Alexander Miller
 * Created Date: 11/8/2018 
 * Tested By:    ContentObjectFieldTriggerHandlerTest
 * Work Item:    W-000421
 *
 * Modified By         Alias       Work Item       Date     Reason
 * -----------------------------------------------------------------
 *
 */
public class ContentObjectFieldTriggerHandler {

    public Map<String, String> mapOfObjectNamesToAPIs {get;set;}

    public ContentObjectFieldTriggerHandler()
    {
        mapOfObjectNamesToAPIs = new Map<String, String>();

        mapOfObjectNamesToAPIs = getMapOfObjectNameToAPIs();
    }

    /**
    * getObjectAPINameIfNeeded
    *
    * Function which looks at the system setup
    * for the API name of the Object given.
    *
    * For example, a Proposal's API name would be "Deal__c" or Account API name would be "Account"
    */
    public void getObjectAPINameIfNeeded(List<Content_Object_Field__c> tempList)
    {
        for(Content_Object_Field__c tempObjField : tempList)
        {   
            if( (tempObjField.Object_Name_API__c == null || tempObjField.Object_Name_API__c == '') && 
                tempObjField.Object_Name__c != null &&
                mapOfObjectNamesToAPIs.get(tempObjField.Object_Name__c) != null)
            {
                tempObjField.Object_Name_API__c = mapOfObjectNamesToAPIs.get(tempObjField.Object_Name__c);
            }
            else if((tempObjField.Object_Name_API__c == null || tempObjField.Object_Name_API__c == '') && 
                tempObjField.Object_Name__c != null &&
                mapOfObjectNamesToAPIs.get(tempObjField.Object_Name__c) == null)
            {
                tempObjField.addError('Could not find the API name for ' + tempObjField.Object_Name__c + '. Please check the spelling and report this to IT if you believe this is an issue.' );
            }
        }
    }

    /**
    * getMapOfObjectNameToAPIs
    *
    * Function which maps the system
    * names to API names. It looks at the 
    * Content Learning Objects custom setting
    * for all Enabled items
    */
    public Map<String, String> getMapOfObjectNameToAPIs()
    {
        Map<String, String> returningMap = new Map<String, String>();
        
        Content_Learning_Objects__c tempCustomSetting = Content_Learning_Objects__c.getInstance();

        List<Content_Learning_Objects__c> listOfObjects = Content_Learning_Objects__c.getAll().values();

        for(Content_Learning_Objects__c tempItem : listOfObjects)
        {
            if(tempItem.Enabled__c && returningMap.get(tempItem.Name) == null)
            {
                returningMap.put(tempItem.Name, tempItem.API_Name__c);
            }
        }

        return returningMap;
    }

    /**
    * getObjectFieldAPINameIfNeeded
    *
    * Function which looks at the system setup
    * for the API name of the Object's field given.
    *
    * For example, a status field would be "Status__c"
    */
    public void getObjectFieldAPINameIfNeeded(List<Content_Object_Field__c> tempList)
    {
        for(Content_Object_Field__c tempObjField : tempList)
        {   
            if( (tempObjField.Object_Field_Name_API__c == null || tempObjField.Object_Field_Name_API__c == '') &&
                tempObjField.Object_Name__c != null &&
                tempObjField.Object_Field_Name__c != null && 
                mapOfObjectNamesToAPIs.get(tempObjField.Object_Name__c) != null)
            {
                String objectName = mapOfObjectNamesToAPIs.get(tempObjField.Object_Name__c);

                System.debug(objectName);

                SObjectType accountType = Schema.getGlobalDescribe().get(objectName);
                Map<String,Schema.SObjectField> mfields = accountType.getDescribe().fields.getMap();

                System.debug(mfields);

                Boolean found = false;
                
                for(String tempField : mfields.keySet())
                {
                    if(mfields.get(tempField).getDescribe().getLabel().equalsIgnoreCase(tempObjField.Object_Field_Name__c))
                    {
                        tempObjField.Object_Field_Name_API__c = mfields.get(tempField).getDescribe().getName();
                        found = true;
                        break;
                    }
                }

                if(!found)
                {
                    tempObjField.addError('Could not find the API name for ' + tempObjField.Object_Field_Name__c + '. Please check the spelling and report this to IT if you believe this is an issue.' );
                }
            }
            else if( (tempObjField.Object_Field_Name_API__c == null || tempObjField.Object_Field_Name_API__c == '') &&
                tempObjField.Object_Name__c != null &&
                tempObjField.Object_Field_Name__c != null && 
                mapOfObjectNamesToAPIs.get(tempObjField.Object_Name__c) == null)
            {
                tempObjField.addError('Could not find the API name for ' + tempObjField.Object_Name__c + '. Please check the spelling and report this to IT if you believe this is an issue.' );
            }
        }
    }

    /**
    * flagIfIdenticalContentObjectFieldExists
    *
    * Function which flags the trigger context if the 
    * record is identical to another record in the system
    * in the following way:
    *
    * - Id
    * - Name
    * - Content
    * - Object Field Name
    * - Object Name
    */
    public void flagIfIdenticalContentObjectFieldExists(List<Content_Object_Field__c> tempList)
    {
        List<Content_Object_Field__c> listOfCurrentTags = new List<Content_Object_Field__c>([SELECT Id,
                                                                                                Name,
                                                                                                Content__c,
                                                                                                Object_Field_Name__c,
                                                                                                Object_Name__c
                                                                                            FROM Content_Object_Field__c]);

        for(Content_Object_Field__c tempTag : tempList)
        {
            for(Content_Object_Field__c currentTag : listOfCurrentTags)
            {
                if((tempTag.Id == null || currentTag.Id != tempTag.Id) &&
                    (tempTag.Name == currentTag.Name) &&
                    (tempTag.Content__c == currentTag.Content__c) && 
                    (tempTag.Object_Field_Name__c == currentTag.Object_Field_Name__c) &&
                    (tempTag.Object_Name__c == currentTag.Object_Name__c))
                {
                    tempTag.addError('This Content Object Field is identical to another one: ' + tempTag.Id + ' Name: ' + tempTag.Name + ' and is therefore not allowed.');
                }
            }
        } 
    }
}