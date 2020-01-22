({
    doInit : function(component, event, helper) {
		console.log('doInit');
	},
	
	ldsHandleRecordUpdated: function(component, event, helper) { 
		console.log('ldsHandleRecordUpdated'); 
		let eventParams = event.getParams(); 
		console.log(eventParams); 
		console.log(eventParams.changeType); 
		
		if (eventParams.changeType === "LOADED") { 
			console.log("Record is loaded successfully."); 
			helper.getAuthorization(component);
			helper.getReportURL(component);
		} else if(eventParams.changeType === "CHANGED") { 
			console.log("Record is changed (saved)"); 
		} else if(eventParams.changeType === "REMOVED") { 
			console.log("Record was deleted"); 
		} else if(eventParams.changeType === "ERROR") { 
			console.log("Error loading record:"+JSON.serialize(eventParams)); 
		} 
	},  

})