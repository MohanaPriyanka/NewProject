@isTest
public class FormAssemblyHelperTestClass {

    @isTest static void testAddNewLeadRecord() {    	
        String url;
        String formId;        
        Map<String, String> formTestMap = new Map<String, String>();
        formTestMap.put('529', 'colemswain@gmail.com');
        url = FormAssemblyHelper.createFormAssemblyUrl('381613', formTestMap);    	
       FormAssemblyHelper.createFormAssemblyUrl(formId, formTestMap);                       
	}
}