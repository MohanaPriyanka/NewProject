
/*************************************************************************************
 * Created By:  Cole Swain
 * Description: Enables the ability to get metadata from a report and show it in a UI without having to query for the actual records. An example is that CSCLP components 
 				call on the LightningReportsController to show various reports in a lightning community. When the reports are adjusted, the data in the UI changes accordingly. 
 * Test: LightningReportsControllerTest
 * Useful Links: //https://developer.salesforce.com/blogs/developer-relations/2015/04/displaying-summary-and-matrix-reports.html
 *************************************************************************************/

public without sharing class LightningReportsController {

	public class ReportResponse {
		@AuraEnabled
		public String reportType {get; set;}
		@AuraEnabled
		public TabularReportResponse tabResp {get; set;}
		@AuraEnabled
		public SummaryReportResponse sumResp {get; set;}
		public reportResponse(){}
	}

	public class SummaryReportResponse {
		@AuraEnabled
		public List<FieldDef> reportFields {get; set;}
		@AuraEnabled
		public List<SummaryReportGroup> groupList {get; set;}
		public SummaryReportResponse(){}
	}	

	public class SummaryReportGroup {
		@AuraEnabled
		public String fieldName {get; set;}
		@AuraEnabled
		public String fieldValue {get; set;}
		@AuraEnabled
		public String fieldLabel {get; set;}
		@AuraEnabled
		public String groupKey {get; set;}
		@AuraEnabled
		public Integer fieldsInGroup {get; set;}
		@AuraEnabled
		public List<FieldAggregate> fieldAggregateList {get; set;}
		@AuraEnabled
		public Integer fieldAggregateListSize {get; set;}
		@AuraEnabled
		public Decimal groupColumnSize {get; set;}
		@AuraEnabled
		public Decimal lastColumnSize {get; set;}
		@AuraEnabled
		public List<List<FieldData>> fieldDataList {get; set;}
		@AuraEnabled
		public Boolean visibleChild {get; set;}
		public SummaryReportGroup(){visibleChild = false;}
	}

	public class TabularReportResponse {
		@AuraEnabled
	    public List<FieldDef> reportFields {get; set;}
	    @AuraEnabled
	    public List<List<FieldData>> fieldDataList {get; set;}
	    public TabularReportResponse(){}
	}

	public class FieldDef {
	    @AuraEnabled
	    public String fieldName {get; set;}
	    @AuraEnabled
	    public String fieldLabel {get; set;}
	    @AuraEnabled
	    public String dataType {get; set;}
	    public FieldDef(){}
	}

	public class FieldData {
	    @AuraEnabled
	    public String fieldValue {get; set;}
	    @AuraEnabled
	    public String fieldLabel {get; set;}
	    @AuraEnabled
	    public String dataType  {get; set;}
	    public fieldData(){}
	}

	public class FieldAggregate {
	    @AuraEnabled
	    public String api {get; set;}
	    @AuraEnabled
	    public String label {get; set;}
	    @AuraEnabled
	    public String value {get; set;}
	    @AuraEnabled
	    public String method {get; set;}
	    public FieldAggregate(){}
	}

	@AuraEnabled
	public static ReportResponse getReportResponse(String reportId, String clientId) {
        Reports.ReportDescribeResult myReportResult = Reports.ReportManager.describeReport(reportId);
        Reports.ReportMetadata myReportMetaData = myReportResult.getReportMetadata();
        Reports.ReportFilter myFilters = myReportMetaData.getReportFilters()[0];
        myFilters.setValue(clientId);

		//get the report result
		Reports.ReportResults results = Reports.ReportManager.runReport(reportId, myReportMetaData,true);

		//get the metadata
		Reports.ReportMetadata reportMetadata = results.getReportMetadata();

		//find out what type of report it is by looking at the groupings down and groupings across
		Integer groupingsDown = 0;
		Integer groupingsAcross = 0;

		List<Reports.GroupingInfo> groupingDownList = reportMetadata.getGroupingsDown();
		List<Reports.GroupingInfo> groupingAcrossList = reportMetadata.getGroupingsAcross();

		if (groupingDownList != null) {
			groupingsDown = groupingDownList.size();
		}

		if (groupingDownList != null) {
			groupingsAcross = groupingAcrossList.size();
		}		

		String reportType = 'tabular';
		if ( (groupingsDown > 0) && (groupingsAcross == 0) ) {
			reportType = 'summary';	
		}

		if ( (groupingsDown > 0) && (groupingsAcross > 0) ) {
			reportType = 'matrix';	
		}		

		ReportResponse rr = new ReportResponse();
		rr.reportType = reportType;	

		if (reportType == 'tabular') {
			rr.tabResp = getTabularReportResponse(results);
		} else if (reportType == 'summary') {
			rr.sumResp = getSummaryReportResponse(results);
		} 
		return rr;
	}

	@AuraEnabled
	public Static TabularReportResponse getTabularReportResponse(reports.ReportResults results) {
	    TabularReportResponse trr = new TabularReportResponse();
	    List<FieldDef> reportFields = new List<FieldDef>(); 
	    List<List<FieldData>> fieldDataList = new List<List<FieldData>>();  

	    //get the metadata
	    Reports.ReportMetadata reportMetadata = results.getReportMetadata();

	    //get a string array of the field names
	    List<String> fieldNames = reportMetadata.getDetailColumns();

	    //get the extended metadata
	    Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();

	    //get the map of the column names to their name and label
	    Map<String, Reports.DetailColumn> detailColumnMap = reportExtendedMetadata.getDetailColumnInfo();

	    //loop over the detailColumnMap and get the name, label, and data type
	    for (String fieldName: fieldNames) {
	        Reports.DetailColumn detailColumn = detailColumnMap.get(fieldName);
	        FieldDef fd = new FieldDef();
	        fd.fieldName = detailColumn.getName(); 
	        fd.fieldLabel = detailColumn.getLabel();
	        fd.dataType = detailColumn.getDataType().name();
	        reportFields.add(fd);
	    }

	    // Get the fact map from the report results
	    // The T!T is used to decode the FactMap - used here https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_fact_map.htm?search_text=!T 
	    // It designated which level of date you are trying to access in a report as sumamries and details can be bunched into the same column. 
	    //This methodology allows you to differentiate these types of datapoints that can fall into the same column
	    Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');

	    List<Reports.ReportDetailRow> reportDetailRowList = factDetails.getRows();

	    //loop over the rows
	    for (Reports.ReportDetailRow reportDetailRow: reportDetailRowList) {
	        Integer cellCounter = 0;
	        List<FieldData> fieldDataRow = new List<FieldData>();
	        //loop over the cells in the row
	        for (Reports.ReportDataCell reportDataCell: reportDetailRow.getDataCells()) {
	            fieldData fd = new fieldData();
	            fd.fieldValue = String.valueOf(reportDataCell.getValue());
	            fd.fieldLabel = (String)reportDataCell.getLabel();
	            fd.dataType = reportFields[cellCounter].dataType;
	            cellCounter++;
	            fieldDataRow.add(fd);
	        }

	        //add the row to the list
	        fieldDataList.add(fieldDataRow);
	    }

	    trr.reportFields = reportFields;
	    trr.fieldDataList = fieldDataList;
	    return trr;
	}

	public static SummaryReportResponse getSummaryReportResponse(Reports.ReportResults results) {
		SummaryReportResponse srr = new SummaryReportResponse();
		List<FieldDef> reportFields = new List<FieldDef>();

		//get the metadata
		Reports.ReportMetadata reportMetadata = results.getReportMetadata();

		Map<String, String> aggregateMap = new Map<String, String>();
		for (String aggregate : reportMetadata.getAggregates()) {
			if (aggregate != 'rowCount') {
				List<String> aggregateSplit = aggregate.split('!');
				aggregateMap.put(aggregateSplit.get(1), aggregateSplit.get(0));
			}
		} 
		//get a string array of the field names
		List<String> fieldNames = reportMetadata.getDetailColumns();

		//get the extended metadata
		Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();

		//get the map of the column names to their name and label
		Map<String, Reports.DetailColumn> detailColumnMap = reportExtendedMetadata.getDetailColumnInfo();

		//get the map of the grouping column names to their name and label
		Map<String, Reports.GroupingColumn> groupingColumnMap = reportExtendedMetadata.getGroupingColumnInfo();

		//get the grouping column info
		Reports.GroupingInfo groupingInfo = reportMetadata.getGroupingsDown()[0]; //only supports one grouping level
		Reports.GroupingColumn groupingColumnDetail = groupingColumnMap.get(groupingInfo.getName());

		//loop over the detailColumnMap and get the name, label, and data type
		for (String fieldName: fieldNames) {
			Reports.DetailColumn detailColumn = detailColumnMap.get(fieldName);
			fieldDef fd = new fieldDef();
			fd.fieldName = detailColumn.getName(); 
			fd.fieldLabel = detailColumn.getLabel();
			fd.dataType = detailColumn.getDataType().name();
			reportFields.add(fd);
		}
		srr.reportFields = reportFields;

		//get the summary grouping down dimension grouping values.  only going 1 level deep
		List<SummaryReportGroup> groupList = new List<SummaryReportGroup>();
		for (Reports.GroupingValue groupingValue: results.getGroupingsDown().getGroupings()) {
			SummaryReportGroup srg = new SummaryReportGroup();
			srg.fieldName = groupingColumnDetail.getLabel();
			srg.fieldValue = String.valueOf(groupingValue.getValue());
			srg.fieldLabel = groupingValue.getLabel();
			srg.groupKey = groupingValue.getKey();

			//use our group key to get the group rows from the fact map
		    // The T!T is used to decode the FactMap - used here https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_fact_map.htm?search_text=!T 
		    // It designated which level of date you are trying to access in a report as sumamries and details can be bunched into the same column. 
		    //This methodology allows you to differentiate these types of datapoints that can fall into the same column
			Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get(srg.groupKey+'!T');
			List<Reports.SummaryValue> fieldAggregateValues = factDetails.getAggregates();
			List<FieldAggregate> fieldAggregates = new List<FieldAggregate>();
			List<String> aggregateLabels = new List<String>();
			Integer i = 0;
			for (String aggregateField : aggregateMap.keySet()) {
				FieldAggregate fieldAggregate = new FieldAggregate();
				List<String> aggregateFieldSplitList = aggregateField.split('\\.');
				Schema.SobjectField theField = Schema.getGlobalDescribe().get(aggregateFieldSplitList[0]).getDescribe().fields.getMap().get(aggregateFieldSplitList[1]);
				Schema.DescribeFieldResult fieldResult = theField.getDescribe();
				fieldAggregate.label = fieldResult.getLabel();
				fieldAggregate.api = aggregateField;
				fieldAggregate.method = aggregateMap.get(aggregateField);
				fieldAggregate.value = fieldAggregateValues.get(i).getLabel();
				fieldAggregates.add(fieldAggregate);
				i += 1;
			}
			List<reports.ReportDetailRow> reportDetailRowList = factDetails.getRows();

			List<List<fieldData>> fieldDataList = new List<List<fieldData>>();

			//loop over the rows
			for (Reports.ReportDetailRow reportDetailRow: reportDetailRowList) {
				Integer cellCounter = 0;
				List<FieldData> fieldDataRow = new List<FieldData>();
				//loop over the cells in the row
				for (Reports.ReportDataCell reportDataCell: reportDetailRow.getDataCells()) {
					fieldData fd = new fieldData();
					fd.fieldValue = String.valueOf(reportDataCell.getValue());
					fd.fieldLabel = (String)reportDataCell.getLabel();
					fd.dataType = reportFields[cellCounter].dataType;
					cellCounter++;
					fieldDataRow.add(fd);
				}

				//add the row to the list
				fieldDataList.add(fieldDataRow);
			}
			srg.fieldsInGroup = srr.reportFields.size();
			srg.fieldDataList = fieldDataList;
			srg.fieldAggregateList = fieldAggregates;
			srg.fieldAggregateListSize = fieldAggregates.size();
			srg.groupColumnSize = srg.fieldsInGroup/(srg.fieldAggregateListSize + 1);
			srg.lastColumnSize = srg.groupColumnSize + (srg.fieldsInGroup - (srg.groupColumnSize*(srg.fieldAggregateListSize + 1)));
			groupList.add(srg);
		}
		srr.groupList = groupList;
		return srr;
	}
}