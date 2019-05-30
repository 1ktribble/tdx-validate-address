public class QueueableApexCallout implements Queueable, Database.AllowsCallouts{
    public List<Account> accList;
    
    public QueueableApexCallout(List<Account> accList){
        this.accList = accList;
    }
    
    public void execute(QueueableContext qc){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:codeysCreds'+'/verify');
        req.setHeader('content-type', 'application/json');
        req.setMethod('POST');
        
		JSONGenerator generator = JSON.createGenerator(true);   //instantiation of the generator
        for(Account acc : accList) {
           	generator.writeStartObject(); 				// Writes the starting marker of a JSON object '{'
			generator.writeStringField('street', acc.BillingStreet);  	//Writes the # of contacts 
			generator.writeStringField('city', acc.BillingCity);  	//Writes the # of contacts 
			generator.writeStringField('state', acc.BillingState);  	//Writes the # of contacts 
			generator.writeStringField('postal_code', acc.BillingPostalCode);  	//Writes the # of contacts 
            generator.writeEndObject(); 				//Writes the ending marker of a JSON object '}'
        }
        String jsonString = generator.getAsString();
        
        req.setBody(JSON.serialize(jsonString));
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
    }
}