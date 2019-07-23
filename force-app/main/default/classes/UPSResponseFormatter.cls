public class UPSResponseFormatter {
        Map<String, Object> upsResponseMap;
        List<Object> responseStatusList;

        public UPSResponseFormatter(Map<String, Object> upsResponse, Boolean isSuccess) {
            if(isSuccess){
                this.upsResponseMap = upsResponse;
            }
            else {
                Map<String, Object> responseObjectMap = (Map<String, Object>) upsResponse.get('response');
                this.responseStatusList = (List<Object>) responseObjectMap.get('errors');
            }
        }

        public String getAddressIndicator() {
            if (this.upsResponseMap.keySet().contains('ValidAddressIndicator')) {
                return 'Valid';
            }

            if (this.upsResponseMap.keySet().contains('NoCandidatesIndicator')) {
                return 'Invalid';
            }

            if (this.upsResponseMap.keySet().contains('AmbiguousAddressIndicator')) {
                return 'Ambiguous';
            }

            return 'Error';
        }

        public String getUPSResponseCode() {
            String responseCode;

            if(!this.responseStatusList.isEmpty()) {
                for (Object errorCodeMessageMapObject : this.responseStatusList) {
                    Map<String, Object> errorCodeMessageMap = (Map<String, Object>) errorCodeMessageMapObject;
                    responseCode = (String) errorCodeMessageMap.get('code');
                }
            } else {
                responseCode = '-1';
            }

            return responseCode;
        }

        public List<Object> getAddressOptions () {

            return null;
        }
    }

// Successful request, no match. {"Response":{"ResponseStatus":{"Code":"1","Description":"Success"}},"NoCandidatesIndicator":""}
// Successful request, with match. {"Response":{"ResponseStatus":{"Code":"1","Description":"Success"}},"ValidAddressIndicator":"","Candidate":{"AddressKeyFormat":"Map of size 7 too large to display"}}