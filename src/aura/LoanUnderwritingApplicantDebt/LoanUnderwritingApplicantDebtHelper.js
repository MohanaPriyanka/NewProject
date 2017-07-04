({
    toggleHelper : function(component, event, auraId) {
        var selectedItem = event.srcElement;
        var targetId = selectedItem.name + '_help';
        var targetElem = document.getElementById(targetId);
        $A.util.toggleClass(targetElem, "toggle");
    }
})
