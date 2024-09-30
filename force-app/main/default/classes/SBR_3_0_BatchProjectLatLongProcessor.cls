public with sharing class SBR_3_0_BatchProjectLatLongProcessor implements Database.Batchable<sObject>,Database.AllowsCallouts, Database.Stateful {
    Set<Id> streetAddresses = new Set<Id>();
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    private static final String MESSAGE = 'message';
    private List<Project__c> projList = new List<Project__c>();
    Integer executionCounter;
    public SBR_3_0_BatchProjectLatLongProcessor(Set<Id> streetAddresses){
        this.streetAddresses = streetAddresses;
          this.executionCounter = 0; 
    }
    public SBR_3_0_BatchProjectLatLongProcessor(Set<Id> streetAddresses, Integer counter) {
        this.streetAddresses = streetAddresses;
        this.executionCounter = counter;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        Set<Id> allAddresses = new Set<Id>(new List<Id>(streetAddresses));

        system.debug('Processing Address Start Method');
        system.debug(JSON.serialize(allAddresses));                                                                                                                        
       
        
        String query = ' SELECT ID, Street__c, City__c, State__c, Country__c, ZIP_Code__c, Latitude_Longitude_Status__c, Latitude_Longitude_error__c, Latitude_Longitude__c, Latitude_Longitude__Latitude__s, Latitude_Longitude__Longitude__s FROM Project__c Where Id IN: allAddresses';
        return Database.getQueryLocator(query);
     }

     public void execute(Database.BatchableContext bc, List<sObject> scope) {
        List<Project__c> projectsToUpdate = new List<Project__c>();
        for(Project__c pct : (List<Project__c>)scope) {
            // Get Street Address Lat Long
            if(streetAddresses.contains(pct.Id)){
                system.debug('Calling Address API');
                SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();
                Map<String, String> result = strLatLongApi.getAddressLatLong(pct.Street__c == null ? '' : pct.Street__c,
                                                '',
                                                pct.City__c == null ? '' : pct.City__c,
                                                pct.State__c == null ? '' : pct.State__c,
                                                pct.ZIP_Code__c == null ? '' : pct.ZIP_Code__c,
                                                pct.Country__c == null ? '' : pct.Country__c);
                System.debug('Address Result: ');
                system.debug(JSON.serialize(result));
                if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') && 
                    result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
                        pct.Latitude_Longitude__Latitude__s = Decimal.valueOf(result.get(LATITUDE));
                        pct.Latitude_Longitude__Longitude__s = Decimal.valueOf(result.get(LONGITUDE));
                        pct.Latitude_Longitude_Status__c = 'Success';
                        pct.Latitude_Longitude_error__c = '';
                        projList.add(pct);
                } else if(result.containsKey(MESSAGE) && String.isNotEmpty(result.get(MESSAGE)) && !result.get(MESSAGE).equalsIgnoreCase('null')){
                    //pct.Latitude_Longitude__Latitude__s = Decimal.valueOf(result.get(LATITUDE));
                    pct.Latitude_Longitude_Status__c = 'Error';
                    pct.Latitude_Longitude_error__c = result.get(MESSAGE);
                } else {
                    pct.Latitude_Longitude_Status__c = 'Error';
                    pct.Latitude_Longitude_error__c = 'Latitude, Longitude not captured; please contact support.';
                    
                }
            }

        }

        update((List<Project__c>)scope);
    }
    
    public void finish(Database.BatchableContext bc) {
     /*if(executionCounter < 99) { 
            executionCounter++;
            SBR_3_0_BatchProjectLatLongProcessor nextBatch = new SBR_3_0_BatchProjectLatLongProcessor(this.streetAddresses, executionCounter);
            Database.executeBatch(nextBatch, 200);  
        }*/
       if (!projList.isEmpty()){
            System.enqueueJob(new SBR_3_0_Queuable_ProjectTerritory(projList));
        }
    }
}