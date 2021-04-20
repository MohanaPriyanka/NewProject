/**
 * @description: Extends Apex-defined Object usability with supporting methods
 * Tested By:
 */
public abstract class CustomApexObject {
    /**
     * @description Retrieves data from an apex-defined object by parameter name
     *              Used for reflection on Custom Apex-defined Objects that extend this class
     *              See https://salesforce.stackexchange.com/questions/135891/can-we-access-class-properties-dynamically-with-object-class
     * @param parameterName Case-sensitive apex object parameter name
     * @return Returns (String) data found in named parameter
     */
    public Object getParamByString(String parameterName) {
        String jsonInstance = JSON.serialize(this);
        Map<String,Object> untypedInstance = (Map<String,Object>) JSON.deserializeUntyped(jsonInstance);
        return untypedInstance.get(parameterName);
    }
}