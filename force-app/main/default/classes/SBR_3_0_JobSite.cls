/**
 * SBR_3_0_JobSite
 * @description A wrapper class for the Create Job Site API call from Mulesoft->Salesforce.
 * Refactoring the CreateJobSite class for better exception reporting.
 * @author James Loghry
 * @date 8/14/2023
 */
public with sharing class SBR_3_0_JobSite{

    /**
     * @description account / customer number.  Relates to the parent object field.
     */
    public String rmAccountNumber {get; set;}

    /**
     * @description branch number
     */
    public String branchNumber {get; set;}

    /**
     * @description Job Site Id.  External Id of the job site.  This must be sent via the job site creation call.
     * Otherwise, the creation will fail.
     */
    public String jobSiteId {get; set;}

    /**
     * @description Name of the job site.
     */
    public String jobLocationName {get; set;}

    /**
     * @description Id of the Sales Rep.
     * Not quite sure how the integration works, since it looks like it passes a number in to this field, instead of a string.
     */
    public String salesRepId {get; set;}

    /**
     * @description Address of the job site / associated location record.
     */
    public SBR_3_0_WrapAddress address {get; set;}

    /**
     * @description Contains the location portion of the request
     */
    public Schema.AssociatedLocation data {get; set;}
}