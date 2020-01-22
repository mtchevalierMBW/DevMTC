({

    GetColumnLabels : function(component) {
		console.log("GetColumnLabels");
		let getcolumnlabels = component.get("c.getColumnLabels");
		getcolumnlabels.setCallback(this, function(response) {
			console.log('GetColumnLabels response');
			//console.log(response);
			//console.log(JSON.stringify(response));
			var state = response.getState();
			console.log(state);
			if (state==="SUCCESS") {
				let stringlist = response.getReturnValue();
				console.log(stringlist);
				component.set("v.columns", stringlist);
				console.log('assigned v.columns');
				console.log(JSON.stringify(component.get("v.columns")));
			} else if (state==="INCOMPLETE") { 
			} else { // if (state==="ERROR") 
			}
		});
		$A.enqueueAction(getcolumnlabels);
	},

	GetApprovalItems : function(component) {
		console.log('GetApprovalItems');
		let getlistofitems = component.get("c.getListOfItems");
		getlistofitems.setParams({includeDelegated : component.get("v.IncludeDelegated")});
		getlistofitems.setCallback(this, function(response) {
			console.log('GetApprovalItems response');
			//console.log(response);
			//console.log(JSON.stringify(response));
			var state = response.getState();
			console.log(state);
			if (state==="SUCCESS") {
				let objlist = response.getReturnValue();
				console.log(objlist);
				component.set("v.ApprovalItems", objlist);
				console.log('assigned v.ApprovalItems');
				console.log(JSON.stringify(component.get("v.ApprovalItems")));
				// jQuery not defined this.initFilter(component);
			} else if (state==="INCOMPLETE") { 
			} else { // if (state==="ERROR") 
			}
		});
		$A.enqueueAction(getlistofitems);
	},

})