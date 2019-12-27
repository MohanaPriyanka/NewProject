/**
 * Created by abarnes on 9/12/2018.
 *
 * Can now run this to delete all testcases regardless of age:
        TestcaseRecordDeleter deleter = new TestcaseRecordDeleter();
        deleter.deleteAll = true;
        deleter.execute(null);
 *
 * Tested by: TestcaseRecordDeleterTest
 */

public without sharing virtual class TestcaseRecordDeleter implements Schedulable {
    public Boolean deleteAll = false;

    public void execute(SchedulableContext context) {
        try {
            deleteTestcaseRecords();
        } catch (Exception e) {
            Logger.logLater('TestcaseRecordDeleter', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    @TestVisible
    private void deleteTestcaseRecords() {
        // Finds and deletes accounts from Zuora
        System.enqueueJob(new TestcaseRecordAsyncDeleter());

        String createdDateFilter = 'AND CreatedDate < Last_N_DAYS:28';
        String closedDateFilter = 'AND CloseDate < Last_N_DAYS:28';
        if (deleteAll) {
            createdDateFilter = '';
            closedDateFilter = '';
        }
        List<String> queries = new List<String>{
            'SELECT Id, Name_on_Account__c FROM Utility_Account_Log__c WHERE (Name_on_Account__c like \'%Testcase%\' ' + createdDateFilter + ' )',
            'SELECT Id, First_Name_from_Lead__c, Last_Name_from_Lead__c FROM LASERCA__Personal_Credit_Report__c WHERE (Last_Name_from_Lead__c like \'%Testcase%\' ' + createdDateFilter + ')',
            'SELECT Id, Name FROM Residential_Equipment__c WHERE (Name like \'%Testcase%\' ' + createdDateFilter + ')',
            'SELECT Id, Name FROM Loan__c WHERE (Name like \'%Testcase%\' ' + createdDateFilter + ')',
            'SELECT Id, Lead__r.Name FROM Partner_Task__c WHERE (Lead__r.Name like \'%Testcase%\' ' + createdDateFilter + ')',
            'SELECT Id, Name FROM Opportunity WHERE (Name like \'%Testcase%\' ' + closedDateFilter + ')',
            'SELECT Id, FirstName, LastName FROM Contact WHERE (LastName = \'Testcase\' ' + createdDateFilter + ') AND Partner_Lookup__r.Name != \'Bluewave Inside Sales\' AND Name != \'BlueWave Testcase\'',
            'SELECT Id, FirstName, LastName FROM Lead WHERE (LastName = \'Testcase\' ' + createdDateFilter + ')',
            'SELECT Id, Name FROM Account WHERE (Zuora_Id__c = NULL AND Name like \'%Testcase%\' ' + createdDateFilter + ')'
        };

        List<SObject> sobjects = new List<SObject>();
        Integer recordsProcessed = 0;
        Integer totalRecords = 0;

        for (String query : queries) {
            sobjects.addAll(Database.query(query));
            totalRecords += sobjects.size();

            if (!sobjects.isEmpty()) {
                String objectType = String.valueOf(sobjects[0].getSObjectType().getDescribe().getName());
                Logger.logLater('DeleteTestcaseRecords', 'execute', 'Found ' + sobjects.size() + ' records of type: \'' + objectType + '\' to delete.', Logger.INFO);

                Database.DeleteResult[] testCaseDeletion = Database.delete(sobjects, false);

                recordsProcessed += processRecords(testCaseDeletion);
                sobjects.clear();
            }
        }
        Logger.logLater('DeleteTestcaseRecords', 'execute', recordsProcessed + ' out of ' + totalRecords + ' records successfully deleted', Logger.INFO);
    }

    public static Integer processRecords(Database.DeleteResult[] testCaseDeletion) {
        Integer recordsProcessed = 0;
        for (Database.DeleteResult dr : testCaseDeletion) {
            if (dr.isSuccess()) {
                recordsProcessed += 1;
            } else {
                for (Database.Error err : dr.getErrors()) {
                    Logger.logLater('DeleteTestcaseRecords', 'execute', 'The following error has occurred.', Logger.ERROR);
                    Logger.logLater('DeleteTestcaseRecords', 'execute', err.getStatusCode() + ': ' + err.getMessage(), Logger.ERROR);
                }
            }
        }
        return recordsProcessed;
    }
}