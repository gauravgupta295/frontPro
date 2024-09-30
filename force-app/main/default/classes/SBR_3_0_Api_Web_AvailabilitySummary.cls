/**
 * 
 * @author Thomas E. Canter
 * @since 8/13/2022
 * @description This is the data layer class for the getAvailabilitySummary Rest EndPoint
 * 
 */public with sharing class SBR_3_0_Api_Web_AvailabilitySummary
{
    /**
     * @description the parameterized wrapper for the Branch desciption
     */

    private List<AggregateResult> mAvailabiltySummaryResultsAggregate = null;
    private String mAvailiabilitySummarySoql = '';
    public Class BranchWrapper
    {
        public string mBranch;
        public string mDistrict;
        public string mRegion;
        public string mTerritory;
        public string mCompany;
        public BranchWrapper(Schema.Location branchLocation){
            mBranch = branchLocation.Name;
            mDistrict = branchLocation.District__c;
            mRegion = branchLocation.Region__c;
            mTerritory = branchLocation.Territory__c;
            mCompany = branchLocation.Company__c;
        }
    }
    /**
     * @description availabilitySummary returns the availability summary as an SObject
     */    
    public List<AggregateResult> availabilitySummary
    {
        get
        {
            if (mAvailabiltySummaryResultsAggregate == null)
            {
                System.debug('mAvailiabilitySummarySoql-->'+mAvailiabilitySummarySoql);
                mAvailabiltySummaryResultsAggregate = Database.query(mAvailiabilitySummarySoql);
                System.debug('mAvailabiltySummaryResultsAggregate: ' + mAvailabiltySummaryResultsAggregate);
            }
            return mAvailabiltySummaryResultsAggregate;
        }
    }

    /**
     * 
     * @param branchId the branch name to lookup in the Location object
     * @return  `BranchWrapper` which contains the names of the District, Region, Territory and Company for the branch
     */
    public static BranchWrapper getBranchData(String branchId){
        String[] listOfBranchRelationships = new String[] {'','','','',''};
        BranchWrapper bw = null;
        List<Schema.Location> branchLocation = [
            Select 
                Name, 
                District__c, 
                Region__c, 
                Territory__c, 
                Company__c
            From 
                Location
            where 
                Name = :branchId
            Limit 1 ];
        if(branchLocation != null && branchLocation.size() != 0){
            bw = new BranchWrapper(branchLocation[0]);
        }
        return bw;        

    }
    /**
     * Query parameters that will be passed into the SOQL template
     */    
    public class SummaryQueryParms{
        public String apiNameField;
        public String apiName;
        public String apiNameComparisonValue;
        public String catClassComparisonValue;
    }
    /**
     * @description this the query template for the SQL to get Availabity Summary results
     */    
    private String mAvailiabilitySummarySoqlTemplate = 
        'select ' + 
        '    SM_PS_Cat_Class__c                           Cat_Class, ' +
        '    Location.{0}                                 {1}, ' + 
        '    Sum(SM_PS_Quantity_Available__c)             Quantity_Available, ' + 
        '    Sum(SM_PS_Quantity_Reserved__c)              Quantity_Reserved, ' + 
        '    Sum(SM_PS_Quantity_on_Scheduled_Pick_Up__c)  Quantity_on_Scheduled_Pick_Up, ' + 
        '    Avg(SM_PS_Utilization__c)                    Utilization, ' + 
        '    Sum(SM_PS_Quantity_Returned__c)              Quantity_Returned ' + 
        'from ' + 
        '    ProductItem ' + 
        'where ' + 
        '    Location.{0} = {2} AND ' + 
        '    SM_PS_Cat_Class__c IN {3} ' + 
        'Group By ' + 
        '    SM_PS_Cat_Class__c,Location.{0}';
    /**
     * @description this constructor builds all the elements necessary to return the results
     * @param queryParameters query parameters as described above, but used to build the SOQL query
     */    
    public SBR_3_0_Api_Web_AvailabilitySummary(summaryQueryParms queryParameters)
    {
        List<Object> catList = new List<Object>{ 
            queryParameters.ApiNameField, 
            queryParameters.ApiName, 
            '\'' + queryParameters.ApiNameComparisonValue + '\'', 
            queryParameters.CatClassComparisonValue  
        };
        mAvailiabilitySummarySoql = String.format(mAvailiabilitySummarySoqlTemplate, catList);
    }
}