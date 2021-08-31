/**
 * @description Created to simplify boiler-plate field filters for trigger records
 * Filters SObject lists, which are commonplace in Apex triggers, by a specific change or specific field values
 * @created by Jeff Parlin, Aug 2021
 * Tested by: SObjectFilterTest
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class SObjectFilter {

    public static final FieldComparison EQUAL_TO = new EqualTo();
    public static final FieldComparison NOT_EQUAL_TO = new NotEqualTo();
    public static final FieldComparison GREATER_THAN = new GreaterThan(); // For numeric comparisons only, converts inputs to Decimal data type
    public static final FieldComparison GREATER_OR_EQUAL_TO = new GreaterThanOrEqual(); // For numeric comparisons only, converts inputs to Decimal data type
    public static final FieldComparison LESS_THAN = new LessThan(); // For numeric comparisons only, converts inputs to Decimal data type
    public static final FieldComparison LESSER_OR_EQUAL_TO = new LesserOrEqual(); // For numeric comparisons only, converts inputs to Decimal data type
    public static final ReturnType SOBJECT_LIST = new ObjectList();
    public static final ReturnType SOBJECT_MAP = new ObjectMap();
    public static final ReturnType SOBJECT_ID_SET = new ObjectIdSet();
    public static final WildcardValue ANY_VALUE = new WildcardValue();

    private Map<Id, SObject> oldRecordMap;
    private List<SObject> newRecordList;
    private List<Record> records = new List<Record>();
    private List<FilterCriteria> filterCriteria = new List<FilterCriteria>();

    /**
     * @description Constructor #1: determine records which differ by a single field value from Trigger.Old to Trigger.New
     * Note: Only usable in an UPDATE or DELETE trigger context
     * @param triggerOldMap Map of Id => SObject typically from Trigger.oldMap
     * @param triggerNew List of SObject typically from Trigger.new
     * @param fieldName Field to check
     * @param changeFromValue Original field value, if relevant, or can provide ANY_VALUE or null
     * @param changeToValue New field value, if relevant, or can provide ANY_VALUE or null
     */
    public SObjectFilter(
        Map<Id, SObject> triggerOldMap, List<SObject> triggerNew, SObjectField fieldName, Object changeFromValue, Object changeToValue) {
        this.oldRecordMap = triggerOldMap;
        this.newRecordList = triggerNew;
        if (oldRecordMap == null || newRecordList == null || fieldName == null) {
            throw new FilterException('triggerOldMap, triggerNew, and fieldName params are required and must not be null');
        }
        if (changeFromValue != ANY_VALUE && changeFromValue == changeToValue) {
            throw new FilterException('changeFromValue and changeToValue cannot be identical');
        }
        parseSObjectsAndEvaluateChangeCondition(fieldName, changeFromValue, changeToValue);
    }

    /**
     * @description Constructor #2: filter records in an SObject list (Trigger.new perhaps) by a particular field value
     * Note: Only currently supports field comparisons visible in class constants (LESSER_OR_EQUAL_TO, etc)
     * @param recordList List of SObject typically from Trigger.new
     * @param fieldName Field to check
     * @param comparator See class constants/subclasses with FieldComparison impl for examples (LESSER_OR_EQUAL_TO, etc)
     * @param fieldValue Field value to filter by (can be various primitive types)
     */
    public SObjectFilter(List<SObject> recordList, SObjectField fieldName, FieldComparison comparator, Object fieldValue) {
        this.newRecordList = recordList;
        parseSObjects();
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
    public SObjectFilter addFilterCriteria(SObjectField fieldName, FieldComparison comparator, Object fieldValue) {
        filterCriteria.add(new FilterCriteria(fieldName, comparator, fieldValue));
        return this;
    }

    /**
     * @description Returns the result of the filter in the format specified
     * @param returnType Dynamic return type, available options are class constants BOOLEAN_MAP, SOBJECT_LIST, or SOBJECT_MAP
     * @return Object return type (see returnType param)
     */
    public Object get(ReturnType returnType) {
        return returnType.buildCollection(this, records);
    }

    public interface FieldComparison {
        Boolean meetsCriteria(Object fieldValue, Object compareToValue);
    }

    public class EqualTo implements FieldComparison {
        public Boolean meetsCriteria(Object fieldValue, Object compareToValue) {
            return fieldValue == compareToValue;
        }
    }

    public class NotEqualTo implements FieldComparison {
        public Boolean meetsCriteria(Object fieldValue, Object compareToValue) {
            return fieldValue != compareToValue;
        }
    }

    public class GreaterThan implements FieldComparison {
        public Boolean meetsCriteria(Object fieldValue, Object compareToValue) {
            return (Decimal) fieldValue > (Decimal) compareToValue;
        }
    }

    public class GreaterThanOrEqual implements FieldComparison {
        public Boolean meetsCriteria(Object fieldValue, Object compareToValue) {
            return (Decimal) fieldValue >= (Decimal) compareToValue;
        }
    }

    public class LessThan implements FieldComparison {
        public Boolean meetsCriteria(Object fieldValue, Object compareToValue) {
            return (Decimal) fieldValue < (Decimal) compareToValue;
        }
    }

    public class LesserOrEqual implements FieldComparison {
        public Boolean meetsCriteria(Object fieldValue, Object compareToValue) {
            return (Decimal) fieldValue <= (Decimal) compareToValue;
        }
    }

    public interface ReturnType {
        Object buildCollection(SObjectFilter filter, List<Record> records);
    }

    public class ObjectList implements ReturnType {
        public List<SObject> buildCollection(SObjectFilter filter, List<Record> records) {
            List<SObject> returnList = new List<SObject>();
            for (Record record : records) {
                if (filter.meetsCriteria(record)) {
                    returnList.add(record.sobj);
                }
            }
            return returnList;
        }
    }

    public class ObjectMap implements ReturnType {
        public Map<Id, SObject> buildCollection(SObjectFilter filter, List<Record> records) {
            Map<Id, SObject> returnMap = new Map<Id, SObject>();
            for (Record record : records) {
                if (filter.meetsCriteria(record)) {
                    returnMap.put(record.recordId, record.sobj);
                }
            }
            return returnMap;
        }
    }

    public class ObjectIdSet implements ReturnType {
        public Set<Id> buildCollection(SObjectFilter filter, List<Record> records) {
            Set<Id> returnSet = new Set<Id>();
            for (Record record : records) {
                if (filter.meetsCriteria(record)) {
                    returnSet.add(record.recordId);
                }
            }
            return returnSet;
        }
    }

    public class FilterException extends Exception {
    }

    public class WildcardValue {
    }

    private class Record {
        Id recordId;
        SObject sobj;
        Boolean specifiedChangeFound;
        public Record(Id sobjectId, SObject sobjectInstance, Boolean changeFound) {
            recordId = sobjectId;
            sobj = sobjectInstance;
            specifiedChangeFound = changeFound; // In Constructor #2 change conditions ignored, default true (see parseSObjects())
        }
    }

    private class FilterCriteria {
        SObjectField fieldName;
        Object fieldValue;
        FieldComparison comparator;
        public FilterCriteria(SObjectField field, FieldComparison comparator, Object value) {
            this.fieldName = field;
            this.fieldValue = value;
            this.comparator = comparator;
        }
    }

    private Boolean meetsCriteria(Record record) {
        return record.specifiedChangeFound && this.meetsFilterCriteria(record.sobj);
    }

    private void parseSObjectsAndEvaluateChangeCondition(SObjectField fieldName, Object changeFromValue, Object changeToValue) {
        for (SObject newRecord : newRecordList) {
            Boolean changeFound = false;
            Object oldFieldValue = oldRecordMap.get(newRecord.Id)?.get(fieldName);
            Object newFieldValue = newRecord.get(fieldName);
            changeFound = isFieldChange(oldFieldValue, changeFromValue, newFieldValue, changeToValue);
            Record record = new Record(newRecord.Id, newRecord, changeFound);
            records.add(record);
        }
    }

    private void parseSObjects() {
        for (SObject newRecord : newRecordList) {
            Record record = new Record(newRecord.Id, newRecord, true); // changeFound flag default true
            records.add(record);
        }
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
            meetsCriteria = criteria.comparator.meetsCriteria(fieldValue, criteria.fieldValue);
            if (!meetsCriteria) {
                return false;
            }
        }
        return true;
    }

    private Boolean isFieldChange(Object oldFieldValue, Object specifiedFromValue, Object newFieldValue, Object specifiedToValue) {
        Boolean fromCriteriaMet = oldFieldValue == specifiedFromValue || specifiedFromValue instanceof WildcardValue;
        Boolean toCriteriaMet = newFieldValue != oldFieldValue && (newFieldValue == specifiedToValue || specifiedToValue instanceof WildcardValue);
        return fromCriteriaMet && toCriteriaMet;
    }
}