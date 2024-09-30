/*********************************************************************************************************
* Apex Class: SBR_3_0_LocationOperationsService
----------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description - Class to Create/Update SBR_3_0_AssetInquiryPicklistValues__mdt Metadata 
                 Methods used by SBR_3_0_LocationTriggerHandler
----------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME           DATE                 DETAIL FEATURES
*   1.0         Chhavi Singhal           2024-06-26           Initial version
**********************************************************************************************************/
public with sharing class SBR_3_0_LocationOperationsService implements Metadata.DeployCallback {
    public static Map<String, String> contextToValueMap = new Map<String, String>();
    public static Map<String, Double> levelCountMap = new Map<String, Double>();
    /**
     * @description handleResult Method of Metadata.DeployCallback interface
     * @param result Stores the results of the asynchronous deployment
     * @param context Stores the context for the queued asynchronous deployment job
    */
    public void handleResult(Metadata.DeployResult result,Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            System.debug('Deployment Success : '+ result); //NOPMD
        } else {
            System.debug('Deployment Fail : '+ result); //NOPMD
        }
        
    }
    
    /**
     * @description Future Method to Create/Update Metadata
     * @param serializedMap Stores the levelToValueMap in serialized form as Map
    */
    @future
    public static void createUpdateMetadata(String serializedMap){
        Map<String, Map<String, String>> levelToValueMap = (Map<String, Map<String, String>>)JSON.deserialize(serializedMap, Map<String, Map<String, String>>.class);
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        
        for(String levelKey : levelToValueMap.keySet()) {
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            //Handled Analysis Region & Inventory Region scenario
            if(levelKey.substring(0,1) != null && (levelKey.substring(0,1)).isNumeric()) {
                String tempFullName = 'X' + levelKey;
                customMetadata.fullName = 'SBR_3_0_AssetInquiryPicklistValues__mdt.' + tempFullName.replace('-','_');
                customMetadata.label = levelKey;
            } else {
                String tempFullName1 = levelKey.replace(' ','');
                String tempFullName2 = tempFullName1.replaceAll('[^a-zA-Z0-9\\s+]', '_');
                customMetadata.fullName = 'SBR_3_0_AssetInquiryPicklistValues__mdt.' + tempFullName2.replaceAll('[_]{2,}','X');
                customMetadata.label = levelKey;
            } 
            Map<String, String> levelValue = levelToValueMap.get(levelKey);
            for(String key : levelValue.keySet()) {
                Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
                customField.field = key;
                customField.value = levelValue.get(key); 
                customMetadata.values.add(customField);
            }
            mdContainer.addMetadata(customMetadata);
        }
        SBR_3_0_LocationOperationsService callback = new SBR_3_0_LocationOperationsService();
        if(Test.isRunningTest() == false) {
        	Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
    
    /**
     * @description Method to check if District/Region/Market/Analysis Region/Territory/Inventory Region on Location exists in existing records or not
     * @param locList Stores the new Location records as list
    */
    public static void locOpsService(List<Schema.Location> locList) { //NOPMD
        sequenceNoUtil();
        Map<String, Map<String, String>> levelToValueMap = new Map<String, Map<String, String>>();
        for(Schema.Location loc : locList) {
            if(loc.District__c != null && !contextToValueMap.containsKey('District-' + loc.District__c)) {
                levelToValueMap = levelFilterCMDTUtil('District', levelCountMap, loc.District__c, levelToValueMap);
            }
            if(loc.Market_Name__c != null && loc.Price_Market__c != null && !contextToValueMap.containsKey('Market-' + loc.Market_Name__c + ' - ' + loc.Price_Market__c)) {
                levelToValueMap = levelFilterCMDTUtil('Market', levelCountMap, loc.Market_Name__c + ' - ' + loc.Price_Market__c, levelToValueMap);  
            } 
            if(loc.Reporting_Region_Name__c != null && !contextToValueMap.containsKey('Region-' + loc.Reporting_Region_Name__c)) {
                levelToValueMap = levelFilterCMDTUtil('Region', levelCountMap, loc.Reporting_Region_Name__c, levelToValueMap); 
            }
            if(loc.Company_Code__c != null && loc.Analysis_Region_Key__c != null && !contextToValueMap.containsKey('Analysis Region-' + loc.Company_Code__c + '-' + loc.Analysis_Region_Key__c)) {
                levelToValueMap = levelFilterCMDTUtil('Analysis Region', levelCountMap, loc.Company_Code__c + '-' + loc.Analysis_Region_Key__c, levelToValueMap); 
            }
            if(loc.Territory__c != null && !contextToValueMap.containsKey('Territory-' + loc.Territory__c)) {
                levelToValueMap = levelFilterCMDTUtil('Territory', levelCountMap, loc.Territory__c, levelToValueMap);    
            }
            if(loc.Inventory_Region_Key__c != null && !contextToValueMap.containsKey('Inventory Region-' + loc.Inventory_Region_Key__c)) {
                levelToValueMap = levelFilterCMDTUtil('Inventory Region', levelCountMap, loc.Inventory_Region_Key__c, levelToValueMap);   
            }
        }
        if(!levelToValueMap.isEmpty()) {
            createUpdateMetadata(JSON.serialize(levelToValueMap));
        }  
    }
    
    /**
     * @description Method to calculate get last sequence number
    */
    public static void sequenceNoUtil(){
        
        List<SBR_3_0_AssetInquiryPicklistValues__mdt> levelValuesList = new List<SBR_3_0_AssetInquiryPicklistValues__mdt>();
        String orderByClause = 'ORDER BY SM_PS_Sequence_Number__c DESC LIMIT 1';
        Double levelMap;
        
        levelValuesList= [SELECT MasterLabel, DeveloperName, SM_PS_Context__c,SM_PS_PickList_Value__c, SM_PS_Sequence_Number__c 
                          FROM SBR_3_0_AssetInquiryPicklistValues__mdt
                          WITH USER_MODE
                         ];
    
        if(!levelValuesList.isEmpty()){
            for(SBR_3_0_AssetInquiryPicklistValues__mdt levelValue : levelValuesList) {
                String key = levelValue.SM_PS_Context__c + '-' + levelValue.SM_PS_PickList_Value__c;
                contextToValueMap.put(key, levelValue.SM_PS_PickList_Value__c);
            }
        }
        SBR_3_0_AssetInquiryPicklistValues__mdt district = Database.Query('SELECT SM_PS_Sequence_Number__c FROM SBR_3_0_AssetInquiryPicklistValues__mdt WHERE SM_PS_Context__c = \'District\'' +orderByClause);
        SBR_3_0_AssetInquiryPicklistValues__mdt market = Database.Query('SELECT SM_PS_Sequence_Number__c FROM SBR_3_0_AssetInquiryPicklistValues__mdt WHERE SM_PS_Context__c = \'Market\'' + orderByClause);
        SBR_3_0_AssetInquiryPicklistValues__mdt region = Database.Query('SELECT SM_PS_Sequence_Number__c FROM SBR_3_0_AssetInquiryPicklistValues__mdt WHERE SM_PS_Context__c = \'Region\'' + orderByClause);
        SBR_3_0_AssetInquiryPicklistValues__mdt analysisRegion = Database.Query('SELECT SM_PS_Sequence_Number__c FROM SBR_3_0_AssetInquiryPicklistValues__mdt WHERE SM_PS_Context__c = \'Analysis Region\'' + orderByClause);
        SBR_3_0_AssetInquiryPicklistValues__mdt territory = Database.Query('SELECT SM_PS_Sequence_Number__c FROM SBR_3_0_AssetInquiryPicklistValues__mdt WHERE SM_PS_Context__c = \'Territory\'' + orderByClause);
        SBR_3_0_AssetInquiryPicklistValues__mdt inventoryRegion = Database.Query('SELECT SM_PS_Sequence_Number__c FROM SBR_3_0_AssetInquiryPicklistValues__mdt WHERE SM_PS_Context__c = \'Inventory Region\'' + orderByClause);
        levelMap = district != null ? levelCountMap.put('District',district.SM_PS_Sequence_Number__c) : levelCountMap.put('District',0);
        levelMap = market != null ?levelCountMap.put('Market',market.SM_PS_Sequence_Number__c) : levelCountMap.put('Market',0);
        levelMap = region != null ? levelCountMap.put('Region',region.SM_PS_Sequence_Number__c) : levelCountMap.put('Region',0);
        levelMap = analysisRegion != null ? levelCountMap.put('Analysis Region',analysisRegion.SM_PS_Sequence_Number__c) : levelCountMap.put('Analysis Region',0);
        levelMap = territory != null ? levelCountMap.put('Territory',territory.SM_PS_Sequence_Number__c) : levelCountMap.put('Territory',0);
        levelMap = inventoryRegion  != null ? levelCountMap.put('Inventory Region',inventoryRegion.SM_PS_Sequence_Number__c) : levelCountMap.put('Inventory Region',0);           
        
    }
    
    /**
     * @description Method to prepare custom metadata record 
     * @param level Stores Level Value
     * @param levelCountMap Stores last seq no against each level
     * @param picklistVal Stores picklist value for custom metadata record 
     * @param levelToValueMap Stores prepared custom metadata record against level
     * @return levelToValueMap Returned prepared custom metadata record against level
    */
    public static Map<String, Map<String, String>> levelFilterCMDTUtil(String level, Map<String, Double> levelCountMap, String picklistVal, Map<String, Map<String, String>> levelToValueMap) {
        Double seqNoCtr = levelCountMap.get(level) + 1;
        levelCountMap.put(level, seqNoCtr);
        
        Map<String, String> newCMDTRecMap = new Map<String, String>();
        newCMDTRecMap.put('SM_PS_Context__c', level);
        newCMDTRecMap.put('SM_PS_PickList_Value__c', picklistVal);
        newCMDTRecMap.put('SM_PS_Sequence_Number__c', String.ValueOf(seqNoCtr));
        
        levelToValueMap.put(picklistVal, newCMDTRecMap); 
        
        return levelToValueMap;
    }
    
}