/**
 * Created by Sarah Renfro on 10/11/2018.
 */
({
    doInit : function(component, event, helper) {
        helper.initHelper(component, event, helper);
        helper.getOFAC(component);
        if (component.get("v.isCoApp")) {
            helper.getCoAppContact(component);
        }
    }
})
