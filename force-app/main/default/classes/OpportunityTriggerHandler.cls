public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    
    private List<Opportunity> newOppList;
    private List<Opportunity> oldOppList;
    private Map<Id, Opportunity> oldOppMap;
    private Map<Id, Opportunity> newOppMap;
    
    public OpportunityTriggerHandler() {
        this.newOppList = (List<Opportunity>)Trigger.new;
        this.oldOppList = (List<Opportunity>)Trigger.old;
        this.oldOppMap = (Map<Id, Opportunity>)Trigger.oldMap;
        this.newOppMap = (Map<Id, Opportunity>)Trigger.newMap;

    }

    public override void beforeInsert(){
        // Set default Type for new Opportunities
        for (Opportunity opp : newOppList){
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }        
    }
    public override void beforeDelete(){
        // Prevents deletion of all closed Opportunities. 
        // Note: This covers a previous rule preventing deletion of Closed Won Opportunities for Banking accounts. 
        // If the rule for closed Opportunities changes, revisit the Banking-specific requirement.
        for (Opportunity oldOpp : oldOppList){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }    
        }
    }
    public override void beforeUpdate(){
        
        Set<Id> accountIds = new Set<Id>(); // used in logic to set Primary Contact
        Set<Opportunity> oppSet = new Set<Opportunity>(); // used in logic to set Primary Contact
        for (Opportunity opp : newOppList){ 
            // When an opportunity is updated validate that the amount is greater than 5000.               
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            } else {
                // Append Stage changes in Opportunity Description
                if (opp.StageName != null && opp.StageName != oldOppMap.get(opp.Id).StageName){
                    opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                }
                //When an opportunity is updated set the primary contact on the opportunity 
                //to the contact with the title of 'CEO'.
                //Get contacts related to the opportunity account                
                oppSet.add(opp);                // Creates set of opps that passed validation
                accountIds.add(opp.AccountId); // Creates Id set for Accts related to these opps
            }                                
        }               //Get CEO Contacts related to associated Accounts        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId
                                                            FROM Contact 
                                                            WHERE AccountId IN :accountIds 
                                                            AND Title = 'CEO' ORDER BY FirstName ASC]);
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        // Fill accountIdToContact Map 
        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }
        // Set Primary Contact for opps that don't already have one set
        for(Opportunity opp : oppSet){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }
    public override void afterInsert(){
        // Create a new Task for newly inserted Opportunities
        List<Task> taskList = new List<Task>();
        for (Opportunity opp : newOppList){
            Task tsk = new Task();
            tsk.Subject = 'Call Primary Contact';
            tsk.WhatId = opp.Id;
            tsk.WhoId = opp.Primary_Contact__c;
            tsk.OwnerId = opp.OwnerId;
            tsk.ActivityDate = Date.today().addDays(3);
            taskList.add(tsk);
        }
        insert taskList;
    }
    public override void afterDelete(){
        // Sends an email notification to the owner of the Opportunity when it gets deleted.
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<Opportunity> oppsWithOwnersList = new List<Opportunity>([SELECT Id, OwnerId, Name,
                                                                    Owner.Email FROM Opportunity WHERE Id IN :oldOppList]);
        for (Opportunity opp : oppsWithOwnersList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> setToAddresses = new List<String>{opp.Owner.Email};
            mail.setToAddresses(setToAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }        
        
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }
    public override void afterUndelete(){
        // Assign the primary contact to undeleted Opportunities
        Set <Id> accIdSet = new Set<Id>();
        for (Opportunity opp : newOppList){
            accIdSet.add(opp.AccountId);
        }
        Map<Id, Account> acctMap = new Map<Id, Account> ([SELECT Id, Name,
                                                        (SELECT Id, AccountId FROM Contacts WHERE Title ='VP Sales')
                                                        FROM Account WHERE Id IN :accIdSet]);
        List<Opportunity> oppList = new List<Opportunity>();
        for (Opportunity opp : newOppList){       
            if (opp.Primary_Contact__c == null && !acctMap.get(opp.AccountId).Contacts.isEmpty()){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = acctMap.get(opp.AccountId).Contacts[0].Id;
                oppList.add(oppToUpdate);
            }
        }
        update oppList;
    }
}