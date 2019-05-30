@isTest
public class Test_ApexCalloutFromProcessBuilder {
    @isTest
    static void createAccountWithoutValidAddress(){
        Account a = new Account(
        	Name = 'Test Account'
            , BillingStreet = '123 Sesame St'
            , BillingCity = 'Somewhereville'
            , BillingState = 'CA'
            , BillingPostalCode = '12345'
        );
        
        List<Account> accList = new List<Account>();
        accList.add(a);
        
        Test.startTest();        
        System.enqueueJob(new QueueableApexCallout(accList));
        Test.stopTest();     
        
    }
}