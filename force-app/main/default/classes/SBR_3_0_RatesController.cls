public class SBR_3_0_RatesController {
    private static final String APINAME = 'Rates_API_V2';

    // Method to make a call to an external Rates API
    public static String callRatesAPI(String ratesRequestJson, String companyId){
        String returnPayload = SBR_3_0_Generic_Callout.callEndpoint(ratesRequestJson, APINAME, companyId);
        return returnPayload;
    }    

    // Method to construct an ATP request based on certain conditions and user information
    public static SBR_3_0_WrapInventoryAtBranch.ATPRequest getATPRequest(Id objectId, List<String> productSkus, 
    String companyCode) {
        SBR_3_0_Log.setRelatedRecordId(objectId);
        SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj = new SBR_3_0_WrapInventoryAtBranch.ATPRequest();
        String objectName = '';
        // get user profile branch
        List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
        if(userLocation.size() == 0) {
            return null;
        }

        if(String.isNotBlank(objectId)) {
            objectName = objectId.getSObjectType().getDescribe().getName();
        }
        if (String.isBlank(companyCode)) {
            User u = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId()];
            companyCode = u.CompanyName;
        }
        API_ATP_Config__mdt atpFieldConfig = SBR_3_0_CustomMetadata_DA.getATPApiConfig('Prod_Inquiry');
        atpReqObj.orgId = companyCode;
        atpReqObj.cartId = SBR_3_0_Constants.SELLING_CHANNEL;
        atpReqObj.fulfillmentType = SBR_3_0_Constants.ATP_FULFILLMENTTYPE_DELIVERY;
        //obj.transactionType = transactionType; //SAL-24282
        atpReqObj.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
        if(atpFieldConfig <> NULL){
            atpReqObj.includeZeroATP = atpFieldConfig.Include_Zero_ATP__c;
            atpReqObj.limitBranchByDistanceCount = Integer.valueOf(atpFieldConfig.Limit_Branch_By_Distance__c);
        }
        if (objectName == 'SBQQ__Quote__c'){
            SBQQ__Quote__c selectedQuote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{objectId}).values()[0];
            //SAL-24240
            if(!selectedQuote.OMS_Sourcing_Enabled__c){
                return null;
            }

            String formatted = selectedQuote.Start_Date__c.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            atpReqObj.requestedDeliveryDate = formatted;

            if(selectedQuote.SBQQ__DeliveryMethod__c == 'Delivery' &&  selectedQuote.OMS_Sourcing_Enabled__c){
                if(selectedQuote.Jobsite__r <> NULL &&
                    selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s <> NULL
                ){
                    atpReqObj.latitude = selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_JOBSITE;
                    // SAL-25138
                    System.debug('********** selectedQuote.Jobsite__r.Time_Zone_Id__c : '+ selectedQuote.Jobsite__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Jobsite__r.Time_Zone_Id__c;
                } else if(
                    selectedQuote.Sourcing_Branch__r <> NULL && 
                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL
                ) {
                    atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
                    atpReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                } else if(selectedQuote.Branch__r <> NULL && 
                        selectedQuote.Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                        selectedQuote.Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                {
                    atpReqObj.latitude = selectedQuote.Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedQuote.Branch__r.Time_Zone_Id__c : '+ selectedQuote.Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Branch__r.Time_Zone_Id__c;
                }
            } else if(selectedQuote.SBQQ__DeliveryMethod__c == 'Pickup' ){
                atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU; 
                if(selectedQuote.Sourcing_Branch__r <> NULL && selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL){
                    atpReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c : '+ selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c);
                    atpReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                }
            } else {
                //List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
                Datetime myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                atpReqObj.requestedDeliveryDate = formatted;
                if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                    atpReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                    atpReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
                }
            }
            // SAL-24258 - End
        } else if (objectName == 'Order'){
            Order selectedOrder = SBR_3_0_OrderDA.getOrders(new Set<Id>{objectId}).values()[0];
            //SAL-24240
            if(!selectedOrder.OMS_Sourcing_Enabled__c){
                return null;
            }
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
                        atpReqObj.timezoneId = selectedOrder.Jobsite__r.Time_Zone_Id__c;
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
               // List<Schema.Location> userLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
                Datetime myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                atpReqObj.requestedDeliveryDate = formatted;
                if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                    atpReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                    atpReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                    atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                    // SAL-25138
                    System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                    atpReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
                }
            }
            // SAL-24258 - End
        } else {   // For Product Inquiry
            List<Schema.Location> userProfileLocation = SBR_3_0_BranchDA.getLoggedInUserProfileBranchLocation();
            if(userProfileLocation.size() == 0) {
               userProfileLocation = userLocation;  
            }
            //SAL-24240
            //SAL-26846   - Need to look at User location. If it is OMS enabled, user needs to see OMS behaviour on spotlight panel
            if(!userLocation[0].OMS_Sourcing_Enabled__c ){  
                return null;
            }
            
            // SAL-24311
            Datetime myDateTime;
            String formatted;
            if(objectName == 'Cart__c')
            {
                Cart__c currentCart = SBR_3_0_CartDA.getCart(objectId);
                myDateTime = (currentCart.Rental_Start_Date__c!=null ?currentCart.Rental_Start_Date__c:Datetime.now())  ;
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 

            }
            else {
                myDateTime = Datetime.now();
                formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
            }
            
            atpReqObj.requestedDeliveryDate = formatted;
            if(userLocation[0].Latitude_Longitude__Latitude__s <> NULL && userLocation[0].Latitude_Longitude__longitude__s <> NULL){
                atpReqObj.latitude = userLocation[0].Latitude_Longitude__Latitude__s;
                atpReqObj.longitude = userLocation[0].Latitude_Longitude__longitude__s;
                atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                // SAL-25138
                System.debug('********** userLocation[0].Time_Zone_Id__c : '+ userLocation[0].Time_Zone_Id__c);
                atpReqObj.timezoneId = userLocation[0].Time_Zone_Id__c;
            }
        } 

        List<SBR_3_0_WrapInventoryAtBranch.Products> products = new list<SBR_3_0_WrapInventoryAtBranch.Products>();
        for(String catClass : productSkus){
            SBR_3_0_WrapInventoryAtBranch.Products p = new SBR_3_0_WrapInventoryAtBranch.Products();
            p.uom = 'EA';
            p.productId = catClass;
            products.add(p);
        }

        atpReqObj.products = products;
        
        return atpReqObj;
    }

     // Method to call the ATP API and return the response
    static SBR_3_0_WrapInventoryAtBranch.ATPResponse callATPAPI(SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj,String companyCode){
        SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_API_FetchInventoryAtBranch.getInventoryAtBranch(atpReqObj,companyCode);
        return response;
    }

    // Method to find the nearest location of a product based on its availability
    static Map<String, String> findNearestLocationOfProduct(Id recordId, List<String> productSkus, String companyCode,String branchNumber){
         // ATP API Call
         SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj = getATPRequest(recordId,productSkus,companyCode);
         System.debug('atpReqObj = '+JSON.serialize(atpReqObj));
         SBR_3_0_WrapInventoryAtBranch.ATPResponse atpResponse = callATPAPI(atpReqObj,companyCode);
         System.debug('atpResponse = '+JSON.serialize(atpResponse));
         // process response to get map of product and locations
         Map<String, String> productLocationMap = getProductLocationMap(atpResponse,productSkus,branchNumber); 
         System.debug('productLocationMap = '+JSON.serialize(productLocationMap));
         // Additional ATP API call if required
         List<String> productsWithNoLocations = getProductsWithNoLocations(productLocationMap);
         System.debug('productsWithNoLocations = '+JSON.serialize(productsWithNoLocations));
         if(!productsWithNoLocations.isEmpty()){
 
             List<SBR_3_0_WrapInventoryAtBranch.Products> products = new list<SBR_3_0_WrapInventoryAtBranch.Products>();
            // can send single product
             for(String product : productsWithNoLocations){
                 SBR_3_0_WrapInventoryAtBranch.Products p = new SBR_3_0_WrapInventoryAtBranch.Products();
                 p.uom = 'EA';
                 p.productId = product;
                 products.add(p);
             }
 
             atpReqObj.products = products;
             System.debug('atpReqObj additional = '+JSON.serialize(atpReqObj));
             SBR_3_0_WrapInventoryAtBranch.ATPResponse additionaATPResponse = callATPAPI(atpReqObj,companyCode);
             System.debug('additionaATPResponse = '+JSON.serialize(additionaATPResponse));
             // process response to get map of product and locations
             Map<String, String> remainingProductLocationMap = getProductLocationMap(additionaATPResponse,productSkus,branchNumber); 
 
             // update received locations to existing productLocationMap
             productLocationMap.putAll(remainingProductLocationMap);
         }
         System.debug('productLocationMap = '+JSON.serialize(productLocationMap));
         return productLocationMap;
    }

    // Method to construct a Rates Request based on product locations, company code, account number, and jobsite name
    public static SBR_3_0_API_RatesRequestWrapper getRatesRequest( Map<String, String> productLocationMap, String companyCode,String accountNumber,String jobSiteName,String branchNumber){
         // Prepare Rates Request
         SBR_3_0_API_RatesRequestWrapper ratesRequest = new SBR_3_0_API_RatesRequestWrapper();
         if (String.isNotEmpty(accountNumber)) {
            ratesRequest.accountNumber = accountNumber.contains('-') ? accountNumber.split('-')[1] : accountNumber;
         }
         if (String.isNotEmpty(jobSiteName)) {
            ratesRequest.jobsite = jobSiteName;
         }
         ratesRequest.products =  mapToProductDetailsList(productLocationMap,branchNumber);

         return ratesRequest;
    }

    @AuraEnabled
    public static String findRatesForProducts(List<String> productSkus,Map<String, String> productLocationMap,String accountNumber,String branchNumber,Boolean formatForBulk){
        String companyCode;
        if(productLocationMap == null){
            productLocationMap = new Map<String, String>();
            for(String product : productSkus){
                productLocationMap.put(product,branchNumber);
            }
        }

        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());

        if(loggedInUser.CompanyName != null && loggedInUser.CompanyName != ''){
            companyCode = loggedInUser.CompanyName;
        }

        List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details> productDetails = getProducts(productSkus,productLocationMap);
        Map<String,List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>> productAddOns =  getProductAddOns(productSkus,companyCode,productLocationMap);
        
        SBR_3_0_API_RatesRequestWrapper ratesRequest = getRatesRequest(productLocationMap,companyCode,accountNumber,null,branchNumber);
        System.debug('ratesRequest = '+JSON.serialize(ratesRequest));
        String ratesResponse =  callRatesAPI(JSON.serialize(ratesRequest,true),companyCode);

        System.debug('productRates = '+JSON.serialize(ratesResponse));
        SBR_3_0_Log.saveLog(); 
        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> formattedResponse = new List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>();
        if(formatForBulk){
            // Rental Addons
            if(productAddOns.containsKey('Rental Addons') && productAddOns.get('Rental Addons')!=null){
                productDetails.addAll(productAddOns.get('Rental Addons'));
            }

            // Kit Components
            if(productAddOns.containsKey('Kit Component') && productAddOns.get('Kit Component')!=null){
                productDetails.addAll(productAddOns.get('Kit Component'));
            }

            // Cat Class Products
            formattedResponse = formatRatesResponseForBulk(ratesResponse,productDetails,accountNumber,branchNumber);
            // Sales Addons
            if(productAddOns.containsKey('Sales Addons') && productAddOns.get('Sales Addons')!=null){
                List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> salesAddonList = getSalesAddonRates(productAddOns.get('Sales Addons'),branchNumber,companyCode);
                formattedResponse.addAll(salesAddonList);
            }

            ratesResponse = JSON.serialize(formattedResponse);
        }
        return ratesResponse;
    }

    // Method to find rates for products based on availability locations and return the rate details
    @AuraEnabled
     public static String findRatesForProductbyAvailabilityLocation(Id recordId, List<String> productSkus,String customerNumberParam,String branchNumber,Boolean formatForBulk){
        String companyCode;
        User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());

        if(loggedInUser.CompanyName != null && loggedInUser.CompanyName != ''){
            companyCode = loggedInUser.CompanyName;
        }
        
        //ATP Logic
        Map<String, String> productLocationMap = findNearestLocationOfProduct(recordId, productSkus, companyCode,branchNumber);
        //Rates Logic
        String accountNumber = customerNumberParam; // todo

        String productRates  = findRatesForProducts(productSkus,productLocationMap,accountNumber,branchNumber,formatForBulk);
        return productRates;
    }

    // Method to process the provided JSON data and create a map of Product IDs to Location IDs
    public static Map<String, String> getProductLocationMap(SBR_3_0_WrapInventoryAtBranch.ATPResponse response,List<String> productSkus,String branchNumber) {
        Map<String, String> productLocationMap = new Map<String, String>();
        if(response == null){
            for(String product: productSKus){
                productLocationMap.put(product,branchNumber);
            }
        }
        // Extract product and location information
        if (response!=null && response.availabilityByProducts != null && !response.availabilityByProducts.isEmpty()) {

            for(SBR_3_0_WrapInventoryAtBranch.AvailabilityByProducts productInfo: response.availabilityByProducts){
                String productId = productInfo.productId;
            
                if (productInfo.availabilityByFulfillmentTypes != null && !productInfo.availabilityByFulfillmentTypes.isEmpty()) {
                    SBR_3_0_WrapInventoryAtBranch.AvailabilityByFulfillmentTypes availability = productInfo.availabilityByFulfillmentTypes[0]; // Assuming there's only one fulfillment type
                    List<SBR_3_0_WrapInventoryAtBranch.AvailabilityDetails> availabilityDetailsList = availability.availabilityDetails;
                    
                    if (availabilityDetailsList != null && !availabilityDetailsList.isEmpty()) {
                        SBR_3_0_WrapInventoryAtBranch.AvailabilityDetails details = availabilityDetailsList[0]; // Assuming there's only one set of availability details
                        List<SBR_3_0_WrapInventoryAtBranch.AvailabilityByLocations> locations = details.availabilityByLocations;
                        
                        if (locations != null && !locations.isEmpty()) {
                            SBR_3_0_WrapInventoryAtBranch.AvailabilityByLocations locationInfo = locations[0]; // Assuming there's only one location
                            String locationId = locationInfo.locationId;
                            
                            // Populate the map with productId as key and locationId as value
                            productLocationMap.put(productId, locationId);
                        }else{

                            // Populate the map with productId as key and lastResortBranch as value
                            productLocationMap.put(productId,response.lastResortBranch);
                        }
                    }
                }
            }
        }
        
        return productLocationMap;
    }

    // Method to identify products with no locations in a Map<String, String>
    public static List<String> getProductsWithNoLocations(Map<String, String> productLocationMap) {
        List<String> productsWithNoLocations = new List<String>();
        
        // Iterate through the map to find products with no locations
        for (String product : productLocationMap.keySet()) {
            String location = productLocationMap.get(product);
            if (String.isBlank(location)) {
                productsWithNoLocations.add(product);
            }
        }
        
        return productsWithNoLocations;
    }

    // Method to convert Map<String, String> to List<ProductDetails>
    public static List<SBR_3_0_API_RatesRequestWrapper.Products> mapToProductDetailsList(Map<String, String> productLocationMap,String branchNumber) {
        List<SBR_3_0_API_RatesRequestWrapper.Products> products = new List<SBR_3_0_API_RatesRequestWrapper.Products>();
        
        for (String productId : productLocationMap.keySet()) {
            SBR_3_0_API_RatesRequestWrapper.Products product = new SBR_3_0_API_RatesRequestWrapper.Products();
            if(!String.isEmpty(productLocationMap.get(productId)) && productLocationMap.get(productId).contains('-')){
                product.pc = productLocationMap.get(productId).split('-')[1];
            }else{
                product.pc = branchNumber;
            } // take the second element
            product.productId = productId;
            products.add(product);
        }
        
        return products;
    }

    public static  List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> formatRatesResponseForBulk(String ratesResponse,  List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details> productDetails,String customerNumberParam,String branchNumber){

        Map <String, SBR_3_0_SpotlightPanelCmpController.AddOn_Details> productMap = new Map <String, SBR_3_0_SpotlightPanelCmpController.AddOn_Details>();
        List <String> productSKUs = new List<String>();

        for (SBR_3_0_SpotlightPanelCmpController.AddOn_Details prod : productDetails) {
            prod.rateBranch = branchNumber;
            if (prod.catClass != null) {
                productMap.put(prod.catClass, prod);
                if (prod.catClass.isNumeric()) {
                    productSKUs.add(prod.catClass);
                }                    
            } else{
                productMap.put(prod.id, prod);
            }
        }

        if (!productSKUs.isEmpty()) {
            String customerNumber = '';
            if (customerNumberParam != null) {
                customerNumber = customerNumberParam;
            }
            String retVal = ratesResponse;
    
            Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(retVal);

            if (rates != null && !rates.isEmpty()) {
                Map<String, Object> data = (Map<String, Object>) rates.get('data');

                if (data != null && !data.isEmpty()) {
                    List<Object> items = (List<Object>) data.get('items');
                    
                    if (items != null && !items.isEmpty()) {       
                        for (Integer i = 0; i < items.size(); i++) {
                            Map<String, Object> item = (Map<String, Object>) items[i];
                            Map<String, Object> ratesGroup = (Map<String, Object>) item.get('rates');
                            Map<String, Object> suggestedRates = (Map<String, Object>) ratesGroup.get('suggestedRates');
                            String pId = (String) item.get('productId');
                            String pc = (String) item.get('pc');
                            System.debug(' pId = ' + pId);
                            System.debug(' productSKUs = ' + productSKUs);
                            System.debug(' contain : ' + productSKUs.contains(pId));
                            if (productSKUs.contains(pId)) {
                                productMap.get(pId).minRate = (String) suggestedRates.get('minimum');
                                productMap.get(pId).ratesDaily = (String) suggestedRates.get('daily');
                                productMap.get(pId).ratesWeekly = (String) suggestedRates.get('weekly');
                                productMap.get(pId).ratesMonthly = (String) suggestedRates.get('monthly');
                                productMap.get(pId).rateFlag = (String) item.get('rateFlag');
                                productMap.get(pId).notToExceed = String.isBlank((String) item.get('notToExceed')) ? '' : (String) item.get('notToExceed');
                                productMap.get(pId).rateBranch = (String)item.get('pc');

                            }
                        }
                    }
                }   
            }
        }       
        system.debug('Product Map: ' + productMap.values());

        return productMap.values();
    }


    public static List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> getProducts(List<String> productSkus,Map<String,String> productLocationMap) {

        List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details> products = new  List <SBR_3_0_SpotlightPanelCmpController.AddOn_Details>();

        for (Product2 product : SBR_3_0_ProductDA.getProductsByProductSKU(new Set<String>(productSkus))) {
            SBR_3_0_SpotlightPanelCmpController.AddOn_Details prod = new SBR_3_0_SpotlightPanelCmpController.AddOn_Details(product);
            prod.rateBranch = productLocationMap.get(prod.catClass);
            products.add(prod);
        }

        return products;

    }


    public static Map<String,List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>> getProductAddOns(List<String> productSkus, String companyCode,Map<String,String> productLocationMap) {

        Map<String,List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>> mapOfTypeAddon = new Map<String,List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>>();

        for (SBQQ__ProductOption__c option : SBR_3_0_ProductDA.getProductOptionsForProducts(productSkus,companyCode,'ALL') ) {
            
            SBR_3_0_SpotlightPanelCmpController.AddOn_Details ao = new SBR_3_0_SpotlightPanelCmpController.AddOn_Details(option);
            ao.rateBranch = productLocationMap.get(ao.parentSKU);
            if(ao.featureName == 'Sales Addons'){
                
            }else if(ao.featureName == 'Rental Addons'){
                productLocationMap.put(ao.catClass,ao.rateBranch);
            }else if(ao.featureName == 'Kit Component' && ao.availQuantity > 0){
                productLocationMap.put(ao.catClass,ao.rateBranch);
            }  

            if(!mapOfTypeAddon.containsKey(ao.featureName)){
                mapOfTypeAddon.put(ao.featureName,new List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details>());
            }
            mapOfTypeAddon.get(ao.featureName).add(ao);
        }

        return mapOfTypeAddon;
    }

    static List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> getSalesAddonRates(List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> salesAddons,String branchNumber,String companyCode){

        // Sales Addon API call for Rates
        String consumableResponse = getConsumablesResponse(salesAddons,branchNumber,companyCode);

        List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> formattedResponse = formatSalesAddonData(salesAddons,consumableResponse,companyCode);

        return formattedResponse;

    }

    static String getConsumablesResponse(List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> salesAddons, String branchNumber,String companyCode){

        // SF-6493 - USing Map to add unique products for bulk items in consumable api request
        Map<String,SBR_3_0_API_ConsumablesRequest.Products> productMap = new Map<String,SBR_3_0_API_ConsumablesRequest.Products>();
        for(SBR_3_0_SpotlightPanelCmpController.AddOn_Details addOn: salesAddons){
            String sku = addOn.parentSKU;
            SBR_3_0_API_ConsumablesRequest.Products prod = new SBR_3_0_API_ConsumablesRequest.Products();
            prod.catId = sku.substring(0,3);
            prod.classId = sku.substring(3);
            if(!productMap.containsKey(sku)){
                productMap.put(sku,prod);
            }            
        }
        SBR_3_0_API_ConsumablesRequest req = new SBR_3_0_API_ConsumablesRequest();
        req.products = productMap.values();

        if(String.isNotEmpty(branchNumber)){ req.pc = branchNumber;}
        
        String response = SBR_3_0_API_Consumables.getConsumableRates(JSON.serialize(req,true), companyCode);
        system.debug('consumables Request: ' + JSON.serialize(req,true));
        system.debug('consumables Response: ' + response);
        return response;  
    }

    public static List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> formatSalesAddonData(List<SBR_3_0_SpotlightPanelCmpController.AddOn_Details> salesList, String consumableResponse,String companyCode){
        Map <String, SBR_3_0_SpotlightPanelCmpController.AddOn_Details> productMap = new Map <String, SBR_3_0_SpotlightPanelCmpController.AddOn_Details>();
        Map <String, SBR_3_0_SpotlightPanelCmpController.AddOn_Details> updatedProductMap = new Map <String, SBR_3_0_SpotlightPanelCmpController.AddOn_Details>();
        Map <String, Decimal> availQuantityMap = new Map <String, Decimal>();
        List <String> productItemNumbers = new List<String>();
        Set <String> itemNumberSet = new Set<String>();
        for (SBR_3_0_SpotlightPanelCmpController.AddOn_Details sale : salesList) {
            
            sale.addonType = 'SalesAddon'; // To identify the addon type on spotlight panel
            if (sale.catClass != null) {
                productMap.put(sale.catClass, sale);
                productItemNumbers.add(sale.catClass); //Revise                 
                itemNumberSet.add(sale.itemNumber);              
            } else{
                productMap.put(sale.id, sale); //Revise
            }
        }
       
        Set<String> salesAddonProductNumberSet = new Set<String>();
        //24085
        Set<String> forcedItemAddonProductNumberSet = new Set<String>();
        Map <String, Decimal> minQuantityMap = new Map <String, Decimal>();
        if (!productItemNumbers.isEmpty()) {
        
            String customerNumber = '';

            String retVal = consumableResponse;

            Map<String, Object> rates = (Map<String, Object>) JSON.deserializeUntyped(retVal);

            if (rates != null && !rates.isEmpty()) {
                Map<String, Object> data = (Map<String, Object>) rates.get('data');

                if (data != null && !data.isEmpty()) {
                    List<Object> suggestedItems = (List<Object>) data.get('suggestedItems');
                    
                        if (suggestedItems != null && !suggestedItems.isEmpty()) {   
                            System.debug('@@@insuggestedItemsArray');
                            System.debug('suggestedItems : ' + suggestedItems.size());
                            for (Integer i = 0; i < suggestedItems.size(); i++) {
                                Map<String, Object> items = (Map<String, Object>) suggestedItems[i];
                                List<Object> consumables = (List<Object>) items.get('consumables');
                                for (Integer j = 0; j < consumables.size(); j++){
                                    Map<String, Object> consumable = (Map<String, Object>) consumables[j];
                                    List<Object> specGroups = (List<Object>) consumable.get('specGroups');

                                    for(Integer k = 0; k < specGroups.size(); k++){
                                        Map<String, Object> specGroup = (Map<String, Object>) specGroups[k];
                                        List<Object> products = (List<Object>) specGroup.get('products');
                                        // SAL-25055
                                        if(products!=null && products.size()>0){
                                            for (Integer l = 0; l < products.size(); l++){
                                                Map<String, Object> product = (Map<String, Object>) products[l];
                                                String prodstockClass = (String) product.get('stockClass');
                                                String productNumber = (String) product.get('productNumber');
                                                String regionNumber =companyCode;
                                                salesAddonProductNumberSet.add(productNumber);
                                                //24085
                                                Boolean isForceItem = (String) product.get('forceItem') == 'Y' ? true : false;
                                                if(isForceItem){
                                                    forcedItemAddonProductNumberSet.add(productNumber);
                                                    if(product.get('minQuantity')!=null){
                                                        minQuantityMap.put(productNumber,(Decimal)product.get('minQuantity'));// SAL-24085
                                                    }
                                                }            
                                                String pId = customerNumber +'-'+ prodstockClass +'-'+ productNumber;
                                                System.debug('pId-->'+pId);
                                                System.debug('prodstockClass-->'+prodstockClass);
                                                if (productItemNumbers.contains(pId)){
                                                    productMap.get(pId).sellPrice = (Decimal) product.get('sellingPrice');
                                                }
                                                if(product.get('availQuantity')!=null){
                                                    availQuantityMap.put(productNumber,(Decimal)product.get('availQuantity'));// SAL-22398  
                                                }                                                                                         
                                            }  
                                        }                                         
                                    }
                                }
                                //START 25115
                                List<Object> rentables = (List<Object>) items.get('rentables');
                                for (Integer j = 0; j < rentables.size(); j++){
                                        Map<String, Object> rentable = (Map<String, Object>) rentables[j];
                                        if(rentable!=null){
                                            String equipmentNumber = (String) rentable.get('equipmentNumber');
                                            System.debug('equipmentNumber-->'+equipmentNumber);

                                            Boolean isForceItem = (String) rentable.get('forceItem') == 'Y' ? true : false;
                                            if(isForceItem && equipmentNumber != null){
                                                //forcedItemAddonProductNumberSet.add(equipmentNumber);
                                                if (productItemNumbers.contains(equipmentNumber)){
                                                    if(rentable.get('minQuantity')!=null){
                                                        productMap.get(equipmentNumber).minQuantity = (Decimal)rentable.get('minQuantity');
                                                    }
                                                    if(rentable.get('minRate')!=null){
                                                        productMap.get(equipmentNumber).minRate = String.valueOf(rentable.get('minRate'));
                                                    }
                                                    if(rentable.get('dayRate')!=null){
                                                        productMap.get(equipmentNumber).ratesDaily = String.valueOf(rentable.get('dayRate'));
                                                    }
                                                    if(rentable.get('wkRate')!=null){
                                                        productMap.get(equipmentNumber).ratesWeekly = String.valueOf(rentable.get('wkRate'));
                                                    }
                                                    if(rentable.get('moRate')!=null){
                                                        productMap.get(equipmentNumber).ratesMonthly = String.valueOf(rentable.get('moRate'));
                                                    }
                                                    productMap.get(equipmentNumber).sellPrice = 0.1;
                                                }
                                            }
                                        }
                                }
                                //END 25115
                            } 
                        }
                }   
            }
        }

        // Compare salesAddon with what consumable api returned. We will keep only the common values to be shown on spotlight panel UI - SAL-22398
        for(String productKey : productMap.keyset()){
            SBR_3_0_SpotlightPanelCmpController.AddOn_Details adDetails = productMap.get(productKey);
            if(salesAddonProductNumberSet.contains(adDetails.itemNumber)){
                if(availQuantityMap.get(adDetails.itemNumber)!=null){
                    adDetails.availQuantity=availQuantityMap.get(adDetails.itemNumber);
                }                
                updatedProductMap.put(productKey,adDetails);
            }
        
            if(!forcedItemAddonProductNumberSet.isEmpty() && ((adDetails.itemNumber !=null && forcedItemAddonProductNumberSet.contains(adDetails.itemNumber) ) || forcedItemAddonProductNumberSet.contains(adDetails.catClass)) ){
                if(minQuantityMap.get(adDetails.itemNumber)!=null){
                    adDetails.minQuantity = minQuantityMap.get(adDetails.itemNumber);
                }                
            }

        }
        system.debug('Updated Product Map Values: ' + updatedProductMap.values());
        return updatedProductMap.values();
    }

}