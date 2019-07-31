/**
 * Created by jlugo on 2019-07-11.
 */
@SuppressWarnings('PMD')
global virtual class MockProvider implements StubProvider{
    private List<MethodCall> methodCalls = new List<MethodCall>();

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
        List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
        MethodCall methodCall = new MethodCall(stubbedObject, stubbedMethodName, returnType, listOfParamTypes, listOfParamNames, listOfArgs);
        methodCalls.add(methodCall);
        return handleMethodCall(methodCall);
    }

    public virtual Object handleMethodCall(MethodCall methodCall) { return null; }

    public List<MethodCall> getMethodCallsByName(String stubbedMethodName) {
        List<MethodCall> results = new List<MethodCall>();
        for (MethodCall methodCall : methodCalls) {
            if (methodCall.stubbedMethodName.equals(stubbedMethodName)) {
                results.add(methodCall);
            }
        }
        return results;
    }

    public class MethodCall {
        public MethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            this.stubbedObject = stubbedObject;
            this.stubbedMethodName = stubbedMethodName;
            this.returnType = returnType;
            this.listOfParamTypes = listOfParamTypes;
            this.listOfParamNames = listOfParamNames;
            this.listOfArgs = listOfArgs;
        }
        public Object stubbedObject;
        public String stubbedMethodName;
        public System.Type returnType;
        public List<System.Type> listOfParamTypes;
        public List<String> listOfParamNames;
        public List<Object> listOfArgs;
    }

}