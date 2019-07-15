public class QueueableApexCallout implements Queueable, Database.AllowsCallouts{
    public List<Account> accList;

    public QueueableApexCallout(List<Account> accList){
        this.accList = accList;
    }
    
    public void execute(QueueableContext qc){
        List<Account> accsToUpdate = new List<Account>();
        String accessToken = [SELECT MasterLabel, Token__c FROM AccessToken__mdt WHERE MasterLabel = 'UPS' LIMIT 1].Token__c;
        for(Account acc : this.accList){
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:UPS_Access');
            req.setHeader('AccessLicenseNumber', accessToken);
            req.setHeader('content-type', 'application/json');
            req.setMethod('POST');
            
            JSONGenerator generator = JSON.createGenerator(true);   //instantiation of the generator
            generator.writeStartObject(); 				// Writes the starting marker of a JSON object '{'
                generator.writeFieldName('XAVRequest');
                generator.writeStartObject();
                    generator.writeFieldName('AddressKeyFormat');
                    generator.writeStartObject();
                        generator.writeFieldName('AddressLine');
                        generator.writeStartArray();
                            generator.writeString(acc.BillingStreet);
                        generator.writeEndArray();
                        generator.writeStringField('PostcodePrimaryLow', acc.BillingPostalCode);
                        generator.writeStringField('PoliticalDivision2', acc.BillingCity);
                        generator.writeStringField('PoliticalDivision1', acc.BillingState);
                        generator.writeStringField('CountryCode', acc.BillingCountry);
                    generator.writeEndObject();
                generator.writeEndObject();
            generator.writeEndObject();
            String jsonString = generator.getAsString();
            
            req.setBody(JSON.serialize(jsonString));
            Http http = new Http();
            HTTPResponse res = http.send(req);

            if(res.getStatusCode()==200){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody()); 

                // TODO: Create an event with the response from the responseMap identifier.
            }
        }
    }
}

/* POST https://wwwcie.ups.com/addressvalidation/v1/1 HTTP/1.1
content-type: application/json
Username: upsSFDevEdition
Password: <password>
AccessLicenseNumber: <access-code>

{
    "XAVRequest": 
    {
        "AddressKeyFormat": 
        {
            "AddressLine":[
                "8430 Sunset Blvd",
                "",
                ""
            ],
            "PostcodePrimaryLow": "90069",
            "PoliticalDivision2": "Los Angeles",
            "PoliticalDivision1": "CA",
            "CountryCode": "US"
        }
    }
} */