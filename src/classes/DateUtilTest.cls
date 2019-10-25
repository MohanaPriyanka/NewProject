/**
 * Created by PeterYao on 10/23/2019.
 */
@IsTest
public with sharing class DateUtilTest {
    @IsTest
    private static void testConvertGmtToDate() {
        Datetime effectiveDate = Datetime.newInstanceGmt(2014,02,03);
        System.assertEquals(Date.newInstance(2014,2,2), Date.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day()));
        System.assertEquals(Date.newInstance(2014,2,3), DateUtil.convertGmtToDate(effectiveDate));
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
}