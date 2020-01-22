({
    doInit : function(component, event, helper) {
		let pageparams='';
		// for each parameter the VF page accepts ... pass it along
		//if (component.get("v.pageReference")!=null && component.get("v.pageReference").state!=null && component.get("v.pageReference").state.v!=null) {
		//	pageparams += '&v=' + component.get("v.pageReference").state.v;
		//}
		//if (component.get("v.pageReference")!=null && component.get("v.pageReference").state!=null && component.get("v.pageReference").state.RecordType!=null) {
		//	pageparams += '&RecordType=' + component.get("v.pageReference").state.RecordType;
		//}
		component.set("v.params",pageparams);
	},
	//initJS : function(component, event, helper) {
	//	console.log('initJS');
	//},
})