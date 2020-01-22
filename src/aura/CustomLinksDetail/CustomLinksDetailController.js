({
    doInit : function(component, event, helper) {
			console.log('CustomLinksDetail doInit');
			let getgrouplinks = component.get("c.GetGroupLinks");
			getgrouplinks.setParams({groupName : component.get("v.groupName")});
			getgrouplinks.setCallback(this, function(response) {
				console.log('getGroupLinks response');
				//console.log(response);
				//console.log(JSON.stringify(response));
				var state = response.getState();
				console.log(state);
				if (state==="SUCCESS") {
					let grplinks = response.getReturnValue();
					console.log(grplinks);
					component.set("v.GroupLinks", grplinks);
					console.log('assigned v.GroupedLinks');
					console.log(JSON.stringify(component.get("v.GroupLinks")));
				} else if (state==="INCOMPLETE") { 
					console.log('CustomLinksDetailController callback incomplete');
					console.log(response);
					console.log(JSON.stringify(response));
				} else { // if (state==="ERROR") 
					console.log('CustomLinksDetailController callback error');
					console.log(response);
					console.log(JSON.stringify(response));
				}
			});
			$A.enqueueAction(getgrouplinks);
	}, 
	
})