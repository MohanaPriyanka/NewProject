public class ProductService {
    public static List<Product_Escalator__c> createEscalators(Decimal percentInflator, Decimal startingRate, Integer numberOfPeriods, Integer timeBetweenPeriods) {
        List<Product_Escalator__c> escalatorList = new List<Product_Escalator__c>();
        Product_Escalation_Schedule__c escalatorSchedule = new Product_Escalation_Schedule__c ( Name = 'AMP Old Contract: $0.1327');
        insert escalatorSchedule;

        for (Integer j = 0; j <= numberOfPeriods ; j++) {
            if (j != 0){
                startingRate = startingRate * (1 + percentInflator);
            }
            startingRate = Util.roundValue(startingRate, 4 ,'HALF_UP');
            Product_Escalator__c escalator = new Product_Escalator__c (
                Product_Escalation_Schedule__c = escalatorSchedule.Id,
                Number_of_Credit_Transfers__c = timeBetweenPeriods * j,
                New_Solar_Electricity_Rate__c = startingRate
            );
            escalatorList.add(escalator);
        }
        insert escalatorList;
        return escalatorList;
    }
}