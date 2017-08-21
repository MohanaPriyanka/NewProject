({
    sortTable: function(component, event, helper) {
        var fieldName = event.currentTarget.name;
        var currentOrder = component.get("v.sortAsc"),
            currentList = component.get("v.allCustomers");
        currentOrder = !currentOrder;
        currentList.sort(function(a,b) {
            var t1 = a[fieldName] == b[fieldName], t2 = a[fieldName] < b[fieldName];
            return t1? 0: (currentOrder?-1:1)*(t2?1:-1);
        });
        component.set("v.sortAsc", currentOrder);
        component.set("v.allCustomers", currentList);
        component.set("v.sortField", fieldName);
    },
})