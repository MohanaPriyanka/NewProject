import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { makeRequest } from 'c/httpRequestService';
import getContentDocumentLinksByLead from '@salesforce/apex/SimpleSignupFormController.getContentDocumentLinksByLead';
import getContentDistributionLink from '@salesforce/apex/SimpleSignupFormController.getContentDistributionById';
import { toggleLoadingSpinnerEvent, modifySpinnerMessageEvent, postReadyStateEvent, postErrorLogEvent } from "c/ssfShared";
import companyShortName from '@salesforce/label/c.SSF_Company_Short_Name';
import esignURL from '@salesforce/label/c.SSF_Esign_URL';

const DOC_GEN_TIMEOUT = 60000; // milliseconds to wait for doc generation

const onLoad = (component) => {
    toggleLoadingSpinnerEvent(component, false, 'waitingRoom');
    if (!component.lead && component.leadJson) {
        component.lead = JSON.parse(component.leadJson);
        if (component.lead.contentDocs && component.lead.contentDocs.length >= component.lead.numberOfContractDocs) {
            postProcessContractDocs(component, component.lead.contentDocs);
        }
    }
}

const onRender = (component) => {
    if (!component.contractDocuments && !component.documentPollerId) {
        getContractDocuments(component);
    }
}

const disclosureSigned = (component, event) => {
    component.disclosures = event.target.checked;
    if (event.target.checked) {
        if (component.renderCreditCheckLanguage) {
            showCreditCheckApproval(component);
        } else {
            showCSAgreementApproval(component);
        }
    }
}

const creditCheckSigned = (component, event) => {
    component.creditCheck = event.target.checked;
    if (event.target.checked) {
        showCSAgreementApproval(component);
    }
}

const communitySolarAgreementSigned = (component, event) => {
    component.csAgreement = event.target.checked;
    if (component.csAgreement) {
        const inputBox = component.template.querySelector('[data-id="consentEmail"]');
        if (inputBox) {
            inputBox.focus();
        }
    }
}

const displayDocument = (component, event) => {
    let contract;
    for (let c in component.contractDocuments) {
        if (component.contractDocuments[c].id === event.target.dataset.id) {
            contract = component.contractDocuments[c];
            break;
        }
    }

    if (contract) {
        if (component.supportsDataUri) {
            component.documentUrl = 'data:application/pdf;base64,' +  contract.body;
        } else {
            if (contract.publicUrl) {
                component.documentUrl = contract.publicUrl;
            } else {
                getContentDistributionLink({
                    leadId: component.lead.Id,
                    email: component.lead.email,
                    documentId: contract.id
                })
                .then(result => {
                    component.documentUrl = result;
                });
            }
        }
        component.showContractDocument = true;
    }
}

const showDisclosureApproval = (component) => {
    component.showDisclosures = true;
    component.disclosureIcon = 'utility:record';
    component.showCreditCheck = false;
    component.creditCheckIcon = 'utility:routing_offline';
    component.showCSAgreement = false;
    component.csAgreementIcon = 'utility:routing_offline';
}

const showCreditCheckApproval = (component) => {
    if (!validDisclosureConsent(component)) {
        return;
    }
    component.showDisclosures = false;
    component.disclosureIcon = 'utility:routing_offline';
    component.showCreditCheck = true;
    component.creditCheckIcon = 'utility:record';
    component.showCSAgreement = false;
    component.csAgreementIcon = 'utility:routing_offline';
}

const showCSAgreementApproval = (component) => {
    if (!component.renderCreditCheckLanguage && !validDisclosureConsent(component)) {
        return;
    } else if (component.renderCreditCheckLanguage && !validCreditCheckReview(component)) {
        return;
    }
    component.showDisclosures = false;
    component.disclosureIcon = 'utility:routing_offline';
    component.showCreditCheck = false;
    component.creditCheckIcon = 'utility:routing_offline';
    component.showCSAgreement = true;
    component.csAgreementIcon = 'utility:record';
}

// Indicate to server that Consents section of the application is complete
const consentsComplete = async (component) => {
    let complete;
    if (!component.renderCreditCheckLanguage) {
        // Do not check Credit Check disclosure signature since there is no underwriting for this Lead
        if (validDisclosureConsent(component) && validCSAgreement(component) && validConsentEmail(component)) {
            complete = true;
        }
    } else {
        if (validDisclosureConsent(component) && validCreditCheckReview(component) &&
            validCSAgreement(component) && validConsentEmail(component))
        {
            complete = true;
        }
    }
    if (complete) {
        modifySpinnerMessageEvent(component, 'Saving your consents...');
        toggleLoadingSpinnerEvent(component, false);
        try {
            let consentPromise = await updateServerConsentsSigned(component);
            // If contracts successfully updated on server, post consentsComplete event to bubble up
            const consentsCompleteEvent = new CustomEvent('consentscomplete', {
                detail: component.lead,
            });
            component.dispatchEvent(consentsCompleteEvent);
        } catch (error) {
            postErrorLogEvent(component, error, null,'ssfAgreementsShared', 'consentsComplete', 'Error');
            showWarningToast(
                component,
                'Oops',
                'We ran into a technical issue, please contact customer care\n' + error
            );
        }
    }
}

const updateServerConsentsSigned = async (component) => {
    let calloutURI = '/apply/services/apexrest/v3/contracts';
    let options = {
        headers: {name: 'Content-Type', value:'application/json'},
        body: JSON.stringify({ leadId: component.lead.id, email: component.lead.email, suppressAppComplete: true })
    };
    return makeRequest(calloutURI, 'PATCH', options);
}

const postProcessContractDocs = (component, contracts) => {
    let tcTitle = 'Terms and Conditions';
    let csaTitle = 'Community Solar Agreement';
    let disclosureTitle = 'Solar Disclosure Form';
    let csAgreementLoaded = false;
    let disclosureLoaded = false;
    let tempContracts = [];
    let parsedContracts = [];

    window.clearInterval(component.documentPollerId);
    window.clearTimeout(component.documentPollerTimeoutId);

    // Contract files received from server are in order of CREATED DATE DESC, so newest first
    // ... in the case of multiples of the same doc found, only include the first (which is latest created)
    contracts.forEach(contract => {
        if (contract.title.endsWith('.pdf')) {
            contract.title = contract.title.slice(0,-4);
        }
        // With W-021302, we add (Review), (Signed) or (Countersigned) to the end of filenames, that we can remove
        // for consistency
        if (contract.title.indexOf(' (') !== -1) {
            contract.title = contract.title.substring(0, contract.title.indexOf(' ('));
        }
        if (contract.title === tcTitle || contract.title === csaTitle) {
            if (!csAgreementLoaded) {
                csAgreementLoaded = true;
                component.csAgreementDocumentId = contract.id;
                tempContracts.push(contract); // Push into temporary array
            }
        }
        else if (contract.title === disclosureTitle) {
            if (!disclosureLoaded) {
                disclosureLoaded = true;
                component.disclosureDocumentId = contract.id;
                parsedContracts.push(contract); // Add to first position of array
            }
        }
    });

    // Combine contracts (with disclosure first, if found)
    // Mark first contract document with "first" attribute for markup on ssfAgreements to properly display language
    parsedContracts = parsedContracts.concat(tempContracts);
    parsedContracts[0].first = true;

    // Add all documents back into single array, and set component variable with result
    component.contractDocuments = parsedContracts;

    toggleLoadingSpinnerEvent(component, true, 'waitingRoom');
    postReadyStateEvent(component, null);
}

const getContractDocuments = (component) => {
    if (component.contractDocuments) {
        return component.contractDocuments;
    }
    if (component.version === 'PARTNER') {
        window.setTimeout(() => {
            modifySpinnerMessageEvent(component, 'Generating your documents...');
        }, 5000);
    }
    component.documentPollerId = window.setInterval(() => {
        getContentDocumentLinksByLead({
            leadId: component.lead.id,
            email: component.lead.email,
            mostRecentContractGen: component.lead.mostRecentContractGen
        })
        .then(result => {
            let docs = JSON.parse(result);
            if (docs.length >= component.lead.numberOfContractDocs) {
                postProcessContractDocs(component, docs);
            }
        })
        .catch(error => {
            postReadyStateEvent(component, 'info');
            toggleLoadingSpinnerEvent(component, true, 'waitingRoom');
            window.clearInterval(component.documentPollerId);
            window.clearTimeout(component.documentPollerTimeoutId);
            showWarningToast(
                component,
                'Error',
                'Sorry, we ran into a technical issue. Please try again by clicking “Next” or contact our Customer Care team.'
            );
            let errContext = `Unexpected error occurred for Lead ${component.lead.id}`;
            postErrorLogEvent(component, error, errContext, 'ssfAgreementsShared', 'getContractDocuments', 'Error');
        });
    }, 2000);
    component.documentPollerTimeoutId = window.setTimeout(() => {
        postReadyStateEvent(component, 'info');
        toggleLoadingSpinnerEvent(component, true, 'waitingRoom');
        window.clearInterval(component.documentPollerId);
        showWarningToast(
            component,
            'Error',
            'Oops! We had an issue generating your documents. Please try again by clicking “Next” or contact our Customer Care team.'
        );
        let error = `Contract document generation timed out for Lead ${component.lead.id}`;
        postErrorLogEvent(component, error, null, 'ssfAgreementsShared', 'getContractDocuments', 'Error');
    }, DOC_GEN_TIMEOUT);
}

const navigateBack = (component) => {
    component.dispatchEvent(new CustomEvent('navigateback', {}));
}

const validDisclosureConsent = (component) => {
    if (!component.disclosures) {
        showWarningToast(
            component,
            'Sorry',
            'Please check the checkbox to consent to electronic disclosures'
        );
        return false;
    } else {
        return true;
    }
}

const validCreditCheckReview = (component) => {
    if (!component.creditCheck) {
        showWarningToast(
            component,
            'Sorry',
            getCreditErrorToastMessage(component)
        );
        return false;
    } else {
        return true;
    }
}

const validCSAgreement = (component) => {
    if (!component.csAgreement) {
        showWarningToast(
            component,
            'Sorry',
            'Please check the checkbox to agree to the Community Solar agreement and disclosure'
        );
        return false;
    } else {
        return true;
    }
}

const validConsentEmail = (component) => {
    if (component.lead.email.toLowerCase() !== component.consentEmail.toLowerCase()) {
        showWarningToast(
            component,
            'Sorry',
            'Please enter the email address that you previously provided to acknowledge consents'
        );
        return false;
    } else {
        return true;
    }
}

const showWarningToast = (component, title, message) => {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: 'warning'
    });
    component.dispatchEvent(evt);
}

const getCreditErrorToastMessage = (component) => {
    if (component.isFicoUnderwriting) {
        return 'Please check the checkbox to authorize credit and utility billing review';
    }
    if (component.isFinDocsUnderwriting) {
        return 'Please check the checkbox to authorize financial and utility billing review';
    }
    if (component.isUtilityDataConsentOnly) {
        return 'Please check the checkbox to authorize utility billing review';
    }
}

const getText = (component, identifier) => {
    switch (identifier) {
        case 'fico1':
            return ficoLanguage1(component);
        case 'fico2':
            return ficoLanguage2();
        case 'finDocs1':
            return finDocsLanguage1();
        case 'finDocs2':
            return finDocsLanguage2();
        case 'utilityDataReview':
            return utilityDataReviewLanguage();
        case 'disclosure1':
            return disclosureLanguage1(component);
        case 'disclosure2':
            return disclosureLanguage2();
        case 'agree1':
            return agreementLanguage1(component);
        case 'agree2':
            return agreementLanguage2();
        case 'agree3':
            return agreementLanguage3();
        case 'esignUrl':
            return esignURL;
        case 'creditCheckLabel':
            return creditCheckLabel(component);
        default:
            return null;
    }
}
const creditCheckLabel = (component) => {
    if (component.isFicoUnderwriting) {
        return 'Check to Authorize Credit and Utility Billing Review';
    }
    else if (component.isFinDocsUnderwriting) {
        return 'Check to Authorize Financial and Utility Billing Review';
    }
    else if (component.isUtilityDataConsentOnly) {
        return 'Check to Authorize Utility Billing Review';
    }
}

const disclosureLanguage1 = (component) => {
    return `By checking this box, entering my email address in the Email field below, and clicking the "${component.continueButtonLabel}"`+
           ` button, I acknowledge that I have reviewed and agree to the ${companyShortName} ` /* E-SIGN DISCLOSURE */;
}

const disclosureLanguage2 = () => {
    return ` and consent to receive electronic disclosures. The device I will use to receive and access electronic disclosures`+
           ` meets the hardware and software requirements described in the ESIGN Consent Disclosure.`;
}

const ficoLanguage1 = (component) => {
    return  `By checking this box, and clicking the “${component.continueButtonLabel}” button, I am providing my electronic`+
            ` signature and signing an electronic record that is my written authorization giving ${companyShortName} and/or its designee(s)`+
            ` and/or sales partners permission to perform one or more soft pulls of one or more consumer reports showing my credit`+
            ` history (which will NOT impact my credit score) and to access my electric utility billing history. I am also giving`+
            ` ${companyShortName} and/or its designee(s) and/or sales partners my permission to use my credit history and my electric utility`+
            ` billing history to determine whether I qualify to participate in one or more community solar projects and for any`+
            ` other lawful purpose`;
}
const ficoLanguage2 = () => {
    return `. I understand that ${companyShortName} and/or its designee(s) and/or sales partners may share my consumer`+
           ` report(s) with third parties that participate in the transaction(s) contemplated by my application (including but not`+
           ` limited to the owner or developer of a community solar project) and/or any party that intends to use the information as`+
           ` a potential investor, servicer or insurer in connection with a valuation of or an assessment or the risks associated`+
           ` with any agreement I enter into with ${companyShortName} pursuant to my application. I understand that if I ask ${companyShortName} whether`+
           ` it checked my credit, it will tell me, and if it did, provide the name and address of the consumer reporting agency or`+
           ` agencies that provided the information. `;
}

const finDocsLanguage1 = () => {
    return `Customer will promptly provide to us, in connection with Customer’s application and from time to time in connection`+
           ` with this Agreement, copies of Customer’s audited Financial Statements for each of the three (3) years prior to the`+
           ` date of our request, along with a copy of Customer’s internally generated interim Financial Statement for any period`+
           ` immediately prior to the date of our request that is not covered by such prior 3 years of Financial Statements.`+
           ` Customer’s delivery of such Financial Statements to us shall be accompanied by a written representation and warranty`+
           ` from a duly authorized officer of Customer that such Financial Statements are true and correct at the time of delivery`;
}

const finDocsLanguage2 = () => {
    return `. “Financial Statement” means a financial statement as prepared for Customer in the ordinary course of business,`+
           ` consisting of a balance sheet, statement of income, changes in stockholders equity, and statement of cash flows,`+
           ` including notes, and prepared in accordance with Generally Accepted Accounting Principles used by the Financial`+
           ` Accounting Standards Board or the American Institute of Certified Public Accountants. Customer authorizes us to`+
           ` use such Financial Statements in connection with your application, including to determine` +
           ` eligibility which may include analysis of your Financial Statements, review of your subscription, any update, renewal,`+
           ` modification or extension of this Agreement, or the collection of amounts due under this Agreement.  You understand`+
           ` that we may share any such Financial Statements with third parties that participate in the transactions contemplated`+
           ` by this Agreement (including but not limited to the Project Owner) and/or any party that intends to use the information`+
           ` as part of our eligibility determination or as a potential investor, servicer or insurer in connection with a valuation`+
           ` of or an assessment of the risks associated with this Agreement).  You certify that all information you provide to us in`+
           ` connection with your Financial Statements are true and understand that this information must be updated upon request if`+
           ` your financial condition changes. For purposes of this request and authorization, “Financial Statement” means a financial`+
           ` statement as prepared for Customer in the ordinary course of business, consisting of a balance sheet, statement of income,`+
           ` changes in stockholders equity, and statement of cash flows, including notes, and prepared in accordance with Generally`+
           ` Accepted Accounting Principles used by the Financial Accounting Standards Board or the American Institute of Certified`+
           ` Public Accountants.`;
}

const utilityDataReviewLanguage = () => {
    return `By checking this box, and clicking the “Finish” button, I am providing my electronic signature and signing an electronic`+
           ` record that is my written authorization giving ${companyShortName} permission to access my electric utility billing history. I am`+
           ` also giving ${companyShortName} my permission to use my electric utility billing history to process my application and for any`+
           ` other lawful purpose.`;
}

const agreementLanguage1 = (component) => {
    return `By checking this box, entering my email address in the Email field below, and clicking the "${component.continueButtonLabel}"`+
           ` button, I acknowledge that I have reviewed and agree to the ` /* DISCLOSURE FORM, CS AGREEMENT, PRIVACY POLICY*/;
}

const agreementLanguage2 = () => {
    return `I understand that by doing so, I am providing my electronic signature and signing the agreements linked above as`+
           ` electronic records, signature is subject to the additional terms and conditions described here`;
}

const agreementLanguage3 = () => {
    return `. I am also granting ${companyShortName} permission to contact me via the phone number provided on this application. I also`+
           ` acknowledge that this is an application only and consummation of this transaction does not occur upon the `+
           ` placement of my electronic signature on this contract; rather consummation occurs (meaning that there is an`+
           ` executed agreement between ${companyShortName} and me) after ${companyShortName} verifies my eligibility, approves the document that`+
           ` I have electronically signed, and returns the contract to me with its countersignature.`;
}

export {
    onLoad,
    onRender,
    disclosureSigned,
    creditCheckSigned,
    communitySolarAgreementSigned,
    displayDocument,
    showDisclosureApproval,
    showCreditCheckApproval,
    showCSAgreementApproval,
    consentsComplete,
    navigateBack,
    getText,
}