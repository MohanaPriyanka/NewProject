trigger TaskTrigger on Task (before update, before insert, after insert, after update) {
	CustomerCareHandler customerCareHandler = new CustomerCareHandler();
	if (Trigger.isUpdate && Trigger.isBefore) {
		customerCareHandler.createCases(Trigger.new, Trigger.oldMap);
	}
	if (Trigger.isInsert && Trigger.isBefore) {
		TaskHandler.moveTaskToConvertedContact(Trigger.new);
	}
}