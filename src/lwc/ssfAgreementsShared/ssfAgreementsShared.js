import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { makeRequest } from 'c/httpRequestService';
import getContentDocumentLinksByLead from '@salesforce/apex/SimpleSignupFormController.getContentDocumentLinksByLead'
import insertLog from '@salesforce/apex/Logger.insertLog';
import getContentDistributionLink from '@salesforce/apex/SimpleSignupFormController.getContentDistributionById'

const onLoad = (component) => {
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
        showCreditCheckApproval(component);
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
    if (!validCreditCheckReview(component)) {
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
    if (validDisclosureConsent(component) && validCreditCheckReview(component) &&
        validCSAgreement(component) && validConsentEmail(component))
    {
        component.showSpinner = true;
        component.spinnerMessage = 'Saving your consents';

        try {
            let consentPromise = await updateServerConsentsSigned(component);
            component.showSpinner = false;

            // If contracts successfully updated on server, post consentsComplete event to bubble up
            const consentsCompleteEvent = new CustomEvent('consentscomplete', {
                detail: component.lead,
            });
            component.dispatchEvent(consentsCompleteEvent);
        } catch (error) {
            const promiseError = JSON.stringify(error);
            insertLog({
                className: 'ssf',
                methodName: 'patchLead',
                message: promiseError,
                severity: 'Error'
            });
            showWarningToast(
                component,
                'Oops',
                'We ran into a technical issue, please contact customer care\n' + promiseError
            );
            component.showSpinner = false;
        }
    }
}

const updateServerConsentsSigned = async (component) => {
    let calloutURI = '/apply/services/apexrest/v3/contracts';
    let options = {
        headers: {name: 'Content-Type', value:'application/json'},
        body: JSON.stringify({ leadId: component.lead.id, email: component.lead.email })
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
    component.showSpinner = false;
}

const getContractDocuments = (component) => {
    if (component.contractDocuments) {
        return component.contractDocuments;
    }
    component.showSpinner = true;
    window.setTimeout(() => {
        component.spinnerMessage = 'Generating your documents';
    }, 5000);
    window.setTimeout(() => {
        component.spinnerMessage = 'This can take a minute';
    }, 1000);
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
            window.clearInterval(component.documentPollerId);
            window.clearTimeout(component.documentPollerTimeoutId);
            component.showSpinner = false;
            showWarningToast(
                component,
                'Error',
                'Sorry, we ran into a technical issue: \n' + error.body.message
            );
        });
    }, 2000);
    component.documentPollerTimeoutId = window.setTimeout(() => {
        window.clearInterval(component.documentPollerId);
        component.showSpinner = false;
        showWarningToast(
            component,
            'Error',
            'Sorry, documents should not take this long to generate. Please contact customer care'
        );
    }, 60000);
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
            'Please check the checkbox to authorize credit and utility billing review'
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
    if (component.lead.email !== component.consentEmail) {
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

const getCreditCheckLabel = (component) => {
    if (component.isFico) {
        return 'Check to Authorize Credit and Utility Billing Review';
    }
    else {
        return 'Check to Authorize Financial and Utility Billing Review';
    }
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
    getCreditCheckLabel
}