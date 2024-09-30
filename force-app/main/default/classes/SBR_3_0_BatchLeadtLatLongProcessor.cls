public with sharing class SBR_3_0_BatchLeadtLatLongProcessor implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful{
    Set<Id> leadIds = new Set<Id>();
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';

    public SBR_3_0_BatchLeadtLatLongProcessor(Set<Id> leadIds){
        this.leadIds = leadIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Job_Address_Street__c, Job_Address_City__c, Job_Address_State__c, Job_Address_Zip_Code__c, Job_Address_Country__c, Latitude, Longitude, '
            + 'Address_LatLong_Status__c, Street, City, State, PostalCode, Country FROM Lead Where Id IN: leadIds';
        return Database.getQueryLocator(query);
     }

     public void execute(Database.BatchableContext bc, List<sObject> scope) {
        system.debug('Processing Lead Address Execute Method');
        system.debug(leadIds);
        List<Lead> leadsToUpdate = new List<Lead>();
        for(Lead ld : (List<Lead>)scope) {
            if(leadIds.contains(ld.Id)){
                system.debug('Calling Address API');
                SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();

                String streetVal, cityVal, stateVal, zipVal, countryVal = '';

                streetVal = ld.Job_Address_Street__c == null ? '' : ld.Job_Address_Street__c;                            
                cityVal = ld.Job_Address_City__c == null ? '' : ld.Job_Address_City__c;
                stateVal = ld.Job_Address_State__c == null ? '' : ld.Job_Address_State__c;
                zipVal = ld.Job_Address_Zip_Code__c == null ? '' : ld.Job_Address_Zip_Code__c;
                countryVal = ld.Job_Address_Country__c == null ? '' : ld.Job_Address_Country__c;

                if(streetVal == '' && cityVal == '' && stateVal == '' && zipVal == '' && countryVal == '') {
                    streetVal = ld.Street == null ? '' : ld.Street;
                    cityVal = ld.City == null ? '' : ld.City;
                    stateVal = ld.State == null ? '' : ld.State;
                    zipVal = ld.PostalCode == null ? '' : ld.PostalCode;
                    countryVal = ld.Country == null ? '' : ld.Country;
                }
                
                System.debug('streetVal -> ' + streetVal);
                System.debug('cityVal -> ' + cityVal);
                System.debug('stateVal -> ' + stateVal);
                System.debug('zipVal -> ' + zipVal);
                System.debug('countryVal -> ' + countryVal);

                Map<String, String> result = strLatLongApi.getAddressLatLong(streetVal, '', cityVal, stateVal, zipVal, countryVal);

                System.debug('Address Result: ');
                system.debug(JSON.serialize(result));
                if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') && 
                    result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
                        ld.Latitude = Decimal.valueOf(result.get(LATITUDE));
                        ld.Longitude = Decimal.valueOf(result.get(LONGITUDE));
                        ld.Address_LatLong_Status__c = 'Success';
                } else {
                    ld.Address_LatLong_Status__c = 'Error';
                }
            }
        }

        update((List<Lead>)scope);
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}