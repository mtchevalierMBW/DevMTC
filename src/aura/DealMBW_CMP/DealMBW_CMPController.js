({
    doInit : function(component, event, helper) {
		let pageparams='';
		if (component.get("v.pageReference")!=null && component.get("v.pageReference").state!=null && component.get("v.pageReference").state.v!=null) {
			pageparams += '&v=' + component.get("v.pageReference").state.v;
		}
		if (component.get("v.pageReference")!=null && component.get("v.pageReference").state!=null && component.get("v.pageReference").state.s!=null) {
			pageparams += '&s=' + component.get("v.pageReference").state.s;
		}
		if (component.get("v.pageReference")!=null && component.get("v.pageReference").state!=null && component.get("v.pageReference").state.b!=null) {
			pageparams += '&b=' + component.get("v.pageReference").state.b;
		}
		if (component.get("v.pageReference")!=null && component.get("v.pageReference").state!=null && component.get("v.pageReference").state.RecordType!=null) {
			pageparams += '&RecordType=' + component.get("v.pageReference").state.RecordType;
		}
		component.set("v.params",pageparams);
		
		/* monitor height of div and save if it changes */
		let divheight=window.localStorage.getItem('dealmbw_height');
		console.log('initial height: ' + divheight);
		if (divheight>'') component.set('v.frameheight',divheight);
		//setTimeout(() => {
		//	let currentheight = document.getElementById("divcontainer").style.height;
		//	if (currentheight>'') {
		//		//console.log('divheight: ' + currentheight);
		//		let divheight=window.localStorage.getItem('dealmbw_height');
		//		if (currentheight!=divheight) {
		//			component.set('v.frameheight',currentheight);
		//			console.log('set new height: ' + currentheight);
		//			window.localStorage.setItem('dealmbw_height',currentheight);
		//		}
		//	}
		//}, 30000);
	},

	initJS : function(component, event, helper) {
		console.log('initJS');
		//setInterval(function(){console.log($('#floor').is(':visible'));}, 2000);
	},

	//saveDivSize : function(componet, event, helper) {
	//	console.log('resizediv');
	//	let currentheight = document.getElementById("divcontainer").style.height;
	//	if (currentheight>'') {
	//		//console.log('divheight: ' + currentheight);
	//		let divheight=window.localStorage.getItem('dealmbw_height');
	//		if (currentheight!=divheight) {
	//			component.set('v.frameheight',currentheight);
	//			console.log('set new height: ' + currentheight);
	//			window.localStorage.setItem('dealmbw_height',currentheight);
	//		}
	//	}
	//},
})