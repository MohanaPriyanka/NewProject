({
    // Sets the checkbox checked if selectedItems contains this item
    doInit : function (component, event, helper) {
        const items = component.get('v.selectedItems');
        const text = component.get('v.text');
        const index = items.indexOf(text);
        if (index === -1) {
            component.set('v.value', false);
        } else {
            component.set('v.value', true);
        }
    },

    // Adds or removes this item from selectedItems when the checkbox is checked
    handleChange : function(component, event, helper) {
        var items = component.get('v.selectedItems');
        const text = component.get('v.text');
        const index = items.indexOf(text);
        if (component.get('v.value')) {
            if (index === -1) {
                items.push(text);
                component.set('v.selectedItems', items);
            }
        } else {
            if (index !== -1) {
                items.splice(index, 1);
                component.set('v.selectedItems', items);
            }
        }
    },
})