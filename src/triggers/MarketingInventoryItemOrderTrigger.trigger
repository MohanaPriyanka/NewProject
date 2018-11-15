trigger MarketingInventoryItemOrderTrigger on Marketing_Inventory_Item_Order__c (before insert, after insert, before update, after update) {
	MarketingInventoryItemOrderHandler marketingInventoryItemOrderHandler = new MarketingInventoryItemOrderHandler();
	if (Trigger.isInsert && Trigger.isBefore) {
	}

	if (Trigger.isInsert && Trigger.isAfter) {
	}

	if (Trigger.isUpdate && Trigger.isBefore) {
	}

	if (Trigger.isUpdate && Trigger.isAfter) {
		marketingInventoryItemOrderHandler.updateInventoryOrderStatus(Trigger.newMap, Trigger.oldMap);
	}
}