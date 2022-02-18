/**
 * Created by peteryao on 9/25/20.
 * Description: Used by the Assignment Agreement flow to find Contract Assignment Entities for a given Client Account
 * Tested By: EntitySelectorTest
 */

public without sharing class InvocableEntitySelector {
    private static EntitySelector entitySelector = new EntitySelector();
    @InvocableMethod(Label='InvocableEntitySelector')
    public static List<List<Entity__c>> getContractAssignmentEntitiesByClient(List<Id> clientAccountIds) {
        if (clientAccountIds.size() != 1) {
            throw new Util.BWException('Only one account supported right now');
        }
        return new List<List<Entity__c>>{entitySelector.getContractAssignmentEntitiesForClient(clientAccountIds[0])};
    }
}