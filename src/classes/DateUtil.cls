/**
 * Created by PeterYao on 10/23/2019.
 * Tested By: DateUtilTest
 */

public with sharing class DateUtil {
    // Because effectiveDate, a Datetime, is in GMT and this happens when converting to paymentApplication.effectiveDate, a Date:
    // System.debug(LoggingLevel.ERROR, effectiveDate); // 2017-04-18 00:00:00
    // System.debug(LoggingLevel.ERROR, Date.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day())); // 2017-04-17 00:00:00
    public static Date convertGmtToDate(Datetime dt) {
        return Date.parse(dt.formatGmt('MM/dd/yyyy'));
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

    /**
     * @description True if dates overlap: if either object starts/end between the other, or surrounds it. Start Dates
     * need to be populated, but end dates can be null
     * @param object1StartDate Start Date for the first object
     * @param object1EndDate End Date for the first object
     * @param object2StartDate Start Date for the second object
     * @param object2EndDate End Date for the second object
     * @return True if the dates overlap
     */
    public static Boolean overlapsDates(Date object1StartDate,
        Date object1EndDate, Date object2StartDate, Date object2EndDate)
    {
        if (object1StartDate == null || object2StartDate == null) {
            throw new Util.BWException('Start dates need to be non-null to check for overlap');
        }
        EffectiveDate effectiveDate1 = new EffectiveDate(object1StartDate, object1EndDate);
        EffectiveDate effectiveDate2 = new EffectiveDate(object2StartDate, object2EndDate);
        return effectiveDate1.startsOrEndsDuring(effectiveDate2) ||
            effectiveDate2.startsOrEndsDuring(effectiveDate1) ||
            effectiveDate1.surrounds(effectiveDate2) ||
            effectiveDate2.surrounds(effectiveDate1);
    }


    @TestVisible
    private static Boolean between(Date startDate, Date dateToCheck, Date endDate) {
        return (dateToCheck == null || dateToCheck >= startDate) && (endDate == null || dateToCheck <= endDate);
    }

    private class EffectiveDate {
        Date startDate;
        Date endDate;
        private EffectiveDate(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
        private Boolean startsOrEndsDuring(EffectiveDate effectiveDate) {
            return between(effectiveDate.startDate, this.startDate, effectiveDate.endDate) ||
                between(effectiveDate.startDate, this.endDate, effectiveDate.endDate);
        }
        private Boolean surrounds(EffectiveDate effectiveDate) {
            return this.startDate <= effectiveDate.startDate &&
                (this.endDate == null || this.endDate >= effectiveDate.endDate);
        }
    }
}