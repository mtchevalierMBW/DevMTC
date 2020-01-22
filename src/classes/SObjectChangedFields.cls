/**
 * SObjectChangedFields
 * Tested by: SObjectChangedFields_TEST
 * Tools to help determine which fields changed within a trigger.
 */
public class SObjectChangedFields {

    // Return list of fields that differ between two SObjects (of the same type)
    public static Set<String> getChangedFieldList(SObject oldobj, SObject newobj) {
    	Set<String> fieldnames = new Set<String>();
    	
    	if (oldobj.getSObjectType()!=newobj.getSObjectType()) {
    		throw new SObjectChangedFieldsException('Object types are not identical');
    	}
    	DescribeSObjectResult dsr = newobj.getSObjectType().getDescribe();
    	Map<String, Schema.SObjectField> fldmap = dsr.fields.getMap();
    	
    	// loop through fields & check for differences
    	for(String k : fldmap.keySet()) {
    		Schema.DescribeFieldResult dfr = fldmap.get(k).getDescribe();
    		//System.debug(k);
    		//System.debug(dfr);
    		if (dfr.isUpdateable()) {
    			// option instead of try/catch using JSON, but may be slower?:
    			// Map<String, Object> omap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
    			// if omap.containsKey(fieldname) { ... } 
                try {
    			    if (String.valueOf(oldobj.get(k))!=String.valueOf(newobj.get(k))) {
    				    fieldnames.add(k);
    			    }
                } catch(Exception e) {}  // ignore errors
    		}
    	}
    	System.debug(fieldnames);
    	return fieldnames;
    } 

    // Determine if all changed fields are allowed to be changed
    public static boolean OnlyAllowedFieldsChanged(SObject oldobj, SObject newobj, Set<String> allowedflds) {
    	Set<String> chgd = SObjectChangedFields.getChangedFieldList(oldobj, newobj);
    	System.debug('OnlyAllowedFieldsChanged');
    	System.debug(chgd);
    	return allowedflds.containsAll(chgd);
    }
    

    // Return list of fields that differ between two SObjects (of a particular data type or types)
    // Schema.DisplayType.Currency, Schema.DisplayType.Double, Schema.DisplayType.Percent, etc.
    public static Set<String> getFieldSetByType(SObject oldobj, SObject newobj, Set<Schema.DisplayType> datatypes) {
    	Set<String> fieldnames = new Set<String>();
    	
    	if (oldobj.getSObjectType()!=newobj.getSObjectType()) {
    		throw new SObjectChangedFieldsException('Object types are not identical');
    	}
    	DescribeSObjectResult dsr = newobj.getSObjectType().getDescribe();
    	Map<String, Schema.SObjectField> fldmap = dsr.fields.getMap();
    	
    	// loop through fields & check for differences
    	for(String k : fldmap.keySet()) {
    		Schema.DescribeFieldResult dfr = fldmap.get(k).getDescribe();
    		//System.debug(k);
    		//System.debug(dfr);
    		Schema.DisplayType datatype = dfr.getType();
    		if (dfr.isUpdateable() && datatypes.contains(datatype)) {
    			// option instead of try/catch using JSON, but may be slower?:
    			// Map<String, Object> omap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj));
    			// if omap.containsKey(fieldname) { ... } 
                try {
    			    if (String.valueOf(oldobj.get(k))!=String.valueOf(newobj.get(k))) {
    				    fieldnames.add(k);
    			    }
                } catch(Exception e) {}  // ignore errors
    		}
    	}
    	System.debug(fieldnames);
    	return fieldnames;
    } 

    // Determine if any changed fields are disallowed to be changed
    public static boolean NoDisallowedFieldsChanged(SObject oldobj, SObject newobj, Set<String> disallowedflds) {
    	boolean rtn=true;
    	Set<String> chgd = SObjectChangedFields.getChangedFieldList(oldobj, newobj);
    	System.debug('NoDisallowedFieldsChanged');
    	System.debug(chgd);
    	for(String s : chgd) {
    		rtn = rtn && !disallowedflds.contains(s);
    	}
    	return rtn;
    }

    public class SObjectChangedFieldsException extends Exception {}
 
}