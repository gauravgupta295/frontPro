public with sharing class SBR_3_0_API_Approve {
    private String approvalId;
    private String comment;
    private String approvedBy;
    private static final String RESOURCE ='/services/apexrest/sbaa/ServiceRouter';

    public SBR_3_0_API_Approve(String approvalId, String comment, Id approvedBy) {
        this.approvalId = approvalId;
        this.comment = comment;
        this.approvedBy = approvedBy;
    }        

    @future (callout=true)
    public static void Approve(String approvalId, String comment, Id approvedBy) {

        String body = 
            '{' +
                '"model":"{\\"approvalId\\":\\"' +
                approvalId + 
                '\\",\\"comments\\":\\"' + 
                comment +
                '\\"}","saver":"SBAA.ApprovalRestApiProvider.Approve"' +
            '}';
       
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:ThisOrgCreds/services/apexrest/sbaa/ServiceRouter');
        req.setMethod('POST');
        req.setBody(body);
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('\n vp:  ' + res.getBody());

        sbaa__Approval__c approval = SBR_3_0_ApprovalDA.getApprovalById(approvalId);
        
        // SF-5301: Commenting this code as this logic is handled by package, plus having this code prevents next Level email sending to the approvers
        /**if(approval.sbaa__ApprovedBy__c != approvedBy) {
            approval.sbaa__Status__c = 'Approved';
            approval.sbaa__ApprovedBy__c = approvedBy;
            update approval;
        }**/
    }
    
    // SF-5301
    @future (callout=true)
    public static void BulkApprove(List<String> approvalIds, List<String> comments) {

        for(Integer count=0;count<approvalIds.size();count++) {
            String body = 
                '{' +
                    '"model":"{\\"approvalId\\":\\"' +
                    approvalIds[count] + 
                    '\\",\\"comments\\":\\"' + 
                    comments[count] +
                    '\\"}","saver":"SBAA.ApprovalRestApiProvider.Approve"' +
                '}';
           
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:ThisOrgCreds/services/apexrest/sbaa/ServiceRouter');
            req.setMethod('POST');
            req.setBody(body);
            req.setHeader('Content-Type', 'application/json');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('\n vp:  ' + res.getBody());
        }
    }

    // private String getRequestBody() {
    //     String body = 
    //         '{' +
    //             '"model":"{\\"approvalId\\":\\"' +
    //             this.approvalId + 
    //             '\\",\\"comments\\":\\"' + 
    //             this.comment +
    //             '\\"}","saver":"SBAA.ApprovalRestApiProvider.Approve"' +
    //         '}';
    //     return body;
    // }

    private class ApprovalException extends Exception {}
}