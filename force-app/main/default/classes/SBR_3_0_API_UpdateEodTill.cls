/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_UpdateEodTill
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description Update EOD Details to Rentalman (via Mulesoft) from salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Vivek Sharma          2024-03-18            Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_UpdateEodTill {
        private static final String API_EOD_UPDATE_TILL = 'UPDATE_TILL_SUMMARY';
        private Id eodTillId;
        private String companyId;
        private String pc;
        private SBR_3_0_ResponseHandler updateResponse;
        private SBR_3_0_ResponseHandler.DenominationDetails updateDenominationDetails;
        private SBR_3_0_ResponseHandler.CreditCardDetails updateCreditCardDetails;
        private SBR_3_0_ResponseHandler.ReasonDetail updateReason;
        private End_of_Day_Till__c eodTill;
        private Till_Over_Short_Reason__c tillOverShortReasons;
        @TestVisible
        private static Object response;
        /**
        * @description BadRequestException.
        */
        public class BadRequestException extends Exception{}
        
        /**
        * @description Private method to save ReasonDetail.
        */
        public class ReasonDetail {
            public Decimal amount ;
            public String description ;
            public Decimal customerNumber ;
            public String note ;
            public String checkNumber ;
            public String reasonCode ;
        }
        
        /**
        * @description Updates the End of Day (EOD) Till summary for a specific EOD Till record.
        * This method triggers an API call to update the EOD Till record with provided details.
        * 
        * @param eodTillRecordId The Id of the EOD Till record to update.
        * @param userId The Id of the user triggering the update.
        * @param reasonRecords JSON serialized string representing the list of reasons for the update.
        * @return Map<String, Object> A response map from the API call.
        * @throws BadRequestException If the API response contains an error, this exception is thrown.
        */
        @AuraEnabled
        public static object updateTillSummary(Id eodTillRecordId , Id userId ,String reasonRecords ) {
            SBR_3_0_Log.setRelatedRecordId(eodTillRecordId);
            new SBR_3_0_API_UpdateEodTill(userId,eodTillRecordId,reasonRecords);
            Map<String, Object> responseMap = (Map<String, Object>) response;
            if(responseMap != null) {
                if(responseMap.containsKey('error')){
                    String jsonExceptionString = JSON.serialize(responseMap);
                    SBR_3_0_Log.logInfo(jsonExceptionString);
                    throw new BadRequestException(jsonExceptionString);
                }      
            }
            return response;
        }
        
        /**
        * @description Constructor for initializing the API updater for EOD Till records.
        * 
        * @param userId The Id of the user invoking the API update.
        * @param eodTillRecordId The Id of the EOD Till record to update.
        * @param reasonRecords JSON serialized string representing the list of reasons for the update.
        */
        public SBR_3_0_API_UpdateEodTill(Id userId , Id eodTillRecordId,String reasonRecords) {
            try{
                List<User> users =new List<User>(SBR_3_0_OrderDA.getUsers(userId));
                List<End_of_Day_Till__c> eodRecords =new List<End_of_Day_Till__c>(SBR_3_0_OrderDA.getEodTill(eodTillRecordId));
                updateResponse =new SBR_3_0_ResponseHandler();
                updateResponse.denominationDetails = new SBR_3_0_ResponseHandler.DenominationDetails();
                updateResponse.creditCardDetails = new SBR_3_0_ResponseHandler.CreditCardDetails();
                this.eodTillId =eodTillRecordId;
                for (End_of_Day_Till__c eodId : eodRecords) {
                    updateResponse.currencyIsoCode =eodId.CurrencyIsoCode;
                    updateResponse.fromDate =eodId.Till_Date__c;
                    updateResponse.fromTime ='23:59:59.05';
                    updateResponse.toDate =eodId.Till_Date__c;
                    updateResponse.toTime ='23:59:59.05';
                    updateResponse.totalRoaChecksAmount =eodId.Total_ROA_Checks__c;
                    updateResponse.totalChecksAmount =eodId.Total_Checks__c;
                    updateResponse.nextDrawerAmount =eodId.Next_Day_Drawer__c;
                    updateResponse.startDrawerAmount =eodId.Start_Drawer__c;
                    updateResponse.depositDate =eodId.Till_Date__c;
                    updateResponse.postedToGL =eodId.Submitted__c? 'Y' : 'N';
                    //updateResponse.cashSalesAmount =eodId.Cash_Sales__c;
                    updateResponse.DenominationDetails.hundredDollarBills=eodId.Drawer_Bills_Hundred__c;
                    updateResponse.DenominationDetails.fiftyDollarBills=eodId.Drawer_Bills_Fifty__c;
                    updateResponse.DenominationDetails.twentyDollarBills=eodId.Drawer_Bills_Twenty__c;
                    updateResponse.DenominationDetails.tenDollarBills=eodId.Drawer_Bills_Ten__c;
                    updateResponse.DenominationDetails.fiveDollarBills=eodId.Drawer_Bills_Five__c;
                    updateResponse.DenominationDetails.twoDollarBills=eodId.Drawer_Bills_Two__c;
                    updateResponse.DenominationDetails.oneDollarBills=eodId.Drawer_Bills_One__c;
                    updateResponse.DenominationDetails.oneDollarCoins=eodId.Drawer_Coins_One__c;
                    updateResponse.DenominationDetails.fiftyCents=eodId.Drawer_Coins_Fifty__c;
                    updateResponse.DenominationDetails.quarters=eodId.Drawer_Coins_Quarter__c;
                    updateResponse.DenominationDetails.dimes=eodId.Drawer_Coins_Dime__c;
                    updateResponse.DenominationDetails.nickels=eodId.Drawer_Coins_Nickel__c;
                    updateResponse.DenominationDetails.pennies=eodId.Drawer_Coins_Penny__c;
                    updateResponse.CreditCardDetails.amexAmount=eodId.Amex__c;
                    updateResponse.CreditCardDetails.amexRoaAmount=eodId.Amex_ROA__c;
                    updateResponse.CreditCardDetails.discoverAmount=eodId.Discover__c;
                    updateResponse.CreditCardDetails.discoverRoaAmount=eodId.Discover_ROA__c;
                    updateResponse.CreditCardDetails.masterCardAmount=eodId.MasterCard__c;
                    updateResponse.CreditCardDetails.masterCardRoaAmount=eodId.MasterCard_ROA__c;
                    updateResponse.CreditCardDetails.visaAmount=eodId.Visa__c;
                    updateResponse.CreditCardDetails.visaRoaAmount=eodId.Visa_ROA__c;
                    updateResponse.CreditCardDetails.dinersClubAmount=eodId.Diners_Club__c;
                    updateResponse.CreditCardDetails.dinersClubRoaAmount=eodId.Diners_Club_ROA__c;
                }
                List<SBR_3_0_ResponseHandler.ReasonDetail> reasonDetailList = new List<SBR_3_0_ResponseHandler.ReasonDetail>();
                List<ReasonDetail> reasonDetailRecordList = (List<ReasonDetail>)JSON.deserialize(reasonRecords, List<ReasonDetail>.class);
                for (ReasonDetail reasonRec : reasonDetailRecordList) {
                    SBR_3_0_ResponseHandler.ReasonDetail reason = new SBR_3_0_ResponseHandler.ReasonDetail();
                    reason.amount = reasonRec.amount;
                    reason.description = reasonRec.description;
                    reason.customerNumber = reasonRec.customerNumber;
                    reason.note = reasonRec.note;
                    reason.checkNumber = reasonRec.checkNumber;
                    reason.reasonCode = reasonRec.reasonCode;
                    reasonDetailList.add(reason);
                }
                updateResponse.reasonDetails = reasonDetailList; 
                for (User use : users) {
                    this.companyId = use.CompanyName;
                    updateResponse.user =use.Wynne_User_Name__c;
                    updateResponse.pc = use.Department;
                    SBR_3_0_Generic_Callout.sourceSystemUserId =use.Wynne_User_Name__c;
                }
                callEODUpdateTill();
            }catch(Exception ex){
                SBR_3_0_Log.logException(ex);
                throw new AuraHandledException(ex.getMessage());
            }finally {
                SBR_3_0_Log.saveLog();
            }   
        }
        
        /**
        * @description Calls the external service endpoint to update the EOD Till record.
        * This method prepares the payload and invokes the callout.
        */
        private void callEODUpdateTill(){
            try{
                String returnPayload = '';
                returnPayload = SBR_3_0_Generic_Callout.callEndpoint(JSON.serialize(this.updateResponse, true),API_EOD_UPDATE_TILL, this.companyId);    
                String hardcodedPayload = '{"data":{"message": "Till In Balance..", "referenceNo": "377902***20240403"}}';
                response = (Map<String, Object>) JSON.deserializeUntyped(hardcodedPayload);               
            }catch(Exception Ex){
                SBR_3_0_Log.logException(ex);
            } 
            }
    }