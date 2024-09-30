/*********************************************************************************************************************
* Apex Class: SBR_3_0_Queueable_VerifyJobSiteAddress
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Queueable Class to update the lat/long and validat the address on Job Site
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-10-18          Initial version
*********************************************************************************************************************/
public without sharing class SBR_3_0_Queueable_VerifyJobSiteAddress implements Queueable, Database.AllowsCallouts {
    // SAL-24521
    private static Boolean OFFSET_FLAG = true;
    private static final String TIMEZONE_ID = 'id';
    private static final String TIMEZONE_NAME = 'name';
    private static final String TIMEZONE_OFFSET = 'rmOffset';

    private static final String JOB_SITE_TYPE = 'delivery';
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    private static final String ADDRRESULT = 'result';
    private static final string ADDMESSAGE = 'message';
    public List<AssociatedLocation> assocLocList;
    public Boolean isInsert;
    private static Boolean recursive = false;
    private SBR_3_0_AVSHelper avh = new SBR_3_0_AVSHelper();
    List<AssociatedLocation> newAls = new List<AssociatedLocation>();
    public SBR_3_0_Queueable_VerifyJobSiteAddress(List<AssociatedLocation> als, Boolean isInsert){
        this.assocLocList = als;
        this.isInsert = isInsert;
    }
    
    public void execute(QueueableContext context){
        if (!recursive) {
            recursive = true;
            SBR_3_0_API_AVS addressValidator = new SBR_3_0_API_AVS();
            SBR_3_0_API_FetchLatLong latLongFetcher= new SBR_3_0_API_FetchLatLong();
            SBR_3_0_API_FetchTerritory territoryFetcher = new SBR_3_0_API_FetchTerritory();
         
            if(assocLocList.size() > 0) {
                for(AssociatedLocation al : assocLocList){
                    AssociatedLocation newAl = new AssociatedLocation();
                    newAl.Id = al.Id;
                    validateAddress(al, addressValidator, newAl);
                    // SAL-24521 
                    //persist timezone data
                    System.debug(' *********** persist timezone data : ');
                    updateTimezoneFields(al, latLongFetcher, newAl);
                    fetchTerritory(territoryFetcher, newAl);
                    newAls.add(newAl); 
                }
                update newAls;
            }
        }
    }
    
    // SAL-24521
    private void updateTimezoneFields(AssociatedLocation al, SBR_3_0_API_FetchLatLong latLongFetcher, AssociatedLocation newAl) {
        Map<String, String> results = latLongFetcher.getTimezoneFields(al.Street_Address__c, '', al.City__c, al.State__c, al.Zip_Code__c, al.Country__c, String.valueOf(al.Latitude_Longitude__Latitude__s), String.valueOf(al.Latitude_Longitude__Longitude__s), OFFSET_FLAG);
        System.debug(' *********** updateTimezoneFields : '+ results.size());
        if (results != null){
            if(results.containsKey(TIMEZONE_ID)){
                System.debug(' *********** TIMEZONE_ID : '+ results.get(TIMEZONE_ID));
                newAl.Time_Zone_Id__c = results.get(TIMEZONE_ID);
            }   
            if(results.containsKey(TIMEZONE_NAME)){
                System.debug(' *********** TIMEZONE_NAME : '+ results.get(TIMEZONE_NAME));
                newAl.Time_Zone_Name__c = results.get(TIMEZONE_NAME);
            }  
            if(results.containsKey(TIMEZONE_OFFSET)){
                System.debug(' *********** TIMEZONE_OFFSET : '+ results.get(TIMEZONE_OFFSET));
                newAl.Time_Zone__c = Decimal.valueOf(results.get(TIMEZONE_OFFSET));
            }  
        }
    }

    private void validateAddress(AssociatedLocation al, SBR_3_0_API_AVS addressValidator, AssociatedLocation newAl) {
        //if(al.City__c != null && al.State__c != null && al.Zip_Code__c != null && al.Street_Address__c !=null){
            avh.address.line1 = al.Street_Address__c;
            avh.address.line2 = '';
            avh.address.city = al.City__c;
            avh.address.state = al.State__c;
            avh.address.zip = al.Zip_Code__c;
            avh.address.type = JOB_SITE_TYPE;
            if (al.Country__c == 'US' || al.Country__c == 'United States') {
                avh.address.company = '1';
            }
            else {
                avh.address.company = '2';
            }
            
            Map<String, String> result = addressValidator.validateAddress(avh);
            if (result != null && result.containsKey(ADDRRESULT)){
                newAl.Address_Validation_Status__c = result.get(ADDRRESULT);
                if (result.containsKey(ADDMESSAGE)) {
                    newAl.Address_Message__c = result.get(ADDMESSAGE);
                }
            }
            if (isInsert && al.Latitude_Longitude__Latitude__s != null && al.Latitude_Longitude__Longitude__s != null) {
                newAl.From_Map__c = true;
            }
            else {
                if (!isInsert) {
                    newAl.From_Map__c = false;
                }
                if (newAl.Address_Validation_Status__c == SBR_3_0_Constants.STATUS_VALID) {
                    if(result.containsKey(LATITUDE)) {
                        newAl.Latitude_Longitude__Latitude__s = Decimal.valueOf(result.get(LATITUDE));
                    }
                    if(result.containsKey(LONGITUDE)) {
                        newAl.Latitude_Longitude__Longitude__s = Decimal.valueOf(result.get(LONGITUDE));
                    }
                }
                else {
                    if (newAl.From_Map__c == false) {
                        newAl.Address_Validation_Status__c = SBR_3_0_Constants.STATUS_INVALID;
                        newAl.Latitude_Longitude__Latitude__s = null;
                        newAl.Latitude_Longitude__Longitude__s = null;
                    }
                }
            }

        //}
    }

    private void fetchTerritory(SBR_3_0_API_FetchTerritory territoryFetcher, AssociatedLocation newAl) {
        if (newAl.Latitude_Longitude__Latitude__s!= null && newAl.Latitude_Longitude__Longitude__s!= null ){
            List<Object> returnval = territoryFetcher.getTerritoryDetails(String.valueOf(newAl.Latitude_Longitude__Latitude__s),String.valueOf(newAl.Latitude_Longitude__Longitude__s),SBR_3_0_Constants.ACCOUNT_API_NAME);
            System.debug('Territory result'+ returnval);
        }
    }
}