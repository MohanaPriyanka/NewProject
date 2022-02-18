/**
 * @description Helps UtilityDataRequestService calculate Annual kWh and Average Demand using KH and K1 UDRPs
 * Tested By: UtilityDataRequestServiceTest
 */
public with sharing class UDRWrapper {
    private Id udrId;
    private List<Utility_Data_Request_Period__c> listKH51;
    private List<Utility_Data_Request_Period__c> listKH40s;
    private List<Utility_Data_Request_Period__c> listK151;
    private List<Utility_Data_Request_Period__c> listK140s;
    public UDRWrapper(Id udrId) {
        this.udrId = udrId;
        this.listKH51 = new List<Utility_Data_Request_Period__c>();
        this.listKH40s = new List<Utility_Data_Request_Period__c>();
        this.listK151 = new List<Utility_Data_Request_Period__c>();
        this.listK140s = new List<Utility_Data_Request_Period__c>();
    }
    public void addUDRPs(List<Utility_Data_Request_Period__c> udrps) {
        for (Utility_Data_Request_Period__c udrp : udrps) {
            add(udrp);
        }
    }
    private void add(Utility_Data_Request_Period__c udrp) {
        if (appliesToKH51(udrp.Measurement_Unit__c, udrp.Measurement_Significance_Code__c)) {
            listKH51.add(udrp);
        } else if (appliesToKH40(udrp.Measurement_Unit__c, udrp.Measurement_Significance_Code__c)) {
            listKH40s.add(udrp);
        } else if (appliesToK151(udrp.Measurement_Unit__c, udrp.Measurement_Significance_Code__c)) {
            listK151.add(udrp);
        } else if (appliesToK140(udrp.Measurement_Unit__c, udrp.Measurement_Significance_Code__c)) {
            listK140s.add(udrp);
        }
    }
    private Boolean appliesToKH51(String measurementUnit, String significanceCode) {
        return (measurementUnit == 'KH' && significanceCode == '51');
    }
    private Boolean appliesToKH40(String measurementUnit, String significanceCode) {
        return (measurementUnit == 'KH' && (significanceCode == '41' || significanceCode == '42' || significanceCode == '43'));
    }
    private Boolean appliesToK151(String measurementUnit, String significanceCode) {
        return (measurementUnit == 'K1' && significanceCode == '51');
    }
    private Boolean appliesToK140(String measurementUnit, String significanceCode) {
        return (measurementUnit == 'K1' && (significanceCode == '42' || significanceCode == '49'));
    }

    public List<Utility_Data_Request_Period__c> getListKH() {
        if (this.listKH51.size() > 0) {
            return this.listKH51;
        } else {
            return this.listKH40s;
        }
    }
    public List<Utility_Data_Request_Period__c> getListK1() {
        if (this.listK151.size() > 0) {
            return this.listK151;
        } else {
            return this.listK140s;
        }
    }
}