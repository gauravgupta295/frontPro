/**
* @description       :  Get ATP call when cloning Order
* @author            : 
* @group             : 
* @last modified on  : 01-09-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SBR_3_0_GetATPOnOrderCloneController {
    
    
    @InvocableMethod(label = 'get Order Rates Branch From ATP Call')
    public static  List<cloneResponse> updateOrderLineItemsWithRates(List<CloneRequest> cloneData){
        List<cloneResponse> returnVal = new List<cloneResponse>();
        try{
            
            List<Schema.Location> userProfileLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
            if(userProfileLocation.size() == 0) {
                cloneResponse cr = new cloneResponse();
                cr.isSuccess = false;
                returnVal.add(cr);
                return returnVal;
            }
            
            String objectName =  cloneData[0].objectName;
            Order selectedOrder = SBR_3_0_OrderDA.getOrders(new Set<Id>{cloneData[0].orderId}).values()[0];
            Schema.Location locationRec = SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetailsNew(selectedOrder.Id, objectName);
            
            if(cloneData[0].isAccountOrJobSiteChanged && locationRec.OMS_Sourcing_Enabled__c){
                SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj = new SBR_3_0_WrapInventoryAtBranch.ATPRequest();
                String companyCode;
                companyCode = locationRec.Company_Code__c;
                if (String.isBlank(companyCode)) {
                    User u = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId()];
                    companyCode = u.CompanyName;
                }
                
                API_ATP_Config__mdt atpFieldConfig = SBR_3_0_CustomMetadata_DA.getATPApiConfig('Prod_Inquiry');
                atpReqObj.orgId = companyCode;
                atpReqObj.cartId = SBR_3_0_Constants.SELLING_CHANNEL;
                atpReqObj.fulfillmentType = SBR_3_0_Constants.ATP_FULFILLMENTTYPE_DELIVERY;
                atpReqObj.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
                if(atpFieldConfig <> NULL){
                    atpReqObj.includeZeroATP = atpFieldConfig.Include_Zero_ATP__c;
                    atpReqObj.limitBranchByDistanceCount = Integer.valueOf(atpFieldConfig.Limit_Branch_By_Distance__c);
                }
                
                if (objectName == 'Order'){
                    String formatted = selectedOrder.Start_Date__c.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                    atpReqObj.requestedDeliveryDate = formatted;
                    // SAL-24258 - Start
                    if(selectedOrder.Deliverymethod__c == 'Delivery' && selectedOrder.OMS_Sourcing_Enabled__c){
                        if(selectedOrder.Jobsite__r.Latitude_Longitude__Latitude__s <> NULL && 
                           selectedOrder.Jobsite__r.Latitude_Longitude__Longitude__s <> NULL){
                               atpReqObj.latitude = selectedOrder.Jobsite__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedOrder.Jobsite__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_JOBSITE;
                               // SAL-25138
                               System.debug('********** selectedOrder.Jobsite__r.Time_Zone_Id__c : '+ selectedOrder.Jobsite__r.Time_Zone_Id__c);
                               if(selectedOrder.Jobsite__r.Time_Zone_Id__c !=null){
                                        atpReqObj.timezoneId = selectedOrder.Jobsite__r.Time_Zone_Id__c;
                                }
                                else if(selectedOrder.Sourcing_Branch__r <> NULL && selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c != null){
                                        atpReqObj.timezoneId = selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c; 
                                }
                           }else if(selectedOrder.Sourcing_Branch__r <> NULL && 
                                    selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                                    selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                           {
                               atpReqObj.latitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                               // SAL-25138
                               System.debug('********** selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c);
                               atpReqObj.timezoneId = selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c;
                           } else if(selectedOrder.Branch__r <> NULL && 
                                     selectedOrder.Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                                     selectedOrder.Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                           {
                               atpReqObj.latitude = selectedOrder.Branch__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedOrder.Branch__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                               // SAL-25138
                               System.debug('********** selectedOrder.Branch__r.Time_Zone_Id__c : '+ selectedOrder.Branch__r.Time_Zone_Id__c);
                               atpReqObj.timezoneId = selectedOrder.Branch__r.Time_Zone_Id__c;
                           }
                    } else if(selectedOrder.Deliverymethod__c == 'Pickup'){
                        atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
                        if(selectedOrder.Sourcing_Branch__r <> NULL && selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                           selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL){
                               
                               atpReqObj.latitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedOrder.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                               // SAL-25138
                               System.debug('********** selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c);
                               atpReqObj.timezoneId = selectedOrder.Sourcing_Branch__r.Time_Zone_Id__c;
                           }
                    } else {
                        Schema.Location userLocation = userProfileLocation[0];
                        Datetime myDateTime = Datetime.now();
                        formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                        atpReqObj.requestedDeliveryDate = formatted;
                        if(userLocation.Latitude_Longitude__Latitude__s <> NULL && userLocation.Latitude_Longitude__longitude__s <> NULL){
                            atpReqObj.latitude = userLocation.Latitude_Longitude__Latitude__s;
                            atpReqObj.longitude = userLocation.Latitude_Longitude__longitude__s;
                            atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                            atpReqObj.timezoneId = userLocation.Time_Zone_Id__c;
                        }
                    }
                    
                    List<SBR_3_0_WrapInventoryAtBranch.Products> products = new list<SBR_3_0_WrapInventoryAtBranch.Products>();
                    for(OrderItem oitem : selectedOrder.OrderItems){
                        if(oitem.Product2Id != null && oitem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS){
                            SBR_3_0_WrapInventoryAtBranch.Products p = new SBR_3_0_WrapInventoryAtBranch.Products();
                            p.uom = 'EA';
                            p.productId = oitem.Product2.Product_SKU__c;
                            products.add(p);
                        }
                    }
                    atpReqObj.products = products;
                    
                    Map<String, String> catClassBranchMap = new   Map<String, String>();
                    List<String> noAvailabilityByLocationsList = new List<String>();
                    
                    system.debug('atpReqObj--> ' + JSON.serialize(atpReqObj));
                    
                    // first call for ATP
                    SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_API_FetchInventoryAtBranch.getInventoryAtBranch(atpReqObj,companyCode);
                    
                    if(response != null){
                        for(SBR_3_0_WrapInventoryAtBranch.AvailabilityByProducts res : response.availabilityByProducts){
                            if( res.availabilityByFulfillmentTypes.size() > 0 && res.availabilityByFulfillmentTypes[0].availabilityDetails.size() > 0 &&  res.availabilityByFulfillmentTypes[0].availabilityDetails[0].availabilityByLocations.size() > 0 ){
                                String ratesBranch = res.availabilityByFulfillmentTypes[0].availabilityDetails[0].availabilityByLocations[0].locationId;
                                ratesBranch = ratesBranch.split('-')[1];
                                catClassBranchMap.put(res.productId , ratesBranch);   
                            }
                            else if(res.productId != null){
                                noAvailabilityByLocationsList.add(res.productId);   
                            }
                        }
                    }
                    // second call for remaining locations
                    if(!noAvailabilityByLocationsList.isEmpty()){
                        List<SBR_3_0_WrapInventoryAtBranch.Products> noAvailabilityByLocationproducts = new list<SBR_3_0_WrapInventoryAtBranch.Products>();
                        SBR_3_0_WrapInventoryAtBranch.Products  noAvailabilityByLocationproduct = new SBR_3_0_WrapInventoryAtBranch.Products();
                        noAvailabilityByLocationproduct.uom = 'EA';
                        noAvailabilityByLocationproduct.productId = noAvailabilityByLocationsList[0];
                        noAvailabilityByLocationproducts.add(noAvailabilityByLocationproduct);
                        atpReqObj.products = noAvailabilityByLocationproducts;
                        SBR_3_0_WrapInventoryAtBranch.ATPResponse noAvailabilityByLocationsresponse = SBR_3_0_API_FetchInventoryAtBranch.getInventoryAtBranch(atpReqObj,companyCode);
                        if(noAvailabilityByLocationsresponse != null){
                            if(noAvailabilityByLocationsresponse.lastResortBranch !=null){
                                String lastResortBranch = noAvailabilityByLocationsresponse.lastResortBranch;
                                lastResortBranch = lastResortBranch?.split('-').size() > 1  ?  lastResortBranch?.split('-')[1] : lastResortBranch?.split('-')[0];
                                for(string catClass : noAvailabilityByLocationsList){
                                    catClassBranchMap.put(catClass , lastResortBranch);   
                                }
                            }
                        }           
                    } 
                    //use user branch if ATP fails
                    
                    system.debug('catClassBranchMap-->' + catClassBranchMap);
                    
                    for(OrderItem oitem : selectedOrder.OrderItems){
                        if(catClassBranchMap.get(oitem.Product2.Product_SKU__c) !=null && oitem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS){
                            oitem.Rates_Branch__c =   catClassBranchMap.get(oitem.Product2.Product_SKU__c);
                        }
                        else{
                            //use user branch if ATP fails
                            oitem.Rates_Branch__c =   userProfileLocation[0].Branch_Location_Number__c;
                        }
                    } 
                    getOrderRates(selectedOrder, selectedOrder.OrderItems);
                    cloneResponse cr = new cloneResponse();
                    cr.isSuccess = true;
                    returnVal.add(cr);
                }
            }
            else{
                getOrderRates(selectedOrder, selectedOrder.OrderItems);
                cloneResponse cr = new cloneResponse();
                cr.isSuccess = true;
                returnVal.add(cr);
            } 
        }
        catch(Exception e){
            cloneResponse cr = new cloneResponse();
            cr.isSuccess = false;
            returnVal.add(cr);
        }
        return returnVal;
    }
    
    
    public static void getOrderRates(Order orderRec, List<OrderItem> OrderItems){
        
        SBR_3_0_API_RatesRequestWrapper reqWrapper = new SBR_3_0_API_RatesRequestWrapper();
        String companyCode = '';
        if(orderRec!=null){
            companyCode = orderRec.Company_Code__c != null ? orderRec.Company_Code__c : orderRec?.Account?.Company_Code__c;
            if(companyCode.length() == 1 && !companyCode.startsWith('0')) { companyCode = '0' + companyCode; }
            // Separate Cat-Class Product types
            Map<String, OrderItem> catClassProducts = new Map<String, OrderItem>();
            Map<String,List<OrderItem>> catClassProductsListMap = new Map<String,List<OrderItem>>();
            Map<String,List<OrderItem>> suggestedProductsListMap = new Map<String,List<OrderItem>>();
            Map<String, SBR_3_0_API_RatesResponseWrapper.Items> catClassResponseProducts = new Map<String, SBR_3_0_API_RatesResponseWrapper.Items>();
            Map<String, OrderItem> suggestedProducts = new Map<String, OrderItem>();
            Map<String, SBR_3_0_API_ConsumablesResponse.Products> suggestedResponseProducts = new Map<String, SBR_3_0_API_ConsumablesResponse.Products>();
            List<OrderItem> lineItemList = new List<OrderItem>();
            List<OrderItem> allOrderLines = new List<OrderItem>();
            Map<String, String> mapSKUandRateBranch = new  Map<String, String>();
            for(OrderItem orderLineItem : OrderItems){
                if(orderLineItem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS){
                    catClassProducts.put(orderLineItem.Product2.Product_SKU__c, orderLineItem);
                    if(catClassProductsListMap.containsKey(orderLineItem.Product2.Product_SKU__c))
                    {
                        lineItemList = new List<OrderItem>();
                        lineItemList = catClassProductsListMap.get(orderLineItem.Product2.Product_SKU__c);
                        lineItemList.add(orderLineItem);
                        catClassProductsListMap.put(orderLineItem.Product2.Product_SKU__c, lineItemList);
                    }
                    else{
                        lineItemList = new List<OrderItem>();
                        lineItemList.add(orderLineItem);
                        catClassProductsListMap.put(orderLineItem.Product2.Product_SKU__c, lineItemList);
                        mapSKUandRateBranch.put(orderLineItem.Product2.Product_SKU__c ,orderLineItem.Rates_Branch__c);
                    }
                } else if((orderLineItem.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || orderLineItem.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || orderLineItem.Product2.Product_Type__c == 'MISC Charge Items')) {
                    suggestedProducts.put((orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c), orderLineItem);
                    if(suggestedProductsListMap.containsKey(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c))
                    {
                        lineItemList = new List<OrderItem>();
                        lineItemList = suggestedProductsListMap.get(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c);
                        lineItemList.add(orderLineItem);
                        suggestedProductsListMap.put(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c, lineItemList);
                    }
                    else{
                        lineItemList = new List<OrderItem>();
                        lineItemList.add(orderLineItem);
                        suggestedProductsListMap.put(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c, lineItemList);
                        
                    }
                }
            }
            System.debug('\n @@suggested prods =' + suggestedProducts);
            System.debug('\n @@mapSKUandRateBranch prods =' + mapSKUandRateBranch);
            
            // Call Rates API for Main Products
            if(!catClassProducts.isEmpty()) {
                String branchNumber = orderRec.Jobsite__r.Branch__r.Branch_Location_Number__c;
                if (String.isBlank(branchNumber)) {
                    branchNumber = orderRec.Branch__r.Branch_Location_Number__c;
                }
                SBR_3_0_API_RatesResponseWrapper respWrapper = SBR_3_0_API_Rates.getRatesFromRatesAPI(branchNumber, 
                                                                                                      orderRec.Account.RM_Account_Number__c, 
                                                                                                      orderRec.Jobsite__r.JobsiteName__c, 
                                                                                                      orderRec.Account.Company_Code__c,mapSKUandRateBranch);
                
                for(SBR_3_0_API_RatesResponseWrapper.Items item: respWrapper.data.items){
                    catClassResponseProducts.put(item.productId, item);
                }
                
                for(String productSku: catClassProductsListMap.keySet() )
                {
                    for(OrderItem orderLine: catClassProductsListMap.get(productSku)){
                        
                        if(catClassResponseProducts.containsKey(orderLine.Product2.Product_SKU__c)){
                            
                            orderLine.Min_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);
                            orderLine.Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);
                            orderLine.Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.daily);
                            orderLine.Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.weekly);
                            orderLine.Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.monthly);
                            
                            orderLine.Suggested_Minimum_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);
                            orderLine.Suggested_Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);                        
                            orderLine.Suggested_Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.daily);
                            orderLine.Suggested_Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.weekly);
                            orderLine.Suggested_Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.monthly);
                            allOrderLines.add(orderLine);
                        } else {
                            new SBR_3_0_API_Clone_Exception('Product Rates Not Found for: ' + orderLine.Product2.Product_SKU__c);
                        }
                    }
                }
                // for Consumables Parts and Merchandise  
                if(!suggestedProducts.isEmpty()) { 
                    // if(false){
                    // Call Consumables API for Suggested Products
                    SBR_3_0_API_ConsumablesResponse consResp = SBR_3_0_API_Rates.getRatesFromConsumablesAPI(branchNumber, 
                                                                                                            orderRec.Account.RM_Account_Number__c, 
                                                                                                            orderRec.Jobsite__r.Job_Number__c, 
                                                                                                            companyCode, catClassProducts.keySet());
                    
                    for(SBR_3_0_API_ConsumablesResponse.SuggestedItems suggItem: consResp.data.suggestedItems){
                        for(SBR_3_0_API_ConsumablesResponse.Consumables consumble: suggItem.consumables){
                            for(SBR_3_0_API_ConsumablesResponse.SpecGroups specGrp: consumble.specGroups){
                                for(SBR_3_0_API_ConsumablesResponse.Products prd: specGrp.products){
                                    //String prdSku = companyCode + '-' + prd.stockClass + '-' + prd.productNumber;
                                    String prdSku =  prd.stockClass + prd.productNumber;
                                    suggestedResponseProducts.put(prdSku, prd);
                                }
                            }
                        }
                    }
                    System.debug('\n@@suggested prods response = ' + suggestedResponseProducts);
                    // Populate Rates for Suggested Products
                    for(String itemNum : suggestedProductsListMap.keySet() )
                    {
                        for(OrderItem orderLine: suggestedProductsListMap.get(itemNum)){
                            System.debug('\n @@orderLine.Product2.Product_SKU__c= ' +  orderLine.Product2.Product_SKU__c);
                            System.debug('\n@@suggested prods response2 = ' + suggestedResponseProducts);
                            if(suggestedResponseProducts.containsKey(orderLine.Product2.Stock_Class__c + orderLine.Product2.Item_Number__c)){
                                orderLine.Selling_Price__c = Decimal.valueOf(suggestedResponseProducts.get((orderLine.Product2.Stock_Class__c + orderLine.Product2.Item_Number__c)).sellingPrice);
                                allOrderLines.add(orderLine);
                                
                            } 
                        }}
                }
                System.debug('allOrderLines->'+allOrderLines);
                if(!allOrderLines.isEmpty()){
                    
                    update allOrderLines;
                }
            }
        }
    }
    
    
    public class CloneRequest{
        
        @InvocableVariable(required=true)
        public String orderId;
        
        @InvocableVariable(required=true)
        public string objectName;
        
        @InvocableVariable(required=true)
        public Boolean isAccountOrJobSiteChanged;
    }
    
    
    Public class cloneResponse {
        @InvocableVariable
        Public Boolean isSuccess;
    }
    
    
    public class SBR_3_0_API_Clone_Exception extends Exception{}
    
    
}