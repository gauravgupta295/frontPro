public with sharing class SBR_3_0_CreateJobsite {
    private static String headerData {get;set;}
    private static String sfFieldData {get;set;}

    private static Schema.DescribeFieldResult countryResult = User.Countrycode.getDescribe();
    private static List<Schema.PicklistEntry> countryEntries = countryResult.getPicklistValues();
    private static Schema.DescribeFieldResult stateResult = User.statecode.getDescribe();
    private static List<Schema.PicklistEntry> stateEntries = stateResult.getPicklistValues();
    private static Map<String, Set<String>> countryStatePicklist = SBR_3_0_GetDependentPicklistHelper.getDependentOptions(stateEntries, countryEntries);

    private static WrapJobSite wjs {
        get{
            if(wjs == null) {
                wjs = (WrapJobSite)JSON.deserialize(headerData, WrapJobSite.class);
                System.debug('\n wjs =' + wjs);
            }
            return wjs;
        }
        set;
    }

    private static AssociatedLocation jobSite {
        get {
            if(jobSite == null) {
                jobSite = new AssociatedLocation();
                //No content to map to Object due to end of input 
                jobSite = (AssociatedLocation) JSON.deserializeStrict(sfFieldData,AssociatedLocation.class);
                System.debug('\n fieldData =' + jobSite);
            }
            return jobSite;
        }
        set;

    }

    private static Account relAcct {
        get{
            system.debug('rental man account number: ' + wjs.rmAccountNumber);
            if(wjs!=null && String.isNotBlank(wjs.rmAccountNumber) && jobsite != null) {
                String uniqueRMAccountNumber = jobsite.Company_Code__c + '-' + wjs.rmAccountNumber ;
                return SBR_3_0_JobsiteDA.getRelatedAccount(uniqueRMAccountNumber);
            }
            return null;
        }
        set;
    }
    private static Schema.Location branch {
        get{
            return (wjs!=null && String.isNotBlank(wjs.branchNumber) && String.isNotBlank(jobSite.Company_Code__c))
                ? SBR_3_0_JobsiteDA.getRelatedBranchLocation(wjs.branchNumber,jobSite.Company_Code__c) : null;
        }
    }

    private static String salesRepUserId {get;set;} 

    private static Schema.Location jobLocation {
        get{
            return SBR_3_0_JobsiteDA.getRelatedJobLocation(wjs.address);
        }
        set;
    }
    
    private static String returnVal {get;set;}

    public SBR_3_0_CreateJobsite(String req) {
        System.debug('\n in constructor');
        System.debug('\n ' + req);
        headerData = req.substringBefore(',"data":') + '}';
        sfFieldData = req.substringAfter('"data":').substringBeforeLast('}');
    }

    public static Exception goCreate(){
        Exception ex = checkPreReqs();
        if (ex == null) {
            return createJobSiteRecord();
        }
        else {
            return ex;
        }
    }

    private static Exception checkPreReqs() {
        if(relAcct == null){
            if(jobsite != null && jobsite.Company_Code__c != null) {
                String uniqueRMAccountNumber = jobsite.Company_Code__c + '-' + wjs.rmAccountNumber;
                relAcct = SBR_3_0_JobsiteDA.getRelatedAccount(uniqueRMAccountNumber);
            }
            else {
                return new CreateJobSiteException('Related Account not found!');
            }
        } 
        if(branch == null){
            return new CreateJobSiteException('Related Branch not found!');
        } 
        if(jobLocation == null){
            //Create new Job Location
            Exception ex = setNewJobLocation();
            if ( ex!= null) {
                return ex;
            }
            System.debug('\n vp:3' + jobLocation );            
        } 
        return null;
    }


    private static Exception createJobSiteRecord() {
        try {
            addJobSiteHeaderData();
            //System.debug('\n data ---- \n' + JSON.serializePretty(jobSite));
            if(wjs.jobSiteId != null) {
                upsert jobSite job_site_id__c;
            }
            else {
                insert jobsite;
            }
            return null;
        } catch (Exception ex) {
            
            return ex;
        }
    }

    private static void addJobSiteHeaderData() {
       
        jobSite.ParentRecordId = relAcct.Id;
        jobSite.LocationId = jobLocation.Id;
        jobSite.Branch__c = branch.Id;
        jobSite.Sales_Rep_Id__c = wjs.salesRepId;
        jobSite.Name__c = wjs.jobLocationName;    
        jobSite.Job_Site_Id__c = wjs.jobSiteId;
        
        //address field
        jobSite.Street_Address__c = wjs.address.street1;
        jobSite.Street_Address_2__c = wjs.address.street2;
        jobSite.City__c = wjs.address.city;
        jobSite.Zip_Code__c = wjs.address.zip;
        populateJobsiteStateCountry();
        //jobSite.State__c = wjs.address.state;
        //jobSite.Country__c = wjs.address.country;
        jobSite.Latitude_Longitude__Latitude__s = wjs.address.latitude;
        jobSite.Latitude_Longitude__Longitude__s = wjs.address.longitude;
        jobSite.Company_Code__c = wjs.data.Company_Code__c != null ? wjs.data.Company_Code__c : '01';
        System.debug('\n jobsite so far = \n' + JSON.serializePretty(jobSite));
    }

    private static Exception setNewJobLocation() {
        Schema.Location l = new Schema.Location();
        l.RecordTypeId = SBR_3_0_Constants.LOCATION_JOB_RT_ID;
        l.Name = wjs.jobLocationName;
        l.Street_Address__c = wjs.address.street1;
        l.Street_Address_2__c = wjs.address.street2;
        l.City__c = wjs.address.city;
        l.Zip_Code__c = wjs.address.zip;
        // l.State__c = wjs.address.state;
        // l.Country__c = wjs.address.country;
        populateLocationStateCountry(l);
        l.Latitude_Longitude__Latitude__s = wjs.address.latitude;
        l.Latitude_Longitude__Longitude__s = wjs.address.longitude;
        l.Company_Code__c = wjs.data.Company_Code__c != null ? wjs.data.Company_Code__c : '01'; //12745, SADAPUR
        try {
            System.debug('\n vp:4 ='  + l );
            insert l;
            jobLocation = l;
            return null;
        } catch (Exception ex) {
            return ex;
        }

    }


    public static void populateJobsiteStateCountry(){
        jobsite.RM_Country__c = wjs.address.country;
        jobsite.RM_State__c = wjs.address.state;
        // Check if the Location's country value is not in the global picklist
        if(countryStatePicklist.containsKey(wjs.address.country) && countryStatePicklist.get(wjs.address.country).contains(wjs.address.state)){
            // if both state and country are good
            jobsite.Country__c = wjs.address.country;
            jobsite.State__c = wjs.address.state;
        }
        else {
            jobsite.Country__c = null;
            jobsite.State__c = null;
        }        

    }


    public static void populateLocationStateCountry(Schema.Location l){
        // Check if the Location's country value is not in the global picklist
        if(countryStatePicklist.containsKey(wjs.address.country) && countryStatePicklist.get(wjs.address.country).contains(wjs.address.state)){
            // if both state and country are good
            l.Country__c = wjs.address.country;
            l.State__c = wjs.address.state;
        }
        else {
            l.Country__c = null;
            l.State__c = null;
        }        

    }


    public class WrapJobSite{
        public String rmAccountNumber = '';
        public String branchNumber = '';
        public String jobLocationName = '';
        public String jobSiteId ='';
        public String salesRepId ='';
        //12745
    	public Schema.AssociatedLocation data = new Schema.AssociatedLocation(); //SF-7018,SF-7220
        public SBR_3_0_WrapAddress address = new SBR_3_0_WrapAddress(); 
    }
    

    public class CreateJobSiteException extends Exception {}

}