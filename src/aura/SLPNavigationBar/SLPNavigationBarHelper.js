({
    activateTab : function(component, event, helper, btnClicked) {
        var tabToActivate = component.find(btnClicked);
        $A.util.addClass(tabToActivate, 'proximaNovaStreamSmall');
        $A.util.removeClass(tabToActivate, 'proximaNovaDataMountaintopSmall');

        if (btnClicked != 'slpalerts'){
            this.deactivateTab(component, event, helper, 'slpalerts');
        }
        if (btnClicked != 'slpdisbursals'){
            this.deactivateTab(component, event, helper, 'slpdisbursals');
        }
        if (btnClicked != 'slpdashboard'){
            this.deactivateTab(component, event, helper, 'slpdashboard');
        }
        if (btnClicked != 'loansheet'){
            this.deactivateTab(component, event, helper, 'loansheet');
        }
        if (btnClicked != 'slpaddcustomer'){
            this.deactivateTab(component, event, helper, 'slpaddcustomer');
        }
        if (btnClicked != 'slpcommunitySolar'){
            this.deactivateTab(component, event, helper, 'slpCommunitySolar');
            component.set("v.currentTab", btnClicked);
        }
    },

    deactivateTab : function(component, event, helper, tabToCheck) {
        var tabToUpdate = component.find(tabToCheck);
        $A.util.removeClass(tabToUpdate, 'proximaNovaStreamSmall');
        $A.util.addClass(tabToUpdate, 'proximaNovaDataMountaintopSmall');
    },
})