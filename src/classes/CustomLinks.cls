/**
 * CustomLinks
 * Tested by: CustomLinks_TEST
 *
 * Code coverage:
 *	2018-09-13	97%	(46/47)
 *	2019-01-28	94%	(67/71)
 *
 * Modifications:
 * 
 */ 
public with sharing class CustomLinks {

	List<CustomLinks__c> linklist;
	List<String> linkGroup;
	Map<String,String> groupCond;
	Map<String,String> groupProfiles;
	Map<String,List<CustomLinks__c>> siteMap;

	// constructor
	//---------------------------
	public CustomLinks() {
		linklist = new List<CustomLinks__c>();
		retrieveCustomLinks();
    }

	// retrieveCustomLinks
	//------------------------------
	public void retrieveCustomLinks() {
		linkGroup = new List<String>();
		groupCond = new Map<String,String>();
		groupProfiles = new Map<String,String>();
		siteMap = new Map<String,List<CustomLinks__c>>();

		linklist.addAll([
			select Name, Condition__c, GroupLabel__c, Link__c, Sequence__c, Target__c, Limit_to_profiles__c
			from CustomLinks__c
			order by Sequence__c, GroupLabel__c, Name
		]);

		for(CustomLinks__c l : linklist) {
			List<CustomLinks__c> links = siteMap.get(l.GroupLabel__c);
			if (links==null) {
				linkGroup.add(l.GroupLabel__c);
				links = new List<CustomLinks__c>();
			}
			if (String.isBlank(l.Link__c)) {
				groupCond.put(l.GroupLabel__c, l.Condition__c);
				groupProfiles.put(l.GroupLabel__c, l.Limit_to_profiles__c);
			} else links.add(l);
			siteMap.put(l.GroupLabel__c, links);
		}
		
	}
    
    
 
	// getCustomLinkPanels
	//------------------------------
	public Component.Apex.outputPanel getCustomLinkPanels() {
    	Component.Apex.outputPanel outerpanel = new Component.Apex.outputPanel();
    	outerpanel.rendered=true;
    	outerpanel.styleClass='slds-scope slds-m-around_x-small';
    	Component.Apex.outputPanel innerpanel = new Component.Apex.outputPanel(styleClass='slds-grid slds-wrap');

    	for(String g : linkGroup) {
    		List<CustomLinks__c> links = sitemap.get(g);
    		String gcondition = groupCond.get(g);
    		Component.Apex.outputPanel op = new Component.Apex.outputPanel();
			if (!String.isBlank(gcondition)) op.expressions.rendered = gcondition;
			else op.rendered=true;

			String html = '';
			html += '<article class="slds-col slds-card slds-m-right_x-small slds-m-bottom_x-small slds-p-around_x-small linkgroup">'
				    + '<div class="slds-card__header">'
					+ '<header class="slds-media slds-media_left">'
					+   '<div class="slds-media__body">'
					+     '<h2 class="slds-card__header-title">'
					+   g
					+     '</h2>'
					+   '</div>'
					+ '</header>';
			
			for(CustomLinks__c l : links) {
				html += ''	// '<div class="slds-no-flex">'
				    + '<a href="#" style="display:block;" ' 
					+ 'onclick="MW_NavigateTo(\'' + l.Link__c + '\', \'' + l.Target__c + '\');" '
					//+ 'onclick="sforce.one.navigateToURL(\'' + l.Link__c + '\');" '
					+ 'oncontextmenu="return false;" '
					+ '>' + l.Name + '</a>'
					+ ''; 	//'</div>';
			}
			html += '</div></article>';
			op.childComponents.add(new Component.Apex.outputText(escape=false, value=html));
			innerpanel.childComponents.add(op);
    		//outerpanel.childComponents.add(op);
    	}
    	outerpanel.childComponents.add(innerpanel);
    	
    	return outerpanel;
    }

	@AuraEnabled
	public static List<String> GetGroupNames() {
		List<String> gnames = new List<String>();
		CustomLinks cl = new CustomLinks();
		String profilename = [select Name from Profile where Id=:userInfo.getProfileId() limit 1].Name;
		for(String g : cl.linkGroup) {
    		String profilenames = cl.groupProfiles.get(g);
			boolean includegroup = false;
			if (String.isBlank(profilenames)) includegroup = true;
			else {
				List<String> pns = profilenames.split(',');
				for(String s : pns) includegroup = includegroup || profilename.contains(s);
			}
			if (includegroup) {
				gnames.add(g);
			}
		}
		return gnames;
	}

	@AuraEnabled
	public static List<CustomLinks__c> GetGroupLinks(String groupName) {
		CustomLinks cl = new CustomLinks();
		return cl.siteMap.get(groupName);
	}

}