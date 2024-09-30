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

}