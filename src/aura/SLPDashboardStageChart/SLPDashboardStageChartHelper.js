({
    loadChart : function(component) {
        var chartobj = component.get("v.chartobj");
        var action = component.get("c.getAll");
    	action.setCallback(this, function(resp) {

            var el = component.find('chart').getElement();
            var ctx = el.getContext('2d'); 

            //if chartobj is not empty, then destory the chart in the view
            if(chartobj){
                chartobj.destroy();
            }

            chartobj = new Chart(ctx, {
                type: 'pie',
                data: {
                    labels: resp.getReturnValue().labels,
                    datasets: [
                        {
                            data: resp.getReturnValue().counts,
                            backgroundColor: ['#1c5a7d','#00AFA9','#9CB6D3','#BEC6C3','#7D98AA','#6CA6CD'],
                            hoverBorderWidth: [10, 10, 10, 10, 10, 10, 10]
                        }]
                },
                options: {
                    title: {
                        display: true,
                        fontSize: 20,
                        padding: 30,
                        text: 'Pending Tasks by Stage'
                    },
                    legend: {
                        display: true,
                        position: 'right'
                    },
                    animation: {
                        animateScale: true
                    }
                }
            });

            //store the chart in the attribute
            component.set("v.chartobj",chartobj);
        });
        $A.enqueueAction(action);
    }
})