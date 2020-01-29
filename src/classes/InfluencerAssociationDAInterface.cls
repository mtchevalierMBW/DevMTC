/**
 * Created by Matthew.Chevalier on 1/29/2020.
 */

public interface InfluencerAssociationDAInterface {
    List<InfluencerAssociation2__c> getAllFromAccountIds(Set<Id> accountIds);
}