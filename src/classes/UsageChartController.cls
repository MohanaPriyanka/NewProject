public with sharing class UsageChartController {
    public class SavingsChartResult {
        @AuraEnabled
        public String units {get;set;}
        
        @AuraEnabled
        public Savings[] results {get;set;}
    }
    
    public class Savings {
        @AuraEnabled
        public String unit {get;set;}
        
        /*@AuraEnabled
        public Decimal production {get;set;}*/
        
        @AuraEnabled
        public Decimal savings {get;set;}
    }
    
    @AuraEnabled
    public static SavingsChartResult getTenYears() {
        return getYears(-10);
    }
    @AuraEnabled
    public static SavingsChartResult getFiveYears() {
        return getYears(-5);
    }
    @AuraEnabled
    public static SavingsChartResult getOneYear() {
        return getMonths(-12);
    }
    
    @AuraEnabled
    public static SavingsChartResult getSixMonths() {
        return getMonths(-6);
    }
    
    @AuraEnabled
    public static SavingsChartResult getOneMonth() {
        return getMonths(-1);
    }
    
    @AuraEnabled
    public static SavingsChartResult getOneDay() {
        return getToday();
    }
    
    @AuraEnabled
    public static SavingsChartResult getAll() {
        return getAllDates();
    }
    
    private static SavingsChartResult getAllDates() {
        SavingsChartResult ucr = new SavingsChartResult();
        ucr.units = 'Year';
        ucr.results = new Savings[0];
        Map<String, Decimal> savings = new Map<String, Decimal>();
        //Map<String, Decimal> production = new Map<String, Decimal>();
        String[] keys = new String[0];
        User u = [Select Id, AccountId, Parent_Account_ID__c, ContactId from User where Id = :UserInfo.getUserId()];
        if(u.ContactId != null) {
            try {
                Integer lowest;
                try {
                    //Energy_Usage_Update__c euu = [Select Id, Date__c, Production__c from Energy_Usage_Update__c where Product_Profile__c = :pp.Id and Date__c != null order by Date__c asc limit 1];
                    Account_Bill__c ab = [Select Id, Date__c, Savings_Rollup__c 
                                          from Account_Bill__c 
                                          where Account_ID__c = : u.Parent_Account_ID__c 
                                          and Date__c != null 
                                          order by Date__c asc limit 1];
                    lowest = ab.Date__c.year();
                }
                catch (Exception productionEx) {
                    
                }
                /*try {
                    Consumption_Update__c cu = [Select Id, Date__c from Consumption_Update__c where Product_Profile__c = :pp.Id and Date__c != null order by Date__c asc limit 1];
                    if(lowest == null || lowest > cu.Date__c.year())
                        lowest = cu.Date__c.year();
                }
                catch (Exception productionEx) {
                    
                }*/
                if(lowest != null) {
                    for(Integer i = (Date.today().year() - lowest); i >= 0; i--) {
                        Date d = Date.today().addYears(0 - i);
                        keys.add(d.year().format().replaceAll(',', ''));
                        savings.put(d.year().format().replaceAll(',', ''), null);
                        //production.put(d.year().format().replaceAll(',', ''), null);
                    }
                    try {
                        /*for(Energy_Usage_Update__c euu : [Select Id, Date__c, Production__c from Energy_Usage_Update__c where Product_Profile__c = :pp.Id order by Date__c]) {
                            if(euu.Date__c != null && euu.Production__c != null && production.containsKey(euu.Date__c.year().format().replaceAll(',', ''))) {
                                Decimal oldVal = production.get(euu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : production.get(euu.Date__c.year().format().replaceAll(',', ''));
                                production.put(euu.Date__c.year().format().replaceAll(',', ''),  oldVal + euu.Production__c);
                            }
                        }*/
                        for(Account_Bill__c euu : [Select Id, Date__c, Savings_Rollup__c from Account_Bill__c where Account_ID__c = : u.Parent_Account_ID__c order by Date__c]) {
                            if(euu.Date__c != null && euu.Savings_Rollup__c != null && savings.containsKey(euu.Date__c.year().format().replaceAll(',', ''))) {
                                Decimal oldVal = savings.get(euu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : savings.get(euu.Date__c.year().format().replaceAll(',', ''));
                                savings.put(euu.Date__c.year().format().replaceAll(',', ''),  oldVal + euu.Savings_Rollup__c);
                            }
                        }
                    } 
                    catch (Exception productionEx) {
                        
                    }
                    /*try {
                        for(Consumption_Update__c cu : [Select Id, Date__c, Energy_Consumption__c from Consumption_Update__c where Product_Profile__c = :pp.Id order by Date__c desc]) {
                            if(cu.Date__c != null && cu.Energy_Consumption__c != null && consumption.containsKey(cu.Date__c.year().format().replaceAll(',', ''))) {
                                Decimal oldVal = consumption.get(cu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : consumption.get(cu.Date__c.year().format().replaceAll(',', ''));
                                consumption.put(cu.Date__c.year().format().replaceAll(',', ''), oldVal + cu.Energy_Consumption__c);
                            }
                        }
                    } 
                    catch (Exception consumptionEx) {
                        
                    }*/
                }
            }
            catch(Exception ex) {
                
            }
            
        }
        for(String s : keys) {
            Savings uTemp = new Savings();
            uTemp.unit = s;
            uTemp.savings = savings.get(s);
            //uTemp.consumption = consumption.get(s);
            ucr.results.add(uTemp);
        }
        return ucr;
    }
    
    private static SavingsChartResult getYears(Integer x) {
        SavingsChartResult ucr = new SavingsChartResult();
        ucr.units = 'Year';
        ucr.results = new Savings[0];
        Map<String, Decimal> savings = new Map<String, Decimal>();
        //Map<String, Decimal> production = new Map<String, Decimal>();
        String[] keys = new String[0];
        for(Integer i = x + 1; i <= 0; i++) {
            Date d = Date.today().addYears(i);
            keys.add(d.year().format().replaceAll(',', ''));
            savings.put(d.year().format().replaceAll(',', ''), null);
            //production.put(d.year().format().replaceAll(',', ''), null);
        }
        User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
        if(u.ContactId != null) {
                try {
                    /* for(Energy_Usage_Update__c euu : [Select Id, Date__c, Production__c from Energy_Usage_Update__c where Product_Profile__c = :pp.Id order by Date__c]) {
                        if(euu.Date__c != null && euu.Production__c != null && production.containsKey(euu.Date__c.year().format().replaceAll(',', ''))) {
                            Decimal oldVal = production.get(euu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : production.get(euu.Date__c.year().format().replaceAll(',', ''));
                            production.put(euu.Date__c.year().format().replaceAll(',', ''),  oldVal + euu.Production__c);
                        }
                     }*/
                    for(Account_Bill__c euu : [Select Id, Date__c, Savings_Rollup__c from Account_Bill__c where Account_ID__c = : u.Parent_Account_ID__c order by Date__c]) {
                        if(euu.Date__c != null && euu.Savings_Rollup__c != null && savings.containsKey(euu.Date__c.year().format().replaceAll(',', ''))) {
                            Decimal oldVal = savings.get(euu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : savings.get(euu.Date__c.year().format().replaceAll(',', ''));
                            savings.put(euu.Date__c.year().format().replaceAll(',', ''),  oldVal + euu.Savings_Rollup__c);
                        }
                     }
                } 
                catch (Exception productionEx) {
                    
                }
                /*try {
                     for(Consumption_Update__c cu : [Select Id, Date__c, Energy_Consumption__c from Consumption_Update__c where Product_Profile__c = :pp.Id order by Date__c desc]) {
                        if(cu.Date__c != null && cu.Energy_Consumption__c != null && consumption.containsKey(cu.Date__c.year().format().replaceAll(',', ''))) {
                            Decimal oldVal = consumption.get(cu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : consumption.get(cu.Date__c.year().format().replaceAll(',', ''));
                            consumption.put(cu.Date__c.year().format().replaceAll(',', ''), oldVal + cu.Energy_Consumption__c);
                        }
                     }
                } 
                catch (Exception consumptionEx) {
                    
                }*/
            
        }
        for(String s : keys) {
            Savings uTemp = new Savings();
            uTemp.unit = s;
            uTemp.savings = savings.get(s);
            //uTemp.consumption = consumption.get(s);
            ucr.results.add(uTemp);
        }
        return ucr;
    }
    
    private static SavingsChartResult getMonths(Integer x) {
        SavingsChartResult ucr = new SavingsChartResult();
        ucr.units = 'Month';
        ucr.results = new Savings[0];
        Map<String, Decimal> savings = new Map<String, Decimal>();
        //Map<String, Decimal> production = new Map<String, Decimal>();
        String[] keys = new String[0];
        for(Integer i = x + 1; i <= 0; i++) {
            Date d = Date.today().addMonths(i);
            keys.add(d.month().format() + '/' + d.year().format().replaceAll(',', ''));
            savings.put(d.month().format() + '/' + d.year().format().replaceAll(',', ''), null);
            //production.put(d.month().format() + '/' + d.year().format().replaceAll(',', ''), null);
        }
        User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
        if(u.ContactId != null) {
                try {
                     /*for(Energy_Usage_Update__c euu : [Select Id, Date__c, Production__c from Energy_Usage_Update__c where Product_Profile__c = :pp.Id order by Date__c]) {
                        if(euu.Date__c != null && euu.Production__c != null && production.containsKey(euu.Date__c.month().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''))) {
                            Decimal oldVal = production.get(euu.Date__c.month().format() + '/' +euu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : production.get(euu.Date__c.month().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''));
                            production.put(euu.Date__c.month().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''),  oldVal + (euu.Production__c == null ? 0 : euu.Production__c));
                        }
                     }*/
                    for(Account_Bill__c euu : [Select Id, Date__c, Savings_Rollup__c from Account_Bill__c where Account_ID__c = : u.Parent_Account_ID__c order by Date__c]) {
                        if(euu.Date__c != null && euu.Savings_Rollup__c != null && savings.containsKey(euu.Date__c.month().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''))) {
                            Decimal oldVal = savings.get(euu.Date__c.month().format() + '/' +euu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : savings.get(euu.Date__c.month().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''));
                            savings.put(euu.Date__c.month().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''),  oldVal + (euu.Savings_Rollup__c == null ? 0 : euu.Savings_Rollup__c));
                        }
                     }
                } 
                catch (Exception productionEx) {
                    
                }
                /*try {
                     for(Consumption_Update__c cu : [Select Id, Date__c, Energy_Consumption__c from Consumption_Update__c where Product_Profile__c = :pp.Id order by Date__c desc]) {
                        if(cu.Date__c != null && cu.Energy_Consumption__c != null && consumption.containsKey(cu.Date__c.month().format() + '/' + cu.Date__c.year().format().replaceAll(',', ''))) {
                            Decimal oldVal = consumption.get(cu.Date__c.month().format() + '/' + cu.Date__c.year().format().replaceAll(',', '')) == null ? 0 : consumption.get(cu.Date__c.month().format() + '/' + cu.Date__c.year().format().replaceAll(',', ''));
                            consumption.put(cu.Date__c.month().format() + '/' + cu.Date__c.year().format().replaceAll(',', ''), oldVal + (cu.Energy_Consumption__c == null ? 0 : cu.Energy_Consumption__c));
                        }
                     }
                } 
                catch (Exception consumptionEx) {
                    
                }*/

        }
        for(String s : keys) {
            Savings uTemp = new Savings();
            uTemp.unit = s;
            uTemp.savings = savings.get(s);
            //uTemp.consumption = consumption.get(s);
            ucr.results.add(uTemp);
        }
        return ucr;
    }
    
    private static SavingsChartResult getToday() {
        SavingsChartResult ucr = new SavingsChartResult();
        ucr.units = 'Day';
        ucr.results = new Savings[0];
        Map<String, Decimal> savings = new Map<String, Decimal>();
        //Map<String, Decimal> production = new Map<String, Decimal>();
        String[] keys = new String[0];
        
        User u = [Select Id, ContactId, Parent_Account_ID__c from User where Id = :UserInfo.getUserId()];
        if(u.ContactId != null) {
                try {
                     /*Energy_Usage_Update__c euu  = [Select Id, Date__c, Production__c from Energy_Usage_Update__c where Product_Profile__c = :pp.Id and Date__c != null order by Date__c  limit 1];
                     keys.add(euu.Date__c.month().format() + '/' + euu.Date__c.day().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''));
                     production.put(euu.Date__c.month().format() + '/' + euu.Date__c.day().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''), (euu.Production__c == null ? 0 : euu.Production__c));
                     consumption.put(euu.Date__c.month().format() + '/' + euu.Date__c.day().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''), null);*/
                     Account_Bill__c euu  = [Select Id, Date__c, Savings_Rollup__c from Account_Bill__c where Account_ID__c = : u.Parent_Account_ID__c and Date__c != null order by Date__c  limit 1];
                     keys.add(euu.Date__c.month().format() + '/' + euu.Date__c.day().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''));
                     savings.put(euu.Date__c.month().format() + '/' + euu.Date__c.day().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''), (euu.Savings_Rollup__c == null ? 0 : euu.Savings_Rollup__c));
                     //consumption.put(euu.Date__c.month().format() + '/' + euu.Date__c.day().format() + '/' + euu.Date__c.year().format().replaceAll(',', ''), null);*/
                } 
                catch (Exception productionEx) {
                    
                }
                /*try {
                     Consumption_Update__c cu = [Select Id, Date__c, Energy_Consumption__c from Consumption_Update__c where Product_Profile__c = :pp.Id and Date__c != null order by Date__c desc limit 1];
                     if(!production.containsKey(cu.Date__c.month().format() + '/' + cu.Date__c.day().format() + '/' + cu.Date__c.year().format().replaceAll(',', ''))) {
                        keys.add(cu.Date__c.month().format() + '/' + cu.Date__c.day().format() + '/' + cu.Date__c.year().format().replaceAll(',', ''));
                        production.put(cu.Date__c.month().format() + '/' + cu.Date__c.day().format() + '/' + cu.Date__c.year().format().replaceAll(',', ''), null);
                     }
                     consumption.put(cu.Date__c.month().format() + '/' + cu.Date__c.day().format() + '/' + cu.Date__c.year().format().replaceAll(',', ''), (cu.Energy_Consumption__c == null ? 0 : cu.Energy_Consumption__c));
                } 
                catch (Exception consumptionEx) {
                    
                }*/
            
        }
        for(String s : keys) {
            Savings uTemp = new Savings();
            uTemp.unit = s;
            uTemp.savings = savings.get(s);
            //uTemp.consumption = consumption.get(s);
            ucr.results.add(uTemp);
        }
        return ucr;
    }
}