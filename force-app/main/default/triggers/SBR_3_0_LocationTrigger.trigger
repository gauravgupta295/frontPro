trigger SBR_3_0_LocationTrigger on Location (before insert, before update, after insert, after update) {
    System.debug('Entered here');
      new SBR_3_0_LocationTriggerHandler().run();
      
}