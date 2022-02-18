/**
 * Created by Kristin White
 * 
 * Used to create a map collection in flows
 * (https://forcepanda.wordpress.com/2019/12/17/how-to-create-a-map-collection-in-flows-part-1/)
 */
public class FlowMap {
    @AuraEnabled public String key;
    @AuraEnabled public String value;
    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public FlowMap() {
    }
    
    public FlowMap(String key, String value) {
        this.key = key;
        this.value = value;
    }
}