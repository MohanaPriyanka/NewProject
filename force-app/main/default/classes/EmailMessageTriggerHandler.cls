/**
 * @description Trigger handler for EmailMessage
 * Tested by: EmailMessageTriggerTest      
 */
public class EmailMessageTriggerHandler {
    private Map<Id, EmailMessage> oldMap;
    private Map<Id, EmailMessage> newMap;
    private List<EmailMessage> newList;

    public EmailMessageTriggerHandler(Map<Id,EmailMessage > oldMap, Map<Id, EmailMessage> newMap, List<EmailMessage> newList) {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.newList = newList;
    }
    public void afterInsert() {
        reopenCaseOnEmail();
    }
    public void reopenCaseOnEmail() {        
        Set<Id> listIds = new Set<Id>();      
        for (EmailMessage eMsg : newList) {
            if(eMsg.Incoming)
                listIds.add(eMsg.RelatedToId);            
        }
         if(listIds.size()==0){
             return;
         }                 
            List<Case> caseUpdate = [Select Id, Status,Subject,isClosed From Case where ID IN: listIds AND isClosed=true];
            for (Case cs : caseUpdate) {            
                cs.status= 'New Email Arrived';
            }        
            if(caseUpdate!=null && caseUpdate.size()> 0)
            {
                update caseUpdate;
            }
        }
}