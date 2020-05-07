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
}