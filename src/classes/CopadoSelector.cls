/**
 * Created by PeterYao on 10/18/2019.
 * Tested By: CopadoSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class CopadoSelector {
    public List<copado__User_Story__c> getUserStoriesToPromote() {
        return [
            SELECT Id, Name, copado__User_Story_Title__c, copado__Promotion_Test_Level__c, copado__Environment__c, copado__Org_Credential__c, copado__Project__c, (
                SELECT Id FROM copado__Promoted_User_Stories__r
                WHERE copado__Promotion__r.copado__Status__c = 'In Progress'
            )
            FROM copado__User_Story__c
            WHERE copado__Status__c = 'Approved'
            AND copado__Promote_Change__c = TRUE
            AND copado__Promote_and_Deploy__c = FALSE
        ];
    }

    public copado__Environment__c getProductionEnvironment() {
        List<copado__Environment__c> productionEnvironments = [
            SELECT Id, Name
            FROM copado__Environment__c
            WHERE copado__Type__c = 'Production/Developer'
        ];
        if (productionEnvironments.size() != 1) {
            throw new Util.BWException('Expected a single production environment, but got these: ' + productionEnvironments);
        }
        return productionEnvironments[0];
    }

    public copado__Org__c getDefaultCredential(Id environmentId) {
        List<copado__Org__c> credentials = [
            SELECT Id, copado__Username__c
            FROM copado__Org__c
            WHERE copado__Default_Credential__c = TRUE
            AND copado__Environment__c = :environmentId
        ];
        if (credentials.size() != 1) {
            throw new Util.BWException('Expected a single default credential but got these: ' + credentials);
        }
        return credentials[0];
    }
}