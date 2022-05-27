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

const displayDocument = (component, event) => {
    let contract;
    for (let contractDocument of component.contractDocuments) {
        if (contractDocument.id === event.detail.id) {
            contract = contractDocument;
            break;
        }
    }
    if (!contract) {
        return;
    }
    if (component.supportsDataUri) {
        component.documentUrl = 'data:application/pdf;base64,' +  contract.body;
    } else if (contract.publicUrl) {
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
    component.showContractDocument = true;
    contract.showError = false;
    contract.documentOpened = true;
}

const showApproval = (component, targetApproval) => {
    const approvals = ['disclosures', 'creditCheck', 'phoneConsent', 'communitySolarAgreement'];
    const targetPosition = approvals.indexOf(targetApproval);
    // return if not found in approvals array
    // validation builds as the carousel progresses
    if (targetPosition === -1 || (targetPosition > 0 && !validDisclosureConsent(component)) || (targetPosition > 1 && component.renderCreditCheckLanguage && !validCreditCheckReview(component)) || (targetPosition > 2 && !validPhoneConsent(component))) {
        return;
    }
    // set show and icon properties
    for (const approval of approvals) {
        // ex: approval = disclosures
        // set component.showDisclosures = true if target is disclosures, otherwise set to false
        // set component.disclosuresIcon to selected icon if target is disclosures, otherwise set to unselected icon
        component[`show${approval[0].toUpperCase()}${approval.slice(1)}`] = approval === targetApproval;
        component[`${approval}Icon`] = approval === targetApproval ? 'utility:record' : 'utility:routing_offline';
    }
}

const showNextApproval = (component) => {
    let targetApproval;
    if (component.showDisclosures && component.renderCreditCheckLanguage) {
        targetApproval = 'creditCheck';
    }
    if ((component.showDisclosures && !component.renderCreditCheckLanguage) || component.showCreditCheck) {
        targetApproval = 'phoneConsent';
    }
    if (component.showPhoneConsent) {
        targetApproval = 'communitySolarAgreement';
    }
    showApproval(component, targetApproval);
}

// Indicate to server that Consents section of the application is complete
const consentsComplete = async (component) => {
    let complete;
    // Check if user has checked all consents, viewed documents, and signed
    // Toast errors will display in order of check
    // Do not check Credit Check Disclosure if there is no underwriting
    if (validDisclosureConsent(component) && (!component.renderCreditCheckLanguage || validCreditCheckReview(component)) && validPhoneConsent(component) && validDocumentsViewed(component) && validCSAgreement(component) && validSignature(component)) {
        complete = true;
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
            postErrorLogEvent(component, error, null,'ssfAgreementsHelper', 'consentsComplete', 'Error');
            showWarningToast(
                component,
                'Oops',
                'We ran into a technical issue, please contact customer care\n' + error
            );
        }
    }
}

const updateServerConsentsSigned = async (component) => {
    let ssfSignatureComponent = component.template.querySelector('c-ssf-signature');
    let signatureId = await ssfSignatureComponent.handleSaveSignature(component.lead.id); // save signature to lead
    let calloutURI = '/apply/services/apexrest/v3/contracts';
    let options = {
        headers: {name: 'Content-Type', value:'application/json'},
        body: JSON.stringify({ leadId: component.lead.id, email: component.lead.email, suppressAppComplete: true, signatureId: signatureId })
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
        // add a check whether the user has clicked to view the document
        contract.documentOpened = false;
        contract.showError = false;
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
            postErrorLogEvent(component, error, errContext, 'ssfAgreementsHelper', 'getContractDocuments', 'Error');
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
        postErrorLogEvent(component, error, null, 'ssfAgreementsHelper', 'getContractDocuments', 'Error');
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

const validPhoneConsent = (component) => {
    if (!component.phoneConsent) {
        showWarningToast(
            component,
            'Sorry',
            'Please check the checkbox to give permission to use your phone number'
        );
        return false;
    } else {
        return true;
    }
}

const validCSAgreement = (component) => {
    if (!component.communitySolarAgreement) {
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

const validSignature = (component) => {
    let ssfSignature = component.template.querySelector('c-ssf-signature');
    if (!ssfSignature.handleCheckSignature()) {
        ssfSignature.handleAddValidationError();
        showWarningToast(
            component,
            'Sorry',
            'Please sign to acknowledge consents'
        );
        return false;
    } else {
        return true;
    }
}

const validDocumentsViewed = (component) => {
    let allViewed = true;
    let unopened = [];
    for (let contract of component.contractDocuments) {
        if (!contract.documentOpened) {
            allViewed = false;
            unopened.push(contract.title);
            contract.showError = true;
        }
    }
    if (!allViewed) {
        let unopenedLength = unopened.length;
        let nameString = '';
        for (let i = 0; i < unopenedLength; i++) {
            nameString += unopened[i];
            if (i === unopenedLength - 1) {
                nameString += unopenedLength === 1 ? ' document' : ' documents';
                break;
            }
            if (unopenedLength > 2) {
                nameString += ',';
            }
            nameString += ' ';
            if (i === unopenedLength - 2) {
                nameString += 'and ';
            }
        }
        showWarningToast(
            component,
            'Sorry',
            `Please ensure that you have opened and reviewed the ${nameString}`
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
        case 'fico':
            return ficoLanguage(component);
        case 'finDocs':
            return finDocsLanguage();
        case 'utilityDataReview':
            return utilityDataReviewLanguage(component);
        case 'disclosure1':
            return disclosureLanguage1(component);
        case 'disclosure2':
            return disclosureLanguage2();
        case 'agree1':
            return agreementLanguage1(component);
        case 'agree2':
            return agreementLanguage2();
        case 'esignUrl':
            return esignURL;
        case 'creditCheckLabel':
            return creditCheckLabel(component);
        case 'phoneConsent':
            return phoneConsentLanguage(component);
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
    return `By checking this box and clicking the "${component.continueButtonLabel}"`+
           ` button, I acknowledge that I have reviewed and agree to the ${companyShortName} ` /* E-SIGN DISCLOSURE */;
}

const disclosureLanguage2 = () => {
    return ` and consent to receive electronic disclosures. The device I will use to receive and access electronic disclosures`+
           ` meets the hardware and software requirements described in the ESIGN Consent Disclosure.`;
}

const ficoLanguage = (component) => {
    return  `By checking this box and clicking the “${component.continueButtonLabel}” button, I am providing my electronic`+
            ` signature and giving ${companyShortName} and/or its designee(s)`+
            ` and/or sales partners permission to perform one or more soft pulls of one or more consumer reports showing my credit`+
            ` history (which will NOT impact my credit score) and to access my electric utility billing history. I am also giving`+
            ` ${companyShortName} and/or its designee(s) and/or sales partners my permission to use my credit history and my electric utility`+
            ` billing history to determine whether I qualify to participate in one or more community solar projects and for any`+
            ` other lawful purpose. I understand that ${companyShortName} and/or its designee(s) and/or sales partners may share my consumer`+
            ` report(s) with third parties that participate in the transaction(s) contemplated by my application (including but not`+
            ` limited to the owner or developer of a community solar project) and/or any party that intends to use the information as`+
            ` a potential investor, servicer or insurer in connection with a valuation of or an assessment or the risks associated`+
            ` with any agreement I enter into with ${companyShortName} pursuant to my application. I understand that if I ask ${companyShortName} whether`+
            ` it checked my credit, it will tell me, and if it did, provide the name and address of the consumer reporting agency or`+
            ` agencies that provided the information. `;
}

const finDocsLanguage = () => {
    return `Customer will promptly provide to us, in connection with Customer’s application and from time to time in connection`+
           ` with this Agreement, copies of Customer’s audited Financial Statements for each of the three (3) years prior to the`+
           ` date of our request, along with a copy of Customer’s internally generated interim Financial Statement for any period`+
           ` immediately prior to the date of our request that is not covered by such prior 3 years of Financial Statements.`+
           ` Customer’s delivery of such Financial Statements to us shall be accompanied by a written representation and warranty`+
           ` from a duly authorized officer of Customer that such Financial Statements are true and correct at the time of delivery`+
           `. “Financial Statement” means a financial statement as prepared for Customer in the ordinary course of business,`+
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

const utilityDataReviewLanguage = (component) => {
    return `By checking this box and clicking the “${component.continueButtonLabel}” button, I am providing my electronic signature and giving ${companyShortName}`+
           ` permission to access my electric utility billing history. I am also giving ${companyShortName} my permission to use my electric`+
           ` utility billing history to process my application and for any other lawful purpose.`;
}

const phoneConsentLanguage = (component) => {
    return `By providing my phone number as part of the application, and by checking this box and clicking the "${component.continueButtonLabel}"`+
           ` button, I am giving ${companyShortName} and/or its designee(s) and/or sales partners permission to contact me at that number about`+
           ` all of my accounts. I understand that I am providing my electronic signature and my consent allows the use of text messaging,`+
           ` artificial or prerecorded voice messages and automatic dialing technology for information and account service calls.`+
           ` I understand that I may revoke my consent and my consent is not required as a condition of purchasing any product or service.`+
           ` Message and data rates may apply.`;
}

const agreementLanguage1 = (component) => {
    return `By checking this box, placing my name below, and clicking the "${component.continueButtonLabel}"`+
           ` button, I acknowledge that I have read and agree to the ` /* DISCLOSURE FORM, CS AGREEMENT, PRIVACY POLICY*/;
}

const agreementLanguage2 = () => {
    return `I understand that by doing so, I am providing my electronic signature and signing the agreements linked above as`+
           ` electronic records. My signature is subject to the additional terms and conditions described here. I also`+
           ` acknowledge that this is an application only and consummation of this transaction does not occur upon the `+
           ` placement of my electronic signature on this contract; rather consummation occurs (meaning that there is an`+
           ` executed agreement between ${companyShortName} and me) after ${companyShortName} verifies my eligibility, approves the document that`+
           ` I have electronically signed, and returns the contract to me with its countersignature.`;
}

export {
    onLoad,
    onRender,
    displayDocument,
    showApproval,
    showNextApproval,
    consentsComplete,
    navigateBack,
    getText,
}