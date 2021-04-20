@IsTest
public class CustomApexObjectTest {

    @IsTest
    public static void testGetParamByString() {
        CustomApexObjectSample sampleObject = new CustomApexObjectSample();
        sampleObject.sampleString = 'Test Object';
        sampleObject.sampleNumber = 42;

        String sampleObjectStrParameter = (String) sampleObject.getParamByString('sampleString');
        String sampleObjectStrParameterCaseInvalid = (String) sampleObject.getParamByString('SampleString');
        Integer sampleObjectIntParameter = (Integer) sampleObject.getParamByString('sampleNumber');

        System.assertEquals(sampleObject.sampleString, sampleObjectStrParameter, 'Invalid string retrieved from Apex Object param');
        System.assertEquals(null, sampleObjectStrParameterCaseInvalid, 'Param retrieval by string should be NULL for incorrect case');
        System.assertEquals(sampleObject.sampleNumber, sampleObjectIntParameter, 'Invalid int retrieved from Apex Object param');
    }

    public class CustomApexObjectSample extends CustomApexObject {
        public String sampleString;
        public Integer sampleNumber;
    }
}