public class InvocableAddressCallout {
	@InvocableMethod(label='Validate Address Method' description='This method creates an instance of the queueable Apex Callout Class')
    public static void validateAddressMethod(List<Account> accounts){
        ID jobID = System.enqueueJob(new QueueableApexCallout(accounts));
    }
}