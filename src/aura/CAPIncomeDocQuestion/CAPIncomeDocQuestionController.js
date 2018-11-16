/**
 * Created by mstackhouse on 9/14/2018.
 */
({
    affirmativeChange : function(component, event, helper) {
        var affirmativeValue = event.getParam('value');
        if (affirmativeValue === true) {
            component.set('v.negativeValue', false);
        } else {
            component.set('v.negativeValue', true);
        }
    },

    negativeChange : function(component, event, helper) {
        var negativeValue = event.getParam('value');
        if (negativeValue === true) {
            component.set('v.affirmativeValue', false);
        } else {
            component.set('v.affirmativeValue', true);
        }
    },
})