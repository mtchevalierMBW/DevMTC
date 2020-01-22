/**
 * SObjectHistory_EXT
 * Tested by: SObjectHistory_EXT_TEST
 * Programmer: Bryan Leaman
 *
 * VisualForce sample: <apex:page ... extensions="...,SObjectHistory_EXT".../>
<apex:pageBlock render="{!sobject_api_name.Id!=null}">
<apex:pageBlockSection >
<apex:outputPanel >Proposal History</apex:outputPanel>
</apex:pageBlockSection>
<apex:pageBlockTable value="{!HistoryLines}" var="h">
   <apex:column value="{!h.whattime}">
     <apex:facet name="header">Date</apex:facet>
   </apex:column>
   <apex:column headerValue="User">
    <apex:outputLink value="/{!h.who.Id}">{!h.username}</apex:outputLink>
   </apex:column>
   <apex:column value="{!h.action}" headerValue="Action"/>
</apex:pageBlockTable>
</apex:pageBlock>
 */
public with sharing class SObjectHistory_EXT {

    public String objectLabel {get; private set;}
    public String objectName {get; private set;}
    public boolean historyAvailable {get; private set;}

    private ApexPages.StandardController stdController;
    private transient SObject sObj;
    private transient Schema.SObjectType objtype;
    private transient Schema.DescribeSObjectResult dsr;
    private transient Map<String,Schema.SObjectField> sfMap;
    private transient List<SObjectHistoryLine> objHistory = new List<SObjectHistoryLine>();

    // constructor
    public SObjectHistory_EXT(ApexPages.StandardController ctlr) {
        historyAvailable=false;
        stdController = ctlr;
        sObj = stdController.getRecord();
        objtype = sObj.getSObjectType();
        dsr = objtype.getDescribe();
        if (dsr!=null) {
            historyAvailable = sObj.Id!=null;
            objectLabel = dsr.getLabel();
            objectName = dsr.getName();
            sfMap = dsr.fields.getMap();
        }
    }

    // getHistoryLines
    public List<SobjectHistoryLine> getHistoryLines() {
        List<sObject> histories;
        if (dsr!=null) {
            String soql = 'select Id, ' + getParentIdName() + ', CreatedDate, CreatedById, Field, NewValue, OldValue '
                        + 'from ' + getHistoryName() + ' '
                        + 'where ' + getParentIdName() + ' = \'' + sObj.Id + '\' '
                        + 'order by CreatedDate desc, NewValue asc '
                        + 'limit 100 '; 
            histories = Database.query(soql);
            
            Set<Id> uids = new Set<Id>();
            for(sObject h : histories) {
                uids.add((Id) h.get('CreatedById'));
            }
            Map<Id,User> users = new Map<Id,User>([select Id, Name from User where Id in :uids]);
            for(sObject h : histories) {
                SObjectHistoryLine line = new SObjectHistoryLine(sfMap, h, users.get((Id) h.get('CreatedById')));
                if (line.action!=null) {
                    if (objHistory.size()>0) {
                        SObjectHistoryLine last = objHistory[objHistory.size()-1];
                        if (last.whattime==line.whattime && last.uid==line.uid) {
                            last.action += line.action;
                        } else {
                            objHistory.add(line);
                        }
                    } else {
                        objHistory.add(line);
                    }
                }
            }
        }
        return objHistory;
    }

    // getHistoryName
    public String getHistoryName() {
        if (dsr==null) {
            return null;
        }
        return (dsr.getName().endsWith('__c') ? (dsr.getName().removeEnd('__c') + '__') : dsr.getName()) 
             + 'History';
    }
    
    // getParentIdName (field name for parent id in history table)
    public String getParentIdName() {
        if (dsr==null) {
            return null;
        }
        return dsr.isCustom() ? 'ParentId' : dsr.getName()+'Id';  
    }
    

    // SObjectHistoryLine
    public class SObjectHistoryLine {
        public String whattime {get;set;}
        public User who {get;set;}
        public Id uid {get;set;}
        public String username {get;set;}
        public String fieldname {get;set;}
        public String fieldlabel {get;set;}
        public String fromvalue {get;set;}
        public String tovalue {get;set;}
        public String action {get;set;}
    
        // constructor
        public SObjectHistoryLine(Map<String,Schema.SObjectField> sfMap, SObject s, User u) {
            Datetime dt = (Datetime) s.get('CreatedDate');
            Id uid = (Id) s.get('CreatedById');
            whattime = dt.format('yyyy-MM-dd hh:mm:ss');
            who = u;
            username=u.Name;
            uid = u.Id;
            fieldname = (String) s.get('Field');
            boolean SkipField = false;
            Schema.DisplayType fieldtype = Schema.DisplayType.String;
            Integer fieldscale=null;
            if (fieldname!=null) {
                Schema.SObjectField f = sfMap.get(fieldname);
                if (f!=null) {
                    Schema.DescribeFieldResult frslt = f.getDescribe();
                    if (frslt!=null) {
                        fieldlabel = frslt.getLabel();
                        fieldtype = frslt.getType();
                        fieldscale = frslt.getScale();
                        if (frslt.isIdLookup() || fieldtype==Schema.DisplayType.REFERENCE) {
                            try {
                                Id testid1 = (Id) s.get('OldValue');
                                Id testid2 = (Id) s.get('NewValue');
                                SkipField = true;
                            } catch(Exception e) {}
                        }
                        System.debug(frslt);
                        System.debug(fieldtype);
                        System.debug(fieldscale);
                        System.debug(SkipField);
                    }
                } 
            }
            if (!SkipField) {
                try{
                    fromvalue = String.valueOf(s.get('OldValue'));
                    tovalue = String.valueOf(s.get('NewValue'));
                    if (fieldtype==Schema.DisplayType.Currency) {
                        Decimal fromdec = Decimal.valueOf(String.valueOf(s.get('OldValue')));
                        Decimal todec = Decimal.valueOf(String.valueOf(s.get('NewValue')));
                        if (fromdec!=null && fieldscale!=null) fromvalue = fromdec.setScale(fieldscale).format();
                        if (todec!=null && fieldscale!=null) tovalue = todec.setScale(fieldscale).format();
                    }
                } catch(Exception e) {}
                if (fromValue==null && toValue==null) {
                    action = fieldname.capitalize() + '. ';
                } else if (fromValue==null || fromValue=='') {
                    action = 'Changed ' + fieldlabel + ' to <b>' + tovalue + '</b>. ';
                } else {
                    action = 'Changed ' + fieldlabel + ' from <b>' + fromvalue + '</b> to <b>' + tovalue + '</b>. ';
                }
            }
        }
    }


}