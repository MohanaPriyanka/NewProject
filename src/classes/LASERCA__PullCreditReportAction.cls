/*
This file is generated and isn't the actual source code for this
managed global class.
This read-only file shows the class's global constructors,
methods, variables, and properties.
To enable code to compile, all methods return null.
*/
global class PullCreditReportAction {
    global PullCreditReportAction() {

    }
    @InvocableMethod(label='Pull Credit Report')
    global static void sendRequest(List<LASERCA.PullCreditReportAction.PullCreditReportActionRequest> requests) {

    }
global class PullCreditReportActionException extends Exception {
}
global class PullCreditReportActionRequest {
    @InvocableVariable(label='Birthdate' description='Applicant Birthdate' required=false)
    global Date birthDate;
    @InvocableVariable(label='Co-Applicant Birthdate' description='' required=false)
    global Date coApplicantBirthDate;
    @InvocableVariable(label='Co-Applicant First Name' description='' required=false)
    global String coApplicantFirstName;
    @InvocableVariable(label='Co-Applicant Last Name' description='' required=false)
    global String coApplicantLastName;
    @InvocableVariable(label='Co-Applicant Social Security Number' description='' required=false)
    global String coApplicantSSN;
    @InvocableVariable(label='Credit Bureus' description='Credit Bureaus separated by semi-colon' required=false)
    global String creditBureaus;
    @InvocableVariable(label='First Name' description='Applicant First NameApplicant First Name' required=false)
    global String firstName;
    @InvocableVariable(label='Home Address' description='Applicant Home Address' required=false)
    global String homeAddress;
    @InvocableVariable(label='Home City' description='Applicant Home City' required=false)
    global String homeCity;
    @InvocableVariable(label='Home Country' description='Applicant Home Country' required=false)
    global String homeCountry;
    @InvocableVariable(label='Home State' description='Applicant Home State' required=false)
    global String homeState;
    @InvocableVariable(label='Home Zip' description='Applicant Home Zip' required=false)
    global String homeZip;
    @InvocableVariable(label='Last Name' description='Applicant Last Name' required=false)
    global String lastName;
    @InvocableVariable(label='Login Account Username' description='Credit API Account Username' required=false)
    global String loginAccount;
    @InvocableVariable(label='Middle Name' description='Applicant Middle Name' required=false)
    global String middleName;
    @InvocableVariable(label='SObject Id' description='Id of the record related to the Personal Credit Report' required=false)
    global Id relatedObjectId;
    @InvocableVariable(label='Request Type' description='Default to "Submit"' required=false)
    global String requestType;
    @InvocableVariable(label='Social Security Number' description='Applicant Social Security Number' required=false)
    global String ssn;
    global PullCreditReportActionRequest() {

    }
}
}
