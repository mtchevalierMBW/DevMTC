({

	// Your renderer method overrides go here

	// Note: unrender doesn't necessarily get called when you navigate away from the proposal
	// Looks like it gets called when re-generating the component for a new record;
	unrender: function (cmp,helper) {
		console.log('unrender');
		let divcontainer = document.getElementById("divcontainer");
		let currentheight = (divcontainer!=null && divcontainer.style!=null) ? divcontainer.style.height : '';
		console.log('current height:'+currentheight);
		if (currentheight>'') {
			//console.log('divheight: ' + currentheight);
			let divheight=window.localStorage.getItem('dealmbw_height');
			if (currentheight!=divheight) {
				//component.set('v.frameheight',currentheight);
				console.log('set new height: ' + currentheight);
				window.localStorage.setItem('dealmbw_height',currentheight);
			}
		}
		this.superUnrender();
	},

})