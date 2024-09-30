public with sharing class SBR_3_0_BatchOpptLatLongProcessor implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful {
    Set<Id> streetAddresses = new Set<Id>();
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    private static final String MESSAGE = 'message';

    public SBR_3_0_BatchOpptLatLongProcessor(Set<Id> streetAddresses){
        this.streetAddresses = streetAddresses;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        Set<Id> allAddresses = new Set<Id>(new List<Id>(streetAddresses));

        system.debug('Processing Address Start Method');
        system.debug(JSON.serialize(allAddresses));                                                                                                                        
       
        
        String query = ' SELECT ID, Street__c, City__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Opportunity Where Id IN: allAddresses';
        return Database.getQueryLocator(query);
     }

     public void execute(Database.BatchableContext bc, List<sObject> scope) {
        system.debug('Processing Address Execute Method');
        system.debug(streetAddresses);
        List<Opportunity> projectsToUpdate = new List<Opportunity>();
        for(Opportunity opt : (List<Opportunity>)scope) {
            // Get Street Address Lat Long
            if(streetAddresses.contains(opt.Id)){
                system.debug('Calling Address API');
                SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();
                Map<String, String> result = strLatLongApi.getAddressLatLong(opt.Street__c == null ? '' : opt.Street__c,
                                                '',
                                                opt.City__c == null ? '' : opt.City__c,
                                                opt.State__c == null ? '' : opt.State__c,
                                                opt.ZIP_Code__c == null ? '' : opt.ZIP_Code__c,
                                                opt.Country__c == null ? '' : opt.Country__c);
                System.debug('Address Result: ');
                system.debug(JSON.serialize(result));
                if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') && 
                    result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
                        opt.Latitude_Longitude__Latitude__s = Decimal.valueOf(result.get(LATITUDE));
                        opt.Latitude_Longitude__Longitude__s = Decimal.valueOf(result.get(LONGITUDE));
                        opt.Latitude_Longitude_Status__c = 'Success';
                        opt.Latitude_Longitude_error__c = '';
                } else if(result.containsKey(MESSAGE) && String.isNotEmpty(result.get(MESSAGE)) && !result.get(MESSAGE).equalsIgnoreCase('null')){
                    //opt.Latitude_Longitude__Latitude__s = Decimal.valueOf(result.get(LATITUDE));
                    opt.Latitude_Longitude_Status__c = 'Error';
                    opt.Latitude_Longitude_error__c = result.get(MESSAGE);
                } else {
                    opt.Latitude_Longitude_Status__c = 'Error';
                    opt.Latitude_Longitude_error__c = 'Latitude, Longitude not captured; please contact support.';
                }
            }

        }

        update((List<Opportunity>)scope);
    }

    public void finish(Database.BatchableContext bc) {
    }
}