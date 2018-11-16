({
    searchEventOnClick : function(component, event, helper) {    
        $A.util.addClass(component.find('searchButton'), "noDisplay");   
        $A.util.removeClass(component.find('searchSpinner'), "noDisplay"); 
        $A.util.addClass(component.find('clearSearchButton'), "noDisplay");                   
    	setTimeout(function() {
	        var searchText = component.find('searchInput').get("v.value");
	        var searchEvt = $A.get("e.c:BlueWaveSearchEvent");
	        searchEvt.setParams({searchText: searchText}); 
	        searchEvt.fire(); 
	        $A.util.addClass(component.find('searchSpinner'), "noDisplay");   
            $A.util.removeClass(component.find('searchButton'), "noDisplay");   
	        $A.util.removeClass(component.find('clearSearchButton'), "noDisplay");                         	        
        }, 200);           
    },  
    searchEventOnEnter : function(component, event) {    
		if (event.getParams().keyCode == 13) {    	
	        $A.util.addClass(component.find('searchButton'), "noDisplay");   
	        $A.util.removeClass(component.find('searchSpinner'), "noDisplay");  
	        $A.util.addClass(component.find('clearSearchButton'), "noDisplay");          
	    	setTimeout(function() {
		        var searchText = component.find('searchInput').get("v.value");
		        var searchEvt = $A.get("e.c:BlueWaveSearchEvent");
		        searchEvt.setParams({searchText: searchText}); 
		        searchEvt.fire(); 
		        $A.util.addClass(component.find('searchSpinner'), "noDisplay");   
	            $A.util.removeClass(component.find('searchButton'), "noDisplay");  
                $A.util.removeClass(component.find('clearSearchButton'), "noDisplay");                 	        
	        }, 200);   
	    }        
    }, 
    clearSearch : function(component, event, helper) {  
        $A.util.addClass(component.find('searchButton'), "noDisplay");   
        $A.util.removeClass(component.find('searchSpinner'), "noDisplay"); 
        $A.util.addClass(component.find('clearSearchButton'), "noDisplay"); 
    	setTimeout(function() {
	        var searchText = "";
	        var searchEvt = $A.get("e.c:BlueWaveSearchEvent");
	        searchEvt.setParams({searchText: searchText}); 
	        searchEvt.fire();  
	        $A.util.addClass(component.find('searchSpinner'), "noDisplay");   
            $A.util.removeClass(component.find('searchButton'), "noDisplay");
            searchInput = component.find("searchInput");
            searchInput.set("v.value", null); 
        }, 200);                	        
    },        
})