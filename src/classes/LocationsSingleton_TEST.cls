/**
 * Created by Matthew.Chevalier on 1/28/2020.
 */

@IsTest
private class LocationsSingleton_TEST {

    @IsTest
    static void addLocationIds_givenIdList_returnsVoid () {
        LocationsSingleton instance = LocationsSingleton.getInstance();
        Test.startTest();
        {
            instance.addLocationIds(new List<Id>());
        }
        Test.stopTest();
    }

    @IsTest
    static void addLocationIds_givenIdSet_returnsVoid () {
        LocationsSingleton instance = LocationsSingleton.getInstance();
        Test.startTest();
        {
            instance.addLocationIds(new Set<Id>());
        }
        Test.stopTest();
    }

    @IsTest
    static void addLocationNames_givenStringList_returnsVoid () {
        LocationsSingleton instance = LocationsSingleton.getInstance();
        Test.startTest();
        {
            instance.addLocationNames(new List<String>());
        }
        Test.stopTest();
    }

    @IsTest
    static void addLocationNames_givenStringSet_returnsVoid () {
        LocationsSingleton instance = LocationsSingleton.getInstance();
        Test.startTest();
        {
            instance.addLocationNames(new Set<String>());
        }
        Test.stopTest();
    }

    @IsTest
    static void getLocationByName_givenStringSet_returnsLocation () {
        LocationsSingleton instance = LocationsSingleton.getInstance();
        Test.startTest();
        {
            instance.getLocationByName('Kent Free Library');
        }
        Test.stopTest();
    }

    @IsTest
    static void retrieveAllLocations_givenVoid_returnsVoid () {
        LocationsSingleton instance = LocationsSingleton.getInstance();
        Test.startTest();
        {
            instance.retrieveAllLocations();
        }
        Test.stopTest();
    }
}