/**
 * SObjectChangedFields_TEST
 * Tests: SObjectChangedFields 
 * 
 */
@isTest
private class SObjectChangedFields_TEST {

    static testMethod void testFieldChanges() {
        Account a1 = new Account(Name='Person Name', BillingState='OH', BillingPostalCode='44641');
        Account a2 = new Account(Name='Person Name', BillingState='OH', BillingPostalCode='44601');
        boolean okay1 = SObjectChangedFields.OnlyAllowedFieldsChanged(a1, a2, new Set<String>{'billingpostalcode'}); 
        boolean okay2 = SObjectChangedFields.NoDisallowedFieldsChanged(a1, a2, new Set<String>{'billingstate'});
        System.assert(okay1, 'Did not recognize that only BillingPostalCode changed');
        System.assert(okay2, 'Did not recognize that BillingState did not change');
        Set<String> strFields = SObjectChangedFields.getFieldSetByType(a1, a2, new Set<Schema.DisplayType>{Schema.DisplayType.String});
        System.debug(strFields);
    }
}