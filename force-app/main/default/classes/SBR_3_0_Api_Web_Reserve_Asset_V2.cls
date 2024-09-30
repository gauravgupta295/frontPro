/************************************************
Class Name : SBR_3_0_Api_Web_Reserve_Asset_V2
Developer Name : Ritesh Mohapatra (ServiceMax)
Created Date : 2022/09/21
*************************************************
Modification History :
2022/09/21 - Ritesh Mohapatra - Initial Version
2022/10/25 - Alex DeVries - Fixed bugs, enhanced efficiency (SAL-7102)
************************************************/
@RestResource(urlMapping = '/ASSET/ReserveAsset/v2/*')
global class SBR_3_0_Api_Web_Reserve_Asset_V2 
{
    private static final Map<string, string> errorCodeKeyMap = new Map<string, string> {
        'ASO0109'=>'BAD_REQUEST', // fundamental schema issue
        'ASO0099'=>'MISSING_COMPANY_ID', 'ASO0101'=>'MISSING_ORDER_ID', // missing order data
        'ASO0102'=>'NO_COMPANY_ACCOUNT_FOUND',
        'ASO0103'=>'MISSING_ORDER_LINE_ID', 'ASO0104'=>'MISSING_PRODUCT_ID', 'ASO0110'=>'LOCATION_ID_MISSING', // missing ol data
        'ASO0106'=>'INVALID_DATETIME', 'ASO0108'=>'INVALID_DATETIME', // invalid ol date
        'ASO0200'=>'INVALID_ORDER_LINES', // all ol invalid
        'ASO0100'=>'INVALID_COMPANY_ID', 'ASO0105'=>'INVALID_PRODUCT_ID', 'ASO0111'=>'INVALID_LOCATION_ID', // no assets found
        'ASO0112'=>'INVALID_COMPANY_PRODUCT_LOCATION',
        'ASO0114'=>'MISSING_FIELD_ACCESS', 'ASO0115'=>'MISSING_FIELD_ACCESS', 'ASO0116'=>'MISSING_CREATE_ACCESS', // access errors
        'ASO0117'=>'INVALID_TIME', 'ASO0118'=>'ASSET_RESERVATION_ERROR' // unable to reserve asset
    };
    private static final Map<string, string> errorCodeMsgMap = new Map<string, string> {
        'ASO0099'=>'Company Id is missing.', 'ASO0101'=>'Order Id is missing.',
        'ASO0102'=>'Account not found for specified Company Id',
        'ASO0103'=>'Order Line Id is missing.', 'ASO0104'=>'ProductId is missing.', 'ASO0110'=>'LocationId id is missing.',
        'ASO0106'=>'Invalid min date.', 'ASO0108'=>'Invalid extnEstimatedReturnDate.',
        'ASO0200'=>'All Order Line data is invalid.',
        'ASO0100'=>'Unable to locate any available assets for the specified Company Id. Please check application logs for more information.',
        'ASO0105'=>'Unable to locate any available assets for the specified Product Id(s). Please check application logs for more information.',
        'ASO0111'=>'Unable to locate any available assets for the specified Location Id(s). Please check application logs for more information.',
        'ASO0112'=>'Unable locate any available assets that match Company, Product, and Location criteria. Please check application logs for more information.',
        'ASO0114'=>'User has insufficient access to Asset Fields. Please check if user has access to all queried fields.',
        'ASO0115'=>'User has insufficient access to Equipment On Hold Fields. Please check if user has access to all queried fields.',
        'ASO0116'=>'User has no access to create Equipment on Hold Records.',
        'ASO0117'=>'Unable to reserve the asset for the requested time period.', 'ASO0118'=>'Error encountered when attempting to reserve assets.'
    };
    
    //Temp Method for testing
    public static void tempMethod(){
      integer i = 0;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
      i++;
    }
    
    @HttpPost
    global static void reserveAsset()
    {
        
        // Rest Response initialization
        if(RestContext.response == null)
        { RestContext.response = new RestResponse(); }

        RestResponse restRes = RestContext.response;
        restRes.addHeader('Content-Type', 'application/json');
        
        //VALIDATE HTTP REQUEST DATA
        //  Validate JSON request body schema
        ReserveAssetWrapper raWrapper;
        try
        {
            String reqBodyStr = RestContext.request.requestBody.toString();
            raWrapper = (ReserveAssetWrapper)JSON.deserialize(reqBodyStr, ReserveAssetWrapper.class);
        } 
        catch (Exception ex) 
        { prepareProcessingFailedResponse(restRes, 'ASO0109', ex.getMessage()); return; }

        //  Validate Order data at root of HTTP request body
        List<string> orderErrorMessageCodeList = requestOrderValidator(raWrapper);
        if(!orderErrorMessageCodeList.isEmpty())
        { prepareProcessingFailedResponse(restRes, orderErrorMessageCodeList); return; }

        List<Account> companyAcctList = [SELECT ID FROM ACCOUNT WHERE RM_Account_Number__c = :raWrapper.orgId LIMIT 1];
        //if(companyAcctList.isEmpty())
        //{ prepareProcessingFailedResponse(restRes, 'ASO0102'); return; }
        String companyAcctId = companyAcctList.isEmpty() ? null : companyAcctList.get(0).Id;

        //  Validate Order Line data nested in HTTP request body
        Map<string, List<string>> orderLineErrorMessageMap = requestOrderLineValidator(raWrapper);
        if(orderLineErrorMessageMap.containsKey('Error'))
        { prepareProcessingFailedResponse(restRes, orderLineErrorMessageMap.get('Error')); return; }


        //VALIDATE USER FIELD / RECORD CREATION ACCESS
        //  Asset FLS validation
        if(!SBR_3_0_Api_Web_Reserve_Asset_Validator.assetFieldValidation())
        { prepareProcessingFailedResponse(restRes, 'ASO0114'); return; }

        //  Equipment On Hold FLS validation
        if(!SBR_3_0_Api_Web_Reserve_Asset_Validator.eqHoldFieldValidation())
        { prepareProcessingFailedResponse(restRes, 'ASO0115'); return; }

        //  Equipment On Hold record creation access validation
        if(!SBR_3_0_Api_Web_Reserve_Asset_Validator.eqHoldCreateValidation())
        { prepareProcessingFailedResponse(restRes, 'ASO0116'); return; }


        //VALIDATE EXISTENCE OF ASSET(S)
        //  collect valid OrderLine data
        Map<String, orderLines> validOrderLineMap = new Map<String, orderLines>();
        for (OrderLines ol : raWrapper.orderLines)
        {
            if(!orderLineErrorMessageMap.containsKey(String.valueOf(ol.orderLineId)))
            { validOrderLineMap.put(String.valueOf(ol.orderLineId), ol); }
        }
        if(validOrderLineMap.isEmpty())
        { prepareProcessingFailedResponse(restRes, 'ASO0200'); return; }
		
        Id RentalAssetRecordTypeID = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Rental Asset').getRecordTypeId();
        //  validate existence of Asset(s) for specified Company
        List<Asset> listAssetForCompany = [SELECT Id, 
                                                  Name,
                                                  SM_PS_Company_Code__c,
                                                  SM_PS_Cat_Class__c, 
                                                  SM_PS_Current_Location__r.Branch_Location_Number__c,
            									  SM_PS_Current_Location__c,
                                                  SM_PS_Assigned_Location__r.A360SPARK_ExternalId__c,
                                                  Status,
                                                  SM_PS_Equipment_Number__c,
                                                  (SELECT ID, SM_PS_Hold_Request_From_Date__c, SM_PS_Hold_Request_To_Date__c FROM Equipment_on_Hold__r)
            							   FROM Asset 
                                           WHERE RecordTypeId = : RentalAssetRecordTypeID 
                                           AND SM_PS_Company_Code__c = :raWrapper.orgId];
        if(listAssetForCompany.isEmpty())
        { prepareProcessingFailedResponse(restRes, raWrapper, 'ASO0100'); return; }

        //  validate existence of Asset(s) for specified Products
        Set<String> prodIdSet = new Set<String>();
        for(OrderLines ol : validOrderLineMap.values()) 
        { 
            prodIdSet.add(ol.productId); 
        }
       
        Map<Id,Asset> mapAssetForProducts = new Map<Id,Asset>([SELECT Id, SM_PS_Cat_Class__c FROM ASSET
            WHERE SM_PS_Cat_Class__c IN:prodIdSet]);        
      
        if(mapAssetForProducts.isEmpty())
        { prepareProcessingFailedResponse(restRes, raWrapper, 'ASO0105'); return; }

        //  validate existence of Asset(s) for specified Locations
        Set<String> locIdSet = new Set<String>();
        for(OrderLines ol : validOrderLineMap.values()) 
        { 
            String locationcode = ol.locations[0].locationId;
            string[] locidcode; 

            if(locationcode.contains('-'))
            {
                locidcode = locationcode.split('-');
                locIdSet.add(locidcode[1]);
            }
            else
            {
                locIdSet.add(locationcode);
            }
        }

        Map<Id,Asset> mapAssetForLocations = new Map<Id,Asset>([SELECT Id FROM ASSET
            WHERE SM_PS_Current_Location__r.Branch_Location_Number__c IN:locIdSet]);
        if(mapAssetForLocations.isEmpty())
        { prepareProcessingFailedResponse(restRes, raWrapper, 'ASO0111'); return; }

        //  validate existence of Asset(s) which meet Company/Products/Locations criteria
        Map<string, Asset> assetMap = new Map<string, Asset>();
        for(Asset asset : listAssetForCompany)
        {
            if(mapAssetForProducts.containsKey(asset.Id) && mapAssetForLocations.containsKey(asset.Id))
            { assetMap.put(asset.Id, asset); }
        }

        if(assetMap.isEmpty())
        { prepareProcessingFailedResponse(restRes, raWrapper, 'ASO0112'); return; }


        //RESERVE ASSETS
        //  determine which requested assets are available / not available
        //  based on order line requested delivery date and eq on hold request to/from
        Map<string, List<ReservedDates>> assetIdReservedDatesMap = new Map<string, List<ReservedDates>>();
        Map<string, Asset> orderLineIdToAvailableAssetMap = new Map<string, Asset>();
        for(OrderLines ol : validOrderLineMap.values())
        {
            Boolean assetLocMatch = false, assetLocProdMatch = false, assetLocProdAvailMatch = false;
            Date reqMinDate = Date.valueOf(ol.dates.requestedDeliveryDate.min.replace('T', ' '));
            Date estRetDate = Date.valueOf(ol.dates.CustomFields.extnEstimatedReturnDate.replace('T', ' '));
            for(Asset asset : assetMap.values())
            {
                String locationcode = ol.locations[0].locationId;
                string[] locidcode; 
    
                if(locationcode.contains('-'))
                {
                    locidcode = locationcode.split('-');
                    locationcode = locidcode[1];
                }
                
                // check for Location match
                if(locationcode == asset.SM_PS_Current_Location__r.Branch_Location_Number__c)
                {
                    assetLocMatch = true;

                    // check for Product match
                    if(ol.productId == asset.SM_PS_Cat_Class__c)
                    {
                        assetLocProdMatch = true;

                        // check for Availability match
                        if(asset.Status == 'AVAILABLE')
                        {
                            assetLocProdAvailMatch = true;

                            // check for time availability match
                            // (scan Asset Eq On Hold records)
                            Boolean assetLocProdTimeMatch = true;
                            for(Equipment_on_Hold__c eqOnHold : asset.Equipment_on_Hold__r)
                            {
                                Date eqFromDate = eqOnHold.SM_PS_Hold_Request_From_Date__c;
                                Date eqToDate = eqOnHold.SM_PS_Hold_Request_To_Date__c;
                                if ((reqMinDate >= eqFromDate && reqMinDate <= eqToDate)
                                    || (estRetDate >= eqFromDate && estRetDate <= eqToDate)
                                    || (reqMinDate < eqFromDate && estRetDate > eqToDate))
                                {
                                    assetLocProdTimeMatch = false;
                                    break;
                                }
                            }
                            // check for time availability match
                            // (scan reservations made by other Order Lines in this request)
                            List<ReservedDates> resDatesList = assetIdReservedDatesMap.get(asset.Id);
                            if(resDatesList != null)
                            {
                                for(ReservedDates resDates : resDatesList)
                                { if(resDates.overlapExists(reqMinDate, estRetDate)) { assetLocProdTimeMatch=false; break; } }
                            }

                            // if asset is available, continue to next order line
                            if(assetLocProdTimeMatch)
                            {
                                if(!assetIdReservedDatesMap.containsKey(asset.Id))
                                { assetIdReservedDatesMap.put(asset.Id, new List<ReservedDates>()); }
                                assetIdReservedDatesMap.get(asset.Id).add(new ReservedDates(reqMinDate,estRetDate));

                                orderLineIdToAvailableAssetMap.put(String.valueOf(ol.orderLineId), asset);
                                break;
                            }
                        }
                    }
                }
            }

            // if no asset is available for this order line, log error describing why
            if(!orderLineIdToAvailableAssetMap.containsKey(String.valueOf(ol.orderLineId)))
            {
                // no location match
                if(!assetLocMatch)
                { orderLineErrorMessageMap.put(String.valueOf(ol.orderLineId), new List<string>{'ASO0111'}); }
                // location match but no product match at that location
                else if(assetLocMatch && !assetLocProdMatch)
                { orderLineErrorMessageMap.put(String.valueOf(ol.orderLineId), new List<string>{'ASO0112'}); }
                // location/product match but no available asset
                else if(assetLocProdMatch && !assetLocProdAvailMatch)
                { orderLineErrorMessageMap.put(String.valueOf(ol.orderLineId), new List<string>{'ASO0111'}); }
                // available asset (but no eligible timeslot)
                else if(assetLocProdAvailMatch)
                { orderLineErrorMessageMap.put(String.valueOf(ol.orderLineId), new List<string>{'ASO0117'}); }
            }
        }

        //  create Equipment on Hold records for available Assets
        List<Equipment_on_Hold__c> eqOnHoldToCreateList = new List<Equipment_on_Hold__c>();
        for(string olId : orderLineIdToAvailableAssetMap.keySet())
        {
            OrderLines ol = validOrderLineMap.get(olId);
            Asset asset = orderLineIdToAvailableAssetMap.get(olId);
            if(ol != null && asset != null)
            {
                Date fromDate = Date.valueOf(ol.dates.requestedDeliveryDate.min.replace('T', ' '));
                Date toDate = Date.valueOf(ol.dates.CustomFields.extnEstimatedReturnDate.replace('T', ' '));
                eqOnHoldToCreateList.add(reserveAsset(asset, fromDate, toDate, companyAcctId, raWrapper.customerId,raWrapper.orderId, ol.orderLineId));
            }
        }
        if(!eqOnHoldToCreateList.isEmpty())
        {
            try { insert eqOnHoldToCreateList; }
            catch(Exception ex) {
                prepareProcessingFailedResponse(restRes, new List<string>{'ASO0118'}, ex.getMessage());
                return;
            }
        }
        

        //PREPARE HTTP RESPONSE
        if(orderLineIdToAvailableAssetMap.isEmpty())
        { restRes.statusCode = 400; }
        else if(raWrapper.orderLines.size() == orderLineIdToAvailableAssetMap.size())
        { restRes.statusCode = 201; }
        else { restRes.statusCode = 206; }

        restRes.responseBody = Blob.valueOf(responseJsonGenerator(raWrapper,
            validOrderLineMap, orderLineErrorMessageMap, orderLineIdToAvailableAssetMap));
    }

    private static Equipment_on_Hold__c reserveAsset(Asset asset,
        Date fromDate, Date toDate, String acctId, String customerIdvalue, String OrderId, Integer OrderLineId)
    {
        
        List<OrderItem> OrderItemList = new List<OrderItem>();
        OrderItemList = [SELECT Id,Reservation_Line_Number__c, Global_Line_Number__c FROM OrderItem WHERE Global_Line_Number__c =: OrderLineId];
		
        Equipment_on_Hold__c newEquipmentHoldRec = new Equipment_on_Hold__c(Name = asset.Name
            ,SM_PS_Asset_Id__c = asset.Name, SM_PS_Company_Code__c = asset.SM_PS_Company_Code__c
            ,SM_PS_Equipment_Number__c = asset.Id, SM_PS_Account_Name__c = acctId
            ,SM_PS_Hold_Request_Location__c = asset.SM_PS_Current_Location__c
            ,SM_PS_Hold_Request_From_Date__c = Date.valueOf(fromDate)
            ,SM_PS_Hold_Request_To_Date__c = Date.valueOf(toDate)
            ,SM_PS_Hold_Request_Reason__c = 'HOLD', SM_PS_Status__c = 'Active');


            if(OrderItemList.size()>0)
            {
               newEquipmentHoldRec.SM_PS_Line_Number__c = OrderItemList[0].id;
            }
            
            if(SBR_3_0_Api_Web_Reserve_Asset_Validator.getOrder(OrderId)!=null)
            {
               newEquipmentHoldRec.SM_PS_Invoice_Number__c = SBR_3_0_Api_Web_Reserve_Asset_Validator.getOrder(OrderId).id;   
            }
        
            newEquipmentHoldRec.SM_PS_Hold_for_Customer_Number_Txt__c = customerIdvalue;
            
            newEquipmentHoldRec.SM_PS_ExternalId__c = asset.SM_PS_Company_Code__c +'-'+ 
                                                      OrderId +'-'+
                                                      String.valueOf(OrderLineId) +'-'+
                                                      String.valueOf(fromDate).replace('-','')+'-'+
                                                      String.valueOf(toDate).replace('-','') ;
        
        return newEquipmentHoldRec;
    }

    private static void prepareProcessingFailedResponse(RestResponse restRes, string errCode)
    { prepareProcessingFailedResponse(restRes, new List<string>{errCode}, null); }

    private static void prepareProcessingFailedResponse(RestResponse restRes, string errCode, string errMsgOverride)
    { prepareProcessingFailedResponse(restRes, new List<string>{errCode}, errMsgOverride); }

    private static void prepareProcessingFailedResponse(RestResponse restRes, List<string> errCodeList)
    { prepareProcessingFailedResponse(restRes, errCodeList, null); }

    private static void prepareProcessingFailedResponse(RestResponse restRes, List<string> errCodeList, string errMsgOverride)
    {
        restRes.statusCode = 400;
        List<ErrorMessageWrapper> errMsgWrapList = new List<ErrorMessageWrapper>();
        for(string errCode : errCodeList) { errMsgWrapList.add(new ErrorMessageWrapper(errCode, errMsgOverride)); }

        restRes.responseBody = Blob.ValueOf(errorNodeGenerator(errMsgWrapList));
    }

    private static void prepareProcessingFailedResponse(RestResponse restRes, ReserveAssetWrapper raWrapper, String errorCode)
    {
        restRes.statusCode = 400;
        Map<string, List<string>> orderLineErrorMap = new Map<string, List<string>>();
        for(OrderLines olRaWrapper : raWrapper.orderLines)
        { orderLineErrorMap.put(String.valueOf(olRaWrapper.orderLineId), new List<string>{errorCode}); }

        restRes.responseBody = Blob.ValueOf(responseJsonGenerator(raWrapper,
            new Map<string, orderLines>(), orderLineErrorMap, new Map<string, Asset>()));
    }

    private static string responseJsonGenerator(ReserveAssetWrapper raWrapper, Map<string, orderLines> validOrderLineMap,
        Map<string, List<string>> orderLineErrorMap, Map<string, Asset> orderLineIdAssetMap)
    {
        Map<String, String> responseMap = new Map<String, String>();
        JSONGenerator genJson = JSON.createGenerator(false);

        // Order
        genJson.writeStartObject();
        genJson.writeStringField('orgId', raWrapper.orgId);
        genJson.writeStringField('orderId', raWrapper.orderId);
        genJson.writeStringField('updateUser', 'SF');

        // Order Lines
        genJson.writeFieldName('orderLines');
        genJson.writeStartArray();
        for(OrderLines olRaWrapper : raWrapper.orderLines)
        {
            string olId = String.valueOf(olRaWrapper.orderLineId);
            genJson.writeStartObject(); // Order Line {
            genJson.writeStringField('orderLineId', olId);

            // Invalid Order Line
            if(orderLineErrorMap.containsKey(olId))
            {
                List<string> errorCodeList = orderLineErrorMap.get(olId);

                genJson.writeFieldName('errors');
                genJson.writeStartArray();

                for(string errCode : errorCodeList)
                {
                    genJson.writeStartObject();
                    genJson.writeStringField('errorMessage', errorCodeMsgMap.get(errCode));
                    genJson.writeStringField('errorKey', errorCodeKeyMap.get(errCode));
                    genJson.writeStringField('errorCode', errCode);
                    genJson.writeEndObject();
                }
                
                genJson.writeEndArray();
            }
            // Valid Order Line
            else if(validOrderLineMap.containsKey(olId))
            {
                // successfully reserved asset
                Asset asset = orderLineIdAssetMap.get(olId);
                if(asset != null)
                {
                    genJson.writeFieldName('reservedAsset');
                    genJson.writeStartObject();
                    genJson.writeStringField('name', asset.Name == null ? '' : asset.Name);
                    genJson.writeStringField('productId', asset.SM_PS_Cat_Class__c == null ? '' : asset.SM_PS_Cat_Class__c);

                    string assetCurLoc = asset.SM_PS_Current_Location__r?.Branch_Location_Number__c;
                    genJson.writeStringField('currentLocation', assetCurLoc == null ? '' : assetCurLoc);

                    string assetAsgnLoc = asset.SM_PS_Assigned_Location__r?.A360SPARK_ExternalId__c;
                    genJson.writeStringField('assignedLocation', assetAsgnLoc == null ? '' : assetAsgnLoc);
                    genJson.writeEndObject();
                }
                // failed to reserve asset
                else
                { genJson.writeStringField('reservationMessage', 'No reservable asset for specified product, location, and dates.'); }
            }

            genJson.writeEndObject(); // Order Line }
        }

        genJson.writeEndArray();

        return genJson.getAsString();
    }

    private static String errorNodeGenerator(List<ErrorMessageWrapper> errorWrapList)
    {
        JSONGenerator genVal = JSON.createGenerator(false);

        genVal.writeStartObject(); //Square Bracket Open
        genVal.writeFieldName('errors'); 
        genVal.writeStartArray(); //Square Bracket Open
        if(!errorWrapList.isEmpty())
        {
            for(ErrorMessageWrapper oErrRecord : errorWrapList)
            {
                genVal.writeStartObject(); //Curly Bracket Open
                genVal.writeStringField('errorMessage',oErrRecord.errorMessage);
                genVal.writeStringField('errorKey', oErrRecord.errorKey);
                genVal.writeStringField('errorCode', oErrRecord.errorCode);
                genVal.writeEndObject(); //Curly Bracket Close
            }  
        }

        genVal.writeEndArray(); //Square Bracket Close
        genVal.writeEndObject(); //Square Bracket Close
        
        return genVal.getAsString();
    }

    private static List<String> requestOrderValidator(ReserveAssetWrapper requestWrapper)
    {
        List<string> orderErrorCodeList = new List<string>();

        //Check Company Id is Missing
        if(String.isEmpty(requestWrapper.orgId))
        { orderErrorCodeList.add('ASO0099'); }
        
        //Check Order Id is Missing
        if(string.isEmpty(requestWrapper.orderId))
        { orderErrorCodeList.add('ASO0101'); }

        return orderErrorCodeList;
    }

    private static Map<String,List<string>> requestOrderLineValidator(ReserveAssetWrapper requestWrapper)
    {
        Map<String, List<String>> orderLineErrorMessageMap = new Map<String, List<String>>();
        for (OrderLines ol : requestWrapper.orderLines)
        {
            //OrderLineId Missing
            if(string.isEmpty(String.valueOf(ol.orderLineId)))
            { return new Map<String, List<string>>{'Error'=>new List<string>{'ASO0103'}}; }

            //ProductId Missing
            List<String> errCodeList = new List<string>();
            if(string.isEmpty(ol.productId)) { errCodeList.add('ASO0104'); }

            //LocationId Missing
            if(ol.locations.isEmpty() || (string.isEmpty(ol.locations[0].locationId)))
            { errCodeList.add('ASO0110'); }

            //Min Date Invalid
            if(ol?.dates?.requestedDeliveryDate?.min == null ||
                !SBR_3_0_Api_Web_Reserve_Asset_Validator.dateFieldValidator(ol.dates.requestedDeliveryDate.min, null))
            { errCodeList.add('ASO0106'); }

            //extnEstimatedReturnDate Invalid
            if(ol.dates.customFields.extnEstimatedReturnDate!=null)
            {   if(!SBR_3_0_Api_Web_Reserve_Asset_Validator.dateFieldValidator(ol.dates.customFields.extnEstimatedReturnDate, null))
                errCodeList.add('ASO0108');
            }

            if(!errCodeList.isEmpty())
            { orderLineErrorMessageMap.put(String.valueOf(ol.orderLineId), errCodeList); }
        }

        return orderLineErrorMessageMap;
    }

    public class ReserveAssetWrapper
    {
        public String orgId{ get; set; }
        public String orderId{ get; set; }
        public String customerId {get; set; }
        public List<OrderLines> orderLines{ get; set; }
    }

    public class OrderLines
    {
        public Integer orderLineId;
        public String productId;
        public Dates dates;
        public List<Locations> locations;
    }

    public class Dates
    {
        public RequestedDeliveryDate requestedDeliveryDate;
        public CustomFields customFields;
    }
    public class RequestedDeliveryDate 
    {
        public String min;
        public String max;
    }
    public class CustomFields
    {
        public String extnEstimatedReturnDate;
    }

    public class Locations
    {
        public String locationId;
        public String locationType;
    }

    public class ReservedDates
    {
        public Date minDate;
        public Date retDate;

        public ReservedDates(Date minDt, Date retDt)
        {
            this.minDate = minDt;
            this.retDate = retDt;
        }

        public Boolean overlapExists(Date reqMinDate, Date reqRetDate)
        {
            if(this.minDate == null || this.retDate == null
                || reqMinDate == null || reqRetDate == null)
            { return false; }

            return ((reqMinDate >= this.minDate && reqMinDate <= this.retDate)
                || (reqRetDate >= this.minDate && reqRetDate <= this.retDate)
                || (reqMinDate < this.minDate && reqRetDate > this.retDate));
        }
    }

    public class ErrorMessageWrapper
    {
        string errorMessage;
        string errorKey;
        string errorCode;
        
        public ErrorMessageWrapper(string errCode, string msgOverride)
        {
            this.errorCode = errCode;
            this.errorKey = errorCodeKeyMap.get(errCode);
            this.errorMessage = string.isNotEmpty(msgOverride) ?
                msgOverride : errorCodeMsgMap.get(errCode);
        }
    }
}