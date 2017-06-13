({
    loadChart : function(component) {
        var chartobj = component.get("v.chartobj");
        var action = component.get("c.getGenerationSavingsData");
        action.setCallback(this, function(resp) {
            var canvas = component.find('chart').getElement();
            var ctx = canvas.getContext('2d'); 

            // if chartobj is not empty, then destory the chart in the view
            if (chartobj) {
                chartobj.destroy();
            }
            
            chartobj = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: resp.getReturnValue().yearMonth,
                    datasets: [
                        {   type: 'bar',
                            data: resp.getReturnValue().savings,
                            backgroundColor: '#7D98AA',
                            hoverBorderWidth: 8,
                            stack: 1,
                            label: 'Savings This Month'
                        },
                        {
                            type: 'bar',
                            data: resp.getReturnValue().totalSavings,
                            backgroundColor: '#1c5a7d',
                            hoverBorderWidth: 8,
                            stack: 1,
                            label: 'Total Savings'
                        },                        
                    ]
                },                
                options: {
                    title: {
                        display: true,
                        text: 'Community Solar Savings'
                    },                    
                    scales: {
                        yAxes: [{
                            stacked: true,
                            ticks: {
                                beginAtZero: true,
                                callback: function(value, index, values) {
                                    return '$' + parseFloat(Math.round(value * 100) / 100).toFixed(2);;
                                }
                            }
                        }],
                        xAxes: [{
                            stacked: true,
                        }]                        
                    },                    
                    legend: {
                        display: true,
                        labels: ['Savings this month', 'Total Savings'],
                        position: 'right',
                        // By default, clicking on a legend item filters the chart. We want to enable
                        // this only when we can also fire the SLPStageChartEvent
                        onClick: function(event, legendItem) {}
                    },
                    animation: {
                        animateScale: true
                    }
                }
            });

            // canvas.onclick = function(evt) {
            //     var activePoints = chartobj.getElementsAtEvent(evt);
            //     var sce = $A.get("e.c:SLPStageChartEvent");
            //     var stageName;
            //     try {
            //         var chartData = activePoints[0]['_chart'].config.data;
            //         var idx = activePoints[0]['_index'];
            //         var label = chartData.labels[idx];
            //         var value = chartData.datasets[0].data[idx];
            //         stageName = label;
            //     } catch (err) {
            //         // Get this: Uncaught TypeError: Cannot read property '_chart' of undefined
            //         // When clicking off the chart. There's probably a better way of handling
            //         // this?
            //         if (err.name === 'TypeError') {
            //             stageName = "All";
            //         } else {
            //             throw err;
            //         }
            //     }
            //     console.log("firing SLPStageChartEvent, stageName: " + stageName);
            //     sce.setParams({"stageName": stageName});
            //     sce.fire();
            // }

            // store the chart in the attribute
            component.set("v.chartobj",chartobj);
        });
        $A.enqueueAction(action);
    }
})