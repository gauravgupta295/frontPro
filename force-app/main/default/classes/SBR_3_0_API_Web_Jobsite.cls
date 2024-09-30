@RestResource(urlMapping='/JobSite/ApiCreate/v1/*')
global with sharing class SBR_3_0_API_Web_Jobsite {    
    
    @HttpPost
    global static void createJobSite(){

        Savepoint sp = Database.setSavepoint();
        SBR_3_0_CreateJobsite cj = new SBR_3_0_CreateJobsite(RestContext.request.requestBody.toString());
        Exception ex = SBR_3_0_CreateJobsite.goCreate();

        Map<String,String> respMap = new Map<String,String>();
        if(ex == null) {
            respMap.put('Status', 'Success');
            respMap.put('Message', 'Jobsite Created/Updated Successfully');
            Integer statusCode = 200;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
        }
        else {
            Database.rollback(sp);
            SBR_3_0_LogException.LogIt(ex);

            respMap.put('Message', ex.getMessage() + ' | ' + ex.getStackTraceString());
            Integer statusCode = 400;
            SBR_3_0_HttpResponse.setRestResponse(respMap, statusCode);
        }
    }
}