public class FormAssemblyHelper {
    public static String createFormAssemblyUrl(String formId, Map<String, String> parametersMap) {
        String url;
        String urlDomain = 'https://forms.bluewaverenewables.com/' + formId + '?';
        String urlParameterSection;
        Integer aliasCount = 0;
        for (String alias : parametersMap.keySet()) {
            aliasCount = aliasCount + 1;
            if (urlParameterSection == null) {
	            urlParameterSection = 'tfa_' + alias + '=' + parametersMap.get(alias);        	
            } else {
	            urlParameterSection = urlParameterSection + 'tfa_' + alias + '=' + parametersMap.get(alias);        	            	
            }
            if (aliasCount != parametersMap.size()) {
                urlParameterSection = urlParameterSection + '&';
            }
        }
        url = urlDomain + urlParameterSection;
        return url;
    }   
}