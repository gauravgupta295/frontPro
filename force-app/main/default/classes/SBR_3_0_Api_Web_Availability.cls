/**
 * 
 * @author Thomas E. Canter
 * @since 8/13/2022
 * @description This is the data layer class for the getAvailability Rest EndPoint
 * 
 */
public with sharing class SBR_3_0_Api_Web_Availability
{
    /**
     * @description availability returns the results of the Availabilty SOQL as a JSON String
     */    
    public List<AggregateResult> availability
    {
        get
        {
            if (mAvailabiltyResults == null)
            {
                mAvailabiltyResults = Database.query(mAvailiabilitySoql);
            }
            return mAvailabiltyResults;
        }
    }

    private List<AggregateResult> mAvailabiltyResults = null;
    private String mAvailiabilitySoql;
    /**
     * @description this is the SOQL template for the query to return the results
     */    
    private String mAvailiabilitySoqlTemplate = 
        'select ' + 
        '    Location.{0}                               {1}, ' + 
        '    Sum(SM_PS_Quantity_Available__c)             Quantity_Available, ' + 
        '    Sum(SM_PS_Quantity_Reserved__c)              Quantity_Reserved, ' + 
        '    Sum(SM_PS_Quantity_on_Scheduled_Pick_Up__c)  Quantity_on_Scheduled_Pick_Up, ' + 
        '    Avg(SM_PS_Utilization__c)                    Utilization, ' + 
        '    Sum(SM_PS_Quantity_Returned__c)              Quantity_Returned ' + 
        'from ' + 
        '    ProductItem ' + 
        'where ' + 
        '    Location.{2} = {3} AND ' + 
        '    SM_PS_Cat_Class__c = {4} ' + 
        'Group By ' + 
        '    Location.{0} ' +
        'Order By ' + 
        'Sum(SM_PS_Quantity_Available__c)  DESC';
    /**
     * 
     * @param queryParameters 
     *  index 0 = the object field reported on, Name (branch)
     *  index 1 = the human readable value in the response column
     *  index 2 = the location filter field
     *  index 3 = the location filter value
     *  index 4 = the part number
     */    
    public SBR_3_0_Api_Web_Availability(String[] queryParameters)
    {
        List<Object> catList = new List<Object>{ queryParameters[0], queryParameters[1], queryParameters[2], '\'' + queryParameters[3] + '\'', '\'' + queryParameters[4] + '\'' };
        mAvailiabilitySoql = String.format(mAvailiabilitySoqlTemplate, catList);
    }

}