({
    getReportRows : function(component, helper) {
    	component.set('v.loading', true);
	    var action = component.get('c.getReportResponse');
	    action.setParams({"reportId" : component.get('v.reportId'),
						  "clientId" : component.get('v.clientId')});
	    action.setCallback(this,function(resp) {
	        if (resp.getState() === 'SUCCESS') {
	        	component.set('v.reportObject', resp.getReturnValue());
	        	component.set('v.loading', false);
	        } else {
	            helper.logError('LightningReportHelper', 'getReportRows', resp.getError(), component.get('v.reportObject'));
	        }
	    });
	    $A.enqueueAction(action);
    },

    convertToCSV : function(component, reportObject){
    	var csv = '';
    	csv = this.createCSVHeader(component, reportObject, csv);
    	csv = this.createCSVBody(component, reportObject, csv);
    	return csv;
    },

    createCSVHeader : function(component, reportObject, csv){
    	var columnDivider = ',';
    	var lineDivider =  '\n';
    	csv += '"' + reportObject.sumResp.groupList[0].fieldName + '"';
    	csv += columnDivider;
    	for (var c=0; c < reportObject.sumResp.reportFields.length; c++) {
    		csv += '"' + reportObject.sumResp.reportFields[c].fieldLabel + '"';
    		csv += columnDivider;
    	}
    	csv += lineDivider;
    	return csv;
    },

    createCSVBody : function(component, reportObject, csv){
    	var columnDivider = ',';
    	var lineDivider =  '\n';
    	for (var i=0; i < reportObject.sumResp.groupList.length; i++){
    		for (var j=0; j < reportObject.sumResp.groupList[i].fieldDataList.length; j++) {
    				csv += '"' + reportObject.sumResp.groupList[i].fieldLabel + '"';
    				csv += columnDivider;
    			for (var k=0; k < reportObject.sumResp.groupList[i].fieldDataList[j].length; k++) {
    				csv += '"' + reportObject.sumResp.groupList[i].fieldDataList[j][k].fieldLabel + '"';
    				csv += columnDivider;
    			}
    				csv += lineDivider;
    		}
    		//uncomment the line below in order to put an extra line break in between grouped records. 
    		// csv += lineDivider;
    	}
    	return csv;
    },
})
