({  accountMenuOutput : function(component, event, helper) {    
        component.set("v.menuOpen", false);                                       
        var source = event.getSource();
        var label = source.get("v.label"); 
        var name = source.get("v.class"); 
        if (label === null || label === undefined ) {
            helper.refreshTableData(component, 'All', helper);
            component.set("v.selectedAccount", "All");
        } else {
            helper.refreshTableData(component, label, helper);
            component.set("v.selectedAccount", name);                                       
        }
    },

    openMenu : function(component, event, helper) { 
        component.set("v.menuOpen", true);                                       
    },

    closeMenu : function(component, event, helper) { 
        component.set("v.menuOpen", false);                                       
    },

    openSingleFile: function(component, event, helper) {
        var btnClicked = event.getSource().get("v.name");
        $A.get('e.lightning:openFiles').fire({
            recordIds: component.get("v.fileNames"),
            selectedRecordId: btnClicked
        });
    },

    doInit : function(component, event, helper) {
        let cleanPropName = component.get("v.selectedAccount");
        if (cleanPropName == null){
            cleanPropName = 'All';
        }
        cleanPropName = cleanPropName.split('%20').join(' ');
        component.set("v.selectedAccount", cleanPropName);

        let prepopulatedAcct = component.get("v.prepopulatedAcctId");
        if (prepopulatedAcct == null){
            prepopulatedAcct = 'All';
        }
        var actionGetPropertyAccounts = component.get("c.getMenuLabelList");
        actionGetPropertyAccounts.setCallback(this,function(resp){
            if(resp.getState() === 'SUCCESS') {
                component.set("v.menuLabels", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
        });    
        $A.enqueueAction(actionGetPropertyAccounts);
        helper.refreshTableData(component, prepopulatedAcct, helper);
    },

    openPaymentWindow : function(component, event, helper) { 
        component.set("v.ShowPaymentForm", true);                                       
    },
})