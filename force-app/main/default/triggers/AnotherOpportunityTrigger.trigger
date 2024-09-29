/*
AnotherOpportunityTrigger Overview

All previous Opportunity Triggers have been combined into this Trigger and refactored to work in conjunction with 
    Trigger.Handler.cls and OpportunityTriggerHandler.cls
to handle all Opportunity Trigger needs for this org.
*/

trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, 
                                                    after update, before delete, after delete, 
                                                    after undelete) {
    
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
    handler.run();    
}