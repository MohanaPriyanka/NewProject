/**
 * Created by mstackhouse on 10/26/2018.
 */
({

    convertLeadFunction : function(component, event, helper) {
        new Promise(function(resolve, reject) {
            let action = component.get('c.convertCSLead');
            action.setParams({
                "leadId": component.get('v.lead.Id'),
                "email": component.get('v.lead.Email')
            });
            action.setCallback(this, function(resp) {
                if (resp.getState() !== "SUCCESS") {
                    helper.logError("CSAPCompleteHelper", "convertLeadFunction", resp.getError(), component.get("v.lead"));
                    reject();
                } else {
                    component.set('v.lead', resp.getReturnValue());
                    component.set('v.loadingText', 'Generating your contract...');
                    resolve();
                }
            });
            $A.enqueueAction(action);
        }).then(
            $A.getCallback(function(resolve, reject) {
                var sendDocuSign = component.get('c.sendEmbeddedContract');
                sendDocuSign.setParams({
                    'lead': component.get('v.lead')
                });
                sendDocuSign.setCallback(this, function(docuSignResp) {
                    if (docuSignResp.getState() !== "SUCCESS") {
                        helper.logError("CSAPCompleteHelper", "sendEmbeddedContract", docuSignResp.getError(), component.get("v.lead"));
                        reject();
                    } else {
                        if ($A.get('$Browser.formFactor') === 'DESKTOP') {
                            component.set('v.loading', false);
                            component.set('v.page', 'ContractSignature');
                            window.addEventListener('DOMContentLoaded', function(e) {
                                var iframe = document.getElementById('docusignIframe');
                                iframe.height = iframe.contentWindow.document.body.scrollHeight;
                            });
                            component.set('v.signingURL', docuSignResp.getReturnValue());
                        } else {
                            window.open(docuSignResp.getReturnValue());
                        }
                        resolve();
                    }
                });
                $A.enqueueAction(sendDocuSign);
            })
        );
    }
})