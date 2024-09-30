public with sharing class SBR_3_0_CustomerMaturityModelController {
    @AuraEnabled(cacheable=true)
    public static Map<String,SBR_3_0_Customer_Maturity_Model_Labels__mdt> getCustomMetadataResponse(){
        Map<String,SBR_3_0_Customer_Maturity_Model_Labels__mdt> mLabels = SBR_3_0_Customer_Maturity_Model_Labels__mdt.getAll();
        System.debug('mLabels'+mLabels);  
        return mLabels;
    }
    @AuraEnabled(cacheable=true)
    public static MaturityModelResponse getMaturityModelResponse(Id recordId){
        MaturityModelResponse oResponse =  new MaturityModelResponse();
        Id CreditRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Credit').getRecordTypeId();
        Id CorpLinkRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ERP_Link').getRecordTypeId();
        Id OfficeRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Office').getRecordTypeId();
        
        Integer CurrentLOBUsed = 0;
        Integer NoOfProductsRented = 0;
        Integer CurrentTTMSpent = 0;
        Integer PotentialLOBUsed = 0;
            
        Map<String,SBR_3_0_CustomerMaturityModelWrapper.products> mCurrentLOB = new Map<String,SBR_3_0_CustomerMaturityModelWrapper.products>();
        Map<String,SBR_3_0_CustomerMaturityModelWrapper.products> mCurrentLOBSorted = new Map<String,SBR_3_0_CustomerMaturityModelWrapper.products>();
        Map<String,SBR_3_0_CustomerMaturityModelWrapper.products> mPotentialLOB = new Map<String,SBR_3_0_CustomerMaturityModelWrapper.products>();
        Map<Integer,SBR_3_0_CustomerMaturityModelWrapper.products> mCrosssellProducts = new Map<Integer,SBR_3_0_CustomerMaturityModelWrapper.products>();
        Map<Integer,SBR_3_0_CustomerMaturityModelWrapper.products> mUpsellProducts = new Map<Integer,SBR_3_0_CustomerMaturityModelWrapper.products>();
        list<String> lUpAndCrossSellNamesFromRes = new list<String>();
        Map<String,Product_Recommendation_Feedback__c> mUpAndCrossSellNamesFromDB = new Map<String,Product_Recommendation_Feedback__c>();
        
        Map<Id,Analysis_Region__c> mAnalysisRegion = new Map<Id,Analysis_Region__c>();
        Map<String,Customer_Spend__c> mCustomerSpend = new Map<String,Customer_Spend__c>();
        Map<String,Integer> mproductUsedQty = new Map<String,Integer>();
        
        list<SBR_3_0_CustomerMaturityModelController.CurrentLOB> lCurrentLOB = new list<SBR_3_0_CustomerMaturityModelController.CurrentLOB>();
        list<SBR_3_0_CustomerMaturityModelController.PotentialLOB> lPotentialLOB = new list<SBR_3_0_CustomerMaturityModelController.PotentialLOB>();
        list<SBR_3_0_CustomerMaturityModelController.UpSellResponse> lUpSell = new list<SBR_3_0_CustomerMaturityModelController.UpSellResponse>();
        list<SBR_3_0_CustomerMaturityModelController.CrossSellResponse> lCrossSell = new list<SBR_3_0_CustomerMaturityModelController.CrossSellResponse>();
        Map<String,SBR_3_0_Customer_Maturity_Model_Labels__mdt> mLabels = SBR_3_0_Customer_Maturity_Model_Labels__mdt.getAll();
        System.debug('mLabels'+mLabels);
        User oUser = 	[
            				SELECT
            				Id,
            				Rep_Type__c,
            				RepID__c 
            				FROM
            				User
            				WHERE
            				Id =: UserInfo.getUserId()
        				];    
        Account oAccount = new Account();
        list<Account> lAccount = [	
        							SELECT
                                    Id,
            						Name,
                                    Company_Code__c,
                                    RM_Account_Number_Display__c, 
                                    AccountNumber,
                                    ParentId,
             						RecordtypeId
                                    FROM
                                    Account
                                    WHERE
                                    Id =: recordId
        						];
        
        if(!lAccount.isEmpty()){
            if(lAccount[0].RecordtypeId == CreditRecordTypeId || lAccount[0].RecordtypeId == CorpLinkRecordTypeId){
                oResponse.isOfficeAccount = false;
                if(lAccount[0].RM_Account_Number_Display__c == NULL || lAccount[0].Company_Code__c == NULL){
                 	throw new AuraHandledException(oResponse+'::'+mLabels.get('R_M_Account_number_is_missing_for_this_A').Label_Value__c);   
                }
                else{
                    oAccount = lAccount[0];
                }
            }
            else if(lAccount[0].RecordtypeId == OfficeRecordTypeId){
                oResponse.isOfficeAccount = true;
                if(lAccount[0].ParentId == NULL){
                    oResponse.AccountNumber = lAccount[0].RM_Account_Number_Display__c;
                    oResponse.AccountName = lAccount[0].Name;
                    throw new AuraHandledException(oResponse+'::'+mLabels.get('Parent_Account_is_missing_from_the_Offic').Label_Value__c); 
                }
                else{
                    list<Account> lAccountParent = 	[	
                                                        SELECT
                                                        Id,
                        								Name,
                                                        Company_Code__c,
                                                        RM_Account_Number_Display__c,  
                                                        AccountNumber,
                                                        ParentId,
                                                        RecordtypeId
                                                        FROM
                                                        Account
                                                        WHERE
                                                        Id =: lAccount[0].ParentId
                                                        AND
                                                        (
                                                            RecordtypeId =: CreditRecordTypeId
                                                            OR 
                                                            RecordtypeId =: CorpLinkRecordTypeId
                                                        )
                                                    ];
                    if(!lAccountParent.isEmpty()){
                        if(lAccountParent[0].RM_Account_Number_Display__c == NULL || lAccountParent[0].Company_Code__c == NULL){
                            oResponse.AccountNumber = lAccount[0].RM_Account_Number_Display__c;
                            oResponse.AccountName = lAccount[0].Name;
                            throw new AuraHandledException(oResponse+'::'+mLabels.get('R_M_Account_number_is_missing_for_this_A').Label_Value__c);
                        }
                        else{
                            oAccount = lAccountParent[0];
                            oResponse.AccountNumber = lAccountParent[0].RM_Account_Number_Display__c;
                            oResponse.AccountName = lAccountParent[0].Name;
                            System.debug('oResponse'+oResponse);
                        }
                    }
                    else{
                        oResponse.AccountNumber = lAccount[0].RM_Account_Number_Display__c;
                        oResponse.AccountName = lAccount[0].Name;
                        throw new AuraHandledException(oResponse+'::'+mLabels.get('Parent_Account_is_missing_from_the_Offic').Label_Value__c);
                    }
                }
            }
        }
        if(oAccount != NULL){
            oResponse.accountRec = oAccount;
        	String Response;
            Response = SBR_3_0_CustomerMaturityModelCallout.CMMCalloutGet(oAccount.Company_Code__c,oAccount.RM_Account_Number_Display__c);
            SBR_3_0_CustomerMaturityModelWrapper oResponseWrapper = SBR_3_0_CustomerMaturityModelWrapper.parse(Response);
            system.debug('oResponseWrapper'+oResponseWrapper);
            SBR_3_0_CustomerMaturityModelWrapper.products[] lProducts = oResponseWrapper.data.products;
            if(lProducts.isEmpty() && lAccount[0].RecordtypeId == CorpLinkRecordTypeId){
                throw new AuraHandledException(oResponse+'::'+mLabels.get('Please_review_related_credit_account_for').Label_Value__c);    
            }
            else if(lProducts.isEmpty() && ( lAccount[0].RecordtypeId == CreditRecordTypeId || lAccount[0].RecordtypeId == OfficeRecordTypeId)){ 
            	if(lAccount[0].RecordtypeId == OfficeRecordTypeId){ 
                	throw new AuraHandledException(oResponse+'::'+mLabels.get('There_are_no_current_Lines_of_Business').Label_Value__c);
                }
                else{
                    throw new AuraHandledException(oResponse+'::'+mLabels.get('There_are_no_current_Lines_of_Business').Label_Value__c);
                }
            }
            else if(!lProducts.isEmpty() && (oAccount.RecordtypeId == CreditRecordTypeId || oAccount.RecordtypeId == CorpLinkRecordTypeId)){
                for(SBR_3_0_CustomerMaturityModelWrapper.products oProduct : lProducts){
                    if(oProduct.productLineOfBusinessValue != ''){
                        if(oProduct.productRecordType == '1' && oProduct.productRecommendationType == 'upSell'){
                            mUpsellProducts.put(Integer.valueOf(oProduct.productRating),oProduct);
                            String Name = oProduct.catClass+'_'+oAccount.RM_Account_Number_Display__c+'_'+oUser.RepID__c;
                            lUpAndCrossSellNamesFromRes.add(Name);
                        }
                        else if (oProduct.productRecordType == '1' && oProduct.productRecommendationType == 'crossSell'){
                            mCrosssellProducts.put(Integer.valueOf(oProduct.productRating),oProduct); 
                            String Name = oProduct.catClass+'_'+oAccount.RM_Account_Number_Display__c+'_'+oUser.RepID__c;
                            lUpAndCrossSellNamesFromRes.add(Name);
                        }
                        if(oProduct.productRecordType == '1' && oProduct.productRecommendationType == 'crossSell'){
                            mPotentialLOB.put(oProduct.productLineOfBusinessValue,oProduct);
                        }      
                        else if(oProduct.productRecordType == '2' && oProduct.productRecommendationType == 'upSell'){
                            if(oProduct.productUsedQty != ''){
                                if(mproductUsedQty.containsKey(oProduct.productLineOfBusinessValue)){
                                    Integer ExistingTemp = mproductUsedQty.get(oProduct.productLineOfBusinessValue)+Integer.valueOf(oProduct.productUsedQty);
                                    mproductUsedQty.put(oProduct.productLineOfBusinessValue,ExistingTemp);
                                }
                                else{
                                    mproductUsedQty.put(oProduct.productLineOfBusinessValue,Integer.valueOf(oProduct.productUsedQty));
                                }
                            }
                            mCurrentLOB.put(oProduct.productLineOfBusinessValue,oProduct);
                        }
                        
                    }
                }
                if(mCurrentLOB != NULL){
                    list<Customer_Spend__c> lCustomerSpend =    [
                                                                    SELECT 
                                                                    Id,
                                                                    Account__r.Name,
                                                                    Analysis_Region__c,
                                                                    Analysis_Region__r.Name,
                                                                    Analysis_Region__r.Analysis_Region_Key__c,
                                                                    Current_TTM_Spend__c
                                                                    FROM
                                                                    Customer_Spend__c
                                                                    WHERE
                                                                    Analysis_Region__r.Analysis_Region_Key__c IN: mCurrentLOB.keySet()
                                                                    AND
                                                                    Account__c =: oAccount.id
                        											AND 
                        											Current_TTM_Spend__c != NULL
                        											ORDER BY Current_TTM_Spend__c DESC
                                                                ];
                    for(Customer_Spend__c oCustomerSpend : lCustomerSpend){
                        mCustomerSpend.put(oCustomerSpend.Analysis_Region__r.Analysis_Region_Key__c,oCustomerSpend);
                    }
                    for(String AnalysisRegionKey : mCustomerSpend.keySet()){
                        if(mCurrentLOB.containsKey(AnalysisRegionKey)){
                            SBR_3_0_CustomerMaturityModelWrapper.products oCurrentLOB = mCurrentLOB.get(AnalysisRegionKey);
                        	mCurrentLOBSorted.put(oCurrentLOB.productLineOfBusinessValue,oCurrentLOB);    
                        }
                    }
                    for(String  productLineOfBusinessValue : mCurrentLOB.keySet()){
                        if(!mCurrentLOBSorted.containsKey(productLineOfBusinessValue)){
                            SBR_3_0_CustomerMaturityModelWrapper.products oCurrentLOB = mCurrentLOB.get(productLineOfBusinessValue);
                        	mCurrentLOBSorted.put(oCurrentLOB.productLineOfBusinessValue,oCurrentLOB);    
                        }
                    }
                    /*Code for Current Line of Business Starts*/
                    for(String  productLineOfBusinessValue : mCurrentLOBSorted.keySet()){
                        SBR_3_0_CustomerMaturityModelWrapper.products oCurrentLOB = mCurrentLOBSorted.get(productLineOfBusinessValue);
                        CurrentLOBUsed = CurrentLOBUsed + 1;
                        if(mCustomerSpend.containsKey(oCurrentLOB.productLineOfBusinessValue)){
                            Customer_Spend__c oCustomerSpend = mCustomerSpend.get(oCurrentLOB.productLineOfBusinessValue);
                            CurrentTTMSpent = CurrentTTMSpent + Integer.valueOf(oCustomerSpend.Current_TTM_Spend__c);
                        }
                    }
                    for(String  productLineOfBusinessValue : mCurrentLOBSorted.keySet()){
                        SBR_3_0_CustomerMaturityModelWrapper.products oCurrentLOB = mCurrentLOBSorted.get(productLineOfBusinessValue);
                        SBR_3_0_CustomerMaturityModelController.CurrentLOB oCurrentLOBResponse = new SBR_3_0_CustomerMaturityModelController.CurrentLOB();
                        if(mCustomerSpend.containsKey(oCurrentLOB.productLineOfBusinessValue)){
                            Customer_Spend__c oCustomerSpend = mCustomerSpend.get(oCurrentLOB.productLineOfBusinessValue);
                            if(String.isNotEmpty(oCustomerSpend.Analysis_Region__r.Name)){
                                oCurrentLOBResponse.Name = oCustomerSpend.Analysis_Region__r.Name;    
                            }
                            if(oCustomerSpend.Current_TTM_Spend__c != 0){
                                oCurrentLOBResponse.TTMSpent = '$'+String.valueOf(oCustomerSpend.Current_TTM_Spend__c.format());
                                Decimal CustomerSpend = oCustomerSpend.Current_TTM_Spend__c* 100;
                                Decimal CustomerSpendPercentage = CustomerSpend/CurrentTTMSpent;
                                String CSPString = String.valueOf(CustomerSpendPercentage);
                                String CustomerSpendPercentageRounded = CSPString.substring(0, CSPString.indexOf('.') + 3);
                                oCurrentLOBResponse.PercentageOfTotal = CustomerSpendPercentageRounded+'%';
                            }
                            else{
                                oCurrentLOBResponse.TTMSpent = '$0'; 
                                oCurrentLOBResponse.PercentageOfTotal = '0%';
                        	}
                        }
                        else{
                            oCurrentLOBResponse.Name = oCurrentLOB.productLineOfBusiness;
                            oCurrentLOBResponse.TTMSpent = '$0'; 
                            oCurrentLOBResponse.PercentageOfTotal = '0.00%';
                        }
                        if(mproductUsedQty.containsKey(oCurrentLOB.productLineOfBusinessValue)){
                            NoOfProductsRented = NoOfProductsRented + mproductUsedQty.get(oCurrentLOB.productLineOfBusinessValue);
                            oCurrentLOBResponse.NoOfProductsRentedOut = String.valueOf(mproductUsedQty.get(oCurrentLOB.productLineOfBusinessValue).format());
                        }
                        lCurrentLOB.add(oCurrentLOBResponse);
                    }
                    
                    /*Code for Current Line of Business Ends*/
                    if(!lCurrentLOB.isEmpty()){
                        oResponse.CurrentLOB = lCurrentLOB;
                        oResponse.isCurrentLOBNULL = false;
                    }
                    else{
                        oResponse.isCurrentLOBNULL = true;
                    }
                    if(CurrentLOBUsed != 0){
                        oResponse.CurrentLOBUsed = String.valueOf(CurrentLOBUsed);
                    }
                    else{
                        oResponse.CurrentLOBUsed = '0';
                    }
                    if(NoOfProductsRented != 0){
                        oResponse.NoOfProductsRented = String.valueOf(NoOfProductsRented.format());
                    }
                    else{
                        oResponse.NoOfProductsRented = '0';
                    }
                    if(CurrentTTMSpent != 0){
                        oResponse.CurrentTTMSpent = '$'+String.valueOf(CurrentTTMSpent.format());    
                    }
                    else{
                        oResponse.CurrentTTMSpent = '$0';
                    }
                }
                if(mPotentialLOB != NULL){
                    /*Code for Potential Line of Business Starts*/
                    for(String  productLineOfBusinessValue : mPotentialLOB.keySet()){
                        SBR_3_0_CustomerMaturityModelController.PotentialLOB oPotentialLOBResponse = new SBR_3_0_CustomerMaturityModelController.PotentialLOB();
                        SBR_3_0_CustomerMaturityModelWrapper.products oPotentialLOB = mPotentialLOB.get(productLineOfBusinessValue);
                        PotentialLOBUsed = PotentialLOBUsed + 1;
                        if(oPotentialLOB.productLineOfBusiness != ''){
                            oPotentialLOBResponse.Name = oPotentialLOB.productLineOfBusiness;
                            lPotentialLOB.add(oPotentialLOBResponse);
                        }
                    }
                    /*Code for Potential Line of Business Ends*/
                    if(!lPotentialLOB.isEmpty()){
                        oResponse.PotentialLOB = lPotentialLOB;
                        oResponse.isPotentialLOBNULL = false;
                    }
                    else{
                        oResponse.isPotentialLOBNULL = true;
                    }
                    if(PotentialLOBUsed != 0){
                        oResponse.PotentialLOBUsed = String.valueOf(PotentialLOBUsed);
                    }
                }
                list<Product_Recommendation_Feedback__c> lProductRecFeedback = 	[
                                                                            SELECT 
                                                                            Id,
                                                                            Name,
                                                                            Cat_Class_Key__c,
                                                                            Model_Version__c,
                                                                            Feedback_Type__c,
                                                                            Rep_ID__c,
                    														Account_number__c 
                                                                            FROM 
                                                                            Product_Recommendation_Feedback__c
                                                                            WHERE 
                                                                            Name IN: lUpAndCrossSellNamesFromRes
                                                                        ];
                for(Product_Recommendation_Feedback__c oProductRecFeedback : lProductRecFeedback){
                    mUpAndCrossSellNamesFromDB.put(oProductRecFeedback.Name,oProductRecFeedback);
                }
                for(Integer Rating : mCrosssellProducts.keySet()){
                    SBR_3_0_CustomerMaturityModelWrapper.products oProduct = mCrosssellProducts.get(Rating);
                    SBR_3_0_CustomerMaturityModelController.CrossSellResponse oCrossSell = new SBR_3_0_CustomerMaturityModelController.CrossSellResponse();
                    if(oProduct.catClass != ''){
                        oCrossSell.CatClass = oProduct.catClass;
                    }
                    if(oProduct.catClassDescription != ''){
                        oCrossSell.Description = oProduct.catClassDescription;
                    }
                    if(oProduct.productModelVersion != ''){
                        oCrossSell.productModelVersion = oProduct.productModelVersion;
                    }
                    if(oProduct.productCategoryDesc != ''){
                        oCrossSell.productCategoryDesc = oProduct.productCategoryDesc;
                    }
                    String Name = oProduct.catClass+'_'+oAccount.RM_Account_Number_Display__c+'_'+oUser.RepID__c;
                    if(mUpAndCrossSellNamesFromDB.containsKey(Name)){
                        Product_Recommendation_Feedback__c oProductRecFeedback = mUpAndCrossSellNamesFromDB.get(Name);
                        if(oProductRecFeedback.Feedback_Type__c == 'good'){
                            oCrossSell.likeStatus = 'like';
                        }
                        if(oProductRecFeedback.Feedback_Type__c == 'bad'){
                            oCrossSell.dislikeStatus = 'dislike';
                        }
                    }
                    lCrossSell.add(oCrossSell);
                }
                if(lCrossSell.isEmpty()){
                    oResponse.isCrosssellNULL = true;
                }
                else{
                    oResponse.isCrosssellNULL = false;
                    oResponse.CrossSellResponse = lCrossSell;
                }
                
                for(Integer Rating : mUpsellProducts.keySet()){
                    SBR_3_0_CustomerMaturityModelWrapper.products oProduct = mUpsellProducts.get(Rating);
                    SBR_3_0_CustomerMaturityModelController.UpSellResponse oUpSell = new SBR_3_0_CustomerMaturityModelController.UpSellResponse();
                    if(oProduct.catClass != ''){
                        oUpSell.CatClass = oProduct.catClass;
                    }
                    if(oProduct.catClassDescription != ''){
                        oUpSell.Description = oProduct.catClassDescription;
                    }
                    if(oProduct.productModelVersion != ''){
                        oUpSell.productModelVersion = oProduct.productModelVersion;
                    }
                    if(oProduct.productCategoryDesc != ''){
                        oUpSell.productCategoryDesc = oProduct.productCategoryDesc;
                    }
                    String Name = oProduct.catClass+'_'+oAccount.RM_Account_Number_Display__c+'_'+oUser.RepID__c;
                    if(mUpAndCrossSellNamesFromDB.containsKey(Name)){
                        Product_Recommendation_Feedback__c oProductRecFeedback = mUpAndCrossSellNamesFromDB.get(Name);
                        if(oProductRecFeedback.Feedback_Type__c == 'good'){
                            oUpSell.likeStatus = 'like';
                        }
                        if(oProductRecFeedback.Feedback_Type__c == 'bad'){ 
                            oUpSell.dislikeStatus = 'dislike';
                        }
                    }
                    lUpSell.add(oUpSell);
                }
                if(lUpSell.isEmpty()){
                    oResponse.isUpsellNULL = true;
                }
                else{
                    oResponse.isUpsellNULL = false;
                    oResponse.UpSellResponse = lUpSell;
                }
                return oResponse; 
            }
            else{
                throw new AuraHandledException(oResponse+'::'+mLabels.get('There_are_no_current_Lines_of_Business').Label_Value__c);
            }
        } 
        else{
        	throw new AuraHandledException(oResponse+'::'+mLabels.get('There_are_no_current_Lines_of_Business').Label_Value__c);
        }
    }
    @AuraEnabled
    public static Boolean updateRecommendations(list<String> Recommendations,
                                                String AdditionalComments,
                                                Account accountRec
                                               ){
        Map<String,Product_Recommendation_Feedback__c> mUpAndCrossSellNamesFromDB = new Map<String,Product_Recommendation_Feedback__c>();                                           
        User oUser = 	[
            				SELECT
            				Id,
            				Rep_Type__c,
            				RepID__c 
            				FROM
            				User
            				WHERE
            				Id =: UserInfo.getUserId()
        				];    
        Map<String,SBR_3_0_Customer_Maturity_Model_Labels__mdt> mLabels = SBR_3_0_Customer_Maturity_Model_Labels__mdt.getAll();
        System.debug('mLabels'+mLabels);                                           
        list<Product_Recommendation_Feedback__c> lFeedback = new list<Product_Recommendation_Feedback__c>();
        list<String> lNamesToCheckInDB = new list<String>();    
        for(String Rec : Recommendations){
            Map<String,Object> oRes = (Map<String,Object>) JSON.deserializeUntyped(Rec);
            String Name = String.valueOf(oRes.get('name'))+'_'+accountRec.RM_Account_Number_Display__c+'_'+oUser.RepID__c;
            lNamesToCheckInDB.add(Name);
        }
        list<Product_Recommendation_Feedback__c> lProductRecFeedback = 	[
                                                                            SELECT 
                                                                            Id,
                                                                            Name,
                                                                            Cat_Class_Key__c,
                                                                            Model_Version__c,
                                                                            Feedback_Type__c,
                                                                            Rep_ID__c,
            																Account_number__c ,
            																Salesforce_Feedback_ID__c,
            																Additional_comments__c,
            																Company_Code__c
                                                                            FROM 
                                                                            Product_Recommendation_Feedback__c
                                                                            WHERE 
                                                                            Name IN: lNamesToCheckInDB
                                                                        ];
       	for(Product_Recommendation_Feedback__c oProductRecFeedback : lProductRecFeedback){
        	mUpAndCrossSellNamesFromDB.put(oProductRecFeedback.Name,oProductRecFeedback);
        }
        for(String Rec : Recommendations){
            Map<String,Object> oRes = (Map<String,Object>) JSON.deserializeUntyped(Rec);
            String FeedbackTypeFromResponse;
            if(String.valueOf(oRes.get('state')) == 'like'){
                FeedbackTypeFromResponse = 'good';
            }
            else{
                FeedbackTypeFromResponse = 'bad';
            }
            String Name = String.valueOf(oRes.get('name'))+'_'+accountRec.RM_Account_Number_Display__c+'_'+oUser.RepID__c;
            Product_Recommendation_Feedback__c oFeedback = new Product_Recommendation_Feedback__c();
            if(mUpAndCrossSellNamesFromDB.containsKey(Name)){
            	oFeedback = mUpAndCrossSellNamesFromDB.get(Name);   
                if(oFeedback.Feedback_Type__c != FeedbackTypeFromResponse){
                    oFeedback.Feedback_Type__c = FeedbackTypeFromResponse;
                    oFeedback.Additional_comments__c = AdditionalComments;
                    lFeedback.add(oFeedback);
                }
            }
            else{
                oFeedback.Cat_Class_Key__c = String.valueOf(oRes.get('name'));
                oFeedback.Feedback_Type__c = FeedbackTypeFromResponse;
                oFeedback.Name = String.valueOf(oRes.get('name'))+'_'+accountRec.RM_Account_Number_Display__c+'_'+oUser.RepID__c;
                oFeedback.Model_Version__c = String.valueOf(oRes.get('version'));
                oFeedback.Description__c = String.valueOf(oRes.get('description'));
                oFeedback.Category__c = String.valueOf(oRes.get('category'));
                oFeedback.Additional_comments__c = AdditionalComments;
                if(oUser.RepID__c == NULL){
                	throw new AuraHandledException(mLabels.get('The_user_has_missing_Rep_Id_Please_cont').Label_Value__c);
                }
                else{
                   	oFeedback.Rep_ID__c = oUser.RepID__c; 
                }
                
                oFeedback.Company_Code__c = Integer.valueOf(accountRec.Company_Code__c);
                oFeedback.Rep_Type__c = oUser.Rep_Type__c;
                oFeedback.Account_number__c = accountRec.RM_Account_Number_Display__c;
                oFeedback.User__c = oUser.id;
                oFeedback.Account__c= accountRec.id;
                Blob oBlob = Crypto.GenerateAESKey(128);
                String oConveredCode = EncodingUtil.ConvertTohex(oBlob);
                oFeedback.Salesforce_Feedback_ID__c = oConveredCode;
                lFeedback.add(oFeedback);
            }
        }
        if(!lFeedback.isEmpty()){
        	String ResponseJson = SBR_3_0_GenerateFeedbackJson.processRecords(lFeedback) ; 
            System.debug('ResponseJson'+ResponseJson);
         	String Response = SBR_3_0_CustomerMaturityModelCallout.FeedbackCalloutGet(ResponseJson);
         	UPSERT lFeedback;
            return true;
        }  
        else{
        	throw new AuraHandledException(mLabels.get('No_Feedback_Provided').Label_Value__c);
     	}
     }
    public class MaturityModelResponse{
        @AuraEnabled
		public String AccountNumber;
        @AuraEnabled
		public String AccountName;
        @AuraEnabled
		public Boolean isOfficeAccount;
        @AuraEnabled
		public Account accountRec;
        @AuraEnabled
		public String CurrentLOBUsed;
        @AuraEnabled
		public String NoOfProductsRented;
        @AuraEnabled
		public String CurrentTTMSpent;
        @AuraEnabled
		public String PotentialLOBUsed;
        @AuraEnabled
		public CurrentLOB[] CurrentLOB;
        @AuraEnabled
		public PotentialLOB[] PotentialLOB;
        @AuraEnabled
		public Boolean isPotentialLOBNULL;
        @AuraEnabled
		public Boolean isCurrentLOBNULL;
        @AuraEnabled
		public UpSellResponse[] UpSellResponse;
        @AuraEnabled
		public CrossSellResponse[] CrossSellResponse;
        @AuraEnabled
		public Boolean isUpsellNULL;
        @AuraEnabled
		public Boolean isCrosssellNULL;
    }
    public class CurrentLOB{
        @AuraEnabled
		public String Name;
        @AuraEnabled
		public String TTMSpent;
        @AuraEnabled
		public String PercentageOfTotal;
        @AuraEnabled
		public String NoOfProductsRentedOut;
    }
    public class PotentialLOB{
        @AuraEnabled
		public String Name;
    }
    public class UpSellResponse{
        @AuraEnabled
		public String CatClass;
        @AuraEnabled
		public String Description;
        @AuraEnabled
		public String Category;
        @AuraEnabled
		public String productModelVersion;
        @AuraEnabled
		public String productCategoryDesc;
        @AuraEnabled
		public String likeStatus;
        @AuraEnabled
		public String dislikeStatus;
    }
    public class CrossSellResponse{
        @AuraEnabled
		public String CatClass;
        @AuraEnabled
		public String Description;
        @AuraEnabled
		public String Category;
        @AuraEnabled
		public String productModelVersion;
        @AuraEnabled
		public String productCategoryDesc;
        @AuraEnabled
		public String likeStatus;
        @AuraEnabled
		public String dislikeStatus;
    }
}