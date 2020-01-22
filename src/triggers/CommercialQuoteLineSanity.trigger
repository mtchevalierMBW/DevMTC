trigger CommercialQuoteLineSanity on CommercialQuoteLine__c (before insert, before update) {
	for(CommercialQuoteLine__c cql : Trigger.new) {
		if(cql.Cost__c == null) { cql.Cost__c = 0; }
		if(cql.Selling_Price__c == null) { cql.Selling_Price__c = 0; }
		cql.Cost__c = cql.Cost__c.setScale(2, System.RoundingMode.HALF_UP);
		cql.Selling_Price__c = cql.Selling_Price__c.setScale(2, System.RoundingMode.HALF_UP);
	}
}