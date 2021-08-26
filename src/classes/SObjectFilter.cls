/**
 * @description Created to simplify boiler-plate field filters for trigger records
 * Simplifies comparisons which are typically boiler-plate code in triggers and trigger handlers
 * @created by Jeff Parlin
 * Tested by: SObjectFilterTest
 */
public without sharing class SObjectFilter {

    public static final String SOBJECT_LIST = 'SObjectList';
    public static final String SOBJECT_MAP = 'SObjectMap';
    public static final String SOBJECT_ID_SET = 'SObjectIdSet';
    public static final String EQUAL_TO = '=';
    public static final String NOT_EQUAL_TO = '!=';
    public static final String GREATER_OR_EQUAL_TO = '>='; // For numeric comparisons only, converts inputs to Decimal data type
    public static final String LESSER_OR_EQUAL_TO = '<='; // For numeric comparisons only, converts inputs to Decimal data type
    public static final String GREATER_THAN = '>'; // For numeric comparisons only, converts inputs to Decimal data type
    public static final String LESS_THAN = '<'; // For numeric comparisons only, converts inputs to Decimal data type
    public static final WildcardValue ANY_VALUE = new WildcardValue();

    private Map<Id,SObject> oldRecordMap;
    private List<SObject> newRecordList;
    private List<SObjectWrapper> wrappers = new List<SObjectWrapper>();
    private List<FilterCriteria> filterCriteria = new List<FilterCriteria>();

    /**
     * @description Constructor to determine records which differ by a single field value from Trigger.Old to Trigger.New
      * Note: Only usable in an UPDATE or DELETE trigger context
     * @param triggerOldMap Map of Id => SObject typically from Trigger.oldMap
     * @param triggerNew List of SObject typically from Trigger.new
     * @param fieldName Field to check
     * @param changeFromValue Original field value, if relevant, or can provide TriggerUtil.ANY_VALUE or null
     * @param changeToValue New field value, if relevant, or can provide TriggerUtil.ANY_VALUE or null
     */
    public SObjectFilter(
        Map<Id,SObject> triggerOldMap, List<SObject> triggerNew, SObjectField fieldName, Object changeFromValue, Object changeToValue)
    {
        this.oldRecordMap = triggerOldMap;
        this.newRecordList = triggerNew;
        if (oldRecordMap == null || newRecordList == null) {
            throw new FilterException(
                'Class instance is designed to run in an UPDATE or DELETE trigger context and requires triggerOldMap and triggerNew params.'
            );
        }
        if (fieldName == null) {
            throw new FilterException('fieldName is a required parameter for this method');
        }
        if (changeFromValue != ANY_VALUE && changeFromValue == changeToValue) {
            throw new FilterException('changeFromValue and changeToValue cannot be identical');
        }
        for (SObject newRecord : newRecordList) {
            SObjectWrapper wrapper = new SObjectWrapper();
            wrapper.recordId = newRecord.Id;
            wrapper.sobj = newRecord;
            Object oldFieldValue = oldRecordMap.get(newRecord.Id)?.get(fieldName);
            Object newFieldValue = newRecord.get(fieldName);
            if (isFieldChange(oldFieldValue, changeFromValue, newFieldValue, changeToValue)) {
                wrapper.specifiedChangeFound = true;
            }
            wrappers.add(wrapper);
        }
    }

    /**
     * @description Constructor to filter records in an SObject list (Trigger.new perhaps) by a particular field value
     * Note: Only currently supports field comparisons visible in class constants (LESSER_OR_EQUAL_TO, etc)
     * @param recordList List of SObject typically from Trigger.new
     * @param fieldName Field to check
     * @param comparator See class constants for examples (LESSER_OR_EQUAL_TO, etc)
     * @param fieldValue Field value to filter by (can be various primitive types)
     */
    public SObjectFilter(List<SObject> recordList, SObjectField fieldName, String comparator, Object fieldValue) {
        this.newRecordList = recordList;
        for (SObject newRecord : newRecordList) {
            SObjectWrapper wrapper = new SObjectWrapper();
            wrapper.recordId = newRecord.Id;
            wrapper.sobj = newRecord;
            wrapper.specifiedChangeFound = true; // set default to true to bypass change check
            wrappers.add(wrapper);
        }
        addFilterCriteria(fieldName, comparator, fieldValue);
    }

    /**
     * @description Adds additional filter criteria to either filterByField() or filterByFieldValueChange(), such that
     * additional fields can be filtered on
     * @param fieldName Field to check
     * @param comparator See class constants for examples (LESSER_OR_EQUAL_TO, etc)
     * @param fieldValue Field value to filter by (can be various primitive types)
     * @return Updated instance of TriggerFilter for chaining purposes
     */
    public SObjectFilter addFilterCriteria(SObjectField fieldName, String comparator, Object fieldValue) {
        filterCriteria.add(new FilterCriteria(fieldName, comparator, fieldValue));
        return this;
    }

    /**
     * @description Filter Trigger.new (or any SObject list)
     * @param returnType Dynamic return type, available options are class constants BOOLEAN_MAP, SOBJECT_LIST, or SOBJECT_MAP
     * @return Object return type (see returnType param)
     */
    public Object filterByCriteria(String returnType) {
        if (filterCriteria.size() == 0) {
            throw new FilterException('No filter criteria specified');
        }
        return getResult(returnType);
    }

    /**
     * @description Checks to see if primitive field values have changed from Trigger.Old to Trigger.New in an UPDATE
     * or DELETE trigger context, and returns a filtered collection of records that meet the criteria
     * @param returnType Dynamic return type, available options are class constants BOOLEAN_MAP, SOBJECT_LIST, or SOBJECT_MAP
     * @return Object return type (see returnType param)
     */
    public Object filterByFieldValueChange(String returnType) {
        return getResult(returnType);
    }

    public class FilterException extends Exception {}
    public class WildcardValue {}

    private class SObjectWrapper {
        Id recordId;
        SObject sobj;
        Boolean specifiedChangeFound = false;
    }

    private class FilterCriteria {
        SObjectField fieldName;
        Object fieldValue;
        String comparator;
        public FilterCriteria(SObjectField field, String comparisonOperator, Object value) {
            this.fieldName = field;
            this.fieldValue = value;
            this.comparator = comparisonOperator;
        }
    }

    private Object getResult(String returnType) {
        if (returnType == SOBJECT_LIST) {
            return getSObjectList(wrappers);
        } else if (returnType == SOBJECT_MAP) {
            return getSObjectMap(wrappers);
        } else if (returnType == SOBJECT_ID_SET) {
            return getSObjectIdSet(wrappers);
        }
        throw new FilterException('Invalid return type specified');
    }

    private List<SObject> getSObjectList(List<SObjectWrapper> sobjectWrappers) {
        List<SObject> returnList = new List<SObject>();
        for (SObjectWrapper wrapper : sobjectWrappers) {
            if (wrapper.specifiedChangeFound && meetsFilterCriteria(wrapper.sobj)) {
                returnList.add(wrapper.sobj);
            }
        }
        return returnList;
    }

    private Map<Id, SObject> getSObjectMap(List<SObjectWrapper> sobjectWrappers) {
        Map<Id,SObject> returnMap = new Map<Id,SObject>();
        for (SObjectWrapper wrapper : sobjectWrappers) {
            if (wrapper.specifiedChangeFound && meetsFilterCriteria(wrapper.sobj)) {
                returnMap.put(wrapper.recordId, wrapper.sobj);
            }
        }
        return returnMap;
    }
    
    private Set<Id> getSObjectIdSet(List<SObjectWrapper> sobjectWrappers) {
        Set<Id> returnSet = new Set<Id>();
        for (SObjectWrapper wrapper : sobjectWrappers) {
            if (wrapper.specifiedChangeFound && meetsFilterCriteria(wrapper.sobj)) {
                returnSet.add(wrapper.recordId);
            }
        }
        return returnSet;
    }

    /**
     * @description Compares input value to SObject field value
     * NOTE: Date, Time, and Datetime data types are NOT SUPPORTED via any comparator OTHER THAN == or !=
     * (will throw System.TypeException)... This is due to leveraging the generic Object data type. All numeric values are
     * converted into Decimals for comparison, which works in most cases.
     * @param sobj SObject record
     * @return TRUE if filter criteria met, else FALSE
     */
    private Boolean meetsFilterCriteria(SObject sobj) {
        for (FilterCriteria criteria : filterCriteria) {
            Boolean meetsCriteria = true;
            Object fieldValue = sobj.get(criteria.fieldName);
            if (criteria.comparator == EQUAL_TO) {
                meetsCriteria = fieldValue == criteria.fieldValue;
            } else if (criteria.comparator == NOT_EQUAL_TO) {
                meetsCriteria = fieldValue != criteria.fieldValue;
            } else if (criteria.comparator == GREATER_THAN) {
                meetsCriteria = (Decimal) fieldValue > (Decimal) criteria.fieldValue;
            } else if (criteria.comparator == GREATER_OR_EQUAL_TO) {
                meetsCriteria = (Decimal) fieldValue >= (Decimal) criteria.fieldValue;
            } else if (criteria.comparator == LESS_THAN) {
                meetsCriteria = (Decimal) fieldValue < (Decimal) criteria.fieldValue;
            } else if (criteria.comparator == LESSER_OR_EQUAL_TO) {
                meetsCriteria = (Decimal) fieldValue <= (Decimal) criteria.fieldValue;
            } else {
                throw new FilterException('Invalid field comparator specified');
            }
            if (!meetsCriteria) {
                return false;
            }
        }
        return true;
    }

    private Boolean isFieldChange(Object oldFieldValue, Object specifiedFromValue, Object newFieldValue, Object specifiedToValue) {
        Boolean fromCriteriaMet = oldFieldValue == specifiedFromValue || specifiedFromValue instanceof WildcardValue;
        Boolean toCriteriaMet = newFieldValue != oldFieldValue &&
            (newFieldValue == specifiedToValue || specifiedToValue instanceof WildcardValue);
        return fromCriteriaMet && toCriteriaMet;
    }
}