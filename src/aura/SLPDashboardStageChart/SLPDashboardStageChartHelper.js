({
	loadChart : function(component) {
		google.charts.load('current', {'packages':['corechart']});
      	google.charts.setOnLoadCallback(this.drawChart(component));
	},
    drawChart : function(component) {
		var action = component.get("c.getAll");
    	action.setCallback(this, function(resp){
            if(resp.getState() == 'SUCCESS') {
       			var data = new google.visualization.DataTable();
                data.addColumn('string', resp.getReturnValue().units);
                data.addColumn('number', 'recordCount');
                var i;
                for(i = 0; i < resp.getReturnValue().results.length; i++) {
                    data.addRow([resp.getReturnValue().results[i].unit, resp.getReturnValue().results[i].recordCount]);// resp.getReturnValue().results[i].consumption
                }
				var formatter = new google.visualization.NumberFormat({    				
				});
        		formatter.format(data, 1);
    			var options = {
                    title: 'Customers in Pending Stages',
	      			hAxis: {title: resp.getReturnValue().units,  titleTextStyle: {color: '#333'}},
	      			vAxis: {minValue: 0},
          			colors: ['#1c5a7d','#00AFA9','#9CB6D3','#BEC6C3','#7D98AA','#6CA6CD'],
                    pieHole: 0.25,
                    slices:{},
	    		};
                var chart = new google.visualization.PieChart(document.getElementById('chart_div'));             
			    chart.selectedSlice = -1;
                function selectHandler() {
                    var selectedItem = chart.getSelection()[0];
                    if (selectedItem) {
                        var value = data.getValue(selectedItem.row,0);
                        var rowNumber = parseInt(selectedItem.row);
                        if(chart.selectedSlice != -1){
                            options.slices[chart.selectedSlice] = {offset:'0'};
                        }
                        if(chart.selectedSlice == rowNumber){
                            chart.selectedSlice = -1;
                            var value = "All";
                            var evt = $A.get("e.c:SLPStageChartEvent");
                            evt.setParams({"stageName": value});
                            evt.fire();                               
                        }else{
                            options.slices[rowNumber] = {offset:'.2'};
                            chart.selectedSlice = rowNumber;
                            var evt = $A.get("e.c:SLPStageChartEvent");
                            evt.setParams({"stageName": value});
                            evt.fire();                            
                        }
                        chart.draw(data,options);
                    }
                }		        
                google.visualization.events.addListener(chart,'select', selectHandler);
                chart.draw(data, options);
                
            }
            else {
                $A.log("Errors", resp.getError());
            }
    	});
	    $A.enqueueAction(action);
	}
})