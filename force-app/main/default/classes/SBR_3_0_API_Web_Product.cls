@RestResource(urlMapping='/Product/ApiCreate/v1/*')
global with sharing class SBR_3_0_API_Web_Product {
    @HttpPost
    global static String createUpdateProduct(){
        String req = RestContext.request.requestBody.toString();
        Savepoint sp = Database.setSavepoint();
        try {
            system.debug('Request: ' + req);
            SBR_3_0_CustomCreateProduct ccProduct = new SBR_3_0_CustomCreateProduct(req);
            String returnData = ccProduct.createUpdateProduct();
            Integer statusCode = 200;
            return JSON.Serialize(SBR_3_0_HttpResponse.setResponseMessage(returnData, 'Success'));
        }catch (Exception error) {
            Database.rollback(sp);
            SBR_3_0_LogException.LogIt(error);
            Integer statusCode = 400;
            return JSON.serialize(SBR_3_0_HttpResponse.setResponseMessage(error.getMessage() + ' \n' + error.getStackTraceString(), 'Error'));
        }
    }
}