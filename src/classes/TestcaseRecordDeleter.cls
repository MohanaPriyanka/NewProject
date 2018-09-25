/**
 * Created by abarnes on 9/12/2018.
 *
 * Tested by: TestcaseRecordDeleterTest
 */

global class TestcaseRecordDeleter implements Schedulable {
    global void execute(SchedulableContext SC) {

        List<String> queries = new List<String>{
            'SELECT Id, Name_on_Account__c FROM Utility_Account_Log__c WHERE (Name_on_Account__c like \'%Testcase%\' AND CreatedDate < Last_N_DAYS:14)',
            'SELECT Id, First_Name_from_Lead__c, Last_Name_from_Lead__c FROM LASERCA__Personal_Credit_Report__c WHERE (Last_Name_from_Lead__c like \'%Testcase%\' AND CreatedDate < Last_N_DAYS:14)',
            'SELECT Id, Name FROM Residential_Equipment__c WHERE (Name like \'%Testcase%\' AND CreatedDate < Last_N_DAYS:14)',
            'SELECT Id, Name FROM Loan__c WHERE (Name like \'%Testcase%\' AND CreatedDate < Last_N_DAYS:14)',
            'SELECT Id, Lead__r.Name FROM Partner_Task__c WHERE (Lead__r.Name like \'%Testcase%\' AND CreatedDate < Last_N_DAYS:14)',
            'SELECT Id, Name FROM Opportunity WHERE (Name like \'%Testcase%\' AND CloseDate < Last_N_DAYS:14)',
            'SELECT Id, FirstName, LastName FROM Contact WHERE (LastName = \'Testcase\' AND CreatedDate < Last_N_DAYS:14) AND Partner_Lookup__r.Name != \'Bluewave Inside Sales\' AND Name != \'BlueWave Testcase\'',
            'SELECT Id, FirstName, LastName FROM Lead WHERE (LastName = \'Testcase\' AND CreatedDate < Last_N_DAYS:14)',
            'SELECT Id, Name FROM Account WHERE (Name like \'%Testcase%\' AND CreatedDate < Last_N_DAYS:14)'
        };

        List<SObject> sobjects = new List<SObject>();
        Integer recordsProcessed = 0;
        Integer totalRecords = 0;


        for (String query : queries) {
            sobjects.addAll(Database.query(query));
            totalRecords += sobjects.size();

            if (!sobjects.isEmpty()) {
                String objectType = String.valueOf(sobjects[0].getSObjectType().getDescribe().getName());
                Logger.logLater('DeleteTestcaseRecords', 'execute', 'Found ' + sobjects.size() + ' records of type: \'' + objectType + '\' to delete.');

                Database.DeleteResult[] testCaseDeletion = Database.delete(sobjects, false);

                recordsProcessed += processRecords(testCaseDeletion);
                sobjects.clear();
            }
        }
        Logger.logLater('DeleteTestcaseRecords', 'execute', recordsProcessed + ' out of ' + totalRecords + ' records successfully deleted');
        Logger.flushLogs();
    }

    private static Integer processRecords(Database.DeleteResult[] testCaseDeletion) {
        Integer recordsProcessed = 0;
        for (Database.DeleteResult dr : testCaseDeletion) {
            if (dr.isSuccess()) {
                recordsProcessed += 1;
            } else {
                for (Database.Error err : dr.getErrors()) {
                    Logger.logLater('DeleteTestcaseRecords', 'execute', 'The following error has occurred.');
                    Logger.logLater('DeleteTestcaseRecords', 'execute', err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
        return recordsProcessed;
    }
}