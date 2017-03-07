({
	upload: function(component, file, fileContents) {
        var action = component.get("c.saveTheFile"); 
 
        action.setParams({
            fileName: file.name,
            base64Data: encodeURIComponent(fileContents), 
            contentType: file.type
        });
 
        action.setCallback(this, function(a) {
            if(a.getReturnValue() != 'success') {
                alert(a.getReturnValue());
            }
            else {
                this.initMore(component, file, fileContents);
            }
        });
            
        $A.run(function() {
            $A.enqueueAction(action); 
        });
    },
    
    initMore: function(component, event, helper) {
        var action = component.get("c.getContactInfo");
    	action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.contactName", resp.getReturnValue().FirstName + ' ' + resp.getReturnValue().LastName);
                component.set("v.userAddress1", (resp.getReturnValue().MailingStreet == null ? '' : resp.getReturnValue().MailingStreet));
                component.set("v.userAddress2", (resp.getReturnValue().MailingCity == null ? '' : (resp.getReturnValue().MailingCity + ', ')) + (resp.getReturnValue().MailingState == null ? '' : resp.getReturnValue().MailingState) + ' ' + (resp.getReturnValue().MailingPostalCode == null ? '' : resp.getReturnValue().MailingPostalCode));
                component.set("v.phone", resp.getReturnValue().Phone);
                component.set("v.email", resp.getReturnValue().Email);
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action);
        
        var action2 = component.get("c.getUserInfo");
    	action2.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.username", resp.getReturnValue().Username);
                component.set("v.profilepicture", resp.getReturnValue().SmallPhotoUrl);
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action2);
        var action3 = component.get("c.getDocuments");
    	action3.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
        		component.set("v.documents", resp.getReturnValue());
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action3);
        var action4 = component.get("c.getProductInfo");
    	action4.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
                component.set("v.utility", resp.getReturnValue().Utility__c);
                component.set("v.subscription", resp.getReturnValue().Subscription__c);
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action4);
    },
    drawChartDelay : function(component, helper) {
    	setTimeout(function() {
    		helper.drawChart(component);
		}, 1000);
	}, 
    drawChart : function(component) {
	    var data = new google.visualization.DataTable();
        data.addColumn('number', 'X');
        data.addColumn('number', 'series 1');
        data.addColumn('number', 'series 2');
        data.addColumn('number', 'series 3');
        data.addRows([
        [0, 0, 1, 3],   [1, 10, 10, 9],  [2, 23, 20, 6, ],  [3, 17, 30, 18],  [4, 18, 40, 9],  [5, 9, 50, 27]
      ]);
        var options = {
	    	hAxis: {
	      		title: 'x-axis'
	    	},
	    	vAxis: {
	    	    title: 'kWh'
	        }
	  	};
        var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
      	chart.draw(data, options);
	},
    loadChart : function(component, helper) {
		google.charts.load('current', {'packages':['corechart']});
      	google.charts.setOnLoadCallback(this.drawChartDelay(component, helper));
	}
   
})