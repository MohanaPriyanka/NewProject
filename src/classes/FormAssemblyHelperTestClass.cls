@isTest
public class FormAssemblyHelperTestClass {
    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
        profile = SLPUserHelper.getPartnerProfile();
    }

    @isTest static void testAddNewLeadRecord() {    	
        String url;
        String formId;        
        Map<String, String> formTestMap = new Map<String, String>();
		List<String> emailList = new List<String>();        
        formTestMap.put('648', (String)profile.partnerId);
        formTestMap.put('649', (String)profile.salesRepId);
        formTestMap.put('529', emailList.get(0));
        url = FormAssemblyHelper.createFormAssemblyUrl('381613', formTestMap);    	
       FormAssemblyHelper.createFormAssemblyUrl(formId, formTestMap);                       
	}
}