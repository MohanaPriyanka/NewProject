@isTest
private class mapAvailableCapacityTest{
	static testMethod void mapAvailableCapacity(){
		Date myDate = Date.newInstance(2015, 2, 17);

		Product2 csProduct = new Product2( Name = 'Community Solar',
		                      Family = 'Community Solar',
		                      Product_Type__c = 'Community Solar',
		                      State__c = 'MA',
		                      ProductCode = 'CS - BlueWave - 10%',
		                      IsActive = True,
		                      Lender_of_Record__c = 'BlueWave',
		                      NMC_Discount__c = 10,
		                      Annual_kWh_Maximum__c = 100000000,
		                      NM_Rate_Floor__c = 0,
		                      Monthly_Late_Fee__c = 1);
		insert csProduct;


		Product2 srecProduct = new Product2( Name = 'Community Solar - SREC 16-01',
		                      Family = 'Community Solar',
		                      Product_Type__c = 'Community Solar',
		                      State__c = 'MA',
		                      ProductCode = 'CS - BlueWave - 10%',
		                      IsActive = True,
		                      Lender_of_Record__c = 'BlueWave',
		                      NMC_Discount__c = 10,
		                      Annual_kWh_Maximum__c = 100000000,
		                      NM_Rate_Floor__c = 0,
		                      Monthly_Late_Fee__c = 1);
		insert srecProduct;

		Partner__c newPartner = new Partner__c(Name = 'BlueWave Inside Sales');
        insert newPartner;

        Bsst__c newBSST = new BSST__c (Name ='PartnerOne', Partner__c = newPartner.id,
                                       Email__c = 'jpentaleri@bluewave-capital.com', Custom_Id__c = 'Partner1');
        insert newBSST;


		Load_u__c newServiceTerritory = new Load_u__c( 	Name = '02052', 
														Load_Zone__c = 'NEMA Eversource', 
														Lz__c = 'NEMA', 
														Utility__c = 'Eversource', 
														Town__c = 'Medfield');

		insert newServiceTerritory;

		Shared_Solar_System__c newSSS = 
			new Shared_Solar_System__c( Name = 'Florence', 
										Service_Territories__c = 'NEMA',
										Total_system_size_kWh_DC__c = 2000,
										Expected_Yield_kWh_kW__c = 1450,
										System_Utility__c = 'Eversource',
										Product__c = csProduct.Id,
										Sales_Partners__c = 'BlueWave Inside Sales',
										Total_CS_Capacity__c = 600);
		insert newSSS;

		Shared_Solar_System__c newSSS2 = 
			new Shared_Solar_System__c( Name = 'Spartanburg', 
										Service_Territories__c = 'NEMA',
										Total_system_size_kWh_DC__c = 10000,
										Expected_Yield_kWh_kW__c = 1450,
										System_Utility__c = 'Eversource',
										Product__c = csProduct.Id,
										Sales_Partners__c = 'All',
										Total_CS_Capacity__c = 500);
		insert newSSS2;

		Shared_Solar_System__c newSSS3 = 
			new Shared_Solar_System__c( Name = 'ProductDoesNotMatch', 
										Service_Territories__c = 'NEMA',
										Total_system_size_kWh_DC__c = 20000,
										Expected_Yield_kWh_kW__c = 1450,
										System_Utility__c = 'Eversource',
										Product__c = srecProduct.Id,
										Sales_Partners__c = 'All',
										Total_CS_Capacity__c = 500);
		insert newSSS3;

		Lead newLead = new Lead(
			FirstName = 'Cole',
			Product_Line__c = 'Community Solar',
			LastName = 'Swain',
			Email = 'cswain@bluewave-capital.com',
			Company = 'BlueWave',
			Status = 'contacted',
			Parcel_Zip__c = '02052',
			Custom_Id__c = 'Partner1',
			Product__c = csProduct.Id);
		Lead noProductLead = new Lead(FirstName = 'Kale',
			Product_Line__c = 'Community Solar',
			LastName = 'Swain',
			Email = 'cswain@bluewave-capital.com',
			Company = 'BlueWave',
			Status = 'contacted',
			Parcel_Zip__c = '02052',
			Custom_Id__c = 'Partner1');
		List<Lead> leads = new List<Lead>{newLead, noProductLead};
		insert leads;
		update leads;

        Lead lead = [
			SELECT Id, Name, Available_Capacity__c
			FROM Lead
			WHERE FirstName = 'Cole'
			LIMIT 1
		];

        System.assertEquals(12000, lead.Available_Capacity__c);

		lead = [
			SELECT Id, Name, Available_Capacity__c
			FROM Lead
			WHERE FirstName = 'Kale'
			LIMIT 1
		];

		System.assertEquals(32000, lead.Available_Capacity__c);
	}
}