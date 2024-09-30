/*********************************************************************************************************************
* Apex Class: SBR_3_0_WOPriorityController
---------------------------------------------------------------------------------------------------------------------------------------
* @description
* - Controller class for loading data for Work Order Priority LWC Components
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
*   1.0         Chhavi Singhal          26-Dec-2023         Initial version
*********************************************************************************************************************/
public without sharing class SBR_3_0_WOPriorityController {
   
    /**
     * @description Get Standard Filters Records from SBR_3_0_WOPriority_Standard_Filters__mdt custom metadata type
     * @param objectName API name of object the returned filters should apply to
     * @return Relevant SBR_3_0_WOPriority_Standard_Filters__mdt records
     */
    @AuraEnabled(Cacheable = true)
    public static List<SBR_3_0_WOPriority_Standard_Filters__mdt> getStandardFiltersDetails(String objectName) {
        List<SBR_3_0_WOPriority_Standard_Filters__mdt> availableStandardFiltersList = new List<SBR_3_0_WOPriority_Standard_Filters__mdt>();
        List<SBR_3_0_WOPriority_Standard_Filters__mdt> standardFiltersList = new List<SBR_3_0_WOPriority_Standard_Filters__mdt>();
        
        availableStandardFiltersList = [SELECT MasterLabel, DeveloperName,SM_PS_Filter_Name__c, SM_PS_isDefault__c, 
                                        SM_PS_Object_Name__c, SM_PS_Sequence_Order__c, 
                                        SM_PS_Where_Clause__c, SM_PS_Status_IN__c, SM_PS_Asset_Status_IN__c, 
                                        SM_PS_Asset_Equipment_Type_IN__c
                                        FROM SBR_3_0_WOPriority_Standard_Filters__mdt
                                        WITH USER_MODE
                                       ];
        
        for(SBR_3_0_WOPriority_Standard_Filters__mdt woPriorityStandardFilter : availableStandardFiltersList) {
            if(objectName == woPriorityStandardFilter.SM_PS_Object_Name__c) {
                standardFiltersList.add(woPriorityStandardFilter);
            }
        }
        if(standardFiltersList.size() > 0){
            standardFiltersList.sort();
        }
        
        return standardFiltersList;   
    }
    
    /**
     * @description Get Level (Branch/District/Inventory Region) Records from SBR_3_0_AssetInquiryPicklistValues__mdt custom metadata type
     * @param context Return only SBR_3_0_AssetInquiryPicklistValues__mdt records where SM_PS_Context__c equals this value
     * @return Relevant SBR_3_0_AssetInquiryPicklistValues__mdt records
     */
    @AuraEnabled(Cacheable = true)
    public static List<SBR_3_0_AssetInquiryPicklistValues__mdt> getPicklistMetadata(String context) {
        List<SBR_3_0_AssetInquiryPicklistValues__mdt> picklistValuesList = new List<SBR_3_0_AssetInquiryPicklistValues__mdt>();
        for(SBR_3_0_AssetInquiryPicklistValues__mdt workOrderPriorityPicklistValue : SBR_3_0_AssetInquiryPicklistValues__mdt.getAll().values()) {    
            if(context == workOrderPriorityPicklistValue.SM_PS_Context__c) {
                if(context == 'Level' && workOrderPriorityPicklistValue.SM_PS_Required_for_Work_Order_Priority__c == true) {
                    picklistValuesList.add(workOrderPriorityPicklistValue);
                } else if (context != 'Level') {
                    picklistValuesList.add(workOrderPriorityPicklistValue);
                } 
            } 
        }
        if(picklistValuesList.size() > 0) {
            picklistValuesList.sort();
        } 
        return picklistValuesList; 
    }
    
    /**
     * @description Get User's Current Location
     * @return Location record from current User's User_Location__c record
     */
    @AuraEnabled(Cacheable = true)
    public static Schema.Location getCurrentUserLocation() {
        Schema.Location userCurrentLocation = null;
        try { 
            Id currentUserId = UserInfo.getUserId();
            User_Location__c currentUserLocation = [SELECT Id, Name, User__c, Branch__c, SM_PS_District__c, Reporting_District_Name__c, SM_PS_Inventory_Region_Key__c  
                                                    FROM User_Location__c 
                                                    WHERE User__c =: currentUserId
                                                    WITH USER_MODE LIMIT 1];
           
            if(currentUserLocation != null && currentUserLocation.Branch__c != null) {
               userCurrentLocation = [SELECT Id, Name
                                      FROM Location
                                      WHERE Id =: currentUserLocation.Branch__c
                                      WITH USER_MODE LIMIT 1];
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return userCurrentLocation;
    }
    
    /**
     * @description Get User's Current Location Record Details
     * @return User_Location__c for current User
     */
    @AuraEnabled(Cacheable = true)
    public static Schema.User_Location__c getCurrentUserLocationRecord() 
    {
        Id currentUserId = UserInfo.getUserId();
        User_Location__c currentUserLocation = [SELECT Id, Name, User__c, Branch__c, SM_PS_District__c, Reporting_District_Name__c, SM_PS_Inventory_Region_Key__c  
                                                FROM User_Location__c 
                                                WHERE User__c =: currentUserId
                                                WITH USER_MODE LIMIT 1];
        
        return currentUserLocation;
    }
    
    
    /**
     * @description Get WorkOrder Table Column Records from CustomDataTableCmpColumn__mdt custom metadata type
     * @return All CustomDataTableCmpColumn__mdt records where Context__c is "Work Order Priority"
     */
    @AuraEnabled(Cacheable = true)
    public static List<CustomDataTableCmpColumn__mdt> getItemSearchColumns(){
        //try {
            // Using CustomDataTableCmpColumn__mdt.getAll() causes Salesforce to trim SM_PS_List_Views_Allowed__c to 255
            // characters as of API v59.0, but SOQL does not have this limitation. The following return statement
            // generates and runs a query to get all CustomDataTableCmpColumn__mdt fields for all records where
            // Context__c is "Work Order Priority"
            return (List<CustomDataTableCmpColumn__mdt>)Database.query(
                    String.format(
                            'SELECT {0} FROM CustomDataTableCmpColumn__mdt WHERE Context__c = \'Work Order Priority\'',
                            new List<String>{
                                    String.join(CustomDataTableCmpColumn__mdt.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().keySet(), ',')
                            }
                    )
            );
        /*} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }*/
    } 
    
    /**
     * @description Get Filtered WorkOrder Records Count
     * @param sCountQuery SOQL COUNT() query to run
     * @return Number of values returned by a COUNT() query
     */
    @AuraEnabled(Cacheable = true)
    public static Integer getFilteredWorkOrdersCount(String sCountQuery) {
           Integer recordCount = Database.countQuery(sCountQuery);
           
           return recordCount;
    }
    
    /**
     * @description Get Filtered WorkOrder Records
     * @param sQuery WorkOrder SOQL query to run
     * @return Work Orders returned by specified query
     */
    @AuraEnabled(Cacheable = true)
    public static List<WorkOrder> getFilteredWorkOrders(String sQuery) {
            List<WorkOrder> filteredWOList = new List<WorkOrder>();
            for(WorkOrder oWO : Database.query(sQuery)){
                filteredWOList.add(oWO);
            }
            return filteredWOList;
    }

    /**
     * @description Get Picklist Values from Picklist fields (Asset.Status, Asset.Equipment Type, WorkOrder Desc, Claim Type etc.)
     * @param objectName API name of the SObject with the picklist field
     * @param fieldName API name of the picklist field
     * @return List of possible picklist values
     */
    @AuraEnabled(Cacheable = true)
    public static List<String> getPickListValuesFromFields(String objectName, String fieldName) {
        List<String> valuesList = new List<String>();
        Schema.DescribeSObjectResult[] objectResultsList = Schema.describeSObjects(new String[]{objectName}, SObjectDescribeOptions.DEFERRED);

        for(Schema.DescribeSObjectResult objectResult : objectResultsList) {
            for (Schema.PicklistEntry pickListEntry : objectResult.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if(pickListEntry.isActive()) {
                    valuesList.add(pickListEntry.getValue());
                }
            }
        }
        return valuesList;
   }
}