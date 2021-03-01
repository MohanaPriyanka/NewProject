/**
 * Created by Kristin White
 */
public class FlowMap {
    // key is the text you want to replace
    @AuraEnabled
    public String key;
    
    // values is the text you want to insert
    @AuraEnabled
    public String value;
    
    public FlowMap(String key, String value){
        this.key = key;
        this.value = value;
    }
}