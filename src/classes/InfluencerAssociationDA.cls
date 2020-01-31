/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

public inherited sharing class InfluencerAssociationDA implements InfluencerAssociationDAInterface{
    public List<InfluencerAssociation2__c> getAllFromAccountIds(Set<Id> accountIds) {
        return [
                SELECT  Id,
                        Name
                FROM InfluencerAssociation2__c
                WHERE InfluencedAccount__c IN :accountIds
                OR (InfluencerAccount__c IN :accountIds AND InfluencerContact__c=null)
                LIMIT 2000
        ];
    }

}