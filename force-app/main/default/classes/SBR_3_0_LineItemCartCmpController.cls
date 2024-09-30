/*********************************************************************************************************************
* Apex Class: SBR_3_0_LineItemCartCmpController
---------------------------------------------------------------------------------------------------------------------------------------
* @description Purpose/Methods:
* - Support for product inquiry, line items and cart
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Steve Gray              2023-01-13          Initial version    
*********************************************************************************************************************/

public with sharing class SBR_3_0_LineItemCartCmpController {
    private static final String LATITUDE = 'latitude';
    private static final String LONGITUDE = 'longitude';
    public static final String QUOTE_LINE_TYPE = 'SBQQ__QuoteLine__c';
    public static final String ORDER_LINE_TYPE = 'OrderItem';
    
    
    
    /**
    * @description method to fetch lat/long from zip code
    * @param zip 
    * @return Map<String, String> 
    **/
    @AuraEnabled(cacheable = true)
    public static Map<String, String> getLatLongFromZip(String zip){
        SBR_3_0_API_FetchLatLong strLatLongApi = new SBR_3_0_API_FetchLatLong();
        Map<String, String> result = strLatLongApi.getAddressLatLong('', '', '', '', zip == null ? '' : zip, '');
        
        if(result.containsKey(LATITUDE) && String.isNotEmpty(result.get(LATITUDE)) && !result.get(LATITUDE).equalsIgnoreCase('null') && 
        result.containsKey(LONGITUDE) && String.isNotEmpty(result.get(LONGITUDE)) && !result.get(LONGITUDE).equalsIgnoreCase('null')){
            result.put('status', 'success');
        } else {
            result.put('status', 'error');
        }
        return result;
    }
    
    /*
    public static Schema.Location getBranchDetails(){
        Schema.location branch = new schema.location();
        try {
            List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
            return userLocation[0];
            
        } catch (QueryException e) {
            e.setMessage('No user location found.');
        }
        return branch;
    }
    */

    /**
    * @description Returns Profile Branch if present otherwise User Branch
    * @return Schema.Location 
    **/
    public static Schema.Location getBranchDetails(){
        Schema.location branch = new schema.location();
        try {
            // SF-6121: Updated to first check for Profile Branch Location on PI 
            // If Profile Branch is not there, use user location branch
            List<Schema.Location> userProfileBranchLocation = SBR_3_0_BranchDA.getLoggedInUserProfileBranchLocation();           
            if(userProfileBranchLocation.size() == 0) {
                List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
                branch = userLocation[0];
            }
            else{
                branch = userProfileBranchLocation[0];              
            } 
        } catch (QueryException e) {
            e.setMessage('No user location found.');
        }
        return branch;
    }
    
    
    /**
    * @description method to fetch estimates for line items
    * @param estimatesRequestJson 
    * @param companyId 
    * @return String 
    **/
    @AuraEnabled
    public static String getLineItemEstimates(String estimatesRequestJson, String companyId) { // NOPMD
        Schema.Location branch = (Schema.Location)getBranchDetails();
        Map<String, Object> estimatesRequest = (Map<String, Object>) JSON.deserializeUntyped(estimatesRequestJson);
        
        List<Object> pcList = (List<Object>)estimatesRequest.get('pc');
        Map<String, Object> pc = (Map<String, Object>)pcList[0];
        if(branch.Branch_Location_Number__c != null) { 
            pc.put('id', Integer.valueOf(branch.Branch_Location_Number__c)); 
        }
        if(branch.Latitude_Longitude__c != null) { 
            pc.put('longitude', Decimal.ValueOf(branch.Latitude_Longitude__c.getLongitude()));
            pc.put('latitude', Decimal.ValueOf(branch.Latitude_Longitude__c.getLatitude()));
        }

        // For SF-6121 : For Pickup OrderType, we do not need to pass address, delivery, pickup parameters in the estimate Json request 
        // RM will make this change as per IS-12999
        String orderType = (String) estimatesRequest.get('orderType');
        if(orderType != null && orderType.equalsIgnoreCase('Pickup')){
            estimatesRequest.remove('address');
            estimatesRequest.remove('delivery');
            estimatesRequest.remove('pickup');
        }
        else{        
            List<Object> aList = (List<Object>)estimatesRequest.get('address');
            Map<String, Object> addr = (Map<String, Object>)aList[0];
            string zip = (string)addr.get('zip');
            
            Map<String, String> latLong = getLatLongFromZip(zip);
            
            if (latLong.get('status') == 'success') {
                addr.put('latitude', Decimal.ValueOf(latLong.get('latitude')));
                addr.put('longitude', Decimal.ValueOf(latLong.get('longitude')));
                // Added city and state - SF-6121
                if(String.ValueOf(latLong.get('city'))!= null){
                addr.put('city', String.ValueOf(latLong.get('city')));
                }else{
                addr.put('city',zip);    
                }
                if(String.ValueOf(latLong.get('state'))!= null){
                addr.put('state', String.ValueOf(latLong.get('state')));
                }
            }

        }      
       
        String eRequest = JSON.serialize(estimatesRequest);
        
        return SBR_3_0_API_Estimates.getEstimates(eRequest, companyId);
    }
    
    /**
    * @description  SAL-26091 - method to delete quote/order line items along with ForcedAddons
    * @param lineIds 
    **/
    @AuraEnabled
    public static void deleteLineItems(List<String> lineIds) {
        
        List<SObject> deleteList = new List<SObject>();
        Map<id,SObject> deleteListMap=new Map<id,SObject>();
        
        if (!lineIds.isEmpty()) {
            Id firstId = (Id) lineIds[0];
            String lineType = firstId.getSobjectType().getDescribe().getName();
            
            if (lineType == ORDER_LINE_TYPE) {
                deleteOrderItems(lineIds,deleteList);
            }
            //SAL-26002
            if (lineType == QUOTE_LINE_TYPE) {
                deleteQuoteLineItems(lineIds,deleteList);
            }
            try {
                deleteListMap.putall(deleteList);
                Database.delete(deleteListMap.values(), true);
            } catch(Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }
    }


    /**
    * @description delete quote line items
    * @param lineIds 
    * @param deleteList 
    **/
    static void deleteQuoteLineItems(List<String> lineIds,List<SObject> deleteList){
        Set<String> productIds = new Set<String>();
        String quoteRecId = '';
        String companyCode='';

        List<SBQQ__QuoteLine__c> quoteLineItems = SBR_3_0_QuoteLineDA.getQuoteLines(new Set<String>(lineIds));
        for (SBQQ__QuoteLine__c item : quoteLineItems) {
            quoteRecId = item.SBQQ__Quote__c;
            companyCode = item.SBQQ__Quote__r.Company_Code__c;
            productIds.add(item.Product_SKU__c);
            deleteList.add(item);
        }

        if(productIds.isEmpty()){
            return;
        }

        List<SBQQ__QuoteLine__c> allQuoteLineItems = SBR_3_0_QuoteLineDA.getQuoteLines(quoteRecId);

        if(allQuoteLineItems.isEmpty()){
            return;
        } 
        //SF-5291,SF-5292
        for(SBQQ__QuoteLine__c fuelItemProds :allQuoteLineItems)
        {
            String kitNumber = fuelItemProds.Kit_Number_this_Item_Belongs_to__c;
            if (!String.isBlank(kitNumber) && productIds.contains(kitNumber)) {
                deleteList.add(fuelItemProds);
            }
        }
    }

    /**
    * @description Delete Order Items
    * @param lineIds 
    * @param deleteList 
    **/
    static void deleteOrderItems(List<String> lineIds,List<SObject> deleteList){
        Set<String> productIds = new Set<String>();
        String orderRecId = '';
        String companyCode = '';
        
        List<OrderItem> orderItems = SBR_3_0_OrderItemDA.getOrderItem(new Set<String>(lineIds));
        Set<String> groupIds = new Set<String>();
        List<String> ungroupedOrderItemIds = new List<String>();
        for (OrderItem item : orderItems) {
            
            orderRecId =item.OrderId;
            companyCode = item.Order.Company_Code__c;
            
            productIds.add(item.Product2.Product_SKU__c);
            
            Map<String, Object> itemObjKeyMap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(item));
            if(itemObjKeyMap.get('groupID__c') == null){
                ungroupedOrderItemIds.add(item.Id);
            }else {
                groupIds.add(item.groupID__c);
            }
        }
        List<OrderItem> ungroupedOrderItems = SBR_3_0_OrderItemDA.getOrderItem(new Set<String>(ungroupedOrderItemIds));
        deleteList.addAll((List<SObject>) SBR_3_0_OrderItemDA.getOrderItemsFromGroupId(groupIds,new Set<Id>()));
        for (OrderItem item : ungroupedOrderItems) {
            deleteList.add(item);
        }
        
        //SAL-26002
        if(productIds.isEmpty()){
            return;
        }
        List<OrderItem> allOrderLineItems = SBR_3_0_OrderItemDA.getOrderItemsByOrder(orderRecId);

        if(allOrderLineItems.isEmpty()){
            return;
        }
        //SF-5291,SF-5292
        for(OrderItem fuelItemProds :allOrderLineItems){
            String kitNumber = fuelItemProds.Kit_Number_This_Item_Belongs_to__c;
            if (!String.isBlank(kitNumber) && productIds.contains(kitNumber)) {
                deleteList.add(fuelItemProds);
            }
        }
    }

    /**
    * @description  SAL-27195 - Returns Bulk Item Flag for OrderItem
    * @param lineItemId 
    * @return Boolean 
    **/
    @AuraEnabled
    public static Boolean getLineItemBulkFlag(String lineItemId) {
        if(String.isNotBlank(lineItemId)){
            return [Select Product2.Bulk_Item__c from OrderItem where Id=: lineItemId].Product2.Bulk_Item__c;
        }
        return false;
    }

    /**
    * @description To update lineItems for Cart/Quote/Order
    * @param apiName 
    * @param lineItems 
    * @return List<SObject> 
    **/
    @AuraEnabled
    public static List<SObject> updateLineItems(String apiName,Object lineItems) {
        List<SObject> returnList = new List<SObject>();
        Map<Id,SObject> returnMap = new Map<Id,SObject>();  //SF-7556
        try{List<Object> fieldList = (List<Object>)JSON.deserializeUntyped(lineItems.toString());
            for(Object fld : fieldList){    
                Map<String,Object> data = (Map<String,Object>)fld;
                if(apiName == 'SBQQ__Quote__c'){
                    SBQQ__QuoteLine__c quoteLine = (SBQQ__QuoteLine__c) JSON.deserializeStrict(JSON.serialize(data.get('fields')), SBQQ__QuoteLine__c.class);
                    //returnList.add(quoteLine);
                    returnMap.put(quoteLine.Id,quoteLine);
                }
                if(apiName == 'Cart__c'){
                    Cart_Items__c cartLine = (Cart_Items__c) JSON.deserializeStrict(JSON.serialize(data.get('fields')), Cart_Items__c.class);
                    //returnList.add(cartLine);
                    returnMap.put(cartLine.Id,cartLine);
                }
                if(apiName == 'Order'){
                    OrderItem orderLine = (OrderItem) JSON.deserializeStrict(JSON.serialize(data.get('fields')), OrderItem.class);
                    //returnList.add(orderLine);
                    returnMap.put(orderLine.Id,orderLine);
                }
            }
            system.debug('returnList >>>> '+returnList);

            if(!returnMap.isEmpty() && (Schema.sObjectType.SBQQ__QuoteLine__c.isUpdateable() && Schema.sObjectType.OrderItem.isUpdateable() && Schema.sObjectType.Cart_Items__c.isUpdateable())){
                returnList = returnMap.values();
                update returnList; // NOPMD
            }
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return returnList;
    }
     /**
    * @description common method to update fuel line items from RM-SF
    * @param lineItems 
    * @param parentFieldApiName 
    * @param productFieldApiName
    * @param productSkuFieldApiName
    * @param parentIdFieldApiNameOnParent
    * @param reservationOrderNumberFieldApiName
    **/
    public static void updateFuelPlanItems(List<SObject> lineItems, String parentFieldApiName, String productFieldApiName, String productSkuFieldApiName, String parentIdFieldApiNameOnParent, String reservationOrderNumberFieldApiName) {
        Set<Id> parentIds = new Set<Id>();
        List<String> lineItemProductIds = new List<String>();
        Map<String, SObject> lineItemMap = new Map<String, SObject>();
        List<String> companyCodeList=new List<String>(); 

        for (SObject item : lineItems) {
            parentIds.add((Id)item.get(parentFieldApiName));
            lineItemProductIds.add((String)item.get(productFieldApiName));
            lineItemMap.put((String)item.get(productSkuFieldApiName), item);
        }

        String queryString;
        if (!lineItems.isEmpty()) {
            queryString = 'SELECT Id,Company_Code__c, ' + reservationOrderNumberFieldApiName
                                 + ' FROM ' + parentIdFieldApiNameOnParent + ' WHERE Id IN :parentIds AND ' + reservationOrderNumberFieldApiName +' != NULL ';      
        }

        Map<Id, SObject> parentMap = new Map<Id,SObject>(Database.query(queryString));
        if(!parentMap.isEmpty() && parentMap != null){
            for(sObject parentRecord: parentMap.values()){
                companyCodeList.add((String)parentRecord.get('Company_Code__c'));
            }
            Map<String, Object> productOptionMap = SBR_3_0_ProductDA.getProductOptionsWithFuelCharge(lineItemProductIds, companyCodeList);
            // Update line items
            // 04.02.2024:SG:PS-5290- Added null check for productOptionMap
            if(productOptionMap!=null && !productOptionMap.isEmpty()){   
                for (SObject item : lineItems) {
                    SObject parent = parentMap.get((Id)item.get(parentFieldApiName));
                        SBQQ__ProductOption__c fuelChargeOption = (SBQQ__ProductOption__c)productOptionMap.get((String)item.get(productFieldApiName));
                        String companyCodeId = (String)parent.get('Company_Code__c');
                        if(fuelChargeOption != null) {
                            Boolean companyCodeMatch = fuelChargeOption.get('Company_Code__c') == companyCodeId;
                            if (parent != null && companyCodeMatch && String.isNotBlank((String)parent.get(reservationOrderNumberFieldApiName))) {
                                item.put('Fuel_Plan__c', true);
                                SObject relatedItem = lineItemMap.get(fuelChargeOption.SBQQ__OptionalSKU__r.Product_SKU__c);
                                if (relatedItem != null) {
                                    relatedItem.put('Kit_Number_this_Item_Belongs_to__c', fuelChargeOption.SBQQ__ConfiguredSKU__r.Product_SKU__c);
                                    relatedItem.put('Line_Comments__c', 'Fuel Plan for ' + fuelChargeOption.SBQQ__ConfiguredSKU__r.Name);
                                }
                            }
                        }
                }
            }
        }
   
}
}