/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-16-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class SetPasswordBatch implements Database.Batchable<sObject>{
  String prefix;
  String password;

  public SetPasswordBatch(String prefix, String password){
    this.prefix = prefix;
    this.password = password;
  }

  public Database.QueryLocator start(Database.BatchableContext jobId){
    String query = 'select id from User '+
      'where lastname like \''+this.prefix+'%\' limit 150';
    return Database.getQueryLocator(query); 

  }

    
  public Void execute(Database.BatchableContext jobId, List<User> users){
    try {
      for(User user : users) {        
        System.setPassword(user.id, this.password);
      }     
    } catch(Exception e) {
      System.debug(e);
    }
  }

  public Void finish(Database.BatchableContext jobId){
  }
}