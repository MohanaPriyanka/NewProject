/**
 * Created by PeterYao on 10/18/2019.
 */
@IsTest
public with sharing class StaticResourceSelectorTest {
    @IsTest
    public static void testGetStaticResource() {
        StaticResourceSelector srs = new StaticResourceSelector();
        StaticResource sr = srs.getStaticResource('TestCSAccount');
        System.assertNotEquals(null, sr);

    }
}