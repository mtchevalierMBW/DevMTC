({
	
	getGroups : function(component) {
		console.log('getGroups');
		let getgroups = component.get("c.GetGroupNames");
		getgroups.setCallback(this, function(response) {
			console.log('getGroups response');
			//console.log(response);
			//console.log(JSON.stringify(response));
			var state = response.getState();
			console.log(state);
			if (state==="SUCCESS") {
				let grplist = response.getReturnValue();
				//console.log(grplist);
				component.set("v.GroupNames", grplist);
				//console.log('assigned v.GroupNames');
				//console.log(JSON.stringify(component.get("v.GroupNames")));
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
		$A.enqueueAction(getgroups);
	},

})