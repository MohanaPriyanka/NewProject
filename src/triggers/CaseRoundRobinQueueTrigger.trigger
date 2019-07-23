trigger CaseRoundRobinQueueTrigger on Case_Round_Robin_Queue__c (before insert, before update,after insert, after update, after delete) {
	List<Case_Round_Robin_Queue__c> records = trigger.isDelete ? trigger.old : trigger.new;

	if(trigger.isBefore){
		if(trigger.isInsert){
			RoundRobinHandler.setStandardQueueIds(records);
		}else if(trigger.isUpdate){
			RoundRobinHandler.setStandardQueueIds(records);
		}else if(trigger.isDelete){}
	}else if(trigger.isAfter){
		if(trigger.isInsert){
			RoundRobinUtils.updateCustomSetting('Case',records);
		}else if(trigger.isUpdate){	
			RoundRobinUtils.updateCustomSetting('Case',records);
		}else if(trigger.isDelete){		   
			RoundRobinUtils.updateCustomSetting('Case',records);
		}
		//else if(trigger.isUndelete)
		//{	  
		//}
	}
}