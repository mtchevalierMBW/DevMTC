@isTest
global class WebServiceCalloutMock implements WebServiceMock {
    global Object responseObject;
    global WebServiceCalloutMock(Object responseObject) {
        this.responseObject = responseObject;
    }
    global void doInvoke(    Object stub,
        Object request,
        Map<String, Object> response,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNS,
        String responseName,
        String responseType) {
           response.put('response_x', responseObject);
        }
}