/**
 * Created by Sarah Renfro on 12/6/2018.
 */

public without sharing class CSCancellationScheduler implements Schedulable{
    public void execute(SchedulableContext sc){
        CSAccountCanceller.handleOverdueAccounts();
    }
}