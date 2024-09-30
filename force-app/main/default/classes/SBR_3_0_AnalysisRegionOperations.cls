/*********************************************************************************************************************
* Apex Class: SBR_3_0_AnalysisRegionOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Concrete class for Analysis Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Philippe Bilodeau       2022-05-08          Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_AnalysisRegionOperations {

    @InvocableMethod(
        label = 'Get Analysis Regions from Ids'
        description = 'Get Analysis Regions from Ids'
    )
    public static List<ARResponse> getAnalysisRegions(List<ARRequest> Requests) {
        ARRequest req = Requests[0];
        
        List<Analysis_Region__c> arList = SBR_3_0_AnalysisRegionDA.getAnalysisRegions(req.ARIds);
        
        List<ARResponse> Response = new List<ARResponse>();
        ARResponse resp = new ARResponse();
        resp.lARResponse = arList;
        Response.add(resp);
        
        return Response;
    }
    
    public class ARRequest {
        @InvocableVariable(label='Analysis Region Ids' required=FALSE)
        public list<String> ARIds;
    }
    public class ARResponse {
        @InvocableVariable(label='Analysis Regions List' required=FALSE)
        public list<Analysis_Region__c> lARResponse = new list<Analysis_Region__c>();
    }
}