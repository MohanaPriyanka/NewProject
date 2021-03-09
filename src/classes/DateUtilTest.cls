/**
 * Created by PeterYao on 10/23/2019.
 */
@IsTest
public with sharing class DateUtilTest {
    @IsTest
    private static void testConvertGmtToDate() {
        Datetime effectiveDate = Datetime.newInstanceGmt(2014,12,28);
        System.assertEquals(Date.newInstance(2014,12,27), Date.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day()));
        System.assertEquals(Date.newInstance(2014,12,28), DateUtil.convertGmtToDate(effectiveDate));
    }

    @IsTest
    private static void testMinTwoDates() {
        Date older = Date.newInstance(2014,02,03);
        Date newer = Date.newInstance(2017,04,23);

        System.assertEquals(older, DateUtil.min(older,newer));
        System.assertEquals(older, DateUtil.min(newer,older));
        System.assertEquals(older, DateUtil.min(null,older));
        System.assertEquals(null, DateUtil.min(null,null));
        System.assertEquals(newer, DateUtil.min(newer,null));
        System.assertEquals(newer, DateUtil.min(newer,newer));
    }

    @IsTest
    private static void testMaxTwoDates() {
        Date older = Date.newInstance(2014,02,03);
        Date newer = Date.newInstance(2017,04,23);

        System.assertEquals(newer, DateUtil.max(older,newer));
        System.assertEquals(newer, DateUtil.max(newer,older));
        System.assertEquals(older, DateUtil.max(null,older));
        System.assertEquals(null, DateUtil.max(null,null));
        System.assertEquals(newer, DateUtil.max(newer,null));
        System.assertEquals(newer, DateUtil.max(newer,newer));
    }

    @IsTest
    private static void testBetween() {
        Date older = Date.newInstance(2017,02,03);
        Date middle = Date.newInstance(2017,03,23);
        Date newer = Date.newInstance(2017,04,23);
        System.assert(DateUtil.between(older, middle, newer));
        System.assert(!DateUtil.between(middle, older, newer));
        System.assert(!DateUtil.between(older, newer, middle));
        middle = Date.newInstance(2017,04,23);
        System.assert(DateUtil.between(older, middle, newer), 'Same date is considered to be between');
        System.assert(!DateUtil.between(middle, older, newer));
        System.assert(DateUtil.between(older, newer, middle), 'Same date is considered to be between');
        System.assert(!DateUtil.between(older, null, newer), 'Null end dates are a far out date');
        System.assert(DateUtil.between(older, newer, null), 'Null end dates are a far out date');
        System.assert(DateUtil.between(older, null, null), 'Null end dates are considered equal');
    }

    @IsTest
    private static void testOverlapsDates() {
        System.assert(
            DateUtil.overlapsDates(Date.newInstance(2020,1,1), null, Date.newInstance(2020,1,1), null),
            'Two objects, both with null end dates, should overlap'
        );
        System.assert(
            !DateUtil.overlapsDates(Date.newInstance(2020,1,1), Date.newInstance(2020,1,31), Date.newInstance(2020,2,1), null),
            '1/1/2020 - 1/31/2020 and 2/1/2020 - null should not overlap'
        );
        System.assert(
            DateUtil.overlapsDates(Date.newInstance(2019,1,1), null, Date.newInstance(2020,1,1), Date.newInstance(2020,1,31)),
            '1/1/2019 - null and 1/1/2020 - 1/31/2020 should overlap'
        );
        System.assert(
            DateUtil.overlapsDates(Date.newInstance(2019,1,1), null, Date.newInstance(2020,1,1), null),
            '1/1/2019 - null and 1/1/2020 - null should overlap'
        );
        System.assert(
            DateUtil.overlapsDates(Date.newInstance(2020,1,1), Date.newInstance(2020,1,31), Date.newInstance(2019,1,1), null),
            '1/1/2020 - 1/31/2020 and 1/1/2019 - null should overlap'
        );
        System.assert(
            DateUtil.overlapsDates(Date.newInstance(2020,1,1), Date.newInstance(2020,1,31), Date.newInstance(2019,12,1), Date.newInstance(2020,1,1)),
            '1/1/2020 - 1/31/2020 and 12/1/2019 - 1/1/2020 should overlap'
        );
        System.assert(
            DateUtil.overlapsDates(Date.newInstance(2020,1,1), Date.newInstance(2020,1,31), Date.newInstance(2019,12,1), Date.newInstance(2020,12,1)),
            '1/1/2020 - 1/31/2020 and 12/1/2019 - 12/1/2020 should overlap'
        );
        System.assert(
            !DateUtil.overlapsDates(Date.newInstance(2020,1,1), Date.newInstance(2020,1,31), Date.newInstance(2020,12,1), Date.newInstance(2020,12,1)),
            '1/1/2020 - 1/31/2020 and 12/1/2020 - 12/1/2020 should not overlap'
        );
    }
}