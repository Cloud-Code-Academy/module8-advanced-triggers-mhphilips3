public with sharing class OpportunityUtils {
    
    
    /**
     * Retrieves a map of Accounts and their related Contacts with the specified title.
     * 
     * @param accountIds A set of Account Ids to filter the query.
     * @param title The title of the Contacts to retrieve (e.g., 'VP Sales').
     * @return A map of Account Ids to Account records, including the related Contacts with the specified title.
     */
    public static Map<Id, Account> getAccountsWithContactsByTitle(Set<Id> accIds, String title) {
        Map<Id, Account> accMap = new Map<Id, Account> ([SELECT Id, Name,
                                                        (SELECT Id, AccountId FROM Contacts WHERE Title = :title)
                                                        FROM Account WHERE Id IN :accIds]);
        return accMap;

    }

    /**
     * Sets the Primary Contact for each Opportunity in the provided list, based on the related Account's identified primary contact.
     * 
     * If the Opportunity does not already have a Primary Contact, this method assigns the appropriate contact
     * from the provided map of Accounts, which contains the necessary related contacts.
     * 
     * @param oppList The list of Opportunities that need their Primary Contact field set.
     * @param accountIdToContact A map of Accounts, which includes a list of Contact records, representing each account's primary contact.
     * @return A list of Opportunities that had their Primary_Contact__c field updated. This list is useful in after 
     *         triggers where a bulk update operation is needed.
     */
    public static List<Opportunity> setPrimaryContactForOpportunities(List<Opportunity> oppList, Map<Id, Account> accMap){
        List<Opportunity> oppsToReturn = new List<Opportunity>();
        for (Opportunity opp : oppList){       
            if (opp.Primary_Contact__c == null && !accMap.get(opp.AccountId).Contacts.isEmpty()){
                Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                oppToUpdate.Primary_Contact__c = accMap.get(opp.AccountId).Contacts[0].Id;
                oppsToReturn.add(oppToUpdate);
            }
        }
        return oppsToReturn;
    }

    /**
     * Sets the Primary Contact for each Opportunity in the provided list, based on the related Account's Contacts with the specified title.
     * 
     * This method:
     * 1. Queries for Contacts with the given title (e.g., 'CEO') for the provided Account IDs.
     * 2. Maps Contacts to their related Accounts.
     * 3. Updates the Primary Contact field for each Opportunity if it is not already set.
     * 
     * @param oppList The list of Opportunities that need their Primary Contact field set.
     * @param accountIds A set of Account IDs to filter the query for relevant Contacts.
     * @param contactTitle The title of the Contacts to retrieve (e.g., 'CEO').
     */
    public static void setPrimaryContactForOpportunities(Set<Opportunity> oppSet, Set<Id> accountIds, String contactTitle){
        // Query for Contacts with the title 'CEO' for the collected Account IDs        
        Map<Id, Contact> contacts = new Map<Id, Contact>([SELECT Id, FirstName, AccountId
                                                        FROM Contact 
                                                        WHERE AccountId IN :accountIds 
                                                        AND Title = :contactTitle ORDER BY FirstName ASC]);
        
        // Map Contacts by their AccountId
        Map<Id, Contact> accountIdToContact = new Map<Id, Contact>();
        for (Contact cont : contacts.values()) {
            if (!accountIdToContact.containsKey(cont.AccountId)) {
                accountIdToContact.put(cont.AccountId, cont);
            }
        }

        // Set Primary Contact for Opportunities without one
        for(Opportunity opp : oppSet){
            if(opp.Primary_Contact__c == null){
                if (accountIdToContact.containsKey(opp.AccountId)){
                    opp.Primary_Contact__c = accountIdToContact.get(opp.AccountId).Id;
                }
            }
        }
    }


}