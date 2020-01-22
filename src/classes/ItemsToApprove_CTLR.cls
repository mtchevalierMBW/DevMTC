/**
 * ItemsToApprove_CTLR
 * Tested by: ItemsToApprove_CTLR_TEST
 * 
 * Approve/Reject link: https://cs13.salesforce.com/p/process/ProcessInstanceWorkitemWizardStageManager?id=04iW0000000N1gs
 * Reassign link: https://cs13.salesforce.com/04iW0000000N1gs/e?et=REASSIGN&retURL=%2Fhome%2Fhome.jsp
 *
 *	2016-11-10	B. Leaman	BLL1 - Sort most recent to the top of the list.
 *	2017-03-08	B. Leaman	BLL2 - Handle queues with group membership.
 *	2018-05-21	B. Leaman	BLL3 - Show items I am a delegated approver for.
 *	2018-07-20	B. Leaman	BLL4 - Show last actor again - somehow I lost that in the update.
 */
public with sharing class ItemsToApprove_CTLR {

	public Integer MaxCustomFields {get;private set;}
	public List<String> columns {get;private set;}
	public boolean embed {get;private set;}
	public boolean includeDelegateFor {get;set;}	// BLL3a
	//public String linkTarget {get;private set;}

	// constructor
	//---------------------------
	public ItemsToApprove_CTLR() {
		columns  = new List<String>();
		MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
		if (mfs!=null && !String.isBlank(mfs.ApprovalColumnHeadings__c)) columns = mfs.ApprovalColumnHeadings__c.split(',');
		MaxCustomFields = columns.size();
		embed = false;	// BLL3a
		// BLL4
		if (ApexPages.currentPage()!=null) {
		// BLL4a end
			for(String k : ApexPages.currentPage().getParameters().keySet()) System.debug(k+'='+ApexPages.currentPage().getParameters().get(k));
			if (ApexPages.currentPage()!=null) embed = ApexPages.currentPage().getParameters().containsKey('inline') && ApexPages.currentPage().getParameters().get('inline')=='1';
		// BLL4
		}
		// BLL4 end
		//linkTarget = embed ? '_blank' : '_top'; 		
		includeDelegateFor = false;	// BLL3a
    }
 
 
 	// manageAll
	//----------------------------------------------------------
 	public PageReference manageAll() {
 		PageReference nextpage = Page.ItemsToApprovePage;
 		nextpage.setRedirect(true);
 		return nextpage;
 	}


	// noaction
	//----------------------------------------------------------
	public void noAction() {}


	// getWorkItemsForUser
	//----------------------------------------------------------
 	public List<ProcessInstanceWorkItem> getWorkItemsForUser(Id uid) {
		List<Id> userAndGroups = new List<Id>();	// BLL2a
		userAndGroups.add(uid);	// BLL2a
		//Map<Id,Group> usergroups = Utility.MemberOfGroups(uid);	// BLL2a
		//BLL3d Map<Id,Group> usergroups = Utility.MemberOfGroupHierarchy(uid);	// BLL2a
		Set<Id> uids = new Set<Id>{uid};	// BLL3a
		if (includeDelegateFor) userAndGroups.addAll(Utility.getUserIdsDelegateFor(new Set<Id>{uid}));	// BLL3a include delegate for user ids
		Map<Id,Group> usergroups = Utility.MembersOfGroupsHierarchy(uids);	// BLL3a

		userAndGroups.addAll(usergroups.keySet());	// BLL2a
		return [
			select Id, ProcessInstanceId, OriginalActorId, OriginalActor.Name, ActorId, Actor.Name, CreatedDate, CreatedById, CreatedBy.Name
			from ProcessInstanceWorkItem
			where ActorId in :userAndGroups // BLL2c ActorId=:uid
	   		and (ProcessInstance.Status not in ('Approved', 'Rejected', 'Removed'))
	   		order by CreatedDate desc	// BLL1a
		];
 	}
 	 

	// getProcessInstanceMap
	//----------------------------------------------------------
	public Map<Id,ProcessInstance> getProcessInstanceMap(Set<Id> piids) {
		return new Map<Id,ProcessInstance>([
		    Select Id, TargetObjectId, Status, CreatedDate, LastActorId, LastActor.Name, LastModifiedDate,
		    	LastModifiedById, LastModifiedBy.Name, SubmittedById, SubmittedBy.Name,  
				(Select Id, ProcessInstanceId, StepStatus, OriginalActorId, ActorId, Comments, StepNodeId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, CreatedDate, CreatedById, SystemModstamp From Steps) 
		    From ProcessInstance 
		    Where Id in :piids
		    order by LastModifiedDate desc 
		]);
	}


	// getApprovalFieldSetsByObjectType
	//----------------------------------------------------------
	public Map<Schema.SObjectType, List<Schema.FieldSetMember>> getApprovalFieldSetsByObjectType(Set<Schema.SObjectType> objtypes) {
		Map<Schema.SObjectType, List<Schema.FieldSetMember>> objfsmap = new Map<Schema.SObjectType, List<Schema.FieldSetMember>>();

		for(Schema.SObjectType ot : objtypes) {
		    Schema.DescribeSObjectResult dsr = ot.getDescribe();
		    Map<String, Schema.FieldSet> FsMap = dsr.fieldSets.getMap();
		    //System.debug(FsMap);
		    Schema.FieldSet fs = FsMap.get('ApprovalInformation');
		    if (fs!=null) {
		        //System.debug(fs.getFields());
		        objfsmap.put(ot, fs.getFields());
		    }
		}

		return objfsmap;
	}
	

	// getApprovalFieldSets
	//----------------------------------------------------------
	public Map<Schema.SObjectTYpe, List<String>> getApprovalFieldSets(Set<Schema.SObjectType> objtypes) {
		Map<Schema.SObjectType, List<Schema.FieldSetMember>> objfsmap = getApprovalFieldSetsByObjectType(objtypes);
		Map<Schema.SObjectTYpe, List<String>> fieldpathmap = new Map<Schema.SObjectTYpe, List<String>>();
		for(Schema.SObjectType sot : objtypes) {
		    List<Schema.FieldSetMember> fsmbrs = objfsmap.get(sot);
		    if (fsmbrs==null) fsmbrs = new List<Schema.FieldSetMember>(); 
		    List<String> fieldpaths = new List<String>();
		    for(Schema.FieldSetMember fsm : fsmbrs) {
		    	fieldpaths.add(fsm.getFieldPath());
		    }
		    fieldpathmap.put(sot,fieldpaths);
			// Keep track of maximum number of custom fields so VF page can know the number of columns needed
		    if (fieldpaths.size()>MaxCustomFields) MaxCustomFields = fieldpaths.size();
		}	
		return fieldpathmap;
	}


	// getItemsToApprove
	//----------------------------------------------------------
 	public List<ApprovalItem> getApprovalItems() {
		List<ApprovalItem> rtnApprovalItems = new List<ApprovalItem>();
		
 		// Get all items to approve for the current user
 		List<ProcessInstanceWorkItem> workItems = getWorkItemsForUser(UserInfo.getUserId());
 		// Map process instance to this user's work item
 		Map<Id, ProcessInstanceWorkItem> piWorkItems = new Map<Id, ProcessInstanceWorkItem>();	// BLL3c SObject instead of just id
 		for(ProcessInstanceWorkItem wi : workItems)	{ 
 			if (!piWorkItems.containsKey(wi.ProcessInstanceId))
 				piWorkItems.put(wi.ProcessInstanceId, wi);	// BLL3c wi instead of wi.id
 		}
 		
 		// Set of unique processinstances
		Set<Id> pids = new Set<Id>();
		for(ProcessInstanceWorkItem w : workitems) pids.add(w.ProcessInstanceId);
 		Map<Id,ProcessInstance> pinstancemap = getProcessInstanceMap(pids);
 		
		Map<Schema.SObjectType, List<Id>> idsbyobj = new Map<Schema.SObjectType, List<Id>>();
		for (ProcessInstance pi : pinstancemap.values()) {
		    Schema.SObjectType objtype = pi.TargetObjectId.getSObjectType();
		    //System.debug(objtype);
		    List<Id> l = idsbyobj.get(objtype);
		    if (l==null) {
		        l = new List<Id>();
		    }
		    l.add(pi.TargetObjectId);
		    idsbyobj.put(objtype, l);
		} 

		// Get list of fields in object-specific fieldsets for each object type in approval list
		Map<Schema.SObjectTYpe, List<String>> fieldpathmap = getApprovalFieldSets(idsbyobj.keySet());

		// Previous step determines largest number of custom fields on any object in the list
		// Make sure we have enough column headings
		for(Integer i=columns.size(); i<MaxCustomFields; i++) columns.add('');
		
		// Build query for each object type & get all referenced SObjects
		Map<Id, SObject> objmap = new Map<Id, SObject>();
		for(Schema.SObjectType sot : idsbyobj.keySet()) {
		    List<Id> objlist = idsbyobj.get(sot);
		    String idlist = '';
		    String junction = '';
		    for (Id i : idsbyobj.get(sot)) {
		         idlist += junction + '\'' + i + '\'';
		         junction = ',';
		    }
			List<String> fieldpaths = fieldpathmap.get(sot);
		    String qry = 'select Id, Name '
		    	+ (fieldpaths.size()>0 ? ', ' : '') + String.join(fieldpaths, ',')
		    	+ ' from ' + sot + ' where Id in (' + idlist + ') ';
		    Map<Id, SObject> omap = new Map<Id, SObject>(Database.query(qry));
		    objmap.putAll(omap);
		}
		
		// Start dumping out pending approvals with additional info
		for (ProcessInstance pi : pinstancemap.values()) {
			List<ProcessInstanceStep> steps = pi.Steps;
			String outstring = '';
    		Schema.SObjectType objtype = pi.TargetObjectId.getSObjectType();
    		List<String> fieldpaths = fieldpathmap.get(objtype);
    		SObject obj = objmap.get(pi.TargetObjectId);
			//outstring = pi.Status + ':'  + steps[0].StepStatus 
			//	+ ':' + pi.TargetObjectId + ':' + obj.get('Name') + ':' + objtype + ':' 
			//	+ ':' + pi.LastActor.Name + ':' + pi.LastModifiedDate;
			List<String> customfields = new List<String>();
    		for(String fp : fieldpaths) {
    			List<String> fieldparts = fp.split('\\.');
    			SObject f = obj;
    			for(Integer i = 0; i<fieldparts.size()-1; ++i) {
					String fn = fieldparts[i];
    				f = f!=null ? f.getSObject(fn) : null;	
    			}
				//outstring += ':' + (String) (f!=null ? f.get(fieldparts[fieldparts.size()-1]) : 'null');
				Object v = f!=null ? f.get(fieldparts[fieldparts.size()-1]) : null;
				if (v==null) {
					customfields.add('');
				} else if (v!=null && (v instanceof Date)) {
					customfields.add(((Date) v).format());
				} else if (v instanceof DateTime) {
					customfields.add(((DateTime) v).format());
				} else {
					customfields.add(String.valueOf(v));
				}
    		}
    		System.debug(customfields);
			//System.debug(outstring);
 			for(Integer i=customfields.size(); i<MaxCustomFields; i++) customfields.add('');
			rtnApprovalItems.add(new ApprovalItem(piWorkItems.get(pi.Id), pi.TargetObjectId, (String) obj.get('Name'), objtype,
					pi.LastModifiedById, pi.LastModifiedBy.Name, pi.LastModifiedDate, customfields));
			System.debug(pi);
			System.debug(pi.LastActorId);
			System.debug(pi.LastActor.Name);
			System.debug(pi.LastModifiedById);
			System.debug(pi.LastModifiedBy.Name);
		} 

		return rtnApprovalItems;		
 	}


	// ApprovalItem
	//=============================================
 	public class ApprovalItem {
 		@AuraEnabled public Id WorkId {get;set;}
 		@AuraEnabled public Id ItemId {get;set;}
 		@AuraEnabled public String ItemName {get;set;}
 		@AuraEnabled public Id ActorId {get;set;}
 		@AuraEnabled public String ActorName {get;set;}
 		public Schema.SObjectType ItemType {get;set;}
 		@AuraEnabled public String ItemLabel {get;set;}
 		@AuraEnabled public DateTime ItemDateTime {get;set;}
 		@AuraEnabled public List<String> ItemCustomFields {get;set;}
 		@AuraEnabled public Id LastActorId {get;set;}
 		@AuraEnabled public String LastActorName {get;set;}
		// bllx
		@AuraEnabled public String DocumentLink {get;set;}
		@AuraEnabled public String LastActorLink {get;set;}
		@AuraEnabled public String ApproverLink {get;set;}
		// bllx end
 		public ApprovalItem(ProcessInstanceWorkItem wi, Id iId, String iName, Schema.SObjectType iType, Id ilastactorid, String ilastactorname, DateTime iDateTime, List<String> iCustomFields) {
			System.debug(wi);
 			System.debug(wi.ActorId);
 			System.debug(wi.Actor.Name);
			//WorkId = wId;
			WorkId = wi.Id;
			ActorId = wi.ActorId;
			ActorName = wi.Actor.Name;
 			ItemId = iId;
 			ItemName = iName;
 			ItemType = iType;
 			ItemLabel = ItemType.getDescribe().getLabel();
 			ItemDateTime = iDateTime;
 			LastActorId = ilastactorid;
 			LastActorName = ilastactorname;
 			ItemCustomFields = iCustomFields;
			// bllx
			//DocumentLink = '/' + wi.ItemId;
			//if (UserInfo.getUiThemeDisplayed().startsWith('Theme4'))
				DocumentLink = new ApexPages.StandardController(ItemType.newSObject(ItemId)).view().getUrl();
				LastActorLink = '';
				if (String.valueOf(LastActorId).startsWith('005'))
					LastActorLink = new ApexPages.StandardController(new User(Id=LastActorId)).view().getUrl();
				ApproverLink = '';
				if (String.valueOf(ActorId).startsWith('005'))
					ApproverLink = new ApexPages.StandardController(new User(Id=ActorId)).view().getUrl();
			// bllx end
 		}
 	}   

	@AuraEnabled
	public static List<String> getColumnLabels(){
		List<String> columns  = new List<String>();
		MobilityForceSettings__c mfs = MobilityForceSettings__c.getOrgDefaults();
		if (mfs!=null && !String.isBlank(mfs.ApprovalColumnHeadings__c)) columns = mfs.ApprovalColumnHeadings__c.split(',');
		return columns;
	}

	@AuraEnabled
	public static List<ApprovalItem> getListOfItems(boolean includeDelegated){
		ItemsToApprove_CTLR ita = new ItemsToApprove_CTLR();
		ita.includeDelegateFor = includeDelegated;
		return ita.getApprovalItems();
	}

}