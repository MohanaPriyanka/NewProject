/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class is used with the ProductionUpdateHelper lightning component (used on the VF page ShowUASes)
 + * When the "Preview Bills" button is hit on a Production Update, this finds all related UASes and 
 + * calculates what their bill will be (NMCs allocated and then with 10% discount)
 + * 
 + * Tested By: TestBillCreationandPayment3
 + *************************************************************************************/


public without sharing class PreviewProductionUpdateResults{

	@AuraEnabled
    public static List<UASB__c> getUASes (String parentId, Boolean isProdUpdate) {
    	system.debug(isProdUpdate);
    	List<UASB__c> newBillList = new List<UASB__c> ();
    	if (isProdUpdate) {
	    	Energy_Usage_Update__c production = [SELECT Name, Id, Shared_Solar_System__c, YearDate__c,
	    											MonthDate__c, Total_System_NMCs__c, Generate_Bills__c
	    										FROM Energy_Usage_Update__c
	    										WHERE Id = : parentId];
	    	List<Utility_Account_Subscription__c> uasList = [	
	    			SELECT 	Name, Customer_Subscription_KW_DC_STATIC__c, Opportunity__r.Shared_Solar_System__c,
	    					Name_on_Account_From_Log__c, Share_of_System__c, Next_Schedule_Z_Status__c
	    			FROM Utility_Account_Subscription__c
	    			WHERE Utility_Account_Log__c != null
					AND Opportunity__c != null 
					AND Customer_Group__c != 'Anchor'
					AND Next_Schedule_Z_Status__c != 'Cancelled'
					AND Next_Schedule_Z_Status__c != 'Not Enacted: Addition'
			        AND Opportunity__r.Shared_Solar_System__c = : production.Shared_Solar_System__c 
			        ORDER BY Name_on_Account_From_Log__c];
			for (Utility_Account_Subscription__c uas : uasList) {
				if (uas.Customer_Subscription_KW_DC_STATIC__c != NULL) {
					UASB__c newBill = new UASB__c (	
						Name = 'PreGenerated Bill',
						PreGen_IsPreGen__c = production.Generate_Bills__c, 
						PreGen_Discounted_Bill__c = (uas.Share_of_System__c.setScale(4)/100 * production.Total_System_NMCs__c)*.9,
						PreGen_NMCs_Allocated__c = uas.Share_of_System__c.setScale(4)/100 * production.Total_System_NMCs__c,
						PreGen_Name_on_Account__c = uas.Name_on_Account_From_Log__c,
						PreGen_Production_Update__c = production.MonthDate__c + ' '+ production.YearDate__c,
						PreGen_Schedule_Z_Status__c = uas.Next_Schedule_Z_Status__c,
						PreGen_System_Share__c = uas.Share_of_System__c.setScale(4),
						PreGen_Utility_Acct__c = uas.Name);
					newBillList.add(newBill);
				}
			}
			system.debug(newBillList);
			return newBillList;

		} else {
	    	List<Id> sssList = new List<Id> ();
	    	
	    	List<Utility_Account_Subscription__c> uasListFromAcct = [	
	    			SELECT 	Name, Customer_Subscription_KW_DC_STATIC__c, Opportunity__r.Shared_Solar_System__r.Id,
	    					Name_on_Account_From_Log__c, Share_of_System__c, Next_Schedule_Z_Status__c
	    			FROM Utility_Account_Subscription__c
	    			WHERE Utility_Account_Log__c != null
					AND Opportunity__c != null 
					AND Customer_Group__c != 'Anchor'
					AND Next_Schedule_Z_Status__c != 'Cancelled'
					AND Next_Schedule_Z_Status__c != 'Not Enacted: Addition'
					AND Utility_Account_Log__r.Account__r.Id = : parentId
			        ORDER BY Name];
			for (Utility_Account_Subscription__c uasOne : uasListFromAcct) {
				sssList.add(uasOne.Opportunity__r.Shared_Solar_System__c); 
			}
			List<Energy_Usage_Update__c> productionList = [SELECT Name, Id, Shared_Solar_System__c, Generate_Bills__c,
															Total_System_NMCs__c, Shared_Solar_System__r.Id
	    													FROM Energy_Usage_Update__c
	    													WHERE Shared_Solar_System__r.Id IN : sssList
	    													ORDER BY Date__c ];
			for (Utility_Account_Subscription__c subscription : uasListFromAcct) {
				for (Energy_Usage_Update__c productionUpdate : productionList) {
					if (subscription.Opportunity__r.Shared_Solar_System__r.Id == productionUpdate.Shared_Solar_System__r.Id
					 	&& !productionUpdate.Generate_Bills__c) {	
							UASB__c newBill = new UASB__c (	
								Name = 'PreGenerated Bill',
								PreGen_IsPreGen__c = False, 
								PreGen_Discounted_Bill__c = (subscription.Share_of_System__c.setScale(4)/100 * productionUpdate.Total_System_NMCs__c)*.9,
								PreGen_NMCs_Allocated__c = subscription.Share_of_System__c.setScale(4)/100 * productionUpdate.Total_System_NMCs__c,
								PreGen_Name_on_Account__c = subscription.Name_on_Account_From_Log__c,
								PreGen_Production_Update__c = productionUpdate.Name,
								Utility_Account_Subscription__c = subscription.Id,
								PreGen_Schedule_Z_Status__c = subscription.Next_Schedule_Z_Status__c,
								PreGen_System_Share__c = subscription.Share_of_System__c.setScale(4),
								PreGen_Utility_Acct__c = subscription.Name);
							newBillList.add(newBill);
					}
				}
			}
	    	List<UASB__c> oldBillList = new List<UASB__c> ();
	    	List<UASB__C> uasbList = [	SELECT  Utility_Account_Subscription__r.Name, Shared_Solar_System__c,
	    									Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
	    									Utility_Account_Subscription__r.Share_of_System__c, 
	    									Production_Update__r.Name,
	    									Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
	    									Net_Metering_Credits_Allocated__c, Discounted_Bill__c
	    								FROM UASB__c
	    								WHERE System_Bill__r.Property_Account_ID__c = : parentId
	    								ORDER BY Date__c DESC];

	    	for (UASB__c oldBill : uasbList) {
	    		UASB__c modifiedBill = new UASB__c (	
	    			Name = 'Old Bill',
					PreGen_IsPreGen__c = True, 
					PreGen_Discounted_Bill__c = oldBill.Discounted_Bill__c,
					PreGen_NMCs_Allocated__c = oldBill.Net_Metering_Credits_Allocated__c,
					PreGen_Name_on_Account__c = oldBill.Utility_Account_Subscription__r.Name_on_Account_From_Log__c,
					PreGen_Production_Update__c = oldBill.Production_Update__r.Name ,
					Utility_Account_Subscription__c = oldBill.Id,
					PreGen_Schedule_Z_Status__c = oldBill.Utility_Account_Subscription__r.Next_Schedule_Z_Status__c,
					PreGen_System_Share__c =  oldBill.Utility_Account_Subscription__r.Share_of_System__c.setScale(4), 
					PreGen_Utility_Acct__c = oldBill.Utility_Account_Subscription__r.Name);
				newBillList.add(modifiedBill);
	    	}
	    	system.debug(newBillList);
			return newBillList;

	    }
    }

    @AuraEnabled
    public static List<ChargentOrders__Transaction__c> getTransactions (String accountLookup) {
		List<ChargentOrders__Transaction__c> transactionList = [ SELECT Name, Id, ChargentOrders__Gateway_Date__c, ChargentOrders__Amount__c,
																ChargentOrders__Response_Status__c, ChargentOrders__Gateway__r.Name, 
																ChargentOrders__Order__r.ChargentOrders__Payment_Status__c
	    														FROM ChargentOrders__Transaction__c
	    														WHERE Property_Account_ID__c = : accountLookup 
	    														ORDER BY  ChargentOrders__Gateway_Date__c DESC];
    	return transactionList;
    }
}