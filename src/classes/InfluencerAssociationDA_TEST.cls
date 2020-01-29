/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

@IsTest
private class InfluencerAssociationDA_TEST {

    @IsTest
    static void getAllFromAccountIds_givenIdSet_returnsInfAssocList () {
        InfluencerAssociationDA instance = new InfluencerAssociationDA();
        Test.startTest();
        {
            List<InfluencerAssociation2__c> res = instance.getAllFromAccountIds(new Set<Id>());
            System.assertEquals(0, res.size());
        }
        Test.stopTest();
    }

    @IsTest
    static void callAllMockMethods() {
        InfluencerAssociationDAMock instance = new InfluencerAssociationDAMock();
        Test.startTest();
        {
            instance.getAllFromAccountIds(new Set<Id>());
        }
        Test.stopTest();
    }
}