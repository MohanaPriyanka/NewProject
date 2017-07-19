public class CustomerCareHandler {
	public  void isAfterUpdate (List<Task> updatedTasks, List<Task> oldTask) {
        //instantiate the Map for old values
        Map <Id, Task> oldvalues = new Map <Id, Task> (); 
        List <Task> triggeredvalues = new List <Task> ();

        //Fill the map with the old values        
        for(Task oldtaskvalue : oldTask) {
        	oldvalues.put(oldtaskvalue.id, oldtaskvalue);
        }

        //Check if old value = new value
        for(Task checkvalue : updatedTasks){
        	String newvalueID = checkvalue.Id;
        	//Checking status of the checkbox 
        	Boolean newbox = checkvalue.Customer_Care_Case__c;
        	Boolean oldbox = oldvalues.get(newvalueId).Customer_Care_Case__c;
        	if(newbox != oldbox){
        		triggeredvalues.add(checkvalue);
        	}

        }

        //Call method to create a new case
        for(Task triggercase : triggeredvalues){
        	String subject = triggercase.Subject;
        	String status = 'New';

            //Check type (Lead vs. Contact)

            String taskID = String.valueOf(triggercase.WhoId);
            String customertype =  taskID.substring(0, 3);

            system.debug('Customer Type: ' + customertype);

            Lead leadname = null;
            Contact contactname = null;

            if(customertype.equals( '00Q')){

            	leadname = [SELECT Id, Name FROM Lead WHERE Id = :triggercase.WhoId];
            	system.debug('Set the Lead ' + leadname);

            	} else {
            		contactname = [SELECT Id, Name FROM Contact WHERE Id = :triggercase.WhoId];
            		system.debug('Set the Contact '+ contactname);
            	}

            	Case newcase = createCustomerCase(subject, status, customertype, leadname, contactname);
            //Write code to open new case in window 
            upsert newcase;

            String uniqueID = newcase.Id;
            system.debug('Unique ID: ' + uniqueID);

            triggercase.Customer_Case_Unique_ID__c = uniqueID; 

        }
    }

    public Case createCustomerCase(String subject, String status, String customertype, Lead leadname, Contact contactname){
    	Id caseId = '012j00000000HA8';

    	//Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Care Case').getRecordTypeId();
    	Boolean islead = null;

    	//Check type of customer
    	if(customertype.equals('00Q')){
    		islead = true;
    		} else {
    			islead = false;
    		}

    		//Create case for a Lead
    		if(islead == true){
    			Case newcase = new Case(
    				Subject = subject,
    				Status = status, 
    				Lead_Lookup__c = leadname.Id,
    				RecordTypeId = caseId
    				);
    			return newcase;
    			//Create a case for a Contact
    			}else{

    				system.debug('Time to create a contact case!');

    				Case newcase = new Case(
    					Subject = subject,
    					Status = status, 
    					ContactId = contactname.Id,
    					RecordTypeId = caseId
    					);
    				return newcase;
    			}
    		}
    	}