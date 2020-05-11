@isTest
public class FFLibHelperTest {
    public static List<SObject> getRegisterNewListFromUnitOfWork (fflib_SObjectUnitOfWork unitOfWork, String sObjectType){
        Map<String, List<SObject>> objectMap = unitOfWork.m_newListByType;
        List<SObject> sObjectList = objectMap.get(sObjectType);
        return sObjectList;
    }

    public static List<SObject> getRegisterDirtyListFromUnitOfWork (fflib_SObjectUnitOfWork unitOfWork, String sObjectType){
        Map<String, Map<Id, SObject>> objectMap = unitOfWork.m_dirtyMapByType;
        Map<Id, SObject> sObjectList = objectMap.get(sObjectType);
        return sObjectList.values();
    }

    public static List<SObject> getRegisterDeletedListFromUnitOfWork (fflib_SObjectUnitOfWork unitOfWork, String sObjectType){
        Map<String, Map<Id, SObject>> objectMap = unitOfWork.m_deletedMapByType;
        Map<Id, SObject> sObjectList = objectMap.get(sObjectType);
        return sObjectList.values();
    }

    /*
        As of 5/8/2020, fflib_SObjectUnitOfWork only gets 67% test coverage from the
        fflib_SObjectUnitofWorkTest, see :
        https://github.com/apex-enterprise-patterns/fflib-apex-common/issues/239#issuecomment-553541756
        This method calls untested methods to get coverage
    */
    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    public static void testCoverageForUOW(){
        Account newAccount = new Account(Name = 'Test');
        insert newAccount;

        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> {
                Subscription_Change_Event__e.SObjectType
            }
        );
        Subscription_Change_Event__e stageChange = new Subscription_Change_Event__e(
            Property_Account_Id__c = newAccount.Id
        );
        List<SObject> eventList = new List<SObject>{stageChange};
        uow.registerPublishBeforeTransaction(eventList);
        uow.registerPublishAfterSuccessTransaction(eventList);
        uow.registerPublishAfterFailureTransaction(eventList);
    }
}