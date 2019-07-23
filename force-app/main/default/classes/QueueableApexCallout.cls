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

            List<Database.SaveResult> results = new List<Database.SaveResult>();

            if(res.getStatusCode() == 200){
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody()); 

                UPSResponseFormatter upsResponse = new UPSResponseFormatter(
                    (Map<String, Object>) responseMap.get('XAVResponse')
                    , true
                );
                
                String addressIndicatorType = upsResponse.getAddressIndicator();
                
                switch on addressIndicatorType {
                    when 'Valid' {
                        List<Address_Validation_Status__e> addressStatus = new List<Address_Validation_Status__e>();

                        addressStatus.add(
                            new Address_Validation_Status__e(
                                Object_Id__c = acc.Id
                                , Valid__c = true
                            )
                        );

                        results = Eventbus.publish(addressStatus);
                    }
                    when 'Invalid' {
                        List<Address_Validation_Status__e> addressStatus = new List<Address_Validation_Status__e>();

                        addressStatus.add(
                            new Address_Validation_Status__e(
                                Object_Id__c = acc.Id
                                , Valid__c = false
                            )
                        );

                        results = Eventbus.publish(addressStatus);
                    }
                    when 'Ambiguous' {
                        List<Address_Validation_Status__e> addressStatus = new List<Address_Validation_Status__e>();

                        addressStatus.add(
                            new Address_Validation_Status__e(
                                Object_Id__c = acc.Id
                                , Valid__c = false
                                , Ambiguous_Address_Options__c = 'placeholder'
                            )
                        );

                        results = Eventbus.publish(addressStatus);
                    }
                    when else {
                        List<Address_Validation_Status__e> addressStatus = new List<Address_Validation_Status__e>();

                        addressStatus.add(
                            new Address_Validation_Status__e(
                                Object_Id__c = acc.Id
                                , Valid__c = false
                                , Error_Message__c = 'error placeholder'
                            )
                        );

                        results = Eventbus.publish(addressStatus);
                    }
                }
            } else if(res.getStatusCode() == 400) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                UPSResponseFormatter upsResponse = new UPSResponseFormatter(
                    (Map<String, Object>) responseMap.get('response')
                    , false
                );

                Integer code = Integer.valueOf(upsResponse.getUPSResponseCode());

                List<Address_Validation_Status__e> addressStatus = new List<Address_Validation_Status__e>();

                addressStatus.add(
                    new Address_Validation_Status__e(
                        Object_Id__c = acc.Id
                        , Valid__c = false
                        , Error_Message__c = 'Unable to format response'
                    )
                );

                results = Eventbus.publish(addressStatus);
            } else {
                List<Address_Validation_Status__e> addressStatus = new List<Address_Validation_Status__e>();

                addressStatus.add(
                    new Address_Validation_Status__e(
                        Object_Id__c = acc.Id
                        , Valid__c = false
                        , Error_Message__c = 'The response code was ' + res.getStatusCode() + '.'
                    )
                );

                results = Eventbus.publish(addressStatus);
            }

            // Inspect publishing result for each event
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                    err.getStatusCode() +
                                    ' - ' +
                                    err.getMessage());
                    }
                }
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