({
    searchEvent : function(component, event, helper) {     
        var searchText = component.find('searchInput').get("v.value");
        var searchEvt = $A.get("e.c:BlueWaveSearchEvent");
        searchEvt.setParams({searchText: searchText}); 
        searchEvt.fire();         
    },  
})

