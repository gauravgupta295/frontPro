/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_SendgridService
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To communicate with Sendgrid Integration API 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Davinder Singh        2022-12-07             Initial version    
*********************************************************************************************************************/
public with sharing class SBR_3_0_API_SendgridService {
  private static final String APINAME = 'Sendgrid_Account_API';
  private static final String TEMPLATE_ACTIVITY_TYPE = Label.Sendgrid_ActivityType_For_CCA;
  private static List<String> toAndContactEmailAddresses = new List<String>();
  private static List<String> bccEmailAddresses = new List<String>();

  public static String sendgridCallout(
    String sendgridRequestJson,
    String companyId
  ) {
    String returnPayload = '';
    System.debug('sendgridRequestJson-->' + sendgridRequestJson);
    returnPayload = SBR_3_0_Generic_Callout.callEndpoint(
      sendgridRequestJson,
      APINAME,
      companyId
    );
    return returnPayload;
  }

  @AuraEnabled
  public static void invokeSendgridAPI(String emailStr) {
    try {
      System.debug(emailStr);
      SBR_3_0_SendgridWrapper.EmailWrapper emailDetails = (SBR_3_0_SendgridWrapper.EmailWrapper) JSON.deserialize(
        emailStr,
        SBR_3_0_SendgridWrapper.EmailWrapper.class
      );
      System.debug(emailDetails);
      // Check for no records
      if (emailDetails.toAddress.size() > 0) {
        toAndContactEmailAddresses.addAll(emailDetails.toAddress);
      }

      if (emailDetails.bcc != null && emailDetails.bcc.size() > 0) {
        bccEmailAddresses.addAll(emailDetails.bcc);
      }

      String toAndContactStr = string.join(toAndContactEmailAddresses, ',');
      String bccStr = string.join(bccEmailAddresses, ',');

      EmailMessage emMessage = new EmailMessage(
        Subject = emailDetails.subject,
        HtmlBody = emailDetails.body,
        FromAddress = emailDetails.frm,
        FromName = emailDetails.frmName,
        Sendgrid_Template_Id__c = TEMPLATE_ACTIVITY_TYPE,
        ToAddress = toAndContactStr,
        BccAddress = bccStr,
        Status = '3',
        RelatedToId = emailDetails.recId
      );

      //prepare wrapper
      SBR_3_0_SendgridWrapper requestWrapper = generateWrapper(emMessage);
      System.debug(requestWrapper);
      String body = JSON.serialize(requestWrapper);
      body = body.replace('override_x', 'override');
      body = body.replace('null', '\"\"');

      body = body.replace('toEmailAddresses', 'Tos');
      body = body.replace('emailDetails', 'EmailDetails');
      body = body.replace('communicationData', 'CommunicationData');
      body = body.replace('subject', 'Subject');
      body = body.replace('activityType', 'ActivityType');

      System.debug('body ' + body);
      String resPayload = sendgridCallout(body, '1');
      System.debug('resPayload -> ' + resPayload);
      Object response = JSON.deserializeUntyped(resPayload);
      System.debug('response -> ' + response);

      //if success , create Email Message
      if (response instanceof Map<String, Object>) {
        Map<String, Object> resultMap = (Map<String, Object>) response;
        if (resultMap.get('data') instanceof Map<String, Object>) {
          Map<String, Object> data = (Map<String, Object>) resultMap.get(
            'data'
          );

          if (data.get('status') instanceof String) {
            String status = (String) data.get('status');

            System.debug('status -> ' + status);
            insert emMessage;
          } else {
            // handle error
            throw new SendgridException(
              'Email could not be sent, please try later'
            );
          }
        } else {
          // handle error
          throw new SendgridException(
            'Email could not be sent, please try later'
          );
        }
      } else {
        // handle error
        throw new SendgridException(
          'Email could not be sent, please try later'
        );
      }
    } catch (Exception ex) {
      System.debug('exception -> ');
      System.debug(ex.getstackTraceString());
      System.debug(ex.getMessage());
      throw new SendgridException(ex.getMessage());
    }
  }

  private static SBR_3_0_SendgridWrapper generateWrapper(
    EmailMessage singleMessage
  ) {
    SBR_3_0_SendgridWrapper sendgridWrapper = new SBR_3_0_SendgridWrapper();
    Account acc = SBR_3_0_AccountDA.getAccount(singleMessage.RelatedToId);
    List<String> toEmailAddressesList = singleMessage.ToAddress.split(',');
    sendgridWrapper.emaildetails = new SBR_3_0_SendgridWrapper.EmailDetails();
    sendgridWrapper.emaildetails.subject = singleMessage.Subject;
    sendgridWrapper.emaildetails.toEmailAddresses = toEmailAddressesList;

    sendgridWrapper.activityType = Integer.ValueOf(TEMPLATE_ACTIVITY_TYPE);
    // Current User Record - Sales Represenative who will send credit application email
    User userRecord = [
      SELECT Id, Name, email, phone
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];

    sendgridWrapper.communicationData = new SBR_3_0_SendgridWrapper.communicationData();
    sendgridWrapper.communicationData.ccaUrl = acc.Credit_Application_Link__c;
    if (
      SBR_3_0_CustomLookupController.getAppName() == 'RAE Frontline' &&
      acc.RecordType.Name == 'Non-Credit'
    ) {
      //FRONT-8745 - Start - sending companycode parameter in the credit application link URL
      String companyCodeParam = String.isNotBlank(acc.Company_Code__c)
        ? '?c=' + acc.Company_Code__c
        : '';
      //FRONT-8745 - End
      Credit_Application_Link_Url__c mc = Credit_Application_Link_Url__c.getOrgDefaults();
      sendgridWrapper.communicationData.ccaUrl =
        mc.Base_Url__c + companyCodeParam;
    }

    sendgridWrapper.communicationData.lastName = '';
    sendgridWrapper.communicationData.fullName = '';
    sendgridWrapper.communicationData.accountNumber = acc.Name;
    sendgridWrapper.communicationData.creditManagerPhone = userRecord.phone !=
      null
      ? userRecord.phone
      : '';
    sendgridWrapper.communicationData.creditManagerEmail = userRecord.email !=
      null
      ? userRecord.email
      : '';
    sendgridWrapper.communicationData.creditManagerName = userRecord.name !=
      null
      ? userRecord.name
      : '';
    sendgridWrapper.communicationData.personalizedText = singleMessage.HtmlBody;

    System.debug('sendgridWrapper-->' + sendgridWrapper);

    return sendgridWrapper;
  }

  public class SendgridException extends Exception {
  }
}