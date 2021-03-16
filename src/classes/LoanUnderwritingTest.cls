/*************************************************************************************
 * Created By: Peter Yao
 * Description: Tests LoanUnderwriting VF/Lightning App
 *************************************************************************************/
@isTest
public with sharing class LoanUnderwritingTest {


    static testMethod void testBlueWaveParentStateConversion() {
        Test.startTest();
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Alabama'), 'AL');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Alaska'), 'AK');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Arizona'), 'AZ');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Arkansas'), 'AR');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('California'), 'CA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Colorado'), 'CO');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Connecticut'), 'CT');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Delaware'), 'DE');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Florida'), 'FL');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Georgia'), 'GA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Hawaii'), 'HI');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Idaho'), 'ID');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Illinois'), 'IL');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Indiana'), 'IN');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Iowa'), 'IA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Kansas'), 'KS');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Kentucky'), 'KY');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Louisiana'), 'LA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Maine'), 'ME');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Maryland'), 'MD');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Massachusetts'), 'MA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Michigan'), 'MI');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Minnesota'), 'MN');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Mississippi'), 'MS');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Missouri'), 'MO');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Montana'), 'MT');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Nebraska'), 'NE');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Nevada'), 'NV');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New Hampshire'), 'NH');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New Jersey'), 'NJ');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New Mexico'), 'NM');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New York'), 'NY');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('North Carolina'), 'NC');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('North Dakota'), 'ND');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Ohio'), 'OH');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Oklahoma'), 'OK');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Oregon'), 'OR');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Pennsylvania'), 'PA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Rhode Island'), 'RI');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('South Carolina'), 'SC');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('South Dakota'), 'SD');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Tennessee'), 'TN');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Texas'), 'TX');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Utah'), 'UT');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Vermont'), 'VT');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Virginia'), 'VA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Washington'), 'WA');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('West Virginia'), 'WV');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Wisconsin'), 'WI');
        System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Wyoming'), 'WY');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('AL'), 'Alabama');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('AK'), 'Alaska');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('AZ'), 'Arizona');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('AR'), 'Arkansas');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('CA'), 'California');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('CO'), 'Colorado');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('CT'), 'Connecticut');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('DE'), 'Delaware');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('FL'), 'Florida');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('GA'), 'Georgia');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('HI'), 'Hawaii');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('ID'), 'Idaho');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('IL'), 'Illinois');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('IN'), 'Indiana');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('IA'), 'Iowa');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('KS'), 'Kansas');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('KY'), 'Kentucky');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('LA'), 'Louisiana');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('ME'), 'Maine');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('MD'), 'Maryland');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('MA'), 'Massachusetts');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('MI'), 'Michigan');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('MN'), 'Minnesota');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('MS'), 'Mississippi');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('MO'), 'Missouri');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('MT'), 'Montana');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('NE'), 'Nebraska');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('NV'), 'Nevada');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('NH'), 'New Hampshire');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('NJ'), 'New Jersey');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('NM'), 'New Mexico');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('NY'), 'New York');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('NC'), 'North Carolina');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('ND'), 'North Dakota');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('OH'), 'Ohio');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('OK'), 'Oklahoma');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('OR'), 'Oregon');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('PA'), 'Pennsylvania');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('RI'), 'Rhode Island');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('SC'), 'South Carolina');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('SD'), 'South Dakota');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('TN'), 'Tennessee');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('TX'), 'Texas');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('UT'), 'Utah');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('VT'), 'Vermont');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('VA'), 'Virginia');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('WA'), 'Washington');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('WV'), 'West Virginia');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('WI'), 'Wisconsin');
        System.assertEquals(BlueWaveParent.convertAbbreviationToState('WY'), 'Wyoming');
        Test.stopTest();
    }
}