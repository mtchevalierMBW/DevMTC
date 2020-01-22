({
    
	countByYear : function(component) {
		console.log('countByYear');
		let self=this;
		let yr = component.get('v.yr');
		console.log('year ' + yr);
		let method = component.get('c.countSolutionsForYear');
		method.setParams({year : yr});
		method.setCallback(this, function(response) {
			console.log('countSolutionsForYear response');
			let state = response.getState();
			if (state==='SUCCESS') {
				let returnval = response.getReturnValue();
				console.log('countSolutionsForYear returnval = ' + JSON.stringify(returnval)); 
				let yc = component.get('v.yearcounts');
				let ts = component.get('v.totalsolutions');
				yc[yc.length] = returnval;
				component.set('v.yearcounts', yc);
				let target = component.get('v.targetNbr');
				let tot = ts + returnval.total;
				console.log('new total solutions: ' + tot);
				console.log(target);
				let today = new Date();
				if (tot<=target && returnval.total>0 && yr<today.getFullYear()) {
					console.log('need to get next year');
					ts = tot;
					component.set('v.totalsolutions', ts);
					yr++;
					component.set('v.yr', yr);
					self.countByYear(component);	// is this okay?
				} else {
					if (returnval.total==0) component.set('v.yr', --yr);
					self.findTargetedSolutions(component);
				}
			} else if (state==='INCOMPLETE') { 
				console.log('countSolutionsForYear was incomplete');
			} else { // if (state==='ERROR') 
				console.log('countSolutionsForYear error:' + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
	},

	findTargetedSolutions: function(component) {
		console.log('findTargetedSolutions');
		let self = this;
		let method = component.get('c.findSolutions');
		let yrnbr = component.get('v.yr');
		console.log('for year ' + yrnbr);
		let target = component.get('v.targetNbr');
		let priorcount = component.get('v.totalsolutions');
		console.log('priorcount='+priorcount);
		method.setParams({year : yrnbr, priorcnt : priorcount, targetnbr : target });
		method.setCallback(this, function(response) {
			self.hideSpinner(component);
			console.log('findSolutions response');
			let state = response.getState();
			if (state==='SUCCESS') {
				let returnval = response.getReturnValue();
				console.log('findSolutions returnval = ' + JSON.stringify(returnval)); 
				component.set('v.solutions', returnval);
			} else if (state==='INCOMPLETE') { 
				console.log('findSolutions was incomplete');
			} else { // if (state==='ERROR') 
				console.log('findSolutions error:' + JSON.stringify(response));
			}
		});
		$A.enqueueAction(method);
	},

	/* show the spinner during long-running operations (like posting) */
	showSpinner : function(component) {
		component.set('v.spinner',true);
	},
	
	/* hide the spinner after long-running operations have completed */
	hideSpinner : function(component) {
		component.set('v.spinner',false);
	},

})