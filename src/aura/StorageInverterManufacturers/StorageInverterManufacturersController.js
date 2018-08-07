/**
 * Created by abarnes on 8/6/2018.
 */
({afterRender : function(component, event, helper) {
    this.superAfterRender();
        helper.getPicklistOptions(component, 'Residential_Equipment__c', 'Storage_Inverter_Manufacturer__c', component.find('storageInverterManufacturer'));
    }
})