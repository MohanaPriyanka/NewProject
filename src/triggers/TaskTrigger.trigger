trigger TaskTrigger on Task (before update, before insert, after insert, after update) {
	CustomerCareHandler customerCareHandler = new CustomerCareHandler();
	if (Trigger.isUpdate && Trigger.isBefore) {
		customerCareHandler.isAfterUpdate(Trigger.new, Trigger.old);
	}
}