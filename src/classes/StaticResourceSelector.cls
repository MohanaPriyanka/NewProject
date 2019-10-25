/**
 * Created by PeterYao on 10/18/2019.
 */

public with sharing class StaticResourceSelector {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public StaticResource getStaticResource(String name) {
        return [
            SELECT Id, Body
            FROM StaticResource
            WHERE Name = :name
            LIMIT 1
        ];
    }
}