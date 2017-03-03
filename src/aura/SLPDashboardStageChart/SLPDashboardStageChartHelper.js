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

            console.log('resp labels: ' + resp.getReturnValue().labels);
            console.log('resp data: ' + resp.getReturnValue().data);

            chartobj = new Chart(ctx, {
                type: 'pie',
                data: {
                    labels: resp.getReturnValue().labels,
                    datasets: [
                        {
                            data: resp.getReturnValue().counts
                        }
                    ]
                },
                options: {
                    hover: {
                        mode: "none"
                    }
                }
            });

            //store the chart in the attribute
            component.set("v.chartobj",chartobj);
        });
        $A.enqueueAction(action);
    }
})