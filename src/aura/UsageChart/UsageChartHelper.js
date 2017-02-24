({
	loadChart : function(component) {
		google.charts.load('current', {'packages':['corechart']});
      	google.charts.setOnLoadCallback(this.drawChartAll(component));
	},
    drawChartAll : function(component) {
        this.drawChart(component, '1 Year');
    },
    drawChart : function(component, range) {
		var action;
        if(range == '10 Years')
        	action = component.get("c.getTenYears");
        else if(range == '5 Years')
            action = component.get("c.getFiveYears");
       	else if(range == '1 Year')
            action = component.get("c.getOneYear");
       	else if(range == '6 Months')
            action = component.get("c.getSixMonths");
        else if(range == '1 Month')
            action = component.get("c.getOneMonth");
        else if(range =='1 Day')
            action = component.get("c.getOneDay");
        else
            action = component.get("c.getAll");
    	action.setCallback(this,function(resp){
            if(resp.getState() == 'SUCCESS') {
       			var data = new google.visualization.DataTable();
                data.addColumn('string', resp.getReturnValue().units);
                data.addColumn('number', 'Savings');
                //data.addColumn('number', 'Consumption');
                var i;
                for(i = 0; i < resp.getReturnValue().results.length; i++) {
                    data.addRow([resp.getReturnValue().results[i].unit, resp.getReturnValue().results[i].savings]);// resp.getReturnValue().results[i].consumption
                }
				var formatter = new google.visualization.NumberFormat({
    				prefix: '$'
				});
        		formatter.format(data, 1);
        		//formatter.format(data, 2);
    			var options = {
	      			hAxis: {title: resp.getReturnValue().units,  titleTextStyle: {color: '#333'}},
	      			vAxis: {minValue: 0, format:'$#'},
          			colors: ['#1c5a7d']
	    		};

		        var chart = new google.visualization.ColumnChart(document.getElementById('chart_div'));
			    chart.draw(data, options);
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action);
	}
})