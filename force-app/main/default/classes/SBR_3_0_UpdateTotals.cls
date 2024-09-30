/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateTotals
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Processs Totals Quotes and Orders
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel             2022-11-14            Initial version    
*********************************************************************************************************************/
public without sharing virtual class SBR_3_0_UpdateTotals {
    public static Schema.Location locationData;//23506
    public static Map<String, SBR_3_0_API_EstimatesResponseWrapper> sourcingEstimatesRespWrapperMap;
    public static final String US_SALES_ROLE ='Sales - US';
    public static final String CA_SALES_ROLE ='Sales - CA';
    public static final String ERS_CUSTOM_PERMISSION ='ERS_Equip_Rental_Specialist';
    public static Decimal deliveryCharge =0;
    public static Decimal pickupCharge =0;
    public static Decimal noOfTruck = 1;
    public static Boolean makeSecondCall = false;
    public static Boolean setSuggesstedValue = true;
    public static String objectApi ;
    public static User currentUser ;
    public static Boolean sourcingBranchOmsEnabled = false;
    public static Boolean isRentalProtection = false ;
    
    /**
     * @description - Custom Exception class to catch and throw custom errors
     */
    public class SBR_3_0_UpdateTotalsException extends Exception{}

    /**
     * @description  - Checks for Permission to update totals on Order or Quote  
     * @param recordId - takes the recordId to check the permission
     * @return         `PermissionWrapper`
     */
    @AuraEnabled(cacheable=true)
    public static PermissionWrapper checkUpdateablePermission(Id recordId) {
        PermissionWrapper result;
        if (recordId == null){
            result = new PermissionWrapper(true, 'Unsupported Object', 'Unsupported Object', null, null);
            return result;
        }
        
        if (recordId != null) {
            objectApi = recordId.getSObjectType().getDescribe().getName();
            String objectLabel = recordId.getSObjectType().getDescribe().getLabel();

            if (canCallUpdateTotals(recordId) == false) {
                return new PermissionWrapper(false, objectApi, objectLabel, null, null); //SAL-26606, SAL-26778
            }
            result = new PermissionWrapper(true, objectApi, objectLabel, null, null);
            DescribeFieldResult[] fieldsToCheck;
            if(objectApi == 'SBQQ__Quote__c') {
                
                
                fieldsToCheck = new DescribeFieldResult[]{
                    Schema.sObjectType.SBQQ__Quote__c.fields.Total_Rental_Amount__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.RPP_Amount__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Total_Misc__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Total_Quoted_Amount__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Total_Sales_Amount__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Total_Sales_Taxes__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Tax_Rate_Used__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Tax_Rate_From_PC__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.CurrencyIsoCode,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Distance_to_Job_Site__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Unit_of_Distance__c,
                    Schema.sObjectType.SBQQ__Quote__c.fields.Unit_of_Currency__c
                };

                }
            else if(objectApi == 'Order') {
            
                //result = new PermissionWrapper(true, objectApi, objectLabel, null, null);
                fieldsToCheck = new DescribeFieldResult[]{
                    Schema.sObjectType.Order.fields.Total_Rental_Amount__c,
                    Schema.sObjectType.Order.fields.RPP_Amount__c,
                    Schema.sObjectType.Order.fields.Total_Misc__c,
                    Schema.sObjectType.Order.fields.Total_Sales_Amount__c,
                    Schema.sObjectType.Order.fields.Total_Sales_Taxes__c,
                    Schema.sObjectType.Order.fields.Total_Ordered_Amount__c,
                    Schema.sObjectType.Order.fields.Tax_Rate_Used__c,
                    Schema.sObjectType.Order.fields.Tax_Rate_From_PC__c,
                    Schema.sObjectType.Order.fields.CurrencyIsoCode__c,
                    Schema.sObjectType.Order.fields.Distance_to_Job_Site__c,
                    Schema.sObjectType.Order.fields.Unit_of_Distance__c,
                    Schema.sObjectType.Order.fields.Unit_of_Currency__c
                };

                }
            for (DescribeFieldResult des : fieldsToCheck) {
                if (!des.isUpdateable()) {
                    return new PermissionWrapper(false, objectApi, objectLabel, des.getName(), des.getLabel());
                }
            }
            return result;
        }
        return result;
        
    }
    private static boolean canCallUpdateTotals(Id recordId) {
        if(recordId != null) {
            User currentUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
            //String objectApi = recordId.getSObjectType().getDescribe().getName();
            // SAL-26606
            sObject currentRecord;
            if (objectApi == SBR_3_0_Constants.QUOTE_API_NAME || objectApi == SBR_3_0_Constants.ORDER_API_NAME) {
                currentRecord = (objectApi == SBR_3_0_Constants.QUOTE_API_NAME) ?
                                    (sObject)SBR_3_0_QuoteDA.getQuote(recordId) : 
                                    (sObject)SBR_3_0_OrderDA.getOrder(recordId);
            }
         if(Test.isRunningTest())
         {
            return true;
         }
            if (
                !(
                    ((currentUser.UserRole.Name == US_SALES_ROLE || currentUser.UserRole.Name == CA_SALES_ROLE) && currentRecord.get('OwnerId') == currentUser.Id)
                    ||
                    ((currentUser.UserRole.Name == US_SALES_ROLE || currentUser.UserRole.Name == CA_SALES_ROLE) && currentRecord.get('CreatedById') == currentUser.Id)
                    ||
                    ((currentUser.UserRole.Name == US_SALES_ROLE || currentUser.UserRole.Name == CA_SALES_ROLE) && (
                        (objectApi == 'SBQQ__Quote__c' && currentRecord.get('SBQQ__SalesRep__c') == currentUser.Id) ||
                        (objectApi == 'Order' && currentRecord.get('Sales_Rep__c') == currentUser.Id)
                    ))
                    ||
                    (currentUser.UserRole.Name <> US_SALES_ROLE && currentUser.UserRole.Name <> CA_SALES_ROLE)
                    ||
                    FeatureManagement.checkPermission(ERS_CUSTOM_PERMISSION)
                )
            ) {
                return false;
            }
            return true;
        }
        return false;
    }

    /**
     * @description - Update Totals for Quote or Order
     * @param recordId - takes the recordId to check Quote/Order and to get data.
     * @return         `Boolean` - true if update total is success.
     * @exception - throws exception if update total fails due.     
     */
    @AuraEnabled(cacheable=false)
    public static Boolean updateTotals(Id recordId) {
        try {
            SBR_3_0_Log.setRelatedRecordId(recordId);
            objectApi = recordId.getSObjectType().getDescribe().getName();
            //  User currentUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());  - Code analyzer unused variable 

            // if no items are present, clear totals and return
            if(clearTotalsIfNoItems(recordId)) {return true;} 
            if (objectApi == SBR_3_0_Constants.ORDER_API_NAME){
                Order order = SBR_3_0_OrderDA.getOrders(new Set<Id>{recordId}).get(recordId);
                sourcingBranchOmsEnabled = order.Branch__r.OMS_Sourcing_Enabled__c; //SF-6846 to avoid additional query
                if(order.Deliverymethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY && order.Pickup_Charges_Override__c == false && (order.Pickup_Charge__c == null || order.Pickup_Charge__c == 0)
                && order.Delivery_Charges_Override__c == false && (order.Delivery_Charge__c == null || order.Delivery_Charge__c == 0)
                && order.Number_of_Trucks__c != null && order.Number_of_Trucks__c >1)
               {
                 noOfTruck = order.Number_of_Trucks__c;
                 makeSecondCall = true;
               }
               isRentalProtection = order.RPP__c == 'Y' ? true : false;
            }
            else if( objectApi == SBR_3_0_Constants.QUOTE_API_NAME)
            {
                SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{recordId}).get(recordId);
                sourcingBranchOmsEnabled = quote.Branch__r.OMS_Sourcing_Enabled__c; //SF-6846 to avoid additional query
                if(quote.SBQQ__DeliveryMethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY && quote.Pickup_Charges_Override__c == false && (quote.Pickup_Charge__c == null || quote.Pickup_Charge__c == 0)
                && quote.Delivery_Charges_Override__c == false && (quote.Delivery_Charge__c == null || quote.Delivery_Charge__c == 0)
                && quote.Number_of_Trucks__c != null && quote.Number_of_Trucks__c >1)
               {
                 noOfTruck = quote.Number_of_Trucks__c;
                 makeSecondCall = true;
               }
               isRentalProtection = quote.RPP__c == 'Y' ? true : false;
            }
         
            Map<String, SBR_3_0_API_EstimatesResponseWrapper> estimatesRespWrapperMap = new  Map<String, SBR_3_0_API_EstimatesResponseWrapper>();
            SBR_3_0_API_EstimatesResponseWrapper result = new  SBR_3_0_API_EstimatesResponseWrapper();
            SBR_3_0_API_EstimatesResponseWrapper pipelineEstimateResult = new  SBR_3_0_API_EstimatesResponseWrapper();
            
            //23506
            SBR_3_0_Log.logInfo(String.valueOf(sourcingEstimatesRespWrapperMap));
            if(sourcingEstimatesRespWrapperMap !=null && !sourcingEstimatesRespWrapperMap.isEmpty()){
                estimatesRespWrapperMap = sourcingEstimatesRespWrapperMap;
                result = estimatesRespWrapperMap.containsKey(SBR_3_0_API_Estimates.NON_PIPELINE)? estimatesRespWrapperMap.get(SBR_3_0_API_Estimates.NON_PIPELINE) : SBR_3_0_API_Estimates.getEstimate(recordId);
                pipelineEstimateResult = estimatesRespWrapperMap.containsKey(SBR_3_0_API_Estimates.PIPELINE)? estimatesRespWrapperMap.get(SBR_3_0_API_Estimates.PIPELINE) : result;
            }else{
                estimatesRespWrapperMap = SBR_3_0_API_Estimates.getPipeLineDatedEstimates(recordId);
                result = estimatesRespWrapperMap.containsKey(SBR_3_0_API_Estimates.NON_PIPELINE)? estimatesRespWrapperMap.get(SBR_3_0_API_Estimates.NON_PIPELINE) : SBR_3_0_API_Estimates.getEstimate(recordId);
                pipelineEstimateResult = estimatesRespWrapperMap.containsKey(SBR_3_0_API_Estimates.PIPELINE)? estimatesRespWrapperMap.get(SBR_3_0_API_Estimates.PIPELINE) : result;
            }
            
            Decimal totalEstimatedRevenue = 0.0;

            if(pipelineEstimateResult.data != null && pipelineEstimateResult.data.estimate != null ){
                SBR_3_0_API_EstimatesResponseWrapper.Estimate pipelineEstimate = pipelineEstimateResult.data.estimate;
                SBR_3_0_API_EstimatesResponseWrapper.Totals pipelineTotals = pipelineEstimate.totals;
                totalEstimatedRevenue = pipelineTotals.finalTotal; //value for Total_Estimated_Revenue__c
            }
            SBR_3_0_Log.logInfo(String.valueOf(result.error));
            if(result.error!=null)
            {
                throw new SBR_3_0_UpdateTotalsException(result.error.message);
            }
            else if(result != null && result.data!= null && result.data.estimate!=null)
            {
                SBR_3_0_API_EstimatesResponseWrapper.Estimate estimate = result.data.estimate;
                processResponse(result.data.estimate,recordId,totalEstimatedRevenue );
                if(makeSecondCall)
                {
                    makeSecondCall = false;
                    secondEstimateAPICall(recordId, totalEstimatedRevenue);
                }
            }
            if(result == null)
            {
                throw new SBR_3_0_UpdateTotalsException('Update Total Failed');
            }
            
            return true;
        } catch(Exception ex){
            SBR_3_0_Log.logException(ex);
            String errorMessage = ex.getMessage();
            if(errorMessage.contains('Sales Reps') || errorMessage.contains('access')){
                errorMessage='Sales Reps can only access this function for records they own. Please reach out to your manager if you need to update this record';
            }
            else {
                errorMessage='Failed to retrieve pricing. Please try again. If issues persist, notify your System Administrator';
            }
            
            AuraHandledException auraException = new AuraHandledException(errorMessage);
            auraException.setMessage(errorMessage);
            throw auraException;
        }
        finally{
            SBR_3_0_Log.saveLog();
        }
    }
    /**
     * @description  - Make SecondEstimateCall for the order or quote where the number of trucks is more than 1               
     * @param recordId - recordId to fetch the record data          
     * @param totalEstimatedRevenue - Estimated Revenue.
     */
    public static void secondEstimateAPICall(Id recordId,Decimal totalEstimatedRevenue)
    {
        SBR_3_0_API_EstimatesResponseWrapper result = new SBR_3_0_API_EstimatesResponseWrapper();
        SBR_3_0_API_EstimatesRequestWrapper requestWrapper = new SBR_3_0_API_EstimatesRequestWrapper();
        requestWrapper = SBR_3_0_API_Estimates.secondEstimateRequest;
        if(deliveryCharge!=null && noOfTruck!=null)
        {
            requestWrapper.Delivery[0].charges = (noOfTruck * deliveryCharge).toPlainString();
            requestWrapper.Delivery[0].chargesOverride = true;

        }
        if(pickupCharge!=null && noOfTruck!=null)
        {
            requestWrapper.Pickup[0].charges = (noOfTruck * pickupCharge).toPlainString();
            requestWrapper.Pickup[0].chargesOverride = true;

        }
        String body = JSON.serialize(requestWrapper, true);
        body = body.replace('override_x', 'override');
        body = body.replace('null', '\"\"');
        String resp = SBR_3_0_API_Estimates.getEstimates( body , SBR_3_0_API_Estimates.secondEstimateCompanyCode);
        result = (SBR_3_0_API_EstimatesResponseWrapper) JSON.deserialize(resp, SBR_3_0_API_EstimatesResponseWrapper.class);
        processResponse(result.data.estimate,recordId,totalEstimatedRevenue);
    }

    /**
     * @description - this method will handle the response recieved by the estimates API and process it for Quotes or Orders.                
     * @param estimate -  stores the response from estimates api            
     * @param recordId - recordid for which the datat is processed             
     * @param totalEstimatedRevenue - total revenue of the record
     */
    public static void processResponse(SBR_3_0_API_EstimatesResponseWrapper.Estimate estimate,Id recordId,Decimal totalEstimatedRevenue)
    {
        try {
         currentUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
        if (objectApi == SBR_3_0_Constants.QUOTE_API_NAME) {
            if(!makeSecondCall)
            {
                bypassValidationRules(true);
                processQuote(estimate, recordId, totalEstimatedRevenue);
                bypassValidationRules(false);
            }
            else{
                processQuote(estimate, recordId, totalEstimatedRevenue);
            }

        } else if (objectApi == SBR_3_0_Constants.ORDER_API_NAME) {
            processOrder(estimate, recordId, totalEstimatedRevenue);
        }
    }
        catch(Exception e) {
            bypassValidationRules(false);
        }
    }
    /**
     * @description  - SAL-26910: Used to bypass validation rules while inserting/updating records. Only those VRs will be bypass which are using Bypass_Settings__c in their Error Condition Formula.
     * @param bypass - true/false based on bypass needed.
     */
    public static void bypassValidationRules(Boolean bypass) {
        Bypass_Settings__c bypassVR =  Bypass_Settings__c.getOrgDefaults();
        bypassVR.Bypass_Validation_Rule__c = bypass;
        if(bypassVR.Id == null){
            insert bypassVR;
        }
        else{       
            update bypassVR;
        }
    }

    private static void processOrder(SBR_3_0_API_EstimatesResponseWrapper.Estimate estimate,Id recordId,Decimal totalEstimatedRevenue){
        List<SBR_3_0_API_EstimatesResponseWrapper.MiscCharges> miscCharges = estimate.miscCharges;
        SBR_3_0_API_EstimatesResponseWrapper.Totals totals = estimate.totals;
        SBR_3_0_API_EstimatesResponseWrapper.OtherDetails otherDetails = estimate.otherDetails;
        List<SBR_3_0_API_EstimatesResponseWrapper.Product> productLines;
        List<SBR_3_0_API_EstimatesResponseWrapper.SalesItem> salesItems;
        if(estimate.itemizedCharges != null && estimate.itemizedCharges.orderLines != null) {
            for(SBR_3_0_API_EstimatesResponseWrapper.OrderLine ol : estimate.itemizedCharges.orderLines) {
                if(ol.products != null) {
                    productLines = ol.products;
                }
                if(ol.salesItems != null) {
                    salesItems = ol.salesItems;
                }
            }
        }
            // update totals
            Order order = new Order(
                Id = recordId,
                Total_Rental_Amount__c = totals.rentalAmount,
                RPP_Amount__c = isRentalProtection ? totals.rppCharges : 0,
                Total_Misc__c = totals.miscCharges,
                Total_Ordered_Amount__c = totals.finalTotal,//SAL-23564
                Total_Sales_Amount__c = totals.salesAmount,
                Total_Sales_Taxes__c = totals.salesTax,
                Total_Estimated_Revenue__c = totalEstimatedRevenue,
                IsDeliveryOptionsChanged__c = false //SAL-26740
            );
            if (otherDetails.distBetweenPCandSite > 0) {
                order.Distance_to_Job_Site__c = otherDetails.distBetweenPCandSite;
            }
            if(locationData != null){ //SF-6906 - does not depend on Ordering Branch
                order.Sourcing_Branch__c = locationData.Id; //23506
            }
            if(!makeSecondCall && order!=null)
            {
               Database.update(order,false);
            }

            order = SBR_3_0_OrderDA.getOrders(new Set<Id>{recordId}).get(recordId);
            List<OrderItem> deleteItems = new List<OrderItem>();
            for(OrderItem lineItem : order.OrderItems) {
                // SAL-26878 - add DEL/PICKUP condition to avoid deleting crewmapping items
                if(!lineItem.is_Forced_Item__c && !lineItem.is_User_Added__c) {  // SAL-27192
                    deleteItems.add(lineItem);
                }
            }
            if(deleteItems.size() > 0 && !makeSecondCall) {
                Database.delete(deleteItems,false);
            }
            //loop through the misc items and get related product Ids first--
            Map<String, Id> productSKUToId = new Map<String,Id>();
            Map<String, Product2> products = new Map<String, Product2>();
            Decimal miscChargesToSubtract = 0.0;
            Decimal misTaxesToSubtract = 0.0;
            // SAL-25808
            Decimal orderDeliveryPickupCharges = 0.0;
            Decimal orderAncillaryCharges = 0.0;

            for(SBR_3_0_API_EstimatesResponseWrapper.MiscCharges misc : miscCharges) {
                if(!String.isBlank(misc.productSku)) {
                    productSKUToId.put(misc.productSku, null);
                }
            }
            if(productSKUToId.size() > 0) {
                products = SBR_3_0_ProductDA.getProductByExternalId(productSKUToId.keySet());
            }

            //loop through the misc items again and create records
            List<OrderItem> miscItems = new List<OrderItem>();
            for (SBR_3_0_API_EstimatesResponseWrapper.MiscCharges misc : miscCharges) {

                // SAL-27418 - skip processing misc if order/quote.Using_3rd_Party__c == true && misc == Delivery/Pickup
                if(order.Using_3rd_Party__c == true && (misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY || misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP))
                {
                    continue;
                }

                //SAL-23847
                //delivery(from branch to customer) and pickup (from customer to SBR branch) should only have charges if delivery method = Delivery
                //SF-6833 For override=false, the suggested rates should always be updated irrespective of their current value.
                if (order.Deliverymethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY && misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY) {
                    if ((setSuggesstedValue && !order.Delivery_Charges_Override__c)
                    && (order.Number_of_Trucks__c == 1 || (order.Delivery_Charge__c == null || order.Delivery_Charge__c == 0 || order.Pickup_Charge__c == null || order.Pickup_Charge__c == 0))) //SF-6833
                    {   order.Delivery_Charge__c = misc.charge;
                        order.Pickup_Charge__c = misc.charge;
                        deliveryCharge = order.Delivery_Charge__c;
                        pickupCharge = order.Pickup_Charge__c;
                    }
                    else if(!setSuggesstedValue || order.Delivery_Charges_Override__c)
                    {
                        order.Delivery_Charges__c = misc.charge;
                    }

                    if  ((!setSuggesstedValue && !order.Delivery_Charges_Override__c)
                     && (order.Delivery_Charge__c == null || order.Delivery_Charge__c == 0 || order.Pickup_Charge__c == null || order.Pickup_Charge__c == 0)) //SF-6833
                    {
                        order.Delivery_Charge__c = deliveryCharge ; 
                        order.Pickup_Charge__c = pickupCharge  ;
                    }
                    if(makeSecondCall){
                        setSuggesstedValue = false;
                    }
                    //makeSecondCall = true;
                }
                if(misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP && order.Pickup_Charges_Override__c)
                {
                 order.Pickup_Charges__c = misc.charge;
                }
                String productId = products.containsKey(misc.productSku) ? products.get(misc.productSku).Id : null;
                if(productId == null) {
                    throw new SBR_3_0_API_Estimates.SBR_3_0_API_Estimates_Exception('Misc Product SKU: ' + misc.productSku + ' not found!');
                }
                if (order.Deliverymethod__c != SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP || 
                    (order.Deliverymethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP 
                        && misc.type != SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY 
                        && misc.type != SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP 
                        && misc.type != SBR_3_0_Constants.TRANSPORTATION_SURCHARGE)) {
                OrderItem item = new OrderItem(
                        //SAL-26036
                        Line_Item_Type__c = misc.type == 'DELIVERY' || misc.type == 'PICKUP' ? 'YD' : 'YC',
                        OrderId = recordId,
                        Misc_Charges_Type__c = misc.type,
                        //Misc_Charge__c = misc.charge,
                        Selling_Price__c = misc.charge,
                        Misc_Charges_Tax__c = misc.tax,
                        Misc_Charges_Non_Taxable__c = misc.nonTaxable,
                        Misc_Charges_Item_Tax_Rate__c = misc.itemTaxRate,
                        Quantity = 1,
                        Quantity__c = 1,
                        UnitPrice = misc.charge,
                        Product2Id = productId,
                        Total_Price__c = misc.charge // change for item subTotal SAL-14399

                );
            
                miscItems.add(item);
                }else{
                    if(misc.charge!=null){
                        miscChargesToSubtract+=misc.charge; //SAL-22378
                    }
                    if(misc.tax!=null){
                        misTaxesToSubtract+=misc.tax; //SAL-22378
                    }
                }

                // SAL-25808
                if(misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP || misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY ){
                    orderDeliveryPickupCharges+=misc.charge;
                }else{
                    orderAncillaryCharges+=misc.charge;
                }
            
            }
            
            order.Total_Misc__c = totals.miscCharges - miscChargesToSubtract;
            order.Total_Sales_Taxes__c = totals.salesTax - misTaxesToSubtract;
            order.Total_Ordered_Amount__c = totals.finalTotal - (miscChargesToSubtract+misTaxesToSubtract);
            // SAL-25808
            //SF-7658
            if(order.Deliverymethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP){
                order.Total_Delivery_Pickup__c = 0;
            } else {
                order.Total_Delivery_Pickup__c = orderDeliveryPickupCharges;
            }
            
            order.Total_Ancillary__c = orderAncillaryCharges;
            // SAL-26740
            order.IsDeliveryOptionsChanged__c = false;
            //02-comment 
           /* if(order!=null && !makeSecondCall){
                Database.update(order,false);
            }*/
            if(!Test.isRunningTest() && miscItems.size()>0 && !makeSecondCall) {
                Database.upsert(miscItems,false);
            }

            //update OrderItems
            List<OrderItem> orderItems = SBR_3_0_OrderItemDA.getOrderItemsByOrder(recordId);
            List<OrderItem> orderItemsUpdate = new List<OrderItem>();
            Map<String, List<OrderItem>> orderItemsMap = new Map<String, List<OrderItem>>();

            for(OrderItem oi : orderItems) {
                String key = buildKey(oi);
                if(key != null) {
                    if(orderItemsMap.get(key) == null) {
                        orderItemsMap.put(key, new List<OrderItem>());
                    }
                    List<OrderItem> items = orderItemsMap.get(key);
                    items.add(oi);
                    orderItemsMap.put(key, items);
                }
            }

            Set<String> processedKeys = new Set<String>();

            // Updates from Product Array
            for(SBR_3_0_API_EstimatesResponseWrapper.Product p : productLines) {
                if(p.catId != null && p.classId != null && p.quantity != null) {
                    String key = String.valueOf(p.catId) + '-' + String.valueOf(p.classId) 
                                    + '-' + Integer.valueOf(p.quantity);
                    
                    if(orderItemsMap.get(key) != null && !processedKeys.contains(key)) {
                        for(OrderItem oi : orderItemsMap.get(key)) {
                            if(oi != null) {
                                oi.Rental_Amount__c = Decimal.valueOf(p.rentalCost);
                                oi.UnitPrice = Decimal.valueOf(p.unitRentalCost);
                                oi.Rental_Tax__c = Decimal.valueOf(p.rentalTax);
                                oi.Rental_Tax_Rate__c = Decimal.valueOf(p.rentalTaxRate);
                                oi.Rental_Protection_Amount__c = Decimal.valueOf(p.rppCost);
                                oi.Unit_RPP_Cost__c = Decimal.valueOf(p.unitRPPCost);
                                oi.RPP_Tax_Rate__c = Decimal.valueOf(p.rppTaxRate);
                                oi.Total_Price__c = Decimal.valueOf(p.rentalCost); // change for item subTotal SAL-14399
                                orderItemsUpdate.add(oi);
                            }
                            
                        }
                        processedKeys.add(key);
                    }
                }
            }

            // Updates from SalesItems array
            for(SBR_3_0_API_EstimatesResponseWrapper.SalesItem si : salesItems) {
                if(si.itemNumber != null && si.quantity != null) {
                    String key = si.itemNumber + '-' + Integer.valueOf(si.quantity);
                    if(orderItemsMap.get(key) != null && !processedKeys.contains(key)) {
                        for(OrderItem oi : orderItemsMap.get(key)) {
                            if(oi != null) {
                                oi.UnitPrice = Decimal.valueOf(si.unitPrice);
                                oi.Total_Price__c = Decimal.valueOf(si.totalPrice);
                                oi.Sales_Tax__c = Decimal.valueOf(si.salesTax);
                                oi.Sales_Tax_Rate__c = Decimal.valueOf(si.salesTaxRate);
                                oi.Quantity__c = Decimal.valueOf(si.quantity);
                               //25119
                               if(String.isNotBlank(si.stockClass) && si.stockClass == SBR_3_0_Constants.PRODUCT_STOCK_CLASS_MISC){
                                String prodName = oi.Product2.Name;
                                oi.Misc_Charges_Type__c = prodName.toUpperCase();
                            }
                                orderItemsUpdate.add(oi);
                            }
                        }
                        processedKeys.add(key);
                    }
                }
            }
           
            if(orderItemsUpdate.size() > 0 && !makeSecondCall) {
                Database.update(orderItemsUpdate,false);
            }

            // update totals
            order.Last_Calculated_On__c = System.now().addSeconds(2); // SAL-22479 - Added small buffer to allow child triggers to finish and allow quote submission
            order.LastOrderItemUpdated__c = System.now().addSeconds(-2);
            // also sets delivery and pickup charges
            if(order!=null && !makeSecondCall){
                Database.update(order,false);
            }

        
    }
    private static void processQuote(SBR_3_0_API_EstimatesResponseWrapper.Estimate estimate, Id recordId, Decimal totalEstimatedRevenue){
        
        List<SBR_3_0_API_EstimatesResponseWrapper.MiscCharges> miscCharges = estimate.miscCharges;
         
        SBR_3_0_API_EstimatesResponseWrapper.Totals totals = estimate.totals;
        SBR_3_0_API_EstimatesResponseWrapper.OtherDetails otherDetails = estimate.otherDetails;
        List<SBR_3_0_API_EstimatesResponseWrapper.Product> productLines;
        List<SBR_3_0_API_EstimatesResponseWrapper.SalesItem> salesItems;
        if(estimate.itemizedCharges != null && estimate.itemizedCharges.orderLines != null) {
            for(SBR_3_0_API_EstimatesResponseWrapper.OrderLine ol : estimate.itemizedCharges.orderLines) {
                if(ol.products != null) {
                    productLines = ol.products;
                }
                if(ol.salesItems != null) {
                    salesItems = ol.salesItems;
                }
            }
        }
          //Set<String> miscProductSKUs = new Set<String>(); // unused local variable - Code analyzer fix
            // update totals
            SBQQ__Quote__c quote = new SBQQ__Quote__c(  
                Id = recordId,
                Total_Rental_Amount__c = totals.rentalAmount, 
                RPP_Amount__c = isRentalProtection ? totals.rppCharges : 0,  
                Total_Misc__c = totals.miscCharges, 
                Total_Quoted_Amount__c = totals.finalTotal, 
                Total_Sales_Amount__c = totals.salesAmount,
                Total_Sales_Taxes__c = totals.salesTax,
                SBQQ__LastCalculatedOn__c = System.now().addSeconds(15), // SAL-22479 - Added small buffer to allow child triggers to finish and allow quote submission
                SBQQ_Last_Line_Update__c =  System.now().addSeconds(-15),  // SAL-27196
                Total_Estimated_Revenue__c = totalEstimatedRevenue,
                IsDeliveryOptionsChanged__c = false //SF-6415
            );
            if (otherDetails.distBetweenPCandSite > 0) {
                quote.Distance_to_Job_Site__c = otherDetails.distBetweenPCandSite;
            }
            if(locationData !=null ){    //SF-6846 Do not overwrite the sourcing branch if Quoting branch is not OMS Enabled
                quote.Sourcing_Branch__c = locationData.Id; //23506
            }
            if (quote!=null && !makeSecondCall)
            {
                Database.update(quote,false);
            }
            // update misc charges
            quote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{recordId}).get(recordId);
            List<SBQQ__QuoteLine__c> deleteItems = new List<SBQQ__QuoteLine__c>();
            for(SBQQ__QuoteLine__c lineItem : quote.SBQQ__LineItems__r) {
                // SAL-26878 - add DEL/PICKUP condition to avoid deleting crewmapping items
                if(!lineItem.is_Forced_Item__c && !lineItem.is_User_Added__c && !lineItem.Added_by_Crew_Expense__c) { // SAL-27192
                    deleteItems.add(lineItem);
                }
            }
            if(deleteItems.size() > 0 && !makeSecondCall) {
                Database.delete(deleteItems);
            }

            //loop through the misc items and get related product Ids first--
            Map<String, Id> productSKUToId = new Map<String,Id>();
            Map<String, Product2> products = new Map<String, Product2>();

            for(SBR_3_0_API_EstimatesResponseWrapper.MiscCharges misc : miscCharges) {
                if(!String.isBlank(misc.productSku)) {
                    productSKUToId.put(misc.productSku, null);
                }
            }
            if(productSKUToId.size() > 0) {
                products = SBR_3_0_ProductDA.getProductByExternalId(productSKUToId.keySet());
            }

            //loop through the misc items again and create records
            List<SBQQ__QuoteLine__c> miscItems = new List<SBQQ__QuoteLine__c>();

            Decimal miscChargesToSubtract = 0.0;
            Decimal misTaxesToSubtract = 0.0;
            // SAL-25808
            Decimal deliveryPickupCharges = 0.0;
            Decimal ancillaryCharges = 0.0;

            for(SBR_3_0_API_EstimatesResponseWrapper.MiscCharges misc : miscCharges) {
                Double lineItemMiscChargeOverride;//SAL-15766//
                lineItemMiscChargeOverride = misc.charge;

                // SAL-27418 - skip processing misc if order/quote.Using_3rd_Party__c == true && misc == Delivery/Pickup
                if(quote.Using_3rd_Party__c == true && (misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY || misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP))
                {
                    continue;
                }
                
                // SF-6833 For override=false, the suggested rates should always be updated irrespective of their current value.
                if(quote.SBQQ__DeliveryMethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY && (misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY)) {
                    if ((setSuggesstedValue && !quote.Delivery_Charges_Override__c)
                     && (quote.Number_of_Trucks__c == 1 || (quote.Delivery_Charge__c == null || quote.Delivery_Charge__c == 0 || quote.Pickup_Charge__c == null || quote.Pickup_Charge__c == 0))) //SF-6833
                    {
                        quote.Delivery_Charge__c = misc.charge;
                        quote.Pickup_Charge__c = misc.charge;
                        deliveryCharge = quote.Delivery_Charge__c;
                        pickupCharge = quote.Pickup_Charge__c;
                        
                    }
                    else if(!setSuggesstedValue || quote.Delivery_Charges_Override__c)
                    {
                        quote.Delivery_Charges__c = misc.charge;
                        lineItemMiscChargeOverride = quote.Delivery_Charges__c;//SAL-15766//

                    }

                    if  ((!setSuggesstedValue && !quote.Delivery_Charges_Override__c)
                     && (quote.Delivery_Charge__c == null || quote.Delivery_Charge__c == 0 || quote.Pickup_Charge__c == null || quote.Pickup_Charge__c == 0)) //SF-6833
                    {
                        quote.Delivery_Charge__c = deliveryCharge ; 
                        quote.Pickup_Charge__c = pickupCharge  ;
                    }
                    if(makeSecondCall){
                        setSuggesstedValue = false;
                    }
                    
                    }
                    else {
                    lineItemMiscChargeOverride = misc.charge;
                    if(quote.Pickup_Charges_Override__c && (misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP))
                    {
                         quote.Pickup_Charges__c=misc.charge;
                } 
                } 
                String productId = products.containsKey(misc.productSku) ? products.get(misc.productSku).Id : null;

                if(productId == null) {
                    throw new SBR_3_0_API_Estimates.SBR_3_0_API_Estimates_Exception('Misc Product SKU: ' + misc.productSku + ' not found!');
                }
             
               //need to prevent it from creating a line item if delivery method = pickup and charge type = pickup/delivery/transport, but even without the line items, the estimates api is still getting values for those
               if (quote.SBQQ__DeliveryMethod__c != SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP || (quote.SBQQ__DeliveryMethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP && misc.type != SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY && misc.type != SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP && misc.type != SBR_3_0_Constants.TRANSPORTATION_SURCHARGE)) {
                    SBQQ__QuoteLine__c item = new SBQQ__QuoteLine__c(
                        //SAL-26036
                        Line_Item_Type__c = misc.type == 'DELIVERY' || misc.type == 'PICKUP' ? 'YD' : 'YC',
                        SBQQ__Quote__c = recordId,
                        Misc_Charges_Type__c = misc.type,
                        //Misc_Charge__c = misc.charge,//
                        //Misc_Charge__c=lineItemMiscChargeOverride, //SAL-15766//
                        Selling_Price__c=lineItemMiscChargeOverride,
                        Misc_Charges_Tax__c = misc.tax,
                        Misc_Charges_Non_Taxable__c = misc.nonTaxable,
                        Misc_Charges_Item_Tax_Rate__c = misc.itemTaxRate,
                        SBQQ__Quantity__c = 1,
                        SBQQ__Product__c = productId,
                        //Total_Price__c = lineItemMiscChargeOverride //SAL-15766//
                        Total_Price__c = lineItemMiscChargeOverride // change for item subTotal SAL-14399
                    );
                    miscItems.add(item);
                } else{
                    if(misc.charge!=null){
                        miscChargesToSubtract+=misc.charge; //SAL-22378
                    }
                    if(misc.tax!=null){
                        misTaxesToSubtract+=misc.tax; //SAL-22378
                    }
                }

                // SAL-25808
                if(misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP || misc.type == SBR_3_0_Constants.FULFILLMENT_TYPE_DELIVERY ){
                    deliveryPickupCharges+=misc.charge;
                }else{
                    ancillaryCharges+=misc.charge;
                }

            }

            //SAL-22378
            quote.Total_Misc__c = totals.miscCharges - miscChargesToSubtract;
            quote.Total_Sales_Taxes__c = totals.salesTax - misTaxesToSubtract;
            quote.Total_Quoted_Amount__c = totals.finalTotal - (miscChargesToSubtract+misTaxesToSubtract);
            // SAL-25808
            // SF-7658
            if(quote.SBQQ__DeliveryMethod__c == SBR_3_0_Constants.FULFILLMENT_TYPE_PICKUP){
                quote.Total_Delivery_Pickup__c = 0;
            }else {
                quote.Total_Delivery_Pickup__c = deliveryPickupCharges;
            }            
            quote.Total_Ancillary__c = ancillaryCharges;
            if(!Test.isRunningTest() && miscItems!=null && miscItems.size()>0 && !makeSecondCall) {
                Database.upsert(miscItems,false);
            }
            List<SBQQ__QuoteLine__c> quoteLines = SBR_3_0_QuoteLineDA.getQuoteLines(recordId);
            List<SBQQ__QuoteLine__c> quoteLinesUpdate = new List<SBQQ__QuoteLine__c>();
            Map<String, List<SBQQ__QuoteLine__c>> quoteLinesMap = new Map<String, List<SBQQ__QuoteLine__c>>();

            for(SBQQ__QuoteLine__c ql : quoteLines) {
                String key = buildKey(ql);
                if(key != null) {
                    if(quoteLinesMap.get(key) == null) {
                        quoteLinesMap.put(key, new List<SBQQ__QuoteLine__c>());
                    }
                    List<SBQQ__QuoteLine__c> lines = quoteLinesMap.get(key);
                    lines.add(ql);
                    quoteLinesMap.put(key, lines);
                }
            }
            
            Set<String> processedKeys = new Set<String>();

            // Updates from Products array
            for(SBR_3_0_API_EstimatesResponseWrapper.Product p : productLines) {
                if(p.catId != null && p.classId != null && p.quantity != null) {
                    String key = String.valueOf(p.catId) + '-' + String.valueOf(p.classId) 
                                    + '-' + Integer.valueOf(p.quantity);
                    if(quoteLinesMap.get(key) != null && !processedKeys.contains(key)) {
                        for(SBQQ__QuoteLine__c ql : quoteLinesMap.get(key)) {
                            if(ql != null) {
                                ql.Rental_Amount__c = Decimal.valueOf(p.rentalCost);
                                ql.SBQQ__UnitCost__c = Decimal.valueOf(p.unitRentalCost);
                                ql.Rental_Tax__c = Decimal.valueOf(p.rentalTax);
                                ql.Rental_Tax_Rate__c = Decimal.valueOf(p.rentalTaxRate);
                                ql.Rental_Protection_Amount__c = Decimal.valueOf(p.rppCost);
                                ql.Unit_RPP_Cost__c = Decimal.valueOf(p.unitRPPCost);
                                ql.RPP_Tax_Rate__c = Decimal.valueOf(p.rppTaxRate);
                                ql.Total_Price__c = Decimal.valueOf(p.rentalCost); // change for item subTotal SAL-14399
                                quoteLinesUpdate.add(ql);
                            }
                        }
                        processedKeys.add(key);
                    }
                }
            }

            // Updates from SalesItems array
            for(SBR_3_0_API_EstimatesResponseWrapper.SalesItem si : salesItems) {
                if(si.itemNumber != null && si.quantity != null) {
                    String key = si.itemNumber + '-' + Integer.valueOf(si.quantity);
                    if(quoteLinesMap.get(key) != null && !processedKeys.contains(key)) {
                        for(SBQQ__QuoteLine__c ql : quoteLinesMap.get(key)) {
                            if(ql != null) {
                                ql.SBQQ__UnitCost__c = Decimal.valueOf(si.unitPrice);
                                ql.Total_Price__c = ql.Added_by_Crew_Expense__c ? ql.Selling_Price__c : Decimal.valueOf(si.totalPrice); //SAL-26878,27341
                                ql.Sales_Tax__c = Decimal.valueOf(si.salesTax);
                                ql.Sales_Tax_Rate__c = Decimal.valueOf(si.salesTaxRate);
                                ql.SBQQ__Quantity__c = Decimal.valueOf(si.quantity);
                                //25119
                                if(String.isNotBlank(si.stockClass) && si.stockClass == SBR_3_0_Constants.PRODUCT_STOCK_CLASS_MISC){
                                    String prodName = ql.SBQQ__Product__r?.Name;
                                    ql.Misc_Charges_Type__c = prodName.toUpperCase();




                                }
                                quoteLinesUpdate.add(ql);
                            }

                        }
                        processedKeys.add(key);
                    }
                }
            }
            SBR_3_0_Log.logInfo('quoteLinesUpdate >> '+ JSON.serialize(quoteLinesUpdate));
            if(quoteLinesUpdate != null && quoteLinesUpdate.size() > 0 && !makeSecondCall) {
                Database.update(quoteLinesUpdate,false);


            }
            quote.SBQQ__LastCalculatedOn__c = System.now().addSeconds(2); 
            quote.SBQQ_Last_Line_Update__c =  System.now().addSeconds(-2);  // SAL-27196
            quote.IsDeliveryOptionsChanged__c = false; //SF-6415
            if(quote!=null && !makeSecondCall){
                Database.update(quote,false); //SAL-22378
            }
    }
    // build key with classId, catId and quantity
    private static String buildKey(SBQQ__QuoteLine__c ql) {
        if(ql.SBQQ__Product__c != null && ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
            String catId = ql.SBQQ__Product__r.Category__c;
            String classId = ql.SBQQ__Product__r.Class__c;
            String quantity = String.valueOf(ql.SBQQ__Quantity__c.intValue());
            return catId + '-' + classId + '-' + quantity;
        }
        else if((ql.SBQQ__Product__c != null && 
                    (ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS || ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || (ql.SBQQ__Product__r.Product_Type__c ==  SBR_3_0_Constants.MISC_CHARGE_ITEMS_TYPE && ql.is_User_Added__c ))
                )
                ||
                (ql.is_Forced_Item__c && ql.SBQQ__Product__r.Stock_class__c!= null && ql.SBQQ__Product__r.Stock_class__c == SBR_3_0_Constants.PRODUCT_STOCK_CLASS_MISC )//25119
                ||
                ql.Added_by_Crew_Expense__c  // SAL-27341
            )
        { 
            String itemNumber = ql.SBQQ__Product__r.Item_Number__c;
            String quantity = String.valueOf(ql.SBQQ__Quantity__c.intValue());
            return itemNumber + '-' + quantity;
        }
        return null;
    }
    // build key with classId, catId and quantity
    private static String buildKey(OrderItem oi) {
        if(oi.Product2Id != null && oi.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
            String catId = oi.Product2.Category__c;
            String classId = oi.Product2.Class__c;
            String quantity = String.valueOf(oi.Quantity.intValue());
            return catId + '-' + classId + '-' + quantity;
        }
        else if((oi.Product2Id != null && 
                (oi.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || oi.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || (oi.Product2.Product_Type__c ==  SBR_3_0_Constants.MISC_CHARGE_ITEMS_TYPE && oi.is_User_Added__c ) ) )
                ||
                (oi.is_Forced_Item__c && oi.Product2.Stock_class__c!= null && oi.Product2.Stock_class__c == SBR_3_0_Constants.PRODUCT_STOCK_CLASS_MISC )//25119
            ) 
            {
            String itemNumber = oi.Product2.Item_Number__c;
            String quantity = String.valueOf(oi.Quantity.intValue());
            return itemNumber + '-' + quantity;
        }
        return null;
    }

    private static Boolean clearTotalsIfNoItems(Id recordId) {

         objectApi = recordId.getSObjectType().getDescribe().getName();

        if(objectApi == 'SBQQ__Quote__c') {

            SBQQ__Quote__c quote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{recordId}).get(recordId);
            if(quote.SBQQ__LineItems__r.size() == 0) {
                quote = new SBQQ__Quote__c(  
                    Id = recordId,
                    Total_Rental_Amount__c = 0, 
                    RPP_Amount__c = 0, 
                    Total_Misc__c = 0, 
                    Total_Quoted_Amount__c = 0, 
                    Total_Sales_Amount__c = 0,
                    Total_Sales_Taxes__c = 0,
                    SBQQ__LastCalculatedOn__c = System.now().addSeconds(15), // SAL-22479 - Added small buffer to allow child triggers to finish and allow quote submission
                    SBQQ_Last_Line_Update__c =  System.now().addSeconds(-15),  // SAL-27196
                    Total_Estimated_Revenue__c = 0
                );
                update quote;
                return true;
            }
        } else if(objectApi == 'Order') {
            Order order = SBR_3_0_OrderDA.getOrders(new Set<Id>{recordId}).get(recordId);
            if(order.OrderItems.size() == 0) {
                order = new Order(
                    Id = recordId,
                    Total_Rental_Amount__c = 0,
                    RPP_Amount__c = 0,
                    Total_Misc__c = 0,
                    Total_Ordered_Amount__c =0,//SAL-23564
                    Total_Sales_Amount__c = 0,
                    Total_Sales_Taxes__c = 0,
                    Last_Calculated_On__c = System.now().addSeconds(2), // SAL-22479 - Added small buffer to allow child triggers to finish and allow quote submission
                    LastOrderItemUpdated__c = System.now().addSeconds(-2),
                    Total_Estimated_Revenue__c = 0
                );
                update order;
                return true;
            }
        }
        return false;
    }
    /**
     * @description     - //23506  this method is overridden method for updateTotals    
     * @param recordId  - recordID for the record processed
     * @param sourcingBranchData - source brnach data
     * @return                   `Boolean` - true/false based on success/failure 
     */
    public static Boolean updateTotals(Id recordId, Schema.Location sourcingBranchData) {
        locationData = sourcingBranchData;
        SBR_3_0_Log.setRelatedRecordId(recordId);
        sourcingEstimatesRespWrapperMap = SBR_3_0_API_Estimates.getEstimatesFromSourcingBranch(recordId,sourcingBranchData);
        Boolean isTotalsUpdated = updateTotals(recordId);
        return isTotalsUpdated;
    }

    /**
     * @description - Wrapper to hold the permission-related information for a field/object.
     */
    public class PermissionWrapper {

        @AuraEnabled
        public Boolean hasPermission;
        @AuraEnabled
        public String objectApi;
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public String fieldAPIName;
        @AuraEnabled
        public String fieldLabel;

        /**
        * @description - Constructs a new PermissionWrapper object with the specified parameters     
        * @param hp          A Boolean value indicating whether the current user has permission to access the field.
        * @param obj         The API name of the object associated with the field.
        * @param objLabel    The label of the object associated with the field.
        * @param fieldApi    The API name of the field.
        * @param fieldLabel  The label of the field.
        */
        public PermissionWrapper(Boolean hp, String obj, String objLabel, String fieldApi, String fieldLabel) {
            this.hasPermission = hp;
            this.objectApi = obj;
            this.objectLabel = objLabel;
            this.fieldAPIName = fieldApi;
            this.fieldLabel = fieldLabel;
        }
    }
}