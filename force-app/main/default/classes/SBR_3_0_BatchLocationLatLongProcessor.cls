public with sharing class SBR_3_0_BatchLocationLatLongProcessor implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful{
    Set<Id> streetAddresses = new Set<Id>();
    list<Schema.Location> lLocations = new list<Schema.Location>();
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';

    public SBR_3_0_BatchLocationLatLongProcessor(Set<Id> streetAddresses, list<Schema.Location> lLocations){
        this.streetAddresses = streetAddresses;
        this.lLocations = lLocations;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        Set<Id> allAddresses = new Set<Id>(new List<Id>(streetAddresses));
        String query = 'SELECT ID, Street_Address__c, City__c, State__c, Zip_Code__c, Country__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Location WHERE Id IN: allAddresses';
        return Database.getQueryLocator(query);
     }

     public void execute(Database.BatchableContext bc, List<sObject> scope) {
        system.debug('Processing Address Execute Method');
        system.debug(streetAddresses);
        List<Schema.Location> locationsToUpdate = new List<Schema.Location>();
        for(Schema.Location loc : (List<Schema.Location>)scope) {
            // Get Street Address Lat Long
            if(streetAddresses.contains(loc.Id)){
                system.debug('Calling Address API');
                SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();
                Map<String, String> result = strLatLongApi.getAddressLatLong(loc.Street_Address__c == null ? '' : loc.Street_Address__c, 
                                                '',
                                                loc.City__c == null ? '' : loc.City__c,
                                                loc.State__c == null ? '' : loc.State__c,
                                                loc.Zip_Code__c == null ? '' : loc.Zip_Code__c,
                                                loc.Country__c == null ? '' : loc.Country__c);
                System.debug('Address Result: ');
                system.debug(JSON.serialize(result));
                if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') && 
                    result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
                        loc.Latitude_Longitude__Latitude__s = Decimal.valueOf(result.get(LATITUDE));
                        loc.Latitude_Longitude__Longitude__s = Decimal.valueOf(result.get(LONGITUDE));
                }
            }
        }

        update((List<Schema.Location>)scope);
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('SBR_3_0_BatchLocationLatLongProcessor finished');
    }
}