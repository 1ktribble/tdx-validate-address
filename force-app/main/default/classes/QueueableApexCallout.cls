public class QueueableApexCallout implements Queueable, Database.AllowsCallouts{
    public List<Account> accList;

    public class AddressKeyFormatter {
        String[] AddressLine;
        String PostcodePrimaryLow, PoliticalDivision1, PoliticalDivision2, CountryCode;

        public AddressKeyFormatter(String countryCode) {

        }

        public AddressKeyFormatter(String countryCode, String[] addressLineArr, String postalCodePrimaryLow,
            String politicalDivision1, String politicalDivision2) {

        }
    }

    public QueueableApexCallout(List<Account> accList){
        this.accList = accList;
    }
    
    public void execute(QueueableContext qc){
        List<Account> accsToUpdate = new List<Account>();
        String accessToken = [SELECT MasterLabel, Token__c FROM AccessToken__mdt WHERE MasterLabel = 'UPS' LIMIT 1].Token__c;
        for(Account acc : this.accList){
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:UPS_Access');
            req.setHeader('Username', '{!$Credential.UserName}');
            req.setHeader('Password', '{!$Credential.Password}');
            req.setHeader('AccessLicenseNumber', accessToken);
            req.setHeader('content-type', 'application/json');
            req.setMethod('POST');
            
            JSONGenerator generator = JSON.createGenerator(true);
            generator.writeStartObject();
                generator.writeFieldName('XAVRequest');
                generator.writeStartObject();
                    generator.writeFieldName('AddressKeyFormat');
                        generator.writeStartObject();
                        generator.writeFieldName('AddressLine');
                        generator.writeStartArray();
                            generator.writeString(acc.BillingStreet);
                        generator.writeEndArray();
                        generator.writeStringField('PoliticalDivision2', acc.BillingCity);
                        generator.writeStringField('PoliticalDivision1', acc.BillingState);
                        generator.writeStringField('PostcodePrimaryLow', acc.BillingPostalCode); 
                        generator.writeStringField('CountryCode', acc.BillingCountry);
                    generator.writeEndObject();
                generator.writeEndObject();
            generator.writeEndObject(); 				//Writes the ending marker of a JSON object '}'
            String jsonString = generator.getAsString();
            
            req.setBody(jsonString);
            Http http = new Http();
            HTTPResponse res = http.send(req);

            if(res.getStatusCode() == 200){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody()); 

                UPSResponseFormatter upsResponse = new UPSResponseFormatter(
                    (Map<String, Object>) responseMap.get('XAVResponse')
                );
                
                Integer code = Integer.valueOf(upsResponse.getUPSResponseCode());
                
                if(code == 1) {
                    List<Address_Validation_Status__e> addressStatus = new List<Address_Validation_Status__e>();

                    addressStatus.add(
                        new Address_Validation_Status__e(
                            
                        )
                    );
                }
            } else if(res.getStatusCode() == 400) {

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