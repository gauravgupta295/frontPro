/**
 *
 * @author Thomas E. Canter
 * @since 9/13/2022
 */
@RestResource(urlMapping = '/Availability/v1/getAvailabilitySummary/*')
global with sharing class SBR_3_0_Api_Web_getAvailabilitySummary
{
    @HttpPost
    /**
     *
     * @param branchId the name of the branch to get the availability summary for
     * @param catClass the product to get the summary for
     */
    global static void getAvailabilitySummaryWeb(String branchId, String catClass)
    {
        RestResponse restRes = RestContext.response;
        if (restRes == null)
        {
            restRes = new RestResponse();
            RestContext.response = restRes;
        }
        Blob response = Blob.valueOf('{"errorMessage":"no results found"}');
        List<SObject> listOfResults = getAvailabilitySummary(branchId, catClass);
        if (listOfResults != null && listOfResults.size() != 0)
        {
            response = Blob.valueOf(JSON.serialize(listOfResults));
        }
        RestContext.response.addHeader('Content-Type', 'application/json');
        restRes.statusCode = 200;
        restRes.responseBody = response;
    }

    global static List<AggregateResult> getAvailabilitySummary(String branchId, String catClass)
    {
        List<AggregateResult> listOfResults = new List<AggregateResult>();
        SBR_3_0_Api_Web_AvailabilitySummary.BranchWrapper branchRelationships = SBR_3_0_Api_Web_AvailabilitySummary.getBranchData(branchId);
        if (branchRelationships != null)
        {
            SBR_3_0_Api_Web_AvailabilitySummary.SummaryQueryParms queryParameters = new SBR_3_0_Api_Web_AvailabilitySummary.SummaryQueryParms();
            queryParameters.apiNameField = 'Name';
            queryParameters.apiName = 'Branch';
            queryParameters.apiNameComparisonValue = branchId;
            queryParameters.catClassComparisonValue = catClass;
            SBR_3_0_Api_Web_AvailabilitySummary ab = null;
            Boolean queryReady = false;
            ab = new SBR_3_0_Api_Web_AvailabilitySummary(queryParameters);
            if (ab?.availabilitySummary != null && ab.availabilitySummary.size() != 0)
            {
                listOfResults.addAll(ab.availabilitySummary);
            }
            queryParameters.apiNameField = 'District__c';
            queryParameters.apiName = 'District';
            queryParameters.apiNameComparisonValue = branchRelationships.mDistrict;
            ab = new SBR_3_0_Api_Web_AvailabilitySummary(queryParameters);
            if (ab?.availabilitySummary != null && ab.availabilitySummary.size() != 0)
            {
                listOfResults.addAll(ab.availabilitySummary);
            }
            queryParameters.apiNameField = 'Region__c';
            queryParameters.apiName = 'Region';
            queryParameters.apiNameComparisonValue = branchRelationships.mRegion;
            ab = new SBR_3_0_Api_Web_AvailabilitySummary(queryParameters);
            if (ab?.availabilitySummary != null && ab.availabilitySummary.size() != 0)
            {
                listOfResults.addAll(ab.availabilitySummary);
            }
            queryParameters.apiNameField = 'Territory__c';
            queryParameters.apiName = 'Territory';
            queryParameters.apiNameComparisonValue = branchRelationships.mTerritory;
            ab = new SBR_3_0_Api_Web_AvailabilitySummary(queryParameters);
            if (ab?.availabilitySummary != null && ab.availabilitySummary.size() != 0)
            {
                listOfResults.addAll(ab.availabilitySummary);
            }
            queryParameters.apiNameField = 'Company__c';
            queryParameters.apiName = 'Company';
            queryParameters.apiNameComparisonValue = branchRelationships.mCompany;
            ab = new SBR_3_0_Api_Web_AvailabilitySummary(queryParameters);
            if (ab?.availabilitySummary != null && ab.availabilitySummary.size() != 0)
            {
                listOfResults.addAll(ab.availabilitySummary);
            }
        }

        return listOfResults.size() != 0 ? listOfResults : null;
    }

}