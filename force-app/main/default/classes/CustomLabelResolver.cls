/**
 * @description As of writing, we can't dynamically resolve labels in apex:
 * https://ideas.salesforce.com/s/idea/a0B8W00000GdcndUAB/runtime-evaluation-of-custom-labels
 * We'd like to retrieve labels via a Tooling API query, but that requires a
 * callout and this is used when sending email messages, in a trigger context.
 * We could put labels into the platform cache ahead of time, but no way to guarantee
 * labels would be there.
 * When we figure that out, we can swap out the customLabelMap initialization for something else.
 * Tested By: CustomLabelResolverTest
 */
public without sharing class CustomLabelResolver {
    private static Pattern labelPattern = Pattern.compile('\\{!\\$Label\\.[a-zA-Z0-9_]+}');

    private static Map<String, String> customLabelMap = new Map<String, String>{
        '{!$Label.AmpBlack_Main_Logo}' => System.Label.AmpBlack_Main_Logo,
        '{!$Label.AmpRed_Main_Logo}' => System.Label.AmpRed_Main_Logo,
        '{!$Label.Client_Portal_URL}' => System.Label.Client_Portal_URL,
        '{!$Label.Company_Default_Farm_Image}' => System.Label.Company_Default_Farm_Image,
        '{!$Label.Company_Email_Icon}' => System.Label.Company_Email_Icon,
        '{!$Label.Company_Facebook}' => System.Label.Company_Facebook,
        '{!$Label.Company_Instagram}' => System.Label.Company_Instagram,
        '{!$Label.Company_LinkedIn}' => System.Label.Company_LinkedIn,
        '{!$Label.Company_Main_Logo}' => System.Label.Company_Main_Logo,
        '{!$Label.Company_Name}' => System.Label.Company_Name,
        '{!$Label.Company_Name_Customer_Acquisition}' => System.Label.Company_Name_Customer_Acquisition,
        '{!$Label.Company_Name_Customer_Management}' => System.Label.Company_Name_Customer_Management,
        '{!$Label.Company_Temp_Website}' => System.Label.Company_Temp_Website,
        '{!$Label.Company_Website}' => System.Label.Company_Website,
        '{!$Label.Customer_Acquisition}' => System.Label.Customer_Acquisition,
        '{!$Label.Customer_Management}' => System.Label.Customer_Management,
        '{!$Label.Customer_Member_Portal_URL}' => System.Label.Customer_Member_Portal_URL,
        '{!$Label.email_anchorsupport}' => System.Label.email_anchorsupport,
        '{!$Label.email_clientservices}' => System.Label.email_clientservices,
        '{!$Label.email_customercare}' => System.Label.email_customercare,
        '{!$Label.email_fin_ops}' => System.Label.email_fin_ops,
        '{!$Label.email_partnersupport}' => System.Label.email_partnersupport,
        '{!$Label.Enrollment_Portal_URL}' => System.Label.Enrollment_Portal_URL,
        '{!$Label.Internal_Classic_Salesforce_URL}' => System.Label.Internal_Classic_Salesforce_URL,
        '{!$Label.Internal_Lightning_Salesforce_URL}' => System.Label.Internal_Lightning_Salesforce_URL,
        '{!$Label.Partner_Portal_URL}' => System.Label.Partner_Portal_URL,
        '{!$Label.phone_clientservices}' => System.Label.phone_clientservices,
        '{!$Label.phone_customercare}' => System.Label.phone_customercare,
        '{!$Label.phone_insidesales}' => System.Label.phone_insidesales,
        '{!$Label.phone_partnersupport}' => System.Label.phone_partnersupport
    };

    /**
     * @description Replaces labels in text
     * @param textWithLabels Text, potential with label tags
     * @return Text without labels
     */
    public String resolve(String textWithLabels) {
        for (String label : getLabelsFromText(textWithLabels)) {
            String labelValue = customLabelMap.get(label);
            if (labelValue == null) {
                throw new Util.BWException('Unknown label found: ' + label + '. Add it to CustomLabelResolver');
            }
            textWithLabels = textWithLabels.replace(label, labelValue);
        }
        return textWithLabels;
    }

    private Set<String> getLabelsFromText(String textWithLabels) {
        Set<String> labels = new Set<String>();
        if (textWithLabels == null) {
            return labels;
        }
        Matcher matcher = labelPattern.matcher(textWithLabels);
        while (matcher.find()) {
            labels.add(textWithLabels.substring(matcher.start(), matcher.end()));
        }
        return labels;
    }
}