/**
 * OpportunityTriggerHandler class extends the TriggerHandler framework to handle Opportunity trigger events.
 * 
 * This class handles different trigger events on the Opportunity object:
 * - beforeInsert: Sets a default type for new Opportunities if none is provided.
 * - beforeUpdate: Validates the Opportunity amount, appends stage change information to the description,
 *                  and sets the Primary Contact on Opportunities if it doesn't already exist.
 * - beforeDelete: Prevents deletion of closed Opportunities.
 * - afterInsert: Creates a follow-up task for newly created Opportunities.
 * - afterDelete: Sends an email notification when an Opportunity is deleted.
 * - afterUndelete: Reassigns the primary contact for undeleted Opportunities.
 * 
 * Important Notes:
 * - If the business rule for preventing deletion of closed Opportunities changes, review the rule for Closed Won 
 *   Opportunities tied to accounts in the 'Banking' industry.
 */
public with sharing class OpportunityTriggerHandler extends TriggerHandler{
    
    // Lists of new and old Opportunities, and a map of old Opportunities by Id for quick access in update triggers
    private List<Opportunity> newOppList;
    private List<Opportunity> oldOppList;
    private Map<Id, Opportunity> oldOppMap;
    
    // Constructor initializes the new and old Opportunity lists, and the old Opportunity map
    public OpportunityTriggerHandler() {
        this.newOppList = (List<Opportunity>)Trigger.new;
        this.oldOppList = (List<Opportunity>)Trigger.old;
        this.oldOppMap = (Map<Id, Opportunity>)Trigger.oldMap;
    }

    /**
     * beforeInsert handler
     * Sets a default Type for new Opportunities if it's not provided.
     * 
     * Business Rule: If an Opportunity is being inserted without a Type, set it to 'New Customer'.
     */
    public override void beforeInsert(){
        // Set default Type for new Opportunities
        for (Opportunity opp : newOppList){
            if (opp.Type == null){
                opp.Type = 'New Customer';
            }
        }        
    }

    /**
     * beforeDelete handler
     * Prevents deletion of closed Opportunities.
     * 
     * Business Rule: Closed Opportunities (Closed Won and Closed Lost) cannot be deleted.
     * This covers a rule preventing deletion of Closed Won Opportunities for accounts in the 'Banking' industry.
     */
    public override void beforeDelete(){
        for (Opportunity oldOpp : oldOppList){
            if (oldOpp.IsClosed){
                oldOpp.addError('Cannot delete closed opportunity');
            }    
        }
    }

    /**
     * beforeUpdate handler
     * - Validates that the Opportunity amount is greater than 5000.
     * - Appends any stage changes to the Opportunity description.
     * - Sets the primary contact to the contact with the title of 'CEO' for the Opportunity's account, if applicable.
     * 
     * Business Rules:
     * - The Opportunity amount must be greater than 5000.
     * - When the stage changes, this change is logged in the Opportunity's description.
     * - When the Opportunity has no Primary Contact (PC) identified, the PC is the first CEO from the related Account.
     */
    public override void beforeUpdate(){
        
        Set<Id> accountIds = new Set<Id>(); // Collect Account Ids for contact query (PC logic)
        Set<Opportunity> validOppSet = new Set<Opportunity>(); // Collect Opportunities that pass validation (PC logic)
        for (Opportunity opp : newOppList){ 
            // Validate that the Opportunity amount is greater than 5000               
            if(opp.Amount < 5000){
                opp.addError('Opportunity amount must be greater than 5000');
            } else {
                // Append stage changes to the Opportunity description if the stage has changed
                if (opp.StageName != null && opp.StageName != oldOppMap.get(opp.Id).StageName){
                    opp.Description += '\n Stage Change:' + opp.StageName + ':' + DateTime.now().format();
                }

                // Collect Opp records and Account IDs for validated opps                
                validOppSet.add(opp);
                accountIds.add(opp.AccountId);
            }                                
        }
        
        // Query for Contacts with the title 'CEO' for the collected Account IDs        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId
                                                        FROM Contact 
                                                        WHERE AccountId IN :accountIds 
                                                        AND Title = 'CEO' ORDER BY FirstName ASC]);
        
        // Map Contacts by their AccountId
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        // Set Primary Contact for Opportunities without one
        for(Opportunity opp : validOppSet){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }

    /**
     * afterInsert handler
     * Creates a follow-up Task for newly inserted Opportunities to call the primary contact.
     * 
     * Business Rule: When a new Opp is created, a Task is assigned to the Opportunity owner
     *                to follow up with the Primary Contact within 3 days.
     */
    public override void afterInsert(){
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

        // Bulk insert the follow-up tasks
        insert taskList;
    }

    /**
     * afterDelete handler
     * Sends an email notification to the Opportunity owner when the Opportunity is deleted.
     * 
     * Business Rule: When an Opportunity is deleted, notify the owner via email with the Opportunity details.
     */
    public override void afterDelete(){
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        // Query for Opportunities and their owners' emails
        List<Opportunity> oppsWithOwnersList = new List<Opportunity>([SELECT Id, OwnerId, Name,
                                                                    Owner.Email FROM Opportunity 
                                                                    WHERE Id IN :oldOppList]);
        
        // Create and send an email for each deleted Opportunity
        for (Opportunity opp : oppsWithOwnersList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> setToAddresses = new List<String>{opp.Owner.Email};
            mail.setToAddresses(setToAddresses);
            mail.setSubject('Opportunity Deleted : ' + opp.Name);
            mail.setPlainTextBody('Your Opportunity: ' + opp.Name +' has been deleted.');
            mails.add(mail);
        }

        // Send the email notifications
        try {
            Messaging.sendEmail(mails);
        } catch (Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
    }

    /**
     * afterUndelete handler
     * Reassigns the Primary Contact to undeleted Opportunities.
     * 
     * Business Rule: If an Opportunity is undeleted, assign the Primary Contact from the Account's 'VP Sales' contact.
     */
    public override void afterUndelete(){        
        
        // Gather Account IDs for the undeleted Opportunities
        Set <Id> accIdSet = new Set<Id>();
        for (Opportunity opp : newOppList){
            accIdSet.add(opp.AccountId);
        }

        // Query for Accounts and their specific Contacts with the title 'VP Sales'
        System.debug(accIdSet.size());
        Map<Id, Account> accMap = OpportunityUtils.getAccountsWithContactsByTitle(accIdSet, 'VP Sales');    
        System.debug('++++ accMap size ' + accMap.size());
        // Set the Primary Contact on Opps if no Primary Contact is set
        List<Opportunity> oppList = OpportunityUtils.setPrimaryContactForOpportunities(newOppList, accMap);
        // for (Opportunity opp : newOppList){       
        //     if (opp.Primary_Contact__c == null && !accMap.get(opp.AccountId).Contacts.isEmpty()){
        //         Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
        //         oppToUpdate.Primary_Contact__c = accMap.get(opp.AccountId).Contacts[0].Id;
        //         oppList.add(oppToUpdate);
        //     }
        // }
        System.debug('++++ oppList: ' + oppList.size() + oppList);
        // Bulk update the Opportunities with the new Primary Contacts
        update oppList;
    }
}