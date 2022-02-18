/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Description: Used to modify and insert products and related objects
 * Test: ProductServiceTest
 *************************************************************************************/
public class ProductService {

    // Creates escalation schedules for products that change rates over time (PPA that increases at a fixed %)
    // For ex) A $0.1327 PPA that increases by 1.9% every 12 credit transfers for the length of the contract
    // would have parameters: createEscalators(0.019, 0.1327, 20, 12)
    public static Product_Escalation_Schedule__c createEscalationSchedule(Decimal percentInflator, Decimal startingRate, Integer numberOfPeriods, Integer creditTransfersBetweenPeriods) {
        List<Product_Escalator__c> escalatorList = new List<Product_Escalator__c>();
        Product_Escalation_Schedule__c escalatorSchedule = new Product_Escalation_Schedule__c (
            Name = 'Product Escalator: ' + startingRate + ' ' + percentInflator  + ' ' +  numberOfPeriods
        );
        insert escalatorSchedule;

        for (Integer j = 0; j <= numberOfPeriods ; j++) {
            startingRate = Util.roundValue(startingRate, 4 ,'HALF_UP');
            Product_Escalator__c escalator = new Product_Escalator__c (
                Product_Escalation_Schedule__c = escalatorSchedule.Id,
                Starting_Credit_Transfer__c = creditTransfersBetweenPeriods * j,
                New_Solar_Electricity_Rate__c = startingRate
            );
            escalatorList.add(escalator);
            startingRate = startingRate * (1 + percentInflator);
        }
        insert escalatorList;

        Product_Escalation_Schedule__c escalationSchedule = [
            SELECT Id,
                (SELECT Id, Name, Starting_Credit_Transfer__c, New_Solar_Electricity_Rate__c
                FROM Product_Escalators__r
                ORDER BY Starting_Credit_Transfer__c)
            FROM Product_Escalation_Schedule__c
            WHERE Id = : escalatorSchedule.Id];
        
        return escalationSchedule;
    }
}