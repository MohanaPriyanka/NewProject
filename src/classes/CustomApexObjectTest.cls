@IsTest
public class CustomApexObjectTest {

    @IsTest
    public static void testGetParamByString() {
        CustomApexObjectSample sampleObject = new CustomApexObjectSample();
        sampleObject.SampleString = 'Test Object';
        sampleObject.SampleNumber = 42;

        String sampleObjectStrParameter = (String) sampleObject.getParamByString('Str');
        String sampleObjectStrParameterCaseInvalid = (String) sampleObject.getParamByString('str');
        Integer sampleObjectIntParameter = (Integer) sampleObject.getParamByString('Num');

        System.assertEquals(sampleObject.SampleString, sampleObjectStrParameter, 'Invalid string retrieved from Apex Object param');
        System.assertEquals(null, sampleObjectStrParameterCaseInvalid, 'Param retrieval by string should be NULL for incorrect case');
        System.assertEquals(sampleObject.SampleNumber, sampleObjectIntParameter, 'Invalid int retrieved from Apex Object param');
    }

    public class CustomApexObjectSample extends CustomApexObject {
        public String SampleString;
        public Integer SampleNumber;
    }
}