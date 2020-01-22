/**
 * Utility
 * Tested by: Utilities_TEST
 * Date: Nov 3, 2016
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2018-05-22	86%	(101/116) 
 *	2019-02-11	86%	(111/128)
 *	2019-12-12	85%	(158/185)
 *
 *	2018-05-21	B. Leaman	BLL2 - get list of users one is a delegate for.
 *  2018-10-18	B. Leaman	W-000461 BLL3	Reduce SOQL query count.
 *	2019-02-11	B. Leaman	W-000588 BLL4 - Update user role in future to get around lightning limitation.
 *	2019-03-11	B. Leaman	W-000579 BLL5 - routine to create sobject from json field map.
 *	2019-12-12	B. Leaman	W-000788 BLL6 - ability to delete SObjects in the future too.
 */
public class Utility {

	static Map<String,Set<String>> customAuthMap;
	static Map<Id,Map<Id,Group>> groupMember;
// BLL3
	private static Map<String, Set<String>> cacheGroupMbrUserEmails = new Map<String, Set<String>>();
// BLL3 end

    // Format phone numbers (USA)
	//-----------------------------------------
    public static String formatPhoneNbr(String phone) {
        String formatted = phone.replaceAll('\\D','');
        // Remove long distance indicator (1 + area + phone) to area + phone
        if (formatted.length()==11 && formatted.substring(0,1)=='1') {
            formatted = formatted.substring(1);
        }
        // Format standard US phone
        if (formatted.length()==10) {
            formatted = '(' + formatted.substring(0,3) + ') '
                      + formatted.substring(3, 6) + '-'
                      + formatted.substring(6);
        } else {  
            // don't reformat!
            formatted = phone;
        }
        return formatted;
    }

	// friendlyErrorMessage
	//-----------------------------------------
	public static String friendlyErrorMessage(Exception e) {
		String msg = e.getMessage();	
        List<String> msgs = msg.split('first error:');	
        msg = msgs[msgs.size()-1];	
        msgs = msg.split(':');
        msg = msgs[0];	
        if (msg!=null) msg=msg.replaceAll('\n','<br/>'); 
        return msg;
	}


	// IsAuthorizedCustom
	//-----------------------------------------
	public static boolean hasCustomPermission(String customPermission) {
		return Utility.hasCustomPermission(customPermission, null);
	}
	public static boolean hasCustomPermission(String customPermission, String namespace) {
		String ns = 'c';	// Treat no namespace as "c" for custom
		if (namespace!=null) ns = namespace;
		Set<String> permissions = new Set<String>();

		// If static stored values haven't been created yet, create them now
		if (customAuthMap==null) customAuthMap = new Map<String,Set<String>>();
		
		// If we haven't retrieved custom permissions for this namespace yet, get them all now
		if (!customAuthMap.containsKey(ns)) {
			// get custom permissions for the namespace
			Map<Id,CustomPermission> customPermissionMap = new Map<Id,CustomPermission>([
    			SELECT Id, MasterLabel, DeveloperName, Description, NamespacePrefix
       			FROM CustomPermission
       			WHERE NamespacePrefix = :namespace 
			]);
			// get custom permissions in the namespace that the current user has been granted
			List<SetupEntityAccess> setupEntities = [
    			SELECT Id, SetupEntityId, ParentId, SetupEntityType
       			FROM SetupEntityAccess
       			WHERE SetupEntityType='CustomPermission'
       			  and SetupEntityId in :customPermissionMap.keySet() AND
             			ParentId IN (
             				SELECT PermissionSetId
                			FROM PermissionSetAssignment
                			WHERE AssigneeId = :UserInfo.getUserId()
                		)
			];
			// Create the set of current user's assigned permissions and store for the namespace
			for(SetupEntityAccess sea : setupEntities) {
				permissions.add(customPermissionMap.get(sea.SetupEntityId).DeveloperName);
				permissions.add(customPermissionMap.get(sea.SetupEntityId).MasterLabel);
			}
			customAuthMap.put(ns, permissions);
		}
		permissions = customAuthMap.get(ns);
		return permissions.contains(customPermission);
	}


	// MemberOfGroupHierarchy
	//--------------------------------------------------
	public static Map<Id,Group> MemberOfGroupHierarchy(Id ugid) {
		return MembersOfGroupsHierarchy(new Set<Id>{ugid});
		/*
		Set<Id> ugids = new Set<Id>();
		ugids.add(ugid);
		Integer nbriterations = 0;
		List<GroupMember> gms = new List<GroupMember>();
		do {
			nbriterations++;
			gms = [select Id, GroupId, UserOrGroupId from GroupMember where UserOrGroupId in :ugids and (Id not in :ugids)];
        	for(GroupMember gm : gms) ugids.add(gm.GroupId);
		} while(gms.size()>0 && nbriterations<10);

		Map<Id,Group> groupsMap = new Map<Id,Group>([select Id, Name, Type from Group where Id in :ugids]);

		return groupsMap;
		*/
	}


	// MembersOfGroupsHierarchy
	//--------------------------------------------------
	public static Map<Id,Group> MembersOfGroupsHierarchy(Set<Id> ugids_p) {
		Set<Id> ugids = new Set<Id>();
		ugids.addAll(ugids_p);
		Integer nbriterations = 0;
		List<GroupMember> gms = new List<GroupMember>();
		do {
			nbriterations++;
			gms = [select Id, GroupId, UserOrGroupId from GroupMember where UserOrGroupId in :ugids and (Id not in :ugids)];
        	for(GroupMember gm : gms) ugids.add(gm.GroupId);
		} while(gms.size()>0 && nbriterations<10);

		Map<Id,Group> groupsMap = new Map<Id,Group>([select Id, Name, Type from Group where Id in :ugids]);

		return groupsMap;
	}

	// MemberOfGroups
	//--------------------------------------------------
	public static Map<Id,Group> MemberOfGroups(Id uid) {
		if (groupMember==null) groupMember = new Map<Id,Map<Id,Group>>();
		if (!groupMember.containsKey(uid)) {
			Set<Id> groupids = new Set<Id>();
			for(GroupMember gm : [select Id, GroupId, UserOrGroupId from GroupMember where UserOrGroupId=:uid]) groupids.add(gm.GroupId);
			Map<Id,Group> gmap = new Map<Id,Group>([select Id, Name, Type from Group where Id in :groupids]);
			groupMember.put(uid,gmap);
		}
		return groupMember.get(uid);
	}
	

	// WaitingOnMyApproval  
	//---------------------------------------------------
	public static boolean WaitingOnMyApproval(Id docId, Set<String> nodes) {
		return Utility.WaitingOnUserApproval(UserInfo.getUserId(), docId, nodes);
	}
	
	// WaitingOnUserApproval  
	//---------------------------------------------------
	public static boolean WaitingOnUserApproval(Id uid, Id docId, Set<String> nodes) {
		boolean rtnOk = false;

		// build set of Ids (1 level for now) that correspond to this user (user or groups user is a member of)
		Set<Id> ugIds = new Set<Id>();
		//Map<Id,Group> usergroupmap = Utility.MemberOfGroups(uid);
		Map<Id,Group> usergroupmap = Utility.MemberOfGroupHierarchy(uid);
		ugIds.add(uid);
		for(Group g : usergroupmap.values()) ugIds.add(g.Id);		
		
		// Pending approvals
		List<ProcessInstance> pilist = [
			Select TargetObjectId, Status, ProcessDefinitionId, Id, 
				(Select Id, ProcessInstanceId, OriginalActorId, ActorId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, IsDeleted, CreatedDate, CreatedById, SystemModstamp From Workitems where ActorId in :ugIds ), 
				(Select Id, ProcessInstanceId, StepStatus, OriginalActorId, ActorId, Comments, StepNodeId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, CreatedDate, CreatedById, SystemModstamp From Steps ), 
				(Select Id, IsDeleted, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ProcessInstanceId, ProcessNodeId, NodeStatus, CompletedDate, LastActorId, ProcessNodeName, ProcessNode.DeveloperName, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes From Nodes Where NodeStatus='Pending' ) 
			From ProcessInstance 
			Where Status='Pending' and TargetObjectId = :docId 
		];
		if (pilist.size()>0 && pilist[0].WorkItems.size()>0) {
			if (nodes==null || nodes.size()==0 
				|| nodes.contains(pilist[0].Nodes[0].ProcessNodeName) || nodes.contains(pilist[0].Nodes[0].ProcessNode.DeveloperName)) {
				// Submit the request for approval
				rtnOk = true;
			} 
		} 
		
		return rtnOk;
	}


	// ProcessApprovalStep - approve/reject current step 
	//---------------------------------------------------
	public static boolean ProcessApprovalStep(Id docId, String action, Set<String> nodes, String comment) {
		boolean rtnOk = false;
		// Pending approvals
		List<ProcessInstance> pilist = [
			Select TargetObjectId, Status, ProcessDefinitionId, Id, 
				(Select Id, ProcessInstanceId, OriginalActorId, ActorId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, IsDeleted, CreatedDate, CreatedById, SystemModstamp From Workitems), 
				(Select Id, ProcessInstanceId, StepStatus, OriginalActorId, ActorId, Comments, StepNodeId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, CreatedDate, CreatedById, SystemModstamp From Steps), 
				(Select Id, IsDeleted, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, ProcessInstanceId, ProcessNodeId, NodeStatus, CompletedDate, LastActorId, ProcessNodeName, ProcessNode.DeveloperName, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes From Nodes Where NodeStatus='Pending') 
			From ProcessInstance 
			Where Status='Pending' and TargetObjectId = :docId
		];
		if (pilist.size()>0 && pilist[0].WorkItems.size()>0) {
			Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
			req.setComments(comment);
			req.setAction(action);
			Id uid = UserInfo.getUserId();
			req.setNextApproverIds(new Id[] {uid});

			// Find matching work item (if there is one that matches the current user, else default to 0)
			Integer wi = 0;
			for(Integer i=0; i<pilist[0].WorkItems.size(); ++i) {
				if (pilist[0].WorkItems[i].ActorId==uid) wi = i;
			}
			
			// Use the ID from the newly created item to specify the item to be worked
			req.setWorkitemId(pilist[0].WorkItems[wi].Id);
			
			if (nodes==null || nodes.size()==0 
				|| nodes.contains(pilist[0].Nodes[0].ProcessNodeName) || nodes.contains(pilist[0].Nodes[0].ProcessNode.DeveloperName)) {
				// Submit the request for approval
				Approval.ProcessResult result =  Approval.process(req);
				rtnOk = result.isSuccess();
				if (result.isSuccess()) System.debug('Automatic approve/reject succeeded');
				else System.debug('Automatic approve/reject failed: ' + JSON.serialize(result));
			} else System.debug('No matching node - did not process');
		} else System.debug('No pending approval for document: ' + docId);
		
		return rtnOk;
	}


	// BLL1a group & email routines
	// getGroupMembers - Return list of email addresses for all public group members
	public static Set<Id> getGroupMembers(Set<Id> groupids) {
		Set<Id> mbrIds = new Set<Id>();
		Set<Id> grpIds = new Set<Id>();

		for(GroupMember gm : [select Id, userOrGroupId from GroupMember where GroupId in :groupids]) 
			if (Schema.Group.SObjectType == gm.userOrGroupId.getSObjectType())
				grpIds.add(gm.userOrGroupId);
			else mbrIds.add(gm.userOrGroupId);

        // does not handle roles or roles and subordinates
        if (grpIds.size()>0) mbrIds.addAll(Utility.getGroupMembers(grpIds));
        
		return mbrIds;		
	}

	// getGroupMbrUserIds 
	public static Set<Id> getGroupMbrUserIds(String groupname) {
		List<Group> grp = [select Id, Name, DeveloperName from Group where Name=:groupname or DeveloperName=:groupname];
		Id grpId = grp.size()>0 ? grp[0].Id : null;
		Set<Id> mbrset = new Set<Id>();
		if (grp.size()>0) mbrset = Utility.getGroupMembers(new Set<Id>{grpId});
		return mbrset;
	}

	// getGroupMbrUserEmails     
    public static Set<String> getGroupMbrUserEmails(String groupname) {
		// BLL3
    	//Set<String> emailset = new Set<String>();
		Set<String> emailset = cacheGroupMbrUserEmails.get(groupname);
		if (emailset==null) {
			emailset = new Set<String>();
		// BLL3 end
    		Set<Id> userIds = Utility.getGroupMbrUserIds(groupname);   
        	for(User u : [Select email FROM user WHERE id IN :userIds]) emailset.add(u.email);
		// BLL3
			cacheGroupMbrUserEmails.put(groupname, emailset);
		}
		// BLL3 end
		return emailset;
	}
	// BLL1a end


	// BLL2a
	// getUsersDelegatedFor(Id uid)
	public static Set<Id> getUserIdsDelegateFor(Set<Id> uids) {
		Set<Id> rtnIds = new Set<Id>();
		for(User u : [select Id, DelegatedApproverId from User where DelegatedApproverId in :uids]) rtnIds.add(u.Id);
		return rtnIds;
	}
	// BLL2a end

	// BLL4
	@future public static void updateSObjectFuture(String jsonstring) {
		System.debug('updateSObjectFuture: '+jsonstring);
		SObject obj = (SObject) JSON.deserialize(jsonstring, SObject.class);
		update(obj);
	}
	@future public static void updateSObjectsFuture(String jsonstring) {
		System.debug('updateSObjectsFuture: '+jsonstring);
		List<SObject> objs = (List<SObject>) JSON.deserialize(jsonstring, List<SObject>.class);
		update(objs);
	}
	// BLL4 end
	// BLLx
	@future public static void deleteSObjectFuture(String jsonstring) {
		System.debug('updateSObjectFuture: '+jsonstring);
		SObject obj = (SObject) JSON.deserialize(jsonstring, SObject.class);
		delete(obj);
	}
	@future public static void deleteSObjectsFuture(String jsonstring) {
		System.debug('updateSObjectsFuture: '+jsonstring);
		List<SObject> objs = (List<SObject>) JSON.deserialize(jsonstring, List<SObject>.class);
		delete(objs);
	}
	// BLLx

	// BLL5
	/* jsonStringToSobject()
	   Take a json string of fields and values and the type of object they apply to 
	   and create an SObject with those values. This is designed to work off of the
	   force:recordData "fields" parameter after converting to JSON format.
	*/
	public static SObject jsonStringToSObject(String jstr, Schema.SObjectType sobjtype) {
		Map<String,Object> jsonmap = (Map<String,Object>) JSON.deserializeUntyped(jstr);
		Schema.describeSObjectResult dsr = sobjtype.getDescribe();
		Map<String,Schema.SObjectField> fieldmap = dsr.fields.getMap();
		SObject obj = sobjtype.newSObject();
		for(String fn : jsonmap.keySet()){ 
			String fieldname = fn.toLowerCase();
			if (fieldmap.containsKey(fieldname)) {
				Schema.DescribeFieldResult dfr = fieldmap.get(fieldname).getDescribe();
				Schema.DisplayType ftype = dfr.getType();
				// Need to only assign values for fields that are assignable, plus Id so that an update can be processed
				if (dfr.isAccessible() && !dfr.isCalculated() && !dfr.isAutoNumber()) {
					if ((dfr.isCreateable() && dfr.isUpdateable()) || fieldname=='id') {
						Object val = jsonmap.get(fn);
						System.debug(fn);
						System.debug(val);
						// Sime fields require special handling (Date, Time, DateTime, Decimal)
						// Try valueOf, parse and JSON deserialization in turn
						// to handle various legitimate format options for Date, Time and DateTime
						if (val==null) {
							// don't try to parse nulls if they're one of the field types that need special handling
							obj.put(fn, null);
						} else if (ftype==Schema.DisplayType.Date) {
							Date dateval;
							try {
								dateval = Date.valueOf(val);
							} catch(Exception e) {
								System.debug(e);
								try {
									dateval = Date.parse(String.valueOf(val));
								} catch(Exception e2) {
									System.debug(e2);
									try {
										dateval = (Date) JSON.deserialize('"'+val+'"',Date.class);
									} catch(Exception e3) {System.debug(e3);}
								}
							}
							obj.put(fn, dateval);
						} else if (ftype==Schema.DisplayType.DateTime) {
							DateTime datetimeval;
							try {
								datetimeval = DateTime.valueOf(val);
							} catch(Exception e) {
								System.debug(e);
								try {
									datetimeval = DateTime.parse(String.valueOf(val));
								} catch(Exception e2) {
									System.debug(e2);
									try {
										datetimeval = (DateTime) JSON.deserialize('"'+val+'"',DateTime.class);
									} catch(Exception e3) {System.debug(e3);}
								}
							}
							obj.put(fn, datetimeval);
						} else if (ftype==Schema.DisplayType.Time) {
							Time timeval;
							List<String> hms = String.valueOf(val).split(':');
							if (hms.size()==3) {
								List<String> seconds = hms[2].split('.');
								timeval = Time.newInstance(Integer.valueOf(hms[0]), Integer.valueOf(hms[1]), Integer.valueOf(seconds[0]), 
									(seconds.size()==2) ? Integer.valueOf(seconds[1]) : 0);
							}
							obj.put(fn, timeval);
						} else if (ftype==Schema.DisplayType.Currency || ftype==Schema.DisplayType.Double || ftype==Schema.DisplayType.Integer || ftype==Schema.DisplayType.Long || ftype==Schema.DisplayType.Percent) {
							obj.put(fn, Decimal.valueOf(String.valueOf(val)));
						}
						// All other field types -- just assign the value!
						else obj.put(fn, val);
					}
				}
			} else {
				System.debug('Field not in object: ' + fn);
			}
		}
		return obj;
	}
	// BLL5 end
}