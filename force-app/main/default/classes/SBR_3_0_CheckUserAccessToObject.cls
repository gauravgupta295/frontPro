public without sharing class SBR_3_0_CheckUserAccessToObject {

    @InvocableMethod(
        label='Check edit access to record'
        description='Returns true if user has edit access to the record'
      )
      public static List<CheckUserAccessResponse> checkAccess(List<CheckUserAccessRequest> requests) {
        List<CheckUserAccessResponse> responses = new List<CheckUserAccessResponse>();
        CheckUserAccessResponse response = new CheckUserAccessResponse();
        if (requests.Size() > 0){

            List<UserRecordAccess> uras = SBR_3_0_UserRecordAccessDA.getRecordAccessByUserAndObject(requests[0].userId, requests[0].recordId);

            if (uras.Size() > 0) {
                response.result = uras[0].HasEditAccess;
            }
        }

        responses.add(response);

        return responses;
      }

    public class CheckUserAccessRequest {
        @InvocableVariable(label='Record Id' required=true)
        public string recordId;
  
        @InvocableVariable(label='User Id' required=true)
        public string userId;
      }
  
      public class CheckUserAccessResponse {
          @InvocableVariable(label='Access Result' required=true)
          public Boolean result;
        }
    
}