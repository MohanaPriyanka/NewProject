public class SurveyHandler {

    public void deleteDuplicateSubmissions(List<BlueWave_Surveys__c> newSurveys) {
        String surveyUniqueIdentifier;
        String incumbantSurveyUniqueIdentifier;
        List<String> surveyidList = new List<String>();   
        List<BlueWave_Surveys__c> duplicateSurveyList = new List<BlueWave_Surveys__c>();        
        Set<String> surveyUniqueIdentifierList = new Set<String>();
        Set<String> incumbantSurveyUniqueIdentifierList = new Set<String>();

        for (BlueWave_Surveys__c surveyRecord : newSurveys) {
            surveyidList.add(surveyRecord.Id);      
        }       
        for (BlueWave_Surveys__c incumbantsurvey : [SELECT Id, Name, Case__r.Contact.Id FROM BlueWave_Surveys__c WHERE Id NOT IN : surveyIdList]) {
            incumbantSurveyUniqueIdentifier = incumbantsurvey.Case__r.Contact.Id + ' ' + incumbantsurvey.Name;
            incumbantSurveyUniqueIdentifierList.add(incumbantSurveyUniqueIdentifier);
        }
        for (BlueWave_Surveys__c surveyRecord : newSurveys) {
            surveyUniqueIdentifier = surveyRecord.Case__r.Contact.Id + ' ' + surveyRecord.Name; 
            if (incumbantSurveyUniqueIdentifierList.contains(surveyUniqueIdentifier)) {
                duplicateSurveyList.add(surveyRecord);
            }           
        }
        delete duplicateSurveyList;
    }
}