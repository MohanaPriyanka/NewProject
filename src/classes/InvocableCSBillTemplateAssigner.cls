/* Created by Jordan Pentaleri on 2/11/19
Tested by: CongaTemplateAssignerTest
*/

public class InvocableCSBillTemplateAssigner {

    @InvocableMethod(   label='CongaTemplateAssigner'
                        description='Assigns a conga template to ABs to prep for PDF generation')
    public static void assignTemplates(){
        CongaTemplateAssigner templateAssigner = new CongaTemplateAssigner();
        templateAssigner.executeBatch();
    }
}