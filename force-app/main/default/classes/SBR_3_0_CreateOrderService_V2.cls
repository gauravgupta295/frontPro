public class SBR_3_0_CreateOrderService_V2 {
    private static final String APINAME = 'Create_Orders_API_V2';
    private static final String UPDATEAPINAME = 'Update_Orders_API_V2';
    private Id orderId;
    private String companyId;
    private Order order;
    private Object response;
    private Map<Integer, OrderItem> mapOrderItem;
    private Integer responseStatusCode;
    private string servicePayload;
    private static final String DATA = 'data';
    private static final String RM_RESERVATION_ID = 'rmReservationId';
    private static final String LINES = 'lines';
    private static final String SF_LINE_NUMBER = 'sfLineNumber';
    private static final String RM_LINE_NUMBER = 'rmLineNumber';
    private static final String GLOBAL_LINE_NUMBER = 'lineNumber';
    private static final String RM_LINE_TYPE = 'rmLineType';
    private static final String ERROR = 'error';
    private static final String SUCCESS = 'success';
    private String currentUserWynneUserName;
    @AuraEnabled
    public static object submitOrder(Id orderId) {
        SBR_3_0_CreateOrderService_V2 orderInstance = new SBR_3_0_CreateOrderService_V2();
        return orderInstance.submit(orderId);
    }
    public object submit (Id orderId) {
        string responseBody;
        Set<Id> orderIds;
        Map<Id, Order> orders;
        this.orderId = orderId;
        orderIds = new Set<Id>();
        mapOrderItem = new Map<Integer, OrderItem>();
        orderIds.add(orderId);
        orders = new Map<Id, Order>(SBR_3_0_OrderDA.getOrders(orderIds));
        order = orders.get(orderId);
        this.companyId = !String.isBlank(order.Company_Code__c) ? order.Company_Code__c : '01';
        if(!Test.isRunningTest()){
        this.currentUserWynneUserName = [SELECT Id,Wynne_User_Name__c FROM User WHERE Id= :UserInfo.getUserId()].Wynne_User_Name__c;
        }
        else{
            this.currentUserWynneUserName=UserInfo.getUserId();
        }
        for (Id key: orders.keySet()) {
            order = orders.get(key);
            for (OrderItem orderItem : order.OrderItems)
            {
                    Integer mapOrderItemKey;
                    if(isConvertQuoteToOrder()){
                        mapOrderItemKey = Integer.valueOf(orderItem.Global_Line_Number__c);
                    } else {
                        mapOrderItemKey = Integer.valueOf(orderItem.OrderItemNumber);
                    }
                    if(!mapOrderItem.containsKey(mapOrderItemKey)) {
                        mapOrderItem.put(mapOrderItemKey, orderItem);
                        System.debug('@@mapOrderItem'+orderItem.OrderItemNumber);
                    }
                }
            }
        validateData();
        servicePayload =  SBR_3_0_OrderServicePayloadGenerator.generatePayload(order);
        if(order.Reservation_Order_Number__c == null ) {
            responseBody = createOrder();
        }
        else
        {
            responseBody = updateOrder();
        }
        handleOrderResponse();
        return responseBody;
    }
    public Boolean isConvertQuoteToOrder(){
        if(order.Rentalman_Quote_Id__c != null && order.SBQQ__Quote__c != null) {
            return true;
        }else {
            return false;
        }
    }
    
    private string createOrder(){
        HTTPResponse returnPayload;
        Map<String,String> headers = new Map<String,String>();
        headers.put('x-correlation-id',SBR_3_0_Generic.generateRandomString(10));
        headers.put('companyId' ,this.companyId);
        SBR_3_0_Generic_Callout.setHeaders(headers);
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(servicePayload, APINAME);
        responseStatusCode = returnPayload.getStatusCode();
        System.debug('\n @@ HTTPresponse =' + returnPayload);
        response = JSON.deserializeUntyped(returnPayload.getBody());
        System.debug('\n @@ response =' + response);
        return returnPayload.getBody();
    }
    private string updateOrder(){
        HTTPResponse returnPayload;
        Map<String,String> headers = new Map<String,String>();
        headers.put('x-correlation-id',SBR_3_0_Generic.generateRandomString(10));
        headers.put('companyId' ,this.companyId);
        SBR_3_0_Generic_Callout.setHeaders(headers);
        List<String> pathParams = new List<String>();
        pathParams.add(order.Reservation_Order_Number__c);
        SBR_3_0_Generic_Callout.setURLParams(pathParams);
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(servicePayload, UPDATEAPINAME);
        responseStatusCode = returnPayload.getStatusCode();
        System.debug('\n @@ HTTPresponse =' + returnPayload);
        response = JSON.deserializeUntyped(returnPayload.getBody());
        System.debug('\n @@ response =' + response);
        return returnPayload.getBody();
    }
    private void validateData() {
        if (order.Order_By__r.LastName == null) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_OrdrByLstName_ErrMsg);
        }
        if (order.Order_By__r.FirstName == null) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_OrdrByFrstName_ErrMsg);
        }
        if(order.Sales_Rep__r.RepID__c == null){
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_SalesRepId_ErrMsg);
        }
        if(order.Account.Record_Type_Text__c != 'Non-Credit'){
            if(order.RM_Account_Number__c == null){
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_RMAccNumber_ErrMsg);
            }
        }
        if(order.Account.Phone == null){
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_AccPhone_ErrMsg); 
        }
        if(this.currentUserWynneUserName == null){
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_WynneName_ErrMsg);
        }
        if (order.Order_By__r.Email == null) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_OrderByEmail_ErrMsg);
        }
        if (order.Order_By__r.Phone == null){
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_OrderByPhone_ErrMsg);
        }
        if (order.Order_By__r.Phone != null && order.Order_By__r.Phone.length() < 10){
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_OrderByPhoneNotValid_ErrMsg);
        }
        if (order.Return_Date__c == null) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_ReturnDate_ErrMsg);
        }
        if(order.Account.Record_Type_Text__c != 'Non-Credit'){
            if(order.Jobsite__r == null){
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_Jobsite_ErrMsg);
            } else {
                if(order.Jobsite__r.Branch__r == null) {
                    throw new CreateOrderException(Label.SBR_3_0_OrderAPI_Branch_ErrMsg);
                } else {
                    if(order.Jobsite__r.Branch__r.Branch_Location_Number__c == null) {
                        throw new CreateOrderException(Label.SBR_3_0_OrderAPI_BrnchLocationNmbr_ErrMsg);
                    }
                    if(order.Jobsite__r.Branch__r.Time_Zone_Id__c == null) {
                        throw new CreateOrderException(Label.SBR_3_0_OrderAPI_LocationTimeZoneId_ErrMsg);
                    }
                }
                if (order.Jobsite__r.Location == null) {
                    throw new CreateOrderException(Label.SBR_3_0_OrderAPI_JobsiteAddress_ErrMsg);
                } else {
                    if(order.Jobsite__r.Location.OMS_Sourcing_Enabled__c == null) {
                        throw new CreateOrderException(Label.SBR_3_0_OrderAPI_JobsiteLocationOMSSourcingEnabled_ErrMsg);
                    }
                    if (order.Jobsite__r.LocationId == null) {
                        throw new CreateOrderException(Label.SBR_3_0_OrderAPI_JobsiteLocationId_ErrMsg);
                    }
                    if (order.Jobsite__r.Job_Number__c == null) {
                        throw new CreateOrderException(Label.SBR_3_0_OrderAPI_JobsiteJobNumber_ErrMsg);
                    }
                }
            }
        }
        for(OrderItem orderItemRec: order.OrderItems) {
            if(orderItemRec.Product2.Product_Type__c == 'Cat-Class') {
                validateProduct(orderItemRec);
            } else if (orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || orderItemRec.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || (orderItemRec.is_User_Added__c && (orderItemRec.Product2.Product_Type__c == 'MISC Charge Items' || orderItemRec.Product2.Product_Type__c == 'Misc-Charge'))) {
                validateSaleItem(orderItemRec);
            } 
            // else if(order.Reservation_Order_Number__c == null){
            //     validateMiscItem(orderItemRec);
            // }
        }
    }
    private void validateProduct(OrderItem orderItem) {
        if (orderItem.Misc_Charges_Type__c == null) {
            if (orderItem.Min_Rate__c == null) {
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_MinRate_ErrMsg);
            }
            if (orderItem.Daily_Rate__c == null) {
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_DailyRate_ErrMsg);
            }
            if (orderItem.Weekly_Rate__c == null) {
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_WeeklyRate_ErrMsg);
            }
            if (orderItem.Monthly_Rate__c == null) {
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_MonthlyRate_ErrMsg);
            }
            if (orderItem.Product2.Category__c == null) {
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_ProductCategory_ErrMsg);
            }
            if (orderItem.Product2.Class__c == null) {
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_ProductClass_ErrMsg);
            }
            if (orderItem.Quantity == null) {
                throw new CreateOrderException(Label.SBR_3_0_OrderAPI_Quantity_ErrMsg);
            }
        }
    }

    private void validateSaleItem(OrderItem orderItem) {
        if (orderItem.Product2.Item_Number__c == null) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg);
        }
        if (orderItem.Product2.Stock_Class__c == null) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_ProductStockClass_ErrMsg);
        }
        if (orderItem.Quantity == null) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_QuantitySalesItem_ErrMsg);
        }
        if (orderItem.Selling_Price__c == null || orderItem.Selling_Price__c == 0) {
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_SellingPriceSalesItem_ErrMsg);
        }
        if (orderItem.Order_Item_Unit_Of_Measure__c == null || orderItem.Order_Item_Unit_Of_Measure__c == ''){
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_OrderItemUntOfMsr_ErrMsg);
        }
        if (orderItem.OrderItemNumber == null){
            throw new CreateOrderException(Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg);
        }
    }
    
    private void handleOrderResponse() {
        String errorMsg  = '';
            if(response != null && response instanceof Map<String, Object>) {
                Map<String, Object> resultMap = (Map<String, Object>)response;
                if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                    Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                    if(data.containsKey(RM_RESERVATION_ID) && order.Reservation_Order_Number__c== null){
                        String rmReservationId = (String)data.get(RM_RESERVATION_ID);
                        order.Reservation_Order_Number__c = rmReservationId;
                        order.Is_Edit_In_Progress__c = false;
                        order.Last_Edit_By__c =null;
                        update order;
                    }
                    if(data.containsKey(LINES)){
                        List<Object> linesData =(List<Object>)data.get(LINES);
                        for(Object line : linesData) {
                            Map<String, Object> linesMap= (Map<String, Object>) line;
                            String lineNumber;
                            if(isConvertQuoteToOrder()){
                                lineNumber = (String)linesMap.get(GLOBAL_LINE_NUMBER);
                            } else {
                                lineNumber = (String)linesMap.get(SF_LINE_NUMBER);
                            }
                            Integer lineNo = (lineNumber!= null && lineNumber != '')?Integer.valueOf(lineNumber):null;
                            if(mapOrderItem.containsKey(lineNo)) {
                                OrderItem ordItem = mapOrderItem.get(lineNo);
                                ordItem.Reservation_Line_Number__c = Integer.valueOf(linesMap.get(RM_LINE_NUMBER));
                                ordItem.Line_Item_Type__c = (String)linesMap.get(RM_LINE_TYPE);
                                ordItem.Global_Line_Number__c = Integer.valueOf(linesMap.get(GLOBAL_LINE_NUMBER));
                                ordItem.Line_Composite_Key__c = order.Reservation_Order_Number__c + '-' +ordItem.Global_Line_Number__c;
                            }
                         
                        }
                        order.Is_Edit_In_Progress__c = false;
                        order.Last_Edit_By__c = null;
                        update order;
                        update mapOrderItem.values();
                    }
                    
                } else if(resultMap.containsKey(ERROR) && resultMap.get(ERROR) instanceof Map<String, Object>) {
                    Integer[] codeArray  = new Integer[] {400,401,404,405,406,415,422,500};
                    if(codeArray.contains(responseStatusCode)) {
                        Map<String, Object> error = (Map<String, Object>)resultMap.get(ERROR);
                        errorMsg = 
                            ' message: ' +
                            error.get('message') +
                            ' errorKey: ' +
                            error.get('errorKey') +
                            ' errorCode: ' +
                            error.get('errorCode');
                    }
                    else{
                        errorMsg = Label.Reservation_API_Error;
                    }
                    throw new CreateOrderException(errorMsg);
                }
            }
    }
    public class CreateOrderException extends Exception {}
    
    // COMMENTING THE BELOW CODE AS THE RATE VALIDATION STORIES ARE CURRENTLY UNTAGGED FROM THE SPRINT AND WILL COME IN FUTURE SPRINT

    // //FRONT-9280
    // public String validateOrder(List<OrderItem> orderItems, Id orderId, Boolean isSales) {
    //     Map<Id, OrderItem> orderLineMap = new Map<Id, OrderItem>(orderItems);
    //     Map<Id, Order> orders = SBR_3_0_OrderDA.getOrders(new Set<Id>{orderId});
    //     Order order = orders.get(orderId);
    //     SBR_3_0_WrapOrder orderPayload =  SBR_3_0_OrderServicePayloadGenerator.getPayloadWrapper(order);
    //     servicePayload = updateLineItemValues(orderPayload, orderLineMap, isSales);
    //     this.companyId = !String.isBlank(order.Company_Code__c) ? order.Company_Code__c : '01';

    //     HTTPResponse returnPayload;
    //     Map<String, String> headers = new Map<String, String>();
    //     headers.put('x-correlation-id', SBR_3_0_Generic.generateRandomString(10));
    //     headers.put('companyId', this.companyId);
    //     headers.put('validate', 'true');
    //     SBR_3_0_Generic_Callout.setHeaders(headers);
    //     returnPayload = SBR_3_0_Generic_Callout.callEndpoint(servicePayload, APINAME);
    //     responseStatusCode = returnPayload.getStatusCode();
    //     System.debug('\n ====HTTPresponse====\n' + returnPayload + '====\nresponse====\n' + JSON.deserializeUntyped(returnPayload.getBody()));
    //     return returnPayload.getBody();
    // }
    
    // /*
    //  * FRONT-9280
    //  * Method used to replace the existing values with user edited by Users  
    // */ 
    // private String updateLineItemValues(SBR_3_0_WrapOrder orderPayload, Map<Id, OrderItem> orderLineMap, Boolean isSales) {
    //     List<SBR_3_0_WrapOrder.Products> updatedProducts=new List<SBR_3_0_WrapOrder.Products>();
    //     List<SBR_3_0_WrapOrder.salesItems> updatedSalesItems=new List<SBR_3_0_WrapOrder.salesItems>();
    //     Map<Id, OrderItem> orderLineValuesMap = getOrderItems(orderLineMap.keySet());
        
    //     if(isSales) {
    //         for(SBR_3_0_WrapOrder.salesItems salesItem: orderPayload.salesItems) {
    //             if(orderLineMap.containsKey(salesItem.lineItemId)) {
    //                 OrderItem lineItemJS = orderLineMap.get(salesItem.lineItemId);
    //                 OrderItem lineItemDB = orderLineValuesMap.get(salesItem.lineItemId);
    //                 salesItem.rmLineNumber = lineItemDB.Reservation_Line_Number__c?.intValue();
    //                 salesItem.sfLineNumber = String.valueOf(lineItemDB.OrderItemNumber);
    //                 salesItem.itemNumber = lineItemDB.Product2.Item_Number__c;
    //                 salesItem.quantity = lineItemJS.Quantity?.intValue();
    //                 salesItem.stockClass = lineItemDB.Product2.Stock_Class__c;
    //                 salesItem.unitPrice = lineItemJS.Selling_Price__c;
    //                 salesItem.unitOfMeasure = lineItemDB.Product2.QuantityUnitOfMeasure;
    //                 salesItem.lineComment = lineItemDB.Line_Comments__c; 
    //                 updatedSalesItems.add(salesItem);
    //             }
    //         }
    //     } else {
    //         for(SBR_3_0_WrapOrder.Products product: orderPayload.Products) {
    //             if(orderLineMap.containsKey(product.lineItemId)) {
    //                 OrderItem lineItemJS = orderLineMap.get(product.lineItemId);
    //                 OrderItem lineItemDB = orderLineValuesMap.get(product.lineItemId);
    //                 product.rmLineNumber = lineItemDB.Reservation_Line_Number__c?.intValue();
    //                 product.sfLineNumber = String.valueOf(lineItemDB.OrderItemNumber);
    //                 product.quantity = lineItemJS.Quantity?.intValue();
    //                 product.minimumRate = lineItemJS.Min_Rate__c;
    //                 product.hourRate = lineItemJS.Hourly_Rate__c != null ? lineItemJS.Hourly_Rate__c : 0;
    //                 product.actualRates.day = lineItemJS.Daily_Rate__c;
    //                 product.actualRates.weekly = lineItemJS.Weekly_Rate__c;
    //                 product.actualRates.monthly = lineItemJS.Monthly_Rate__c;
    //                 updatedProducts.add(product);
    //             }
    //         }
    //     }
    //     orderPayload.Products = updatedProducts;
    //     orderPayload.salesItems = updatedSalesItems;
    //     System.debug('\n====validateOrder=Request===\n' + JSON.serializePretty(orderPayload));
    //     return JSON.serialize(orderPayload, true);
    // }
    
    // private static Map<Id, OrderItem> getOrderItems(Set<Id> orderItemIds) {
    //     return new Map<Id, OrderItem>([
    //         SELECT 
    //         	Reservation_Line_Number__c, OrderItemNumber, Product2.Item_Number__c, 
    //         	Product2.Stock_class__c, Product2.QuantityUnitOfMeasure, Line_Comments__c
    //         FROM OrderItem
    //         WHERE Id IN: orderItemIds
    //     ]);
    // }

    // private void validateMiscItem(OrderItem orderItem) {
    //     if (orderItem.Misc_Charges_Type__c == null) {
    //         throw new CreateOrderException('Order Item is missing Misc Charges Type. Please update Order Item and Resubmit.');
    //     }
    //     if (orderItem.Selling_Price__c == null) {
    //         throw new CreateOrderException('Order Item is missing Selling price. Please update Order Item and Resubmit.');
    //     }
    //     if (orderItem.OrderItemNumber == null) {
    //         throw new CreateOrderException('Order Item is missing OrderItemNumber. Please update Order Item and Resubmit.');
    //     }
    //     if (orderItem.Product2.Item_Number__c == null) {
    //         throw new CreateOrderException('Order Item Product is missing Item Number. Please update Product and Resubmit.');
    //     }
    //     if (orderItem.Product2.Stock_Class__c == null) {
    //         throw new CreateOrderException('Order Item Product is missing Stock Class. Please update Product and Resubmit.');
    //     }
    // }
}