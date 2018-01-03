@isTest
public class MarketingInventoryTestClass {
    @testSetup public static void setupTestData(){
    	Campaign campaign = new Campaign(Name='Campaign');
    	insert campaign;

    	Marketing_Inventory__c marketingInventory = new Marketing_Inventory__c(Name='Marketing Inventory');
    	insert marketingInventory;

    	Marketing_Inventory_Item__c marketingInventoryItemPen = new Marketing_Inventory_Item__c(Name='Pens', Marketing_Inventory__c=marketingInventory.Id, Unit_Price__c=0.2);
    	insert marketingInventoryItemPen;

    	Marketing_Inventory_Item__c marketingInventoryItemBottle = new Marketing_Inventory_Item__c(Name='Bottles', Marketing_Inventory__c=marketingInventory.Id, Unit_Price__c=0.6);
    	insert marketingInventoryItemBottle;  

    	Marketing_Inventory_Order__c marketingInventoryOrder = new Marketing_Inventory_Order__c(Name='Order', Marketing_Inventory__c=marketingInventory.Id, Status__c='In Process');
    	insert marketingInventoryOrder;  	

    	Marketing_Inventory_Item_Order__c marketingInventoryItemOrderPens = new Marketing_Inventory_Item_Order__c(Name='MIOP', Quantity__c=500, Marketing_Inventory_Item__c=marketingInventoryItemPen.Id, Marketing_Inventory_Order__c=marketingInventoryOrder.Id);
    	insert marketingInventoryItemOrderPens;

    	Marketing_Inventory_Item_Order__c marketingInventoryItemOrderBottles = new Marketing_Inventory_Item_Order__c(Name='MIOB', Quantity__c=100, Marketing_Inventory_Item__c=marketingInventoryItemBottle.Id, Marketing_Inventory_Order__c=marketingInventoryOrder.Id);
    	insert marketingInventoryItemOrderBottles;    	

    	Campaign_Inventory_Log__c campaignInventoryLog = new Campaign_Inventory_Log__c(Name='Pens', Marketing_Inventory_Item__c=marketingInventoryItemPen.Id, Campaign__c=campaign.Id, Inventory_Required__c=300);
    	insert campaignInventoryLog;

    }
    @isTest static void testMarketingOrderStatus() {
    	List<Marketing_Inventory_Item_Order__c> itemOrdersToUpdate = new List<Marketing_Inventory_Item_Order__c>();
    	for (Marketing_Inventory_Item_Order__c itemOrder : [SELECT Id, Status__c FROM Marketing_Inventory_Item_Order__c]) {
    		itemOrder.Status__c = 'Delivered';
    		itemOrdersToUpdate.add(itemOrder);
    	}
    	update itemOrdersToUpdate;
    	Marketing_Inventory_Order__c order = [SELECT Id, Status__c FROM Marketing_Inventory_Order__c];    	
    	System.assertEquals(order.Status__c, 'Complete');
    }
}