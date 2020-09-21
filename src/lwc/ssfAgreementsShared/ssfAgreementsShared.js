/**
 * Created by lindsayholmes_gearscrm on 2020-09-14.
**/

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { makeRequest } from 'c/httpRequestService';
import getContentDocumentLinksByLead from '@salesforce/apex/SimpleSignupFormController.getContentDocumentLinksByLead'
import insertLog from '@salesforce/apex/Logger.insertLog';
import getContentDistributionLink from '@salesforce/apex/SimpleSignupFormController.getContentDistributionById'


const connCallback = (component) => {
    if (!component.lead && component.leadJson) {
        component.lead = JSON.parse(component.leadJson);
        if(component.lead.contentDocs && component.lead.contentDocs.length >= component.lead.numberOfContractDocs) {
            postProcessContractDocs(component, component.lead.contentDocs);
        }
    }
}

const rendCallback = (component) => {
    if (!component.contractDocuments && !component.documentPollerId) {
        getContractDocuments(component);
    }
}

const disclosureChecked_shared = (component, event) => {
    component.disclosures = event.target.checked;
    if (event.target.checked) {
        showCreditCheckApproval(component);
    }
}

const creditCheckChecked_shared = (component, event) => {
    component.creditCheck = event.target.checked;
    if (event.target.checked) {
        showCSAgreementApproval(component);
    }
}

const csAgreementChecked_shared = (component, event) => {
    component.csAgreement = event.target.checked;
    if (component.csAgreement) {
        const inputBox = component.template.querySelector('[data-id="consentEmail"]');
        if (inputBox) {
            inputBox.focus();
        }
    }
}

const filePreview_shared = (component, event) => {
    var contract;
    for(let c in component.contractDocuments) {
        if(component.contractDocuments[c].id === event.target.dataset.id) {
            contract = component.contractDocuments[c];
            break;
        }
    }

    if(contract) {
        if(component.supportsDataUri) {
            component.documentUrl = 'data:application/pdf;base64,' +  contract.body;
        } else {
            if(contract.publicUrl) {
                component.documentUrl = contract.publicUrl;
            } else {
                getContentDistributionLink({ leadId: component.lead.Id, email: component.lead.email, documentId: contract.id })
                    .then(result => {
                        component.documentUrl = result;
                    })
            }
            
        }
        component.showContractDocument = true;
    }
}

const showDisclosureApproval_shared = (component) => {
    component.showDisclosures = true;
    component.disclosureIcon = 'utility:record';
    component.showCreditCheck = false;
    component.creditCheckIcon = 'utility:routing_offline';
    component.showCSAgreement = false;
    component.csAgreementIcon = 'utility:routing_offline';
}

const showCreditCheckApproval_shared = (component) => {
    showCreditCheckApproval(component);
}

const showCSAgreementApproval_shared = (component) => {
    showCSAgreementApproval(component);
}

const continueAgreement_shared = (component) => {
    if (validDisclosureConsent(component) && validCreditCheckReview(component) && validCSAgreement(component) && validConsentEmail(component)) {
        component.showSpinner = true;
        component.spinnerMessage = 'Saving your consents';
        consentToDocs(component).then(
            (resolveResult) => {
                component.showSpinner = false;
                const consentsCompleteEvent = new CustomEvent('consentscomplete', {
                    detail: component.lead,
                });
                component.dispatchEvent(consentsCompleteEvent);
            },
            (rejectResult) => {
                component.showSpinner = false;
                insertLog({
                    className: 'ssf',
                    methodName: 'patchLead',
                    message: JSON.stringify(rejectResult),
                    severity: 'Error'
                });
                showWarningToast(component, 'Oops', 'We ran into a technical issue, please contact customer care\n' + JSON.stringify(rejectResult));
            }
        );
    }
}


export {
    connCallback,
    rendCallback,
    disclosureChecked_shared,
    creditCheckChecked_shared,
    csAgreementChecked_shared,
    filePreview_shared,
    showDisclosureApproval_shared,
    showCreditCheckApproval_shared,
    showCSAgreementApproval_shared,
    continueAgreement_shared
}


// ///////////////////////////////////
//      Helper Methods
// ///////////////////////////////////
function postProcessContractDocs(component, contracts) {
    window.clearInterval(component.documentPollerId);
    window.clearTimeout(component.documentPollerTimeoutId);
    component.showSpinner = false;
    component.contractDocuments = contracts;
    var disclosurePosition;
    for (let c in contracts) {
        contracts[c].first = false;
        
        if(contracts[c].title.endsWith('.pdf')) {
            contracts[c].title = contracts[c].title.slice(0,-4);
        }
        if (contracts[c].title === 'Terms and Conditions' || contracts[c].title === 'Community Solar Agreement') {
            component.csAgreementDocumentId = contracts[c].id;
        }
        if (contracts[c].title === 'Solar Disclosure Form') {
            component.disclosureDocumentId = contracts[c].id;
            disclosurePosition = c;
        }
    }
    
    if(disclosurePosition) {
        contracts = contracts.splice(0, 0, contracts.splice(disclosurePosition, 1)[0]);
    }
    component.contractDocuments[0].first = true;
}


function getContractDocuments(component) {
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
        getContentDocumentLinksByLead({leadId: component.lead.id, email: component.lead.email, mostRecentContractGen: component.lead.mostRecentContractGen})
        .then(result => {
            let docs = JSON.parse(result);
            if (docs.length >= component.lead.numberOfContractDocs) {
                postProcessContractDocs(component, docs);
            }
        })
        .catch(error => {
            showWarningToast(component, 'Error', 'Sorry, we ran into a technical issue: \n' + error.body.message);
            window.clearInterval(component.documentPollerId);
            window.clearTimeout(component.documentPollerTimeoutId);
            component.showSpinner = false;
        });
    }, 2000);
    component.documentPollerTimeoutId = window.setTimeout(() => {
        window.clearInterval(component.documentPollerId);
        component.showSpinner = false;
        showWarningToast(component, 'Error', 'Sorry, documents should not take component long to generate. Please contact customer care');
    }, 60000);
}

function showCreditCheckApproval(component) {
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

function showCSAgreementApproval(component) {
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

function validDisclosureConsent(component) {
    if (!component.disclosures) {
        showWarningToast(component, 'Sorry', 'Please check the checkbox to consent to electronic disclosures');
        return false;
    } else {
        return true;
    }
}

function validCreditCheckReview(component) {
    if (!component.creditCheck) {
        showWarningToast(component, 'Sorry', 'Please check the checkbox to authorize credit and utility billing review');
        return false;
    } else {
        return true;
    }
}

function validCSAgreement(component) {
    if (!component.csAgreement) {
        showWarningToast(component, 'Sorry', 'Please check the checkbox to agree to the Community Solar agreement and disclosure');
        return false;
    } else {
        return true;
    }
}

function validConsentEmail(component) {
    if (component.lead.email !== component.consentEmail) {
        showWarningToast(component, 'Sorry', 'Please enter the email address that you previously provided to acknowledge consents');
        return false;
    } else {
        return true;
    }
}

function consentToDocs(component) {
    let calloutURI = '/apply/services/apexrest/v3/contracts';
    let options = {
        headers: {name: 'Content-Type', value:'application/json'},
        body: JSON.stringify({ leadId: component.lead.id, email: component.lead.email })
    };
    return makeRequest(calloutURI, 'PATCH', options);
}

function showWarningToast(component, title, message) {
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: 'warning'
    });
    component.dispatchEvent(evt);
}