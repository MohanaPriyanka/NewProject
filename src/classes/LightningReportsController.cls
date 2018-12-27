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
        public ReportResponse(){}
        @AuraEnabled
        public Boolean fullData {get; set;}
    }

    public class SummaryReportResponse {
        @AuraEnabled
        public List<FieldDef> reportFields {get; set;}
        @AuraEnabled
        public Map<String, SummaryReportGroup> groupMap {get; set;}
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
        public FieldData(){}
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
    public static Id getAsyncReport(String reportId) {
        Set<String> availableReports = new Set<String>();
        if (!Test.isRunningTest()) {
            availableReports.addAll(CSCLPController.getClientReportIds());
        } else {
            availableReports.add([
                SELECT Id, DeveloperName
                FROM Report
                WHERE DeveloperName = 'LightningReportsTestReport'
                LIMIT 1
            ].Id);
        }
        Id userId = UserInfo.getUserId();
        User currentUser = [SELECT Email, Contact.Account.Name, Contact.Account_ID__c FROM User WHERE Id = : userId];
        String clientId = currentUser.Contact.Account_ID__c;

        if (availableReports.contains(reportId)) {
            List<Reports.ReportInstance> reportInstances = Reports.ReportManager.getReportInstances(reportId);
            Reports.ReportInstance reportInstance;
            if (reportInstances.size() >= 1) {
                for (Reports.ReportInstance queriedReportInstance : reportInstances) {
                    if (userId == queriedReportInstance.getOwnerId()) {
                        reportInstance = queriedReportInstance;
                        break;
                    }
                }
            }

            if (reportInstance == null) {
                Reports.ReportDescribeResult myReportResult = Reports.ReportManager.describeReport(reportId);
                Reports.ReportMetadata myReportMetaData = myReportResult.getReportMetadata();
                if (!myReportMetaData.getReportFilters().isEmpty()) {
                    Reports.ReportFilter myFilters = myReportMetaData.getReportFilters()[0];
                    if (clientId != null && !Test.isRunningTest()) {
                        myFilters.setValue(clientId);
                    } else if (Test.isRunningTest()) {
                        String testValue = 'TestLightningReports';
                        myFilters.setValue(testValue);
                    }
                    System.debug(myFilters);
                }
                if (!Test.isRunningTest()) {
                    Reports.StandardDateFilter dateFilter = myReportMetaData.getStandardDateFilter();
                    Datetime today = Datetime.now();
                    String startDate = today.addMonths(-2).format('yyyy-MM-dd');
                    String endDate = today.format('yyyy-MM-dd');
                    dateFilter.setStartDate(startDate);
                    dateFilter.setEndDate(endDate);
                    myReportMetaData.setStandardDateFilter(dateFilter);
                }
                //get the report result
                reportInstance = Reports.ReportManager.runAsyncReport(reportId, myReportMetaData,true);
            }
            return reportInstance.getId();
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static Boolean checkAsyncReport(Id asyncReportId) {
        Reports.ReportInstance reportInstance = Reports.ReportManager.getReportInstance(asyncReportId);
        String status = reportInstance.getStatus();
        if (status == 'Success') {
            return true;
        } else if (status == 'Error') {
            String message = 'report ' + reportInstance.getReportId() + ' failed to run';
            message += ' for user: ' + reportInstance.getOwnerId();
            Logger.logNow('LightningReportsController', 'checkAsyncReport', message);
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled
    public static ReportResponse getAsyncReportResponseWithoutRows(Id asyncReportId) {
        Reports.ReportInstance reportInstance = Reports.ReportManager.getReportInstance(asyncReportId);
        Reports.ReportResults results = reportInstance.getReportResults();

        String reportType = checkReportType(results);

        ReportResponse rr = new ReportResponse();
        rr.reportType = reportType;
        rr.fullData = results.getAllData();

        if (reportType == 'tabular') {
            rr.tabResp = getTabularReportResponse(results);
        } else if (reportType == 'summary') {
            rr.sumResp = getSummaryReportResponseWithoutRows(results);
        }
        return rr;
    }

    @AuraEnabled
    public static TabularReportResponse getTabularReportResponse(reports.ReportResults results) {
        TabularReportResponse trr = new TabularReportResponse();

        //get the metadata
        Reports.ReportMetadata reportMetadata = results.getReportMetadata();

        //get a string array of the field names
        List<String> fieldNames = reportMetadata.getDetailColumns();

        //get the extended metadata
        Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();

        //get the map of the column names to their name and label
        Map<String, Reports.DetailColumn> detailColumnMap = reportExtendedMetadata.getDetailColumnInfo();

        List<FieldDef> reportFields = getReportFields(fieldNames, detailColumnMap);

        /*
        Get the fact map from the report results
        The T!T is used to decode the FactMap - used here https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_fact_map.htm?search_text=!T
        It designated which level of date you are trying to access in a report as sumamries and details can be bunched into the same column.
        This methodology allows you to differentiate these types of datapoints that can fall into the same column
        */
        Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)results.getFactMap().get('T!T');

        List<Reports.ReportDetailRow> reportDetailRowList = factDetails.getRows();

        List<List<FieldData>> fieldDataList = getFieldData(reportDetailRowList, reportFields);

        trr.reportFields = reportFields;
        trr.fieldDataList = fieldDataList;
        return trr;
    }

    @AuraEnabled
    public static SummaryReportResponse getSummaryReportResponseWithoutRows(Reports.ReportResults results) {
        SummaryReportResponse srr = new SummaryReportResponse();

        Reports.ReportMetadata reportMetadata = results.getReportMetadata();
        Map<String, String> aggregateMap = getAggregateMap(reportMetadata);

        List<String> fieldNames = reportMetadata.getDetailColumns();
        Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();
        Map<String, Reports.DetailColumn> detailColumnMap = reportExtendedMetadata.getDetailColumnInfo();
        List<FieldDef> reportFields = getReportFields(fieldNames, detailColumnMap);
        srr.reportFields = reportFields;

        List<Reports.GroupingValue> groupingValues = results.getGroupingsDown().getGroupings();

        Map<String, Reports.GroupingColumn> groupingColumnMap = reportExtendedMetadata.getGroupingColumnInfo();
        Reports.GroupingInfo groupingInfo = reportMetadata.getGroupingsDown()[0]; //only supports one grouping level
        Reports.GroupingColumn groupingColumnDetail = groupingColumnMap.get(groupingInfo.getName());


        //get the summary grouping down dimension grouping values.  only going 1 level deep
        Map<String, FieldAggregate> fieldAggregatesMap = getFieldAggregates(aggregateMap);
        Map<String, Reports.ReportFact> factMap = results.getFactMap();

        Map<String, SummaryReportGroup> groupMap = new Map<String, SummaryReportGroup>();
        for (Reports.GroupingValue groupingValue : groupingValues) {
            String groupKey = groupingValue.getKey();
            Reports.ReportFactWithDetails factWithDetails = (Reports.ReportFactWithDetails) factMap.get(groupKey+'!T');
            SummaryReportGroup srg = getSummaryReportGroup(
                groupingValue,
                groupingColumnDetail.getLabel(),
                factWithDetails,
                aggregateMap,
                fieldAggregatesMap,
                reportFields,
                false
            );
            groupMap.put(srg.groupKey, srg);
        }
        srr.groupMap = groupMap;
        return srr;
    }

    @AuraEnabled
    public static SummaryReportGroup getAsyncSummaryReportGroup(String asyncReportId, String groupKey) {
        // lightning bug, need to make sure string is string
        groupKey = String.valueOf(groupKey);

        Reports.ReportInstance reportInstance = Reports.ReportManager.getReportInstance(asyncReportId);
        Reports.ReportResults results = reportInstance.getReportResults();
        Reports.ReportMetadata reportMetadata = results.getReportMetadata();

        Map<String, String> aggregateMap = getAggregateMap(reportMetadata);

        Reports.ReportExtendedMetadata reportExtendedMetadata = results.getReportExtendedMetadata();
        Map<String, Reports.DetailColumn> detailColumnMap = reportExtendedMetadata.getDetailColumnInfo();

        //get the grouping column info
        Map<String, Reports.GroupingColumn> groupingColumnMap = reportExtendedMetadata.getGroupingColumnInfo();
        Reports.GroupingInfo groupingInfo = reportMetadata.getGroupingsDown()[0]; //only supports one grouping level
        Reports.GroupingColumn groupingColumnDetail = groupingColumnMap.get(groupingInfo.getName());


        Map<String, Reports.ReportFact> factMap = results.getFactMap();

        List<Reports.GroupingValue> groupingValues = results.getGroupingsDown().getGroupings();
        List<String> fieldNames = reportMetadata.getDetailColumns();
        List<FieldDef> reportFields = getReportFields(fieldNames, detailColumnMap);

        Map<String, FieldAggregate> fieldAggregatesMap = getFieldAggregates(aggregateMap);

        Reports.GroupingValue groupingValue;

        for (Reports.GroupingValue groupingValueVar : groupingValues) {
            String key = groupingValueVar.getKey();
            if (key == groupKey) {
                groupingValue = groupingValueVar;
            }
        }

        Reports.ReportFactWithDetails factWithDetails = (Reports.ReportFactWithDetails) factMap.get(groupKey+'!T');
        SummaryReportGroup srg = getSummaryReportGroup(
            groupingValue,
            groupingColumnDetail.getLabel(),
            factWithDetails,
            aggregateMap,
            fieldAggregatesMap,
            reportFields,
            true
        );

        return srg;
    }

    private static String checkReportType(Reports.ReportResults results) {
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
        return reportType;
    }

    private static Map<String, String> getAggregateMap(Reports.ReportMetadata reportMetadata) {
        Map<String, String> aggregateMap = new Map<String, String>();
        for (String aggregate : reportMetadata.getAggregates()) {
            if (aggregate != 'rowCount') {
                List<String> aggregateSplit = aggregate.split('!');
                aggregateMap.put(aggregateSplit.get(1), aggregateSplit.get(0));
            }
        }
        return aggregateMap;
    }

    private static List<FieldDef> getReportFields(List<String> fieldNames, Map<String, Reports.DetailColumn> detailColumnMap) {
        List<FieldDef> reportFields = new List<FieldDef>();
        //loop over the detailColumnMap and get the name, label, and data type
        for (String fieldName: fieldNames) {
            Reports.DetailColumn detailColumn = detailColumnMap.get(fieldName);
            FieldDef fd = new FieldDef();
            fd.fieldName = detailColumn.getName();
            fd.fieldLabel = detailColumn.getLabel();
            fd.dataType = detailColumn.getDataType().name();
            reportFields.add(fd);
        }

        return reportFields;
    }

    private static List<List<FieldData>> getFieldData(List<Reports.ReportDetailRow> reportDetailRowList, List<FieldDef> reportFields) {
        List<List<FieldData>> fieldDataList = new List<List<FieldData>>();
        //loop over the rows
        System.debug('row count: ' + reportDetailRowList.size());
        for (Reports.ReportDetailRow reportDetailRow: reportDetailRowList) {
            Integer cellCounter = 0;
            List<FieldData> fieldDataRow = new List<FieldData>();
            //loop over the cells in the row
            for (Reports.ReportDataCell reportDataCell: reportDetailRow.getDataCells()) {
                FieldData fd = new FieldData();
                fd.fieldValue = String.valueOf(reportDataCell.getValue());
                fd.fieldLabel = (String)reportDataCell.getLabel();
                fd.dataType = reportFields[cellCounter].dataType;
                cellCounter++;
                fieldDataRow.add(fd);
            }

            //add the row to the list
            fieldDataList.add(fieldDataRow);
        }

        return fieldDataList;
    }

    private static Map<String, FieldAggregate> getFieldAggregates(Map<String, String> aggregateMap) {
        Map<String, FieldAggregate> fieldAggregatesMap = new Map<String, FieldAggregate>();
        for (String aggregateField : aggregateMap.keySet()) {
            FieldAggregate fieldAggregate = new FieldAggregate();
            List<String> aggregateFieldSplitList = aggregateField.split('\\.');
            String label = aggregateField;
            if (aggregateFieldSplitList.size() > 1) {
                Schema.SObjectField theField = Schema.getGlobalDescribe().get(aggregateFieldSplitList[0]).getDescribe().fields.getMap().get(aggregateFieldSplitList[1]);
                Schema.DescribeFieldResult fieldResult = theField.getDescribe();
                label = fieldResult.getLabel();
            }
            fieldAggregate.label = label;
            fieldAggregate.api = aggregateField;
            fieldAggregate.method = aggregateMap.get(aggregateField);
            fieldAggregatesMap.put(aggregateField, fieldAggregate);
        }
        return fieldAggregatesMap;
    }

    private static SummaryReportGroup getSummaryReportGroup(
        Reports.GroupingValue groupingValue,
        String fieldName,
        Reports.ReportFactWithDetails factDetails,
        Map<String, String> aggregateMap,
        Map<String, FieldAggregate> fieldAggregatesMap,
        List<FieldDef> reportFields,
        Boolean includeRows
    ) {
        SummaryReportGroup srg = new SummaryReportGroup();
        srg.fieldName = fieldName;
        srg.fieldValue = String.valueOf(groupingValue.getValue());
        srg.fieldLabel = groupingValue.getLabel();
        srg.groupKey = groupingValue.getKey();

        List<Reports.SummaryValue> fieldAggregateValues = factDetails.getAggregates();
        List<FieldAggregate> fieldAggregates = new List<FieldAggregate>();

        Integer j = 0;
        for (String aggregateField : aggregateMap.keySet()) {
            FieldAggregate fieldAggregateTemplate = fieldAggregatesMap.get(aggregateField);
            FieldAggregate fieldAggregate = new FieldAggregate();
            fieldAggregate.label = fieldAggregateTemplate.label;
            fieldAggregate.api = fieldAggregateTemplate.api;
            fieldAggregate.method = fieldAggregateTemplate.method;
            fieldAggregate.value = fieldAggregateValues.get(j).getLabel();
            fieldAggregates.add(fieldAggregate);
            j += 1;
        }

        if (includeRows) {
            srg.fieldDataList = getFieldData(factDetails.getRows(), reportFields);
        } else {
            srg.fieldDataList = new List<List<FieldData>>();
        }

        srg.fieldsInGroup = reportFields.size();
        srg.fieldAggregateList = fieldAggregates;
        srg.fieldAggregateListSize = fieldAggregates.size();
        srg.groupColumnSize = srg.fieldsInGroup/(srg.fieldAggregateListSize + 1);
        srg.lastColumnSize = srg.groupColumnSize + (srg.fieldsInGroup - (srg.groupColumnSize*(srg.fieldAggregateListSize + 1)));
        return srg;
    }

    @AuraEnabled
    public static Boolean sendCSVReport(String reportId, String reportName) {
        Set<String> availableReports = new Set<String>();
        availableReports.addAll(CSCLPController.getClientReportIds());

        if (availableReports.contains(reportId)) {
            Id userId = UserInfo.getUserId();
            User currentUser = [SELECT Email, Contact.Account.Name, Contact.Account_ID__c FROM User WHERE Id = : userId];

            List<String> recipients = new List<String>{currentUser.Email};
            List<String> filters = new List<String>{currentUser.Contact.Account_ID__c};

            System.enqueueJob(new ReportSender(reportId, reportName, filters, recipients, currentUser.Contact.Account.Name));
            return true;
        } else {
            return false;
        }
    }
}