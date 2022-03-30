/**
 * @description Created by jeffparlin on 3/23/22
 */
@IsTest
public class GetObjectNameTest {

    @IsTest
    public static void testReturnObjectName(){
        String fakeLeadId = Util.getFakeId(Lead.SObjectType);
        List<String> results = GetObjectName.returnObjectName(new List<String>{ fakeLeadId });
        System.assertEquals('Lead', results[0], 'ERROR IN GetObjectNameTest.testReturnObjectName : sObject Name did not match');
    }

}