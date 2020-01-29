/**
 * Created by Matthew.Chevalier on 1/28/2020.
 */

@IsTest(SeeAllData = false)
private class DealerLocationDA_TEST {

    @IsTest
    static void getConditionallyFilteredLocations_givenVoid_returnsEmptyDealerLocationList () {
        DealerLocationDA instance = new DealerLocationDA();
        Test.startTest();
        {
            List<dealer__Dealer_Location__c> res = instance.getConditionallyFilteredLocations(new Set<Id>(), new Set<String>(), new Set<String>());
            System.assertEquals(0, res.size());
        }
        Test.stopTest();
    }

    @IsTest
    static void getConditionallyFilteredLocations_givenVoid_returnsDealerLocationList () {
        DealerLocationDA instance = new DealerLocationDA();
        Test.startTest();
        {
            List<dealer__Dealer_Location__c> res = instance.getConditionallyFilteredLocations(new Set<Id>(), new Set<String>{'a'}, new Set<String>{'b'});
            System.assertEquals(0, res.size());
        }
        Test.stopTest();
    }

    @IsTest
    static void getAllLocations_givenVoid_returnsDealerLocationList () {
        DealerLocationDA instance = new DealerLocationDA();
        Test.startTest();
        {
            List<dealer__Dealer_Location__c> res = instance.getAllLocations();
            System.assertEquals(0, res.size());
        }
        Test.stopTest();
    }

    @IsTest
    static void getAllNonClosedLocations_givenVoid_returnsDealerLocationList () {
        DealerLocationDA instance = new DealerLocationDA();
        Test.startTest();
        {
            List<dealer__Dealer_Location__c> res = instance.getAllNonClosedLocations();
            System.assertEquals(0, res.size());
        }
        Test.stopTest();
    }
}