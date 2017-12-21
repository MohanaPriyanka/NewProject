public class MarketingInventoryItemOrderHandler {
    public void updateInventoryOrderStatus(Map<Id, Marketing_Inventory_Item_Order__c> newItemOrderMap, Map<Id, Marketing_Inventory_Item_Order__c> oldItemOrderMap) {
    	Integer deliveredOrders = 0;
    	List<String> orderIdList = new List<String>();
    	List<Marketing_Inventory_Order__c> ordersToUpdate = new List<Marketing_Inventory_Order__c>();
    	List<Marketing_Inventory_Item_Order__c> itemOrdersToUpdate = new List<Marketing_Inventory_Item_Order__c>();

    	for (Marketing_Inventory_Item_Order__c itemOrder : newItemOrderMap.values()) {
    		if (itemOrder.Status__c != oldItemOrderMap.get(itemOrder.Id).Status__c) {
    			orderIdList.add(itemOrder.Marketing_Inventory_Order__c);    			
    		}
    	}
    	for (Marketing_Inventory_Order__c order : [SELECT Id, Name, Status__c,
    												(SELECT Id, Name, Status__c 
    												 FROM Marketing_Inventory_Item_Orders__r)
    											   FROM Marketing_Inventory_Order__c
    											   WHERE Id IN : orderIdList]) {
    		for (Marketing_Inventory_Item_Order__c itemOrder : order.Marketing_Inventory_Item_Orders__r) {
    			if (itemOrder.Status__c == 'Delivered') {
    				deliveredOrders = deliveredOrders + 1;
    				itemOrder.Delivery_Date__c = Date.today();
    				itemOrdersToUpdate.add(itemOrder);
    			} else {
    				itemOrder.Delivery_Date__c = null;
    				itemOrdersToUpdate.add(itemOrder);    				
    			}
    		} 	
	    	if (deliveredOrders == order.Marketing_Inventory_Item_Orders__r.size()) {
	    		order.Status__c = 'Complete';
	    		order.Completion_Date__c = Date.today();
	    		ordersToUpdate.add(order);
	    	} else {
	    		if (order.Status__c == 'Complete') {
	    			order.Status__c = 'In Process';
	    			order.Completion_Date__c = null;
	    			ordersToUpdate.add(order);
	    		}
	    	}
	    }
	    if (!ordersToUpdate.isEmpty()) {
	    	update ordersToUpdate;
	    }
	    if (!itemOrdersToUpdate.isEmpty()) {
	    	update itemOrdersToUpdate;
	    }	    
	}	
}