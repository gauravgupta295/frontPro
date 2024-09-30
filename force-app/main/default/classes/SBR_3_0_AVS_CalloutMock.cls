@isTest
public class SBR_3_0_AVS_CalloutMock implements HttpCalloutMock {
  public Integer testCondition { get; set; }

  public SBR_3_0_AVS_CalloutMock() {
    this(0);
  }

  public SBR_3_0_AVS_CalloutMock(Integer i) {
    testCondition = i;
  }

  public HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    System.debug('Test Condition: ' + testCondition);
    res.setHeader('Content-Type', 'application/json');
    if (req.getEndpoint().endsWithIgnoreCase('token')){
      res.setBody('{"access_token":"test"}');
    }
    else {

      if (testCondition == 1) {
        res.setBody(
          '{\"data\":{\"addressInfo\":{\"result\":\"1\",\"addMessage\":\"\",\"lat\":38.897663,\"long\":-77.036573},\"addrList\":[{\"address1\":\"1600PENNSYLVANIAAVENW\",\"address2\":\"\",\"city\":\"WASHINGTON\",\"state\":\"DC\",\"zip\":\"205000005\"}]}}'
        );
      }
      else if (testCondition == 2) {
          
          res.setBody('');
      }
      else if (testCondition == 3) {
        res.setBody(
          '{\"error\":{\"message\":{\"result\":\"1\",\"addMessage\":\"\",\"lat\":38.897663,\"long\":-77.036573},\"addrList\":[{\"address1\":\"1600PENNSYLVANIAAVENW\",\"address2\":\"\",\"city\":\"WASHINGTON\",\"state\":\"DC\",\"zip\":\"205000005\"}]}}'
        );
      }
     else if (testCondition == 4) {
        res.setBody(
          '{\"data\":{\"addressInfo?\":{\"result\":\"1\",\"addMessage\":\"\",\"lat\":38.897663,\"long\":-77.036573},\"addrList\":[{\"address1\":\"1600PENNSYLVANIAAVENW\",\"address2\":\"\",\"city\":\"WASHINGTON\",\"state\":\"DC\",\"zip\":\"205000005\"}]}}'
        );
      }
      else if (testCondition == 5) {
        res.setBody(
          '{\"data\":{\"addressInfo\":{\"result?\":\"1\",\"addMessage\":\"\",\"lat\":38.897663,\"long\":-77.036573},\"addrList\":[{\"address1\":\"1600PENNSYLVANIAAVENW\",\"address2\":\"\",\"city\":\"WASHINGTON\",\"state\":\"DC\",\"zip\":\"205000005\"}]}}'
        );
      } 
      else if (testCondition == 6) {
        res.setBody(
          '{\"data\":{\"addressInfo\":{\"result\":\"0\",\"message\":\"\",\"latitude\":38.897663,\"longitude\":-77.036573},\"addrList\":[{\"address1\":\"1600PENNSYLVANIAAVENW\",\"address2\":\"\",\"city\":\"WASHINGTON\",\"state\":\"DC\",\"zip\":\"205000005\"}]}}'
          );
      }
      else if(testCondition == 7) {
        res.setBody(
          '{\"data\":{\"addressInfo\":{\"result\":\"1\",\"message\":\"\",\"latitude\":38.897663,\"longitude\":-77.036573},\"addrList\":[{\"address1\":\"1600PENNSYLVANIAAVENW\",\"address2\":\"\",\"city\":\"WASHINGTON\",\"state\":\"DC\",\"zip\":\"205000005\"}]}}'

          );

      }
    }
    res.setStatusCode(200);
    return res;
  }
}