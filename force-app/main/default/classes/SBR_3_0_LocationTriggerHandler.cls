/******************************************************************************************************************************
* Apex Class: SBR_3_0_LocationTriggerHandler
-------------------------------------------------------------------------------------------------------------------------------
* @description - Purpose/Methods:
* - Class to handle Location Before Insert/Update and After Insert/Update context
* - SAL-1424
-------------------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                     DATE                 DETAIL FEATURES
* 1.0         Harry Rokad, Viren Patel           2022-03-30           Initial version
* 2.0         Chhavi Singhal                     2024-06-28           Added SBR_3_0_LocationOperationsService.locOpsService() 
*                                                                     in afterInsert & afterUpdate
*******************************************************************************************************************************/
public with sharing class SBR_3_0_LocationTriggerHandler extends SBR_3_0_TriggerHandler {
    @TestVisible
    private Map<Id, Schema.Location> oldLocationMap;
    @TestVisible
    private Map<Id, Schema.Location> newLocationMap;
    @TestVisible
    private List<Schema.Location> newLocationList;
    
    public static Boolean beforeUpdateRecursiveCheck = false;
    public static Boolean afterUpdateRecursiveCheck = false;
    public static List<Schema.Location> newlocList = new List<Schema.Location>();
    public static List<Schema.Location> updatedlocList = new List<Schema.Location>();
    public static Id branchLocRecordTypeId = Schema.SObjectType.Location.getRecordTypeInfosByName().get('Branch').getRecordTypeId();
    
    /**
     * @description Constructor of SBR_3_0_LocationTriggerHandler
    */
    public SBR_3_0_LocationTriggerHandler() {
        this.oldLocationMap = (Map<Id, Schema.Location>) Trigger.oldMap;
        this.newLocationMap = (Map<Id, Schema.Location>) Trigger.newMap;
        this.newLocationList = (List<Schema.Location>) Trigger.new;
    }
    
    public override void beforeInsert() {
        SBR_3_0_LocationOperations.updateSourceOfUpdate(Trigger.new);
        SBR_3_0_LocationOperations.setCompanyCodeOnJobLocation(Trigger.new);
    }
    
    public override void beforeUpdate() {
        if(!beforeUpdateRecursiveCheck){
            SBR_3_0_LocationOperations.updateSourceOfUpdate(Trigger.new);
            SBR_3_0_LocationOperations.proccessDeliveryFieldsUpdate(oldLocationMap, newLocationMap, false);
            beforeUpdateRecursiveCheck = true;
        }
    }
    
    public override void afterInsert() { 
        SBR_3_0_LocationOperations.publishBranchLocations(this.oldLocationMap,this.newLocationMap);
        if (Test.isRunningTest() == false) {
            SBR_3_0_LocationOperations.fetchAddressLatLong(NULL, this.newLocationMap);
        }
        
        for(Schema.Location loc : this.newLocationList) {
            if(loc.RecordTypeId == branchLocRecordTypeId) {
                newlocList.add(loc);
            }
        }
        SBR_3_0_LocationOperationsService.locOpsService(newlocList);
    }
    
    public override void afterUpdate() {
        if(!afterUpdateRecursiveCheck){
            SBR_3_0_LocationOperations.publishBranchLocations(this.oldLocationMap,this.newLocationMap);
            if (Test.isRunningTest() == false) {
                SBR_3_0_LocationOperations.fetchAddressLatLong(this.oldLocationMap, this.newLocationMap);
            }
            
            for(Schema.Location loc : this.newLocationMap.values()) {  
                if(loc.RecordTypeId == branchLocRecordTypeId && 
				   (loc.District__c != this.oldLocationMap.get(loc.Id).District__c || 
                   loc.Market_Name__c != this.oldLocationMap.get(loc.Id).Market_Name__c ||loc.Price_Market__c != this.oldLocationMap.get(loc.Id).Price_Market__c || 
                   loc.Reporting_Region_Name__c != this.oldLocationMap.get(loc.Id).Reporting_Region_Name__c ||
                   loc.Company_Code__c != this.oldLocationMap.get(loc.Id).Company_Code__c || loc.Analysis_Region_Key__c != this.oldLocationMap.get(loc.Id).Analysis_Region_Key__c ||
                   loc.Territory__c != this.oldLocationMap.get(loc.Id).Territory__c ||
                   loc.Inventory_Region_Key__c != this.oldLocationMap.get(loc.Id).Inventory_Region_Key__c)) {
                       //Add location record to list 
                       updatedlocList.add(loc);	
                }  
            }
            SBR_3_0_LocationOperationsService.locOpsService(updatedlocList);
            
            afterUpdateRecursiveCheck= true;
        }        
    }
}