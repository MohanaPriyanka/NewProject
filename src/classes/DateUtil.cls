/**
 * Created by PeterYao on 10/23/2019.
 * Tested By: DateUtilTest
 */

public with sharing class DateUtil {
    // Because effectiveDate, a Datetime, is in GMT and this happens when converting to paymentApplication.effectiveDate, a Date:
    // System.debug(LoggingLevel.ERROR, effectiveDate); // 2017-04-18 00:00:00
    // System.debug(LoggingLevel.ERROR, Date.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day())); // 2017-04-17 00:00:00
    public static Date convertGmtToDate(Datetime dt) {
        return Date.parse(dt.formatGmt('MM/dd/YYYY'));
    }

    public static Date min(Date dateOne, Date dateTwo) {
        if (dateOne != null && dateTwo != null){
            return dateOne < dateTwo ? dateOne : dateTwo;
        } else if (dateOne != null){
            return dateOne;
        } else if (dateTwo != null){
            return dateTwo;
        } else {
            return null;
        }
    }

    public static Date max(Date dateOne, Date dateTwo) {
        if (dateOne != null && dateTwo != null){
            return dateOne > dateTwo ? dateOne : dateTwo;
        } else if (dateOne != null){
            return dateOne;
        } else if (dateTwo != null){
            return dateTwo;
        } else {
            return null;
        }
    }
}