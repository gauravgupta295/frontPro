/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateQuotes
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quote to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Raymond Gee          2022-09-23             Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_API_CreateQuotes {
    private static final String APINAME = 'Create_Quotes_API';
    private static final String DATA = 'data';
    private static final String RMQUOTEID = 'rmQuoteId';
    private static final String ERROR = 'error';
    private static final String LINES = 'lines';
    private static final String SF_LINE_NUMBER = 'sfLineNumber';
    private static final String RM_LINE_NUMBER = 'rmLineNumber';
    private static final String RM_LINE_TYPE = 'rmLineType';
    private static final String LINE_NUMBER = 'lineNumber';
    private static final String SUCCESS = 'success';
    private static final String ORDERLINEITEM_MESSAGE = 'Line item is not present for this Order';
    private static final String USEREDIT_MESSAGE = 'User does not have access for this record';
    private static final String RMERROR_MESSAGE = 'Record is already sent to RentalMan';
    private static final String DELIVERY = 'Delivery';
    private static final String PICKUP = 'Pickup';
    private static final String SUBMITTED = 'Submitted';
    private Id quoteId;
    private String companyId;
    private SBR_3_0_WrapQuote quoteWrapper;
    private SBQQ__Quote__c quote;
    private Object response;
    private Map<Integer, SBQQ__QuoteLine__c> mapQuoteLineItem = new Map<Integer,SBQQ__QuoteLine__c>();


    public SBR_3_0_API_CreateQuotes(Id quoteId, String companyId) {
        Set<Id> quoteIds;
        Map<Id, SBQQ__Quote__c> quotes;

        quoteWrapper = new SBR_3_0_WrapQuote();
        this.quoteId = quoteId;
        this.companyId = companyId;

        quoteIds = new Set<Id>();
        quoteIds.add(quoteId);

        quotes = new Map<Id, SBQQ__Quote__c>(SBR_3_0_QuoteDA.getQuotes(quoteIds));
        for (Id key: quotes.keySet()) {
            quote = quotes.get(key);
        }

        validateData();
        generateWrapper();
        createQuote();
        handleQuoteResponse();
    }

    private void createQuote(){
        String returnPayload = '';
        
        // generateJSONPayload();
        // System.debug(JSON.serializePretty(generateJSONPayload()).replace('null', '\"\"'));
        // System.debug(JSON.serializePretty(this.quoteWrapper).replace('null', '\"\"'));
        // System.debug(generateJSONPayload());
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(generateJSONPayload(), APINAME, this.companyId);
        
        response = JSON.deserializeUntyped(returnPayload);
    }

    private void handleQuoteResponse() {
        String errorMsg  = '';
        System.debug('\n@@ response = ' + response);
        try {
            if(response != null && response instanceof Map<String, Object>) {
                
                Map<String, Object> resultMap = (Map<String, Object>)response;
                if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                    Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                    if(data.containsKey(RMQUOTEID)){
                        String rmQuoteId = companyId + '-' + (String)data.get(RMQUOTEID);
                        quote.Rentalman_Quote_Id__c = rmQuoteId;
                        quote.Submitted_to_Wynne__c = true;
                        quote.SBQQ__Status__c = SUBMITTED;
                        update quote;
                    }
                    if(data.containsKey(LINES)){
                        List<Object> linesData =(List<Object>)data.get(LINES);
                    
                        for(Object line : linesData) {
                            Map<String, Object> linesMap= (Map<String, Object>) line;
                            String lineNumber = (String)linesMap.get(SF_LINE_NUMBER);
                            Integer lineNo = (lineNumber!= null && lineNumber != '')?Integer.valueOf(lineNumber):null;
                            if(mapQuoteLineItem.containsKey(lineNo)) {
                                SBQQ__QuoteLine__c quoteLineItem = mapQuoteLineItem.get(lineNo);
                                quoteLineItem.RM_Quote_Line_Number__c = Integer.valueOf(linesMap.get(RM_LINE_NUMBER));
                            //    quoteLineItem.Global_Line_Number__c = String.valueOf(linesMap.get(LINE_NUMBER));
                                quoteLineItem.Global_Line_Number__c = Integer.valueOf(linesMap.get(LINE_NUMBER));
                                quoteLineItem.Line_Item_Type__c = String.valueOf(linesMap.get(RM_LINE_TYPE));
                                quoteLineItem.Line_Composite_Key__c = companyId + '-' + String.valueOf(linesMap.get(RM_LINE_NUMBER)) + '-' + String.valueOf(linesMap.get(LINE_NUMBER));
                            }
                            /*
                            else{
                                SBQQ__QuoteLine__c quoteLineNoSF = new SBQQ__QuoteLine__c();
                                quoteLineNoSF = (SBQQ__QuoteLine__c) line;
                                quoteLineNoSF.RM_Quote_Line_Number__c = Integer.valueOf(linesMap.get(RM_LINE_NUMBER));
                                quoteLineNoSF.Global_Line_Number__c = Integer.valueOf(linesMap.get(LINE_NUMBER));
                                quoteLineNoSF.Line_Composite_Key__c = companyId + '-' + String.valueOf(linesMap.get(RM_LINE_NUMBER)) + '-' + String.valueOf(linesMap.get(LINE_NUMBER));
                                //need to do AC2 here
                                //set the info for the json response
                            }
                            */
                        }
                        update mapQuoteLineItem.values();
                    }
                } else if(resultMap.containsKey(ERROR) && resultMap.get(ERROR) instanceof Map<String, Object>) {
                    Map<String, Object> error = (Map<String, Object>)resultMap.get(ERROR);
                    errorMsg = 
                                'message: ' +
                                    error.get('message') + 
                                    ' errorKey: ' + 
                                    error.get('errorKey') +
                                    ' errorCode: ' +
                                    error.get('errorCode');
                    //SF-6805
                    String errorStr = String.valueOf(error.get('message'));
                    String jobLocNotFound = 'Job location not found';
                    
                    if(String.isNotBlank(errorStr) && errorStr.contains(jobLocNotFound)){
                        errorMsg = 
                                'message: ' +
                                Label.Job_Site_Error + 
                                    ' errorKey: ' + 
                                    error.get('errorKey') +
                                    ' errorCode: ' +
                                    error.get('errorCode');
                    }
                    throw new CreateQuoteException(errorMsg);
                }
            }
        }
        catch(Exception e) {
            if(errorMsg  == null) {
                errorMsg = SBR_3_0_Constants.ERROR_MSG;
            }
            throw new CreateQuoteException(errorMsg);
        }
    }

    private void validateData() {
        if(quote.SBQQ__Account__r.Record_Type_Text__c == null) {
            throw new CreateQuoteException('Account Record type is missing. Please update Account and Resubmit');
        }
        if(quote.SBQQ__Account__r.Record_Type_Text__c == SBR_3_0_Constants.ACCOUNT_REC_TYPE_PROSPECT) {
            throw new CreateQuoteException('You cannot submit this Quote while the Account is still a Prospect. Please have the customer complete the Credit Application, which can be sent from the Account record page.');
        }
        if(quote.Id == null) {
            throw new CreateQuoteException('Quote Id is required');
        }
      /*  if(quote.SBQQ__Account__c == null)
        {
            throw new CreateQuoteException('quote.SBQQ__Account__r is required');
        }*/
        if (quote.Start_Date__c == null) {
            throw new CreateQuoteException('quote.Start_Date__c is required');
        } 
        if (quote.End_Date__c == null) {
            throw new CreateQuoteException('quote.End_Date__c is required');
        }
        if (quote.Delivery_Date__c == null) {
            throw new CreateQuoteException('quote.Delivery_Date__c is required');
        }
        if (quote.Ordered_by__r.Email == null) {
            throw new CreateQuoteException('Ordered By Contact is missing email. Please update Contact and Resubmit.');
        }
        if (quote.Ordered_by__r.Phone == null && quote.Ordered_by__r.MobilePhone == null ){
            throw new CreateQuoteException('Ordered By Contact is missing phone number. Please update Contact and Resubmit.');
        }
    /*if (quote.Opt_Out_RPP__c == null) {   //SF-7224 commented
      throw new CreateQuoteException(
        'Quote is missing Opt Out RPP is required'
      );
    }*/
        if (quote.Opt_Out_Fuel_Charge__c == null) {
            throw new CreateQuoteException('Quote Opt Out Fuel Charge is required');
        }
        if (quote.Selling_Channel__c == null) {
            throw new CreateQuoteException('Quote Selling Channel is required');
        }
        if(quote.Jobsite__r == null){
            throw new CreateQuoteException('Quote is missing Jobsite');
        } else {
            if(quote.Jobsite__r.Branch__r == null) {
                throw new CreateQuoteException('Quote Jobsite is missing Branch. Please update Jobsite and Resubmit.');
            } else {
                if(quote.Jobsite__r.Branch__r.Branch_Location_Number__c == null) {
                    throw new CreateQuoteException('Quote Jobsite Branch is missing Branch Location Number. Please update Branch and Resubmit.');
                }
                if(quote.Jobsite__r.Branch__r.Time_Zone_Id__c == null) {
                    throw new CreateQuoteException('Quote Jobsite Branch is missing Time Zone Id. Please update Branch and Resubmit.');
                }
            }
            if (quote.Jobsite__r.Location == null) {
                throw new CreateQuoteException('quote.Jobsite__r.Location is required');
            } else {
                if(quote.Jobsite__r.Location.OMS_Sourcing_Enabled__c == null) {
                    throw new CreateQuoteException('quote.Jobsite__r.Location.OMS_Sourcing_Enabled__c is required');
                }
                if (quote.Jobsite__r.LocationId == null) {
                    throw new CreateQuoteException('quote.Jobsite__r.LocationId is required');
                }
                if (quote.Jobsite__r.Job_Number__c == null) {
                    throw new CreateQuoteException('quote.Jobsite__r.Job_Number__c is required');
                }
            }
        }
        
        for(SBQQ__QuoteLine__c ql: quote.SBQQ__LineItems__r) {
            mapQuoteLineItem.put(Integer.valueOf(ql.QuoteItemNumber__c), ql);
            if(ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
                validateProduct(ql);
            } else if(ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS || ql.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE 
                || (ql.is_User_Added__c && (ql.SBQQ__Product__r.Product_Type__c == 'MISC Charge Items' || ql.SBQQ__Product__r.Product_Type__c == 'Misc-Charge'))) {//22570
                validateSaleItem(ql);
            } else {
                validateMiscItem(ql);
            }
        }
    }

    private void validateProduct(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.SBQQ__Product__r.Product_SKU__c == null) {
            throw new CreateQuoteException('Quote Line product is missing Product SKU.  Please update product and Resubmit.');
        } 
        if (quoteLine.SBQQ__Product__r.Category__c == null) {
            throw new CreateQuoteException('Quote Line product is missing Category .  Please update product and Resubmit.');
        } 
        if (quoteLine.SBQQ__Product__r.Class__c == null) {
            throw new CreateQuoteException('Quote Line product is missing Class. Please update product and Resubmit.');
        } 
        if (quoteLine.SBQQ__Quantity__c == null) {
            throw new CreateQuoteException('Quote Line Quantity. Please update Quote Line and Resubmit.');
        } 
        if (quoteLine.Free_Flag__c == null) {
            throw new CreateQuoteException('Quote Line Free Flag. Please update Quote Line and Resubmit.');
        } 
        if (quoteLine.SBQQ__Product__r.ToolFlex__c == null) {
            throw new CreateQuoteException('Quote Line product is missing ToolFlex. Please update product and Resubmit.');
        } 
        if (quoteLine.Hourly_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Hourly Rate. Please update Quote Line and Resubmit.');
        } 
        if (quoteLine.Min_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Min Rate. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Suggested_Daily_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Suggested Daily Rate. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Suggested_Weekly_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Suggested Weekly Rate. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Suggested_Monthly_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Suggested Monthly Rate. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Daily_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Daily Rate. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Weekly_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Weekly Rate. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Monthly_Rate__c == null) {
            throw new CreateQuoteException('Quote Line is missing Monthly Rate. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Rates_Overriden__c == null) {
            throw new CreateQuoteException('Quote Line is missing Rates Overriden. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.QuoteItemNumber__c == null) {
            throw new CreateQuoteException('Quote Line is missing QuoteItemNumber. Please update Quote Line and Resubmit.');
        }
    }

    private void validateSaleItem(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.SBQQ__Product__r.Item_Number__c == null) {
            throw new CreateQuoteException('Quote Line product is missing Item Number. Please update product and Resubmit.');
        }
        if (quoteLine.SBQQ__Product__r.Stock_Class__c == null) {
            throw new CreateQuoteException('Quote Line product is missing Stock Class. Please update product and Resubmit.');
        }
        if (quoteLine.SBQQ__Quantity__c == null) {
            throw new CreateQuoteException('Quote Line is missing Quantity. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.Selling_Price__c == null) {
            throw new CreateQuoteException('Quote Line is missing Selling Price. Please update Quote Line and Resubmit.');
        }
    }

    private void validateMiscItem(SBQQ__QuoteLine__c quoteLine) {
        if (!quoteLine.is_User_Added__c && quoteLine.Misc_Charges_Type__c == null) { //22570
            throw new CreateQuoteException('Quote Line is missing Misc Charges Type. Please update Quote Line and Resubmit.');
        }
        if (quoteLine.SBQQ__Product__r.Item_Number__c == null) {
            throw new CreateQuoteException('Quote Line product is missing Item Number. Please update product and Resubmit.');
        }
        if (quoteLine.SBQQ__Product__r.Stock_Class__c == null) {
            throw new CreateQuoteException('Quote Line product is missing Stock Class. Please update product and Resubmit.');
        }
    }

    private string generateJSONPayload() {
        String currentWrapper = JSON.serialize(this.quoteWrapper).replace('null', '""');
        if(currentWrapper.contains('"driverLicenseState":"",')) {
            currentWrapper = currentWrapper.remove('"driverLicenseState":"",');
        }
        if(currentWrapper.contains('"driverLicenseNumber":"",')) {
            currentWrapper = currentWrapper.remove('"driverLicenseNumber":"",');
        }
        System.debug(currentWrapper);
        return currentWrapper;
    }

    private void generateWrapper() {
        quoteWrapper.chronos = quote.Jobsite__r.Location.OMS_Sourcing_Enabled__c ? 'Y' : 'N';
        quoteWrapper.userType = quote.SBQQ__Account__r.Record_Type_Text__c == 'Credit' || quote.SBQQ__Account__r.Record_Type_Text__c == 'Corp Link' ? 'credit' : '';
        quoteWrapper.sfQuoteId = quote.Name;

      /*
            SAL-22296
            (1) If the Account has an RM Account# (i.e. Credit or Non-Credit), use RM Account#
            (2) If the Account does not have an RM Account # then
                (3) If the Parent account in the hierarchy has the RM Account# then use that RM#
                (4) Else if it has Driver’s license information, use that
                (5) Else use 0 (zero) as the RM Account# in the request
        */
        String accountNumber;
        Account currentAccount = new Account();
        if(quote.SBQQ__Account__r != null)
        {
            		if(quote.SBQQ__Account__r.RM_Account_Number__c!= null)
                    {
                        accountNumber = quote.SBQQ__Account__r.RM_Account_Number__c;
                        if(accountNumber.contains('-')) {
                            accountNumber = accountNumber.subStringAfter('-');
                        }
                        quoteWrapper.accountNumber = accountNumber;
                    }
            	    else
                    {
                     	currentAccount = SBR_3_0_AccountDA.getAccountRMNumberAndType(quote.SBQQ__Account__c, true);
                        if(currentAccount != null && currentAccount.RM_Account_Number__c!=null ) {
                            if(currentAccount.RM_Account_Number__c.contains('-')) {
                                accountNumber = currentAccount.RM_Account_Number__c.subStringAfter('-');
                                quoteWrapper.accountNumber = accountNumber;
                            }
                           quoteWrapper.userType = currentAccount.Record_Type_Text__c == 'Credit' ? 'credit' : '';
                        }  else {
                           quoteWrapper.accountNumber = '0';
                        }
         			}
                    quoteWrapper.sfAccountNumber = quote.SBQQ__Account__r.SF_Account_Number__c;
       			    quoteWrapper.driverLicenseState = quote.SBQQ__Account__r.Driver_s_License_State__c;
        			quoteWrapper.driverLicenseNumber = quote.SBQQ__Account__r.Drivers_License__c;
            
        }  
/*
        String acctNum = quote.SBQQ__Account__r.RM_Account_Number__c;
        if(acctNum != null && acctNum.contains('-')) {
            acctNum = acctNum.subStringAfter('-');
        } 
        quoteWrapper.accountNumber = acctNum;*/
        
        //fulfillmentType = SBQQ__Quote__c.SBQQ__DeliveryMethod__c
        quoteWrapper.fulfillmentType = quote.SBQQ__DeliveryMethod__c != null ? quote.SBQQ__DeliveryMethod__c : '';
        quoteWrapper.deliveryInstructions = quote.SBQQ__Notes__c;
        quoteWrapper.startDateTime = quote.Start_Date__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        quoteWrapper.endDateTime = quote.End_Date__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        quoteWrapper.earliestDateTime = quote.Delivery_Date__c.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); // optional
        quoteWrapper.poNumber = quote.P_O_Num__c;
    	quoteWrapper.optOutRPP = quote.RPP__c == 'N' ? 'Y' : 'N';	// SF-7224
        quoteWrapper.optOutFuelCharge = quote.Opt_Out_Fuel_Charge__c ? 'Y' : 'N';
        quoteWrapper.deliveryCharge = quote.Delivery_Charge__c != null ? quote.Delivery_Charge__c : 0;
        quoteWrapper.sellingChannel = quote.Selling_Channel__c;
        quoteWrapper.initiatingChannel = 'SLSFRC';
        //quoteWrapper.email = quote.SBQQ__Account__r.E_mail_Address__c; // REMOVE
        //quoteWrapper.phoneNumber = quote.SBQQ__Account__r.Phone.replaceAll('[^0-9]', ''); // REMOVE
        if (String.isNotBlank(quote.Sales_Rep_ID__c)) {
            quoteWrapper.primarySalesRepId = quote.Sales_Rep_ID__c.isNumeric() ? quote.Sales_Rep_ID__c : '';
        }

        quoteWrapper.pickUpCharge = quote.Pickup_Charge__c != null ? quote.Pickup_Charge__c : 0;

        setPC();
        setOrderedBy();
        setJobsite();
        groupQuoteLines(quote.SBQQ__LineItems__r);
    }

    private void setPC() {
        if(quote.Sourcing_Branch__c != null) {
            quoteWrapper.pc = new SBR_3_0_WrapQuote.Pc();
            quoteWrapper.pc.id = quote.Sourcing_Branch__r.Branch_Location_Number__c;

            if(quote.Sourcing_Branch__r?.Time_Zone_Id__c !=null){
                quoteWrapper.pc.timezoneName = quote.Sourcing_Branch__r.Time_Zone_Id__c;
            }else{
                User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
                quoteWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
            }
            
        }
        else {
            quoteWrapper.pc = new SBR_3_0_WrapQuote.Pc();
            if(quote.Branch__r.Branch_Location_Number__c == null) {
                throw new CreateQuoteException('Branch Location Number is required');
            }
            quoteWrapper.pc.id = quote.Branch__r.Branch_Location_Number__c;
            if(quote.Branch__r?.Time_Zone_Id__c !=null){
                quoteWrapper.pc.timezoneName = quote.Branch__r.Time_Zone_Id__c;
            }else{
                User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
                quoteWrapper.pc.timezoneName = loggedInUser?.TimeZoneSidKey;
            }
        }
    }
    
    private void setOrderedBy(){
        quoteWrapper.orderedBy = new SBR_3_0_WrapQuote.OrderedBy();
        String concatName = quote.Ordered_by__r.Lastname+', '+quote.Ordered_by__r.Firstname;
        Integer maxSize = 20;
        if(concatName.length() > maxSize ){
            concatName = concatName.substring(0, maxSize);
        }
        quoteWrapper.orderedBy.name = concatName;
        quoteWrapper.orderedBy.phoneNumber = (String.isNotBlank(quote.Ordered_by__r.Phone) ? quote.Ordered_by__r.Phone : quote.Ordered_by__r.MobilePhone);
        quoteWrapper.orderedBy.email = quote.Ordered_by__r.Email;
    }

    private void setJobsite() {
        quoteWrapper.jobsite = new SBR_3_0_WrapQuote.Jobsite();
        quoteWrapper.jobsite.address = new SBR_3_0_WrapQuote.Address();
        quoteWrapper.jobsite.id = quote.Jobsite__r.LocationId;
        quoteWrapper.jobsite.jobsiteNumber = quote.Jobsite__r.Job_Number__c;
        quoteWrapper.jobsite.address.name = quote.Jobsite__r.Location.Name;
        quoteWrapper.jobsite.address.line1 = quote.Jobsite__r.Location.Street_Address__c;
        quoteWrapper.jobsite.address.line2 = quote.Jobsite__r.Location.Street_Address_2__c;
        quoteWrapper.jobsite.address.city = quote.Jobsite__r.Location.City__c;
        quoteWrapper.jobsite.address.state = quote.Jobsite__r.Location.State__c;
        quoteWrapper.jobsite.address.country = quote.Jobsite__r.Location.Country__c;
        quoteWrapper.jobsite.address.zip = quote.Jobsite__r.Location.Zip_Code__c;
        quoteWrapper.jobsite.address.phoneNumber = quote.Jobsite__r.Job_Site_Contact_0__r.Phone != null ? quote.Jobsite__r.Job_Site_Contact_0__r.Phone.replaceAll('[^0-9]', '') : '';
        // quoteWrapper.jobsite.address.location = ?; // Unsure - Leave blank according to document
        quoteWrapper.jobsite.address.distance = quote.Jobsite__r.Location.Distance_Multiplier__c != null ? quote.Jobsite__r.Location.Distance_Multiplier__c.intValue() : 0; // Converting decimal to Int
    }

    private void setProduct(SBQQ__QuoteLine__c quoteLine) {
        SBR_3_0_WrapQuote.Products product = new SBR_3_0_WrapQuote.Products();
        product.suggestedRates = new SBR_3_0_WrapQuote.SuggestedRates();
        product.actualRates = new SBR_3_0_WrapQuote.SuggestedRates();
        product.toolFlex = (quoteLine.SBQQ__Product__r?.ToolFlex__c == 'C' || String.isBlank(quoteLine.SBQQ__Product__r?.ToolFlex__c)) ? 'N' : quoteLine.SBQQ__Product__r?.ToolFlex__c; //22580, SF-5294
        product.hourRate = quoteLine.Hourly_Rate__c;
        product.minimumRate = quoteLine.Min_Rate__c;
        product.equipmentId = quoteLine.SBQQ__Product__r.Bulk_Item__c ? quoteLine.SBQQ__Product__r?.itemNumberUsedByReservationsRentalOut__c : quoteLine.SBQQ__Product__r.Category__c + quoteLine.SBQQ__Product__r.Class__c;//SAL-24130
        product.catId = quoteLine.SBQQ__Product__r.Category__c;
        product.classId = quoteLine.SBQQ__Product__r.Class__c;
        product.quantity = quoteLine.SBQQ__Quantity__c.intValue(); // converting decimal to Int
        product.freeFlag = quoteLine.Free_Flag__c || quoteLine.Hourly_Rate__c == 0 ? 'Y' : 'N'; // SF-5056
        product.suggestedRates.day = quoteLine.Suggested_Daily_Rate__c != null ? quoteLine.Suggested_Daily_Rate__c : 0;
        product.suggestedRates.weekly = quoteLine.Suggested_Weekly_Rate__c != null ? quoteLine.Suggested_Weekly_Rate__c : 0;
        product.suggestedRates.monthly = quoteLine.Suggested_Monthly_Rate__c != null ? quoteLine.Suggested_Monthly_Rate__c : 0;
        product.actualRates.day = quoteLine.Daily_Rate__c != null ? quoteLine.Daily_Rate__c : 0;
        product.actualRates.weekly = quoteLine.Weekly_Rate__c != null ? quoteLine.Weekly_Rate__c : 0;
        product.actualRates.monthly = quoteLine.Monthly_Rate__c != null ? quoteLine.Monthly_Rate__c : 0;
        product.dayRateOverride = quoteLine.Rates_Overriden__c ? 'Y' : 'N';
        product.weeklyRateOverride = quoteLine.Rates_Overriden__c ? 'Y' : 'N';
        product.monthlyRateOverride = quoteLine.Rates_Overriden__c ? 'Y' : 'N';
        product.lineComment = quoteLine.Line_Comments__c;
        product.sfLineNumber = String.valueOf(quoteLine.QuoteItemNumber__c);
        quoteWrapper.products.add(product);
    }

    private void setSalesItem(SBQQ__QuoteLine__c quoteLine) {
        SBR_3_0_WrapQuote.SalesItems salesItems = new SBR_3_0_WrapQuote.SalesItems();
        salesItems.itemNumber = quoteLine.SBQQ__Product__r.Item_Number__c;
        salesItems.stockClass = quoteLine.SBQQ__Product__r.Stock_Class__c;
        salesItems.quantity = quoteLine.SBQQ__Quantity__c != null ? quoteLine.SBQQ__Quantity__c.intValue() : 0; // Converting demical to Int
        salesItems.unitPrice = quoteLine.Selling_Price__c != null ? quoteLine.Selling_Price__c : 0;
        salesItems.sfLineNumber = String.valueOf(quoteLine.QuoteItemNumber__c);
        quoteWrapper.salesItems.add(salesItems);
    }

    private void setMiscItem(SBQQ__QuoteLine__c quoteLine) {
        SBR_3_0_WrapQuote.MiscItems miscItems = new SBR_3_0_WrapQuote.MiscItems();
        miscItems.type = quoteLine.Misc_Charges_Type__c;
        miscItems.charge = quoteLine.Selling_Price__c != null ? quoteLine.Selling_Price__c : 0;
        if(String.isNotBlank(quoteLine.Misc_Charges_Type__c) && quoteLine.Misc_Charges_Type__c == DELIVERY) {
            quoteWrapper.deliveryCharge = quoteLine.Selling_Price__c;
        }
        if(String.isNotBlank(quoteLine.Misc_Charges_Type__c) && quoteLine.Misc_Charges_Type__c == PICKUP) {
            quoteWrapper.pickupCharge = quoteLine.Selling_Price__c;
        }
        miscItems.tax = quoteLine.Misc_Charges_Tax__c != null ? quoteLine.Misc_Charges_Tax__c : 0;
        miscItems.taxExempt = quoteLine.SBQQ__Taxable__c;
        miscItems.nonTaxable = quoteLine.Misc_Charges_Non_Taxable__c;
        miscItems.itemTaxRate = quoteLine.Misc_Charges_Item_Tax_Rate__c != null ? quoteLine.Misc_Charges_Item_Tax_Rate__c : 0;
        miscItems.itemNumber = quoteLine.SBQQ__Product__r.Item_Number__c;
        miscItems.stockClass = quoteLine.SBQQ__Product__r.Stock_Class__c;
        miscItems.sfLineNumber = String.valueOf(quoteLine.QuoteItemNumber__c);
        miscItems.productSku = String.valueOf(quoteLine.SBQQ__Product__r.Product_SKU__c);
        quoteWrapper.miscItems.add(miscItems);
    }

    private void groupQuoteLines(List<SBQQ__QuoteLine__c> quoteLines) {
        quoteWrapper.products = new List<SBR_3_0_WrapQuote.Products>();
        quoteWrapper.salesItems = new List<SBR_3_0_WrapQuote.SalesItems>();
        quoteWrapper.miscItems = new List<SBR_3_0_WrapQuote.MiscItems>();
        for(SBQQ__QuoteLine__c ql: quoteLines) {
            if(ql.SBQQ__Product__r.Product_Type__c == 'Cat-Class') {
                setProduct(ql);
            } else if(ql.SBQQ__Product__r.Product_Type__c == 'Parts' || ql.SBQQ__Product__r.Product_Type__c == 'Merchandise' 
                || (ql.is_User_Added__c && (ql.SBQQ__Product__r.Product_Type__c == 'MISC Charge Items' || ql.SBQQ__Product__r.Product_Type__c == 'Misc-Charge'))){ //22570
                setSalesItem(ql);
            } else {
                setMiscItem(ql);
            }
        }
    }

    public class CreateQuoteException extends Exception {}
}