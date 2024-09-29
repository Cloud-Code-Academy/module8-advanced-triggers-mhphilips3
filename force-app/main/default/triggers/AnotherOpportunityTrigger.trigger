/*
AnotherOpportunityTrigger Overview

This trigger was initially created for handling various events on the Opportunity object. It was developed by a prior developer and has since been noted to cause some issues in our org.

IMPORTANT:
- This trigger does not adhere to Salesforce best practices.
- It is essential to review, understand, and refactor this trigger to ensure maintainability, performance, and prevent any inadvertent issues.

ISSUES:
Avoid nested for loop - 1 instance
Avoid DML inside for loop - 1 instance
Bulkify Your Code - 1 instance
Avoid SOQL Query inside for loop - 2 instances
Stop recursion - 1 instance

RESOURCES: 
https://www.salesforceben.com/12-salesforce-apex-best-practices/
https://developer.salesforce.com/blogs/developer-relations/2015/01/apex-best-practices-15-apex-commandments
*/
trigger AnotherOpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
    handler.run();
    
    
    // if (Trigger.isBefore){
    //     if (Trigger.isInsert){
    //         // 1. Set default Type for new Opportunities     MOVED TO OPPTRIGGHANDLER
    //         for (Opportunity opp : Trigger.new){
    //             if (opp.Type == null){
    //                 opp.Type = 'New Customer';
    //             }
    //         }        
    //     } else if (Trigger.isDelete){                        MODED TO OPPTRIGGHANDLER
    //         // 2. Prevent deletion of closed Opportunities
    //         for (Opportunity oldOpp : Trigger.old){
    //             if (oldOpp.IsClosed){
    //                 oldOpp.addError('Cannot delete closed opportunity');
    //             }
    //         }
    //     } else if (Trigger.isUpdate){
    //         // 4. Append Stage changes in Opportunity Description        MOVED TO OPPTRIGGHANDLER
    //         for (Opportunity opp : Trigger.new){                
    //             if (opp.StageName != null && opp.StageName != Trigger.oldMap.get(opp.Id).StageName){
    //                 opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
    //             }                                
    //         }        
    //     }
    // }

    // if (Trigger.isAfter){
    //     if (Trigger.isInsert){
    //         // 3. Create a new Task for newly inserted Opportunities  MOVED TO OPPTRIGGHANDLER
    //         List<Task> taskList = new List<Task>();
    //         for (Opportunity opp : Trigger.new){
    //             Task tsk = new Task();
    //             tsk.Subject = 'Call Primary Contact';
    //             tsk.WhatId = opp.Id;
    //             tsk.WhoId = opp.Primary_Contact__c;
    //             tsk.OwnerId = opp.OwnerId;
    //             tsk.ActivityDate = Date.today().addDays(3);
    //             taskList.add(tsk);
    //         }
    //         insert taskList;
    //     } 
    //     // 5. Send email notifications when an Opportunity is deleted 
    //     else if (Trigger.isDelete){
    //         notifyOwnersOpportunityDeleted(Trigger.old);
    //     } 
    //     // 6. Assign the primary contact to undeleted Opportunities
    //     else if (Trigger.isUndelete){
    //         assignPrimaryContact(Trigger.newMap);
    //     }
    // }

    // /*
    // notifyOwnersOpportunityDeleted:
    // - Sends an email notification to the owner of the Opportunity when it gets deleted.
    // - Uses Salesforce's Messaging.SingleEmailMessage to send the email.
    // */
    // private static void notifyOwnersOpportunityDeleted(List<Opportunity> opps) {
    //     List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    //     List<Opportunity> oppsWithOwnersList = new List<Opportunity>([SELECT Id, OwnerId, Name,
    //                                                                 Owner.Email FROM Opportunity WHERE Id IN :opps]);
    //     for (Opportunity opp : oppsWithOwnersList){
    //         Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //         List<String> setToAddresses = new List<String>{opp.Owner.Email};
    //         mail.setToAddresses(setToAddresses);
    //         mail.setSubject('Opportunity Deleted : ' + opp.Name);
    //         mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
    //         mails.add(mail);
    //     }        
        
    //     try {
    //         Messaging.sendEmail(mails);
    //     } catch (Exception e){
    //         System.debug('Exception: ' + e.getMessage());
    //     }
    // }

    // /*
    // assignPrimaryContact:
    // - Assigns a primary contact with the title of 'VP Sales' to undeleted Opportunities.
    // - Only updates the Opportunities that don't already have a primary contact.
    // */
    // private static void assignPrimaryContact(Map<Id,Opportunity> oppNewMap) {        
    //     Set <Id> accIdSet = new Set<Id>();
    //     for (Opportunity opp : oppNewMap.values()){
    //         accIdSet.add(opp.AccountId);
    //     }
    //     Map<Id, Account> acctMap = new Map<Id, Account> ([SELECT Id, Name,
    //                                                     (SELECT Id, AccountId FROM Contacts WHERE Title ='VP Sales')
    //                                                     FROM Account WHERE Id IN :accIdSet]);
    //     List<Opportunity> oppList = new List<Opportunity>();
    //     for (Opportunity opp : oppNewMap.values()){       
    //         if (opp.Primary_Contact__c == null && !acctMap.get(opp.AccountId).Contacts.isEmpty()){
    //             Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
    //             oppToUpdate.Primary_Contact__c = acctMap.get(opp.AccountId).Contacts[0].Id;
    //             oppList.add(oppToUpdate);
    //         }
    //     }
    //     update oppList;
    // }
}