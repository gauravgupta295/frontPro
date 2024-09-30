public with sharing class SBR_3_0_Generic_Callout {
 
  public static String PaymentMethod = '';
  public static String sourceTransactionId = '';
  public static string sourceSystemUserId ='';

  public class SBR_3_0_CalloutException extends Exception {
  }
  public static String callEndpoint(
    String jsonRequest,
    String metadataApiName,
    String companyId
  ) {
    String returnPayload = '';

    SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(metadataApiName);
    if (!httpCallout.apiMap.get(metadataApiName).Is_JWT_Enabled__c) {
      Credential__c creds = httpCallout.credsMap.get(
        httpCallout.apiMap.get(metadataApiName).Credential_Name__c
      );
      httpCallout.setHeader('client_secret', creds.Secret__c);
      httpCallout.setHeader('client_id', creds.Key_Id__c);
      System.debug('creds-->' + creds);
    }
    if (companyId != '') {
      httpCallout.setHeader('companyId', companyId);
    }
    system.debug('PaymentMethod'+PaymentMethod);
    if (metadataApiName == 'UPDATE_TILL_SUMMARY'){
      httpCallout.setHeader('sourceSystemUserId', sourceSystemUserId);
      httpCallout.setHeader('sourceSystemName', 'Salesforce');
    }
    if (PaymentMethod == 'Amex' || PaymentMethod == 'Visa' || PaymentMethod == 'Mastercard' || PaymentMethod == 'Discover'
        || PaymentMethod == 'Diners Club' || PaymentMethod == 'Interac Debit') {
      
              httpCallout.setHeader('method', 'async');
              httpCallout.setHeader('sourceSystemUserId', sourceSystemUserId);
              httpCallout.setHeader('sourceSystemName', 'Salesforce');
              httpCallout.setHeader('sourceTransactionId',sourceTransactionId);
        }else{
              httpCallout.setHeader('sourceSystemUserId', sourceSystemUserId);
              httpCallout.setHeader('sourceSystemName', 'Salesforce');
              httpCallout.setHeader('sourceTransactionId',sourceTransactionId);
        }
    
    httpCallout.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    System.debug('jsonRequest--> ' + jsonRequest);
    System.debug('httpCallout--> ' + httpCallout);

    httpCallout.setRequestBody(jsonRequest);
    HttpResponse res = httpCallout.sendRequest();
    returnPayload = res.getBody();
    system.debug('returnPayload --> '+returnPayload);
    // Added to test logging framework
    SBR_3_0_Log.logAPIDetails(jsonRequest, returnPayload, metadataApiName);
    return returnPayload;
  }
  static List<String> pathParams;
  public static void setURLParams(List<String> pathParamsList) {
    pathParams = pathParamsList;
  }

  static Map<String, String> headers;
  public static void setHeaders(Map<String, String> headerList) {
    headers = headerList;
  }
  public static String callEndpointEod(
    String metadataApiName,
    String companyId,
    String pc
  ) {
    system.debug('pc valu'+ pc);
        system.debug('this.companyId'+companyId);
    String returnPayload = '';

    SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(metadataApiName);
    httpCallout.setHeader('pc', pc);
    if (companyId != '') {
      httpCallout.setHeader('companyId', companyId);
    }
    if (!httpCallout.apiMap.get(metadataApiName).Is_JWT_Enabled__c) {
      Credential__c creds = httpCallout.credsMap.get(
        httpCallout.apiMap.get(metadataApiName).Credential_Name__c
      );
      httpCallout.setHeader('client_secret', creds.Secret__c);
      httpCallout.setHeader('client_id', creds.Key_Id__c);
      
      System.debug('pc/id-->' + pc);
      System.debug('creds-->' + creds);
    }
 
    
    httpCallout.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    System.debug('httpCallout-->' + httpCallout);

    HttpResponse res = httpCallout.sendRequest();
    returnPayload = res.getBody();
    system.debug('returnPayload --> '+returnPayload);
    // Added to test logging framework
    return returnPayload;
  }

  public static HttpResponse callEndpoint(
    String jsonRequest,
    String metadataApiName
  ) {
    String returnPayload = '';
    system.debug('meta-' + metadataApiName + '' + jsonRequest);
    SBR_3_0_HttpCallout httpCallout = new SBR_3_0_HttpCallout(metadataApiName);
    if (pathParams != null && pathParams.size() > 0) {
      httpCallout.setPathParams(pathParams);
    }
    if (!httpCallout.apiMap.get(metadataApiName).Is_JWT_Enabled__c) {
      Credential__c creds = httpCallout.credsMap.get(
        httpCallout.apiMap.get(metadataApiName).Credential_Name__c
      );
      httpCallout.setHeader('client_secret', creds.Secret__c);
      httpCallout.setHeader('client_id', creds.Key_Id__c);
      System.debug('creds-->' + creds);
    }
    if (PaymentMethod == 'Amex' || PaymentMethod == 'Visa' || PaymentMethod == 'Mastercard' || PaymentMethod == 'Discover'
        || PaymentMethod == 'Diners Club' || PaymentMethod == 'Interac Debit') {
      
              httpCallout.setHeader('method', 'async');
              httpCallout.setHeader('sourceSystemUserId', sourceSystemUserId);
              httpCallout.setHeader('sourceSystemName', 'Salesforce');
              httpCallout.setHeader('sourceTransactionId',sourceTransactionId);
        }else{
              httpCallout.setHeader('sourceSystemUserId', sourceSystemUserId);
              httpCallout.setHeader('sourceSystemName', 'Salesforce');
              httpCallout.setHeader('sourceTransactionId',sourceTransactionId);
        }
    if (headers != null) {
      for (string key : headers.keyset()) {
        httpCallout.setHeader(key, headers.get(key));
      }
    }

    httpCallout.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    System.debug('jsonRequest-->' + jsonRequest);
    System.debug('httpCallout-->' + httpCallout);
    //system.debug('x-correlation-id'+httpCallout.getHeader('x-correlation-id'));
    httpCallout.setRequestBody(jsonRequest);
    HttpResponse res = httpCallout.sendRequest();
    // returnPayload = res.getBody();
    return res;
  }
}