/*********************************************************************************************************************
* Apex Class: SBR_3_0_ProductItemEventOperations
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Class used to update the product item record by comparing the timestamp.

---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Shilpa Mitra                      2024-02-22             Initial version(PS-4644)
    
*********************************************************************************************************************/
public with sharing class SBR_3_0_ProductItemEventOperations {
    public static List<Exception_Log__c> exceptionLogList = new List<Exception_Log__c>();
    private static final Map<String, String> RECORD_FIELD_TO_EVENT_FIELD_MAP = new Map<String, String>{
            'LocationId'               => 'SM_PS_LocationId__c',
            'Product2Id'               => 'SM_PS_Product2Id__c',
            'QuantityOnHand'           => 'QuantityOnHand__c',
            'RecordTypeId'             => 'SM_PS_RecordTypeId__c'
    };
    /**
    * @description Update Product Item record based on platform event
    * @param newProductItemEventMap store the SBR_3_0_Product_Item__e record in the form of Map<id,SBR_3_0_Product_Item__e>
    */
    public static void updateProductItems(Map<Id, SBR_3_0_Product_Item__e> newProductItemEventMap) {
        //System.debug(JSON.serializePretty(newProductItemEventMap));
        Set<String> productItemExternalIds = new Set<String>();
        Map<String, SBR_3_0_Product_Item__e> newProductItemEventsByExternalId = new Map<String, SBR_3_0_Product_Item__e>();
        List<Database.UpsertResult> results;
        for (SBR_3_0_Product_Item__e productItemEvent : newProductItemEventMap.values()) {
            productItemExternalIds.add(productItemEvent.SM_PS_ProductItem_Id__c);
            newProductItemEventsByExternalId.put(productItemEvent.SM_PS_ProductItem_Id__c, productItemEvent);
        }
        Map<String, ProductItem> oldProductItemsByExternalId = new Map<String, ProductItem>();
        for (ProductItem oldProductItem : [
                SELECT
                        Id, SM_PS_Last_Message_DateTime_Stamp__c, SM_PS_ProductItem_Id__c
                FROM
                        ProductItem
                WHERE
                        SM_PS_ProductItem_Id__c IN :productItemExternalIds
                WITH SECURITY_ENFORCED]) {
            oldProductItemsByExternalId.put(oldProductItem.SM_PS_ProductItem_Id__c, oldProductItem);
        }
        //System.debug(JSON.serializePretty(oldProductItemsByExternalId));

        Map<String, ProductItem> productItemsToUpdateByExternalId = new Map<String, ProductItem>();

        Map<String, String> recordFieldToEventFieldMapForCreate = buildRecordFieldToEventFieldMapForCreate();
        Map<String, String> recordFieldToEventFieldMapForUpdate = buildRecordFieldToEventFieldMapForUpdate();
        for (String externalId : newProductItemEventsByExternalId.keySet()) {
            SBR_3_0_Product_Item__e newProductItemEvent = newProductItemEventsByExternalId.get(externalId);
            ProductItem productItemToCompare;
            if(productItemsToUpdateByExternalId.containsKey(externalId)) {
                productItemToCompare = productItemsToUpdateByExternalId.get(externalId);
            } else {
                productItemToCompare = oldProductItemsByExternalId.get(externalId);
            }
            //system.debug('productItemToCompare'+productItemToCompare);
            try{
                if(productItemToCompare == null) {
                    productItemsToUpdateByExternalId.put(externalId, createProductItemFromEventForCreate(recordFieldToEventFieldMapForCreate, newProductItemEvent));
                } else if(compareTimestamp(newProductItemEvent.SM_PS_Last_Message_DateTime_Stamp__c, productItemToCompare.SM_PS_Last_Message_DateTime_Stamp__c) > 0) {
                    productItemsToUpdateByExternalId.put(externalId, createProductItemFromEventForUpdate(recordFieldToEventFieldMapForUpdate, newProductItemEvent, productItemToCompare.Id));
                }
            }catch(Exception e){
                createException(e);
            }
                
            
        }
        //System.debug(JSON.serializePretty(productItemsToUpdateByExternalId.values()));
       /*try {
            upsert productItemsToUpdateByExternalId.values();
        } catch (Exception e) {
            System.debug(e);
           SBR_3_0_LogException.LogIt(e);
        }*/
           
        	results = Database.upsert(productItemsToUpdateByExternalId.values(),false);
       
            if(results != null){
                createDMLExceptionLog(results,productItemsToUpdateByExternalId.values());
            }
            
            if(!exceptionLogList.isEmpty()){
                insert exceptionLogList;
            }
       
        //System.debug(JSON.serializePretty(productItemsToUpdateByExternalId.values()));
    }
	/**
    * @description createDMLExceptionLog is used to find the error log and create exception log record
    * @param results stores the log for DML operation
    * @param productItemList stores the list of Product Item record that are created/updated
    * @return List of Exception log record
    */
    private static List<Exception_Log__c> createDMLExceptionLog(List<Database.UpsertResult> results, List<ProductItem> productItemList) {
        for(Integer i=0;i<results.size();i++){
            if(!results[i].isSuccess() && results[i].getErrors()[0].getMessage().toString()=='Product Item Location must be an inventory location.'){
               exceptionLogList.add(createException(new DMLException('ProductItem Upsert Failed: '+results[i].getErrors()[0].getMessage().toString() +' - Location Id: '+String.valueof(productItemList[i].LocationId))));
            }else if(!results[i].isSuccess()){
                exceptionLogList.add(createException(new DMLException('ProductItem Upsert Failed: '+results[i].getErrors()[0].getMessage().toString())));
            }   
        }
        return exceptionLogList;
    }
    
    /**
    * @description compareTimestamps is used to compare the two timestamp
    * @param timestamp1 refers to platform event's SM_PS_Last_Message_DateTime_Stamp__c field
    * @param timestamp2 refers to productItem's SM_PS_Last_Message_DateTime_Stamp__c field
    * @return integer value based on comparision
	*/
    
    /*private static Integer compareTimestamps(String timestamp1, String timestamp2) {
        List<String> splitTimestamp1 = timestamp1.split('[-:TZ]');
        List<String> splitTimestamp2 = timestamp2.split('[-:TZ]');
        if(splitTimestamp1.size() != splitTimestamp2.size()) {
            throw new IllegalArgumentException('');
        }
        for(Integer i = splitTimestamp1.size() - 1; i >= 0; i--) {
            if(Decimal.valueOf(splitTimestamp1[i]) > Decimal.valueOf(splitTimestamp2[i])) {
                return 1;
            } else if(Decimal.valueOf(splitTimestamp1[i]) < Decimal.valueOf(splitTimestamp2[i])) {
                return -1;
            }
        }
        return 0;
    }*/
    
    /**
    * @description compareTimestamp is used to compare the two timestamp
    * @param timestamp1 refers to platform event's SM_PS_Last_Message_DateTime_Stamp__c field
    * @param timestamp2 refers to productItem's SM_PS_Last_Message_DateTime_Stamp__c field
    * @return difference value based on comparision
	*/
    
    private static Double compareTimestamp(String timestamp1, String timestamp2) {
        Double time1WithMillisecond=0;
        Double time2WithMillisecond=0;
        Double time1WithMillisecondExtra=0;
        Double time2WithMillisecondextra=0;
        Double difference = 0;
        if(timestamp1 != null){
            DateTime time1 = DateTime.Valueof(timestamp1.replaceAll('[ZT]', ' '));
            time1WithMillisecondExtra = Double.valueOf(timestamp1.replaceAll('[ZT]', ' ').split('[.]')[1]);
            time1WithMillisecond= time1.getTime();
        }
        if(timestamp2 != null){
            DateTime time2 = DateTime.Valueof(timestamp2.replaceAll('[ZT]', ' '));
        	time2WithMillisecond= time2.getTime();
            time2WithMillisecondExtra = Double.valueOf(timestamp2.replaceAll('[ZT]', ' ').split('[.]')[1]);
        }
        if(time1WithMillisecond-time2WithMillisecond > 0){
            difference = time1WithMillisecond-time2WithMillisecond;
        }else{
            difference = time1WithMillisecondExtra - time2WithMillisecondExtra;
        }
        return difference;
    }
    
    /**
    * @description createProductItemFromEventForCreate is used to call create productItem method
    * @param recordFieldToEventFieldMap holds the field api name of platform event as value and product item field as key
    * @param productItemEvent holds platform event data
    * @return returns the ProductItem record
	*/
    private static ProductItem createProductItemFromEventForCreate(Map<String, String> recordFieldToEventFieldMap, SBR_3_0_Product_Item__e productItemEvent) {
        return createProductItemFromEventShared(recordFieldToEventFieldMap, productItemEvent, new ProductItem());
    }
	
    /**
    * @description createProductItemFromEventForUpdate is used to call update productItem method
    * @param recordFieldToEventFieldMap holds the field api name of platform event as value and product item field as key
    * @param productItemEvent holds platform event record
    * @param productItemId holds productItem record Id
    * @return returns the ProductItem record
	*/
    private static ProductItem createProductItemFromEventForUpdate(Map<String, String> recordFieldToEventFieldMap, SBR_3_0_Product_Item__e productItemEvent, Id productItemId) {
        return createProductItemFromEventShared(recordFieldToEventFieldMap, productItemEvent, new ProductItem(Id = productItemId));
    }
	
    /**
    * @description createProductItemFromEventForUpdate is used to create/update productItem record
    * @param recordFieldToEventFieldMap holds the field api name of platform event as value and product item field as key
    * @param productItemEvent holds platform event record
    * @param baseProductItem holds productItem record
    * @return returns the ProductItem record
	*/
    private static ProductItem createProductItemFromEventShared(Map<String, String> recordFieldToEventFieldMap, SBR_3_0_Product_Item__e productItemEvent, ProductItem baseProductItem) {
        for (String recordField : recordFieldToEventFieldMap.keySet()) {
            baseProductItem.put(recordField, productItemEvent.get(recordFieldToEventFieldMap.get(recordField)));
        }
        return baseProductItem;
    }

    /**
    * @description buildRecordFieldToEventFieldMapForCreate
    * @return Map<String, String> which holds the field api name of platform event as value and product item field as key
    */
    private static Map<String, String> buildRecordFieldToEventFieldMapForCreate() {
        return buildRecordFieldToEventFieldMap(true);
    }
 
    /**
    * @description buildRecordFieldToEventFieldMapForUpdate
    * @return Map<String, String> which holds the field api name of platform event as value and product item field as key
    */
    private static Map<String, String> buildRecordFieldToEventFieldMapForUpdate() {
        return buildRecordFieldToEventFieldMap(false);
    }
    
    /**
    * @description buildRecordFieldToEventFieldMap is used to compare the field api name and store in the form of map
    * @param isForCreate accepts boolean which determines the create/update
    * @return Map<String, String> which holds the field api name of platform event as value and product item field as key
    */
    private static Map<String, String> buildRecordFieldToEventFieldMap(Boolean isForCreate) {
        Set<String> eventFields = new Set<String>();
        for (SObjectField field : SBR_3_0_Product_Item__e.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().values()) {
            eventFields.add(field.toString());
        }
        Map<String, String> result = new Map<String, String>();
        for (SObjectField field : ProductItem.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).fields.getMap().values()) {
            String fieldString = field.toString();
            if((!isForCreate && !field.getDescribe().isUpdateable()) || (isForCreate && !field.getDescribe().isCreateable())) {
                continue;
            }
            if(eventFields.contains(fieldString)) {
                result.put(fieldString, fieldString);
            } else if(RECORD_FIELD_TO_EVENT_FIELD_MAP.containsKey(fieldString)) {
                result.put(fieldString, RECORD_FIELD_TO_EVENT_FIELD_MAP.get(fieldString));
            }
        }
        return result;
    }
    
    /**
    * @description createException is used to create exception log record
    * @param e stores the exception data
    * @return Exception log record
    */
    private static Exception_Log__c createException(Exception e) {
		    String stackTrace = e.getStackTraceString().substringBefore('\n');
		    String className = stackTrace.substringAfter('.').substringBefore('.');	
            String methodName = stackTrace.substringBefore(':').substringAfter(className).substringAfter('.');
            
            //Governer Limit of executingQuery 
            String queryLimit = 'SOQL: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries();
            String dMLimit = 'Records: ' + Limits.getDmlRows() + ' of ' + Limits.getLimitDmlRows();
            String dMLStat = 'DML Stmts' +  Limits.getDmlStatements() + ' of ' + Limits.getLimitDmlStatements();   
            String cPUT = 'CPU time (in ms): ' + Limits.getCpuTime() + ' of ' + Limits.getLimitCpuTime();
            
            //Log information in object
            Exception_Log__c exc = new Exception_Log__c();
            exc.Govt_Limit_in_Executing_Code__c = String.format('{0}\n{1}\n{2}\n{3}',new List<Object> {queryLimit, dMLimit, dMLStat, cPUT});
            exc.Exception_Message__c = e.getMessage();
            exc.Exception_Type__c = e.getTypeName();
            exc.Line_Number__c = e.getLineNumber();
            exc.Stack_Trace__c = e.getStackTraceString();
            exc.Method_Name__c= methodName;
            exc.Class_Name__c= className;
            return exc;
        } 

}