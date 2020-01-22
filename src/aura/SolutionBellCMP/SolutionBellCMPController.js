({
    
	findSolution : function(component, event, helper) {
    	component.set('v.yearcounts', []);
    	component.set('v.solutions', []);
		component.set('v.yr', component.get('v.startYear'));
		component.set('v.totalsolutions', 0);
		helper.showSpinner(component);
        helper.countByYear(component);
	},
    
})