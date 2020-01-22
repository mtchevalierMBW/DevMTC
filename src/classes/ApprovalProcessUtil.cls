/**
 * ApprovalProcessUtil
 * Tested by: ApprovalProcessUtil_TEST
 * Date: Aug 5, 2016
 * Programmer: Bryan Leaman
 *
 * Code coverage:
 *	2018-01-16	96%	(48/50)
 *
 *	2017-07-31	B. Leaman	BLL1 - Recognize approval groups/queues.
 *	2019-01-16	B. Leaman	W-000482 BLL2 - Process approval automation.
 */
public with sharing class ApprovalProcessUtil {

	Set<Id> targetIds;
	List<ProcessInstance> procInst;

	// ApprovalProcessUtil
	//---------------------------------------
	public ApprovalProcessUtil(Set<Id> objIds) {
		targetIds = objIds;
	    if (targetIds.size()>0) {
			// First, get the process instance(s) for these deals, including work items (current approvers)
	        procInst = [
		    	select TargetObjectId, Status, ProcessDefinitionId, LastActorId, CreatedDate, 
		    	    (Select Id, ActorId, OriginalActorId from WorkItems )
		    	from ProcessInstance 
		    	where TargetObjectId in :targetIds
		    	  and Status!='Removed'  
	        ];
	    }

	}


	//-----------------------------------------------------
	public Map<Id,Set<Id>> getObjectApproverMap() {
		Map<Id,Set<Id>> rtnMap = new Map<Id,Set<Id>>();
		Set<Id> allApprovers = new Set<Id>();

		if (procInst==null) return rtnMap;

		// Build list of approvers (work items) for each deal (even though only 1)
        for (ProcessInstance pi : procInst) {
        	Set<Id> approvers = rtnMap.get(pi.TargetObjectId);
        	if (approvers==null) approvers = new Set<Id>();
        	for(Integer i=0; i<pi.WorkItems.size(); ++i) {
        		// BLL1a/c
        		Id actId = pi.WorkItems[i].ActorId;
        		Set<Id> mbrIds = new Set<Id>();
        		if (actId.getSObjectType()==Schema.Group.SObjectType) {
					mbrIds = Utility.getGroupMembers(new Set<Id>{actId});
        		} else {
        			mbrIds.add(actId);
        		}
       			approvers.addAll(mbrIds);
       			allApprovers.addAll(mbrIds);
       			// BLL1a/c end
        	}
            rtnMap.put(pi.TargetObjectId, approvers);
        }
	    
	    // Generate a map of all delegated approvers for all listed users in the work items
		List<User> users = [select Id, DelegatedApproverId from User where Id in :allApprovers and DelegatedApproverId!=null];
		Map<Id, Id> delegateMap = new Map<Id, Id>();
		for(User u : users) delegateMap.put(u.Id, u.DelegatedApproverId);

	    // Loop through & ensure actual approver is on the list!
	    // Only running if there is only 1 deal, but code is bulkified anyway.
	    for(Id tid : targetIds) {
	    	// List of approvers for the deal
	        Set<Id> authUsers = (Set<Id>) rtnMap.get(tid);
	        if (authUsers==null) authUsers = new Set<Id>(); 
			// Add delegated approvers
			for(Id uid : authUsers) {
				if (delegateMap.containsKey(uid)) authUsers.add(delegateMap.get(uid));
			}
		}
		return rtnMap;
	}


	// BLL2 - autoapprove document
    // ApproveDocument - approve current step when posted
    //-------------------------------------
    public static boolean ApproveDocument(Id docId, String comment, Set<String> nodes) {
		boolean rtnOk = false;
        // Pending approvals
        List<ProcessInstance> pilist = [
            Select TargetObjectId, Status, ProcessDefinitionId, Id, 
                (Select Id, ProcessInstanceId, OriginalActorId, ActorId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, IsDeleted, CreatedDate, CreatedById, SystemModstamp From Workitems), 
                (Select Id, ProcessInstanceId, StepStatus, OriginalActorId, ActorId, Comments, StepNodeId, ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes, CreatedDate, CreatedById, SystemModstamp From Steps), 
                (Select Id, IsDeleted, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, 
					ProcessInstanceId, ProcessNodeId, NodeStatus, CompletedDate, LastActorId, ProcessNodeName, ProcessNode.DeveloperName, 
					ElapsedTimeInDays, ElapsedTimeInHours, ElapsedTimeInMinutes From Nodes Where NodeStatus='Pending') 
            From ProcessInstance 
            Where Status='Pending' and TargetObjectId = :docId
        ];
        if (pilist.size()>0 && pilist[0].WorkItems.size()>0) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments(comment);
            req.setAction('Approve');
            Id uid = UserInfo.getUserId();
            req.setNextApproverIds(new Id[] {uid});

            // Find matching work item (if there is one that matches the current user, else default to 0)
            Integer wi = 0;
            for(Integer i=0; i<pilist[0].WorkItems.size(); ++i) {
                if (pilist[0].WorkItems[i].ActorId==uid) wi = i;
            }
            
            // Use the ID from the newly created item to specify the item to be worked
            req.setWorkitemId(pilist[0].WorkItems[wi].Id);
            
			System.debug(nodes);
			System.debug(pilist[0].Nodes[0]);
			System.debug(pilist[0].Nodes[0].ProcessNodeName);
			System.debug(pilist[0].Nodes[0].ProcessNode.DeveloperName);
            if (nodes==null || nodes.size()==0 
                || nodes.contains(pilist[0].Nodes[0].ProcessNodeName) || nodes.contains(pilist[0].Nodes[0].ProcessNode.DeveloperName)) {
                // Submit the request for approval
                Approval.ProcessResult result =  Approval.process(req);
				rtnOk = result.isSuccess();
                if (result.isSuccess()) System.debug('Automatic approval succeeded');
                else System.debug('Automatic approval failed: ' + JSON.serialize(result));
            } else System.debug('No matching node - do not auto-approve');
        } else System.debug('No pending approval for document: ' + docId);
		
		return rtnOk;
    }
    // BLL2 end

}